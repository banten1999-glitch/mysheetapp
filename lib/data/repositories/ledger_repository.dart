import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/ledger_entry.dart';
import '../../domain/models/sync_status.dart';
import '../local/transactions_dao.dart';
import '../services/connectivity_service.dart';
import '../services/google_auth_service.dart';
import '../services/google_drive_service.dart';
import '../services/google_sheets_service.dart';

const _uuid = Uuid();

/// Orchestrates the offline-first flow: every new entry is written locally
/// first, then synced to Google Sheets/Drive when possible. A single
/// in-flight guard prevents duplicate concurrent sync passes (double taps,
/// connectivity-restored + manual sync firing together, etc).
class LedgerRepository {
  LedgerRepository({
    required TransactionsDao dao,
    required GoogleAuthService authService,
    required ConnectivityService connectivityService,
  })  : _dao = dao,
        _authService = authService,
        _connectivityService = connectivityService;

  final TransactionsDao _dao;
  final GoogleAuthService _authService;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;
  final Set<String> _currentlySyncing = {};

  Future<List<LedgerEntry>> getAll() => _dao.getAll();

  /// Computes the next serial by combining the local queue's highest serial
  /// with the remote sheet's highest serial (when reachable), so numbering
  /// stays sequential and collision-free whether or not previous entries
  /// have synced yet.
  Future<int> computeNextSerial({
    required AppSettings settings,
    required GoogleSignInAccount? account,
  }) async {
    final localMax = await _dao.getMaxSerial();
    int base = settings.startingSerial - 1;
    if (localMax != null && localMax > base) base = localMax;

    if (account != null && settings.isSheetsConfigured) {
      final online = await _connectivityService.isOnlineNow();
      if (online) {
        try {
          // Silent-only: this runs on app startup / pull-to-refresh, not
          // necessarily from a direct user tap, so it must never prompt.
          final client = await _authService.getSilentAuthorizedClient(account);
          if (client != null) {
            final sheets = GoogleSheetsService(
              client: client,
              spreadsheetId: settings.spreadsheetId,
              sheetName: settings.sheetName,
              columnLetters: settings.effectiveColumnLetters,
            );
            final remoteMax = await sheets.getMaxSerial();
            client.close();
            if (remoteMax != null && remoteMax > base) base = remoteMax;
          }
        } catch (_) {
          // Fall back to local-only numbering; sync will reconcile later.
        }
      }
    }
    return base + 1;
  }

  /// Validates, persists locally, and (if possible) immediately syncs a new
  /// entry. Returns the saved entry.
  Future<LedgerEntry> addEntry({
    required int serial,
    DateTime? entryDate,
    required String statement,
    String? note,
    File? receiptImage,
    double? debitAmount,
    double? creditAmount,
    required AppSettings settings,
    required GoogleSignInAccount? account,
  }) async {
    _validate(
      statement: statement,
      debitAmount: debitAmount,
      creditAmount: creditAmount,
      allowBoth: settings.allowBothAmounts,
    );

    if (await _dao.serialExists(serial)) {
      throw ValidationException('رقم الرديف $serial مستخدم بالفعل. يرجى اختيار رقم آخر.');
    }

    final now = DateTime.now();
    final entry = LedgerEntry(
      transactionId: _uuid.v4(),
      serial: serial,
      date: AppFormatters.date(entryDate ?? now),
      time: AppFormatters.time(now),
      statement: statement.trim(),
      note: (note ?? '').trim().isEmpty ? null : note!.trim(),
      localImagePath: receiptImage?.path,
      debitAmount: debitAmount,
      creditAmount: creditAmount,
      syncStatus: SyncStatus.pending,
      createdAt: now,
    );

    await _dao.insert(entry);

    if (account != null && settings.isFullyConfigured) {
      final online = await _connectivityService.isOnlineNow();
      if (online) {
        try {
          await _syncEntry(entry, settings: settings, account: account);
        } catch (_) {
          // Left as pending/failed for later retry - addEntry itself must
          // never throw once the local write has succeeded.
        }
      }
    }

    return (await _dao.getByTransactionId(entry.transactionId))!;
  }

  /// Updates an existing entry's editable fields and re-syncs it. If the
  /// entry was already synced, the sync step overwrites its existing row in
  /// the sheet in place (via [GoogleSheetsService.updateRow]) rather than
  /// appending a duplicate. The serial number and transactionId never change.
  Future<LedgerEntry> updateEntry({
    required LedgerEntry original,
    required DateTime entryDate,
    required String statement,
    String? note,
    File? newReceiptImage,
    bool removeReceiptImage = false,
    double? debitAmount,
    double? creditAmount,
    required AppSettings settings,
    required GoogleSignInAccount? account,
  }) async {
    _validate(
      statement: statement,
      debitAmount: debitAmount,
      creditAmount: creditAmount,
      allowBoth: settings.allowBothAmounts,
    );

    var updated = original.copyWith(
      date: AppFormatters.date(entryDate),
      statement: statement.trim(),
      note: (note ?? '').trim().isEmpty ? null : note!.trim(),
      clearNote: (note ?? '').trim().isEmpty,
      debitAmount: debitAmount,
      clearDebitAmount: (debitAmount ?? 0) <= 0,
      creditAmount: creditAmount,
      clearCreditAmount: (creditAmount ?? 0) <= 0,
      syncStatus: SyncStatus.pending,
      clearErrorMessage: true,
    );

    if (newReceiptImage != null) {
      updated = updated.copyWith(
        localImagePath: newReceiptImage.path,
        clearDriveFileId: true,
        clearReceiptUrl: true,
      );
    } else if (removeReceiptImage) {
      updated = updated.copyWith(
        clearLocalImagePath: true,
        clearDriveFileId: true,
        clearReceiptUrl: true,
      );
    }

    await _dao.update(updated);

    if (account != null && settings.isFullyConfigured) {
      final online = await _connectivityService.isOnlineNow();
      if (online) {
        try {
          await _syncEntry(updated, settings: settings, account: account);
        } catch (_) {
          // Left as pending/failed for later retry.
        }
      }
    }

    return (await _dao.getByTransactionId(updated.transactionId))!;
  }

  /// Deletes [entry]. If it never reached the sheet (pending/failed), it's
  /// removed immediately, along with any not-yet-uploaded local image file.
  /// Otherwise it's hidden from the UI right away (soft delete) and the
  /// remote row/image are cleaned up now if online, or by the next sync pass
  /// (manual "Sync now" or automatic on reconnect) if not.
  Future<void> deleteEntry(
    LedgerEntry entry, {
    required AppSettings settings,
    required GoogleSignInAccount? account,
  }) async {
    if (entry.syncStatus == SyncStatus.pending || entry.syncStatus == SyncStatus.failed) {
      if (entry.localImagePath != null) {
        try {
          final file = File(entry.localImagePath!);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // Best-effort cleanup only.
        }
      }
      await _dao.hardDelete(entry.transactionId);
      return;
    }

    await _dao.markPendingDeletion(entry.transactionId);

    if (account != null && settings.isFullyConfigured) {
      final online = await _connectivityService.isOnlineNow();
      if (online) {
        try {
          await _processDeletion(entry.transactionId, settings: settings, account: account);
        } catch (_) {
          // Left as pending_delete for the next sync pass to retry.
        }
      }
    }
  }

  /// Returns true if the deletion was fully processed (or there was nothing
  /// left to do). Throws on a genuine failure so the caller can count it.
  Future<bool> _processDeletion(
    String transactionId, {
    required AppSettings settings,
    required GoogleSignInAccount account,
    bool interactive = true,
  }) async {
    final entry = await _dao.getByTransactionId(transactionId);
    if (entry == null) return true;

    final client = interactive
        ? await _authService.getAuthorizedClient(account)
        : await _authService.getSilentAuthorizedClient(account);
    if (client == null) return false;

    try {
      final sheets = GoogleSheetsService(
        client: client,
        spreadsheetId: settings.spreadsheetId,
        sheetName: settings.sheetName,
        columnLetters: settings.effectiveColumnLetters,
      );
      final rowNumber = await sheets.findRowNumber(transactionId);
      if (rowNumber != null) {
        await sheets.deleteRow(rowNumber);
      }

      if (entry.driveFileId != null) {
        try {
          final drive = GoogleDriveService(client: client);
          await drive.deleteFile(entry.driveFileId!);
        } catch (_) {
          // Best-effort: don't block the local/sheet cleanup on a stray
          // Drive file that may already be gone or inaccessible.
        }
      }

      await _dao.hardDelete(transactionId);
      return true;
    } finally {
      client.close();
    }
  }

  void _validate({
    required String statement,
    double? debitAmount,
    double? creditAmount,
    required bool allowBoth,
  }) {
    if (statement.trim().isEmpty) {
      throw const ValidationException('يرجى إدخال البيان.');
    }
    final hasDebit = (debitAmount ?? 0) > 0;
    final hasCredit = (creditAmount ?? 0) > 0;
    if (!hasDebit && !hasCredit) {
      throw const ValidationException('يجب إدخال مبلغ في مدين له أو مدين عليه.');
    }
    if (hasDebit && hasCredit && !allowBoth) {
      throw const ValidationException(
        'لا يمكن إدخال مبلغ في مدين له ومدين عليه معاً. يمكن تفعيل ذلك من الإعدادات.',
      );
    }
    if ((debitAmount != null && debitAmount < 0) || (creditAmount != null && creditAmount < 0)) {
      throw const ValidationException('يجب أن يكون المبلغ أكبر من صفر.');
    }
  }

  /// Syncs every pending/failed local entry, in serial order, one at a time.
  ///
  /// [interactive] must be true only when this call originates directly from
  /// a user tap (Sync now, Save). Automatic background sync (e.g. triggered
  /// by connectivity being restored) must pass false so it never pops an
  /// authorization prompt unprompted - entries that need one are simply left
  /// pending until the user next triggers a manual sync.
  Future<SyncSummary> syncAll({
    required AppSettings settings,
    required GoogleSignInAccount? account,
    bool interactive = true,
  }) async {
    if (_isSyncing) {
      return const SyncSummary(succeeded: 0, failed: 0, skippedNoAccount: false, alreadyRunning: true);
    }
    if (account == null) {
      return const SyncSummary(succeeded: 0, failed: 0, skippedNoAccount: true, alreadyRunning: false);
    }
    if (!settings.isFullyConfigured) {
      throw const SettingsNotConfiguredException();
    }

    _isSyncing = true;
    var succeeded = 0;
    var failed = 0;
    try {
      final pending = await _dao.getPendingOrFailed();
      for (final entry in pending) {
        try {
          final synced = await _syncEntry(
            entry,
            settings: settings,
            account: account,
            interactive: interactive,
          );
          if (synced) succeeded++;
        } catch (_) {
          failed++;
        }
      }

      final pendingDeletions = await _dao.getPendingDeletions();
      for (final entry in pendingDeletions) {
        try {
          final done = await _processDeletion(
            entry.transactionId,
            settings: settings,
            account: account,
            interactive: interactive,
          );
          if (done) succeeded++;
        } catch (_) {
          failed++;
        }
      }
    } finally {
      _isSyncing = false;
    }
    return SyncSummary(succeeded: succeeded, failed: failed, skippedNoAccount: false, alreadyRunning: false);
  }

  /// Returns true if the entry ended up synced, false if it was left
  /// untouched (already syncing elsewhere, or non-interactive authorization
  /// unavailable). Throws on a genuine sync failure.
  Future<bool> _syncEntry(
    LedgerEntry entry, {
    required AppSettings settings,
    required GoogleSignInAccount account,
    bool interactive = true,
  }) async {
    if (_currentlySyncing.contains(entry.transactionId)) return false;
    _currentlySyncing.add(entry.transactionId);

    var working = entry.copyWith(syncStatus: SyncStatus.syncing, clearErrorMessage: true);
    await _dao.update(working);

    try {
      final client = interactive
          ? await _authService.getAuthorizedClient(account)
          : await _authService.getSilentAuthorizedClient(account);
      if (client == null) {
        // Not authorized without prompting - revert to pending, not failed;
        // the next manual sync will pick it up.
        working = working.copyWith(syncStatus: SyncStatus.pending);
        await _dao.update(working);
        return false;
      }
      try {
        final sheets = GoogleSheetsService(
          client: client,
          spreadsheetId: settings.spreadsheetId,
          sheetName: settings.sheetName,
          columnLetters: settings.effectiveColumnLetters,
        );

        // Upsert by transactionId: if a row already exists (a retried sync
        // whose earlier response was lost, or an edit made after the entry
        // was already synced), overwrite it in place instead of appending a
        // duplicate row.
        final existingRow = await sheets.findRowNumber(working.transactionId);

        if (working.localImagePath != null && working.driveFileId == null) {
          final drive = GoogleDriveService(client: client);
          final file = File(working.localImagePath!);
          if (await file.exists()) {
            final fileName = AppFormatters.receiptFileName(serial: working.serial, at: working.createdAt);
            final uploaded = await drive.uploadReceipt(
              file: file,
              fileName: fileName,
              folderId: settings.driveFolderId,
            );
            working = working.copyWith(
              driveFileId: uploaded.fileId,
              receiptUrl: uploaded.url,
              clearLocalImagePath: true,
            );
            await _dao.update(working);
          } else {
            // Local file vanished (e.g. cache cleared) - proceed without it.
            working = working.copyWith(clearLocalImagePath: true);
          }
        }

        await sheets.ensureHeaderRow(settings.headerValuesByField);
        if (existingRow != null) {
          await sheets.updateRow(existingRow, working.toSheetValues());
        } else {
          await sheets.insertEntryRow(working.toSheetValues());
        }

        working = working.copyWith(syncStatus: SyncStatus.synced, clearErrorMessage: true);
        await _dao.update(working);
        return true;
      } finally {
        client.close();
      }
    } on AppException catch (e) {
      working = working.copyWith(syncStatus: SyncStatus.failed, errorMessage: e.message);
      await _dao.update(working);
      rethrow;
    } catch (e) {
      working = working.copyWith(syncStatus: SyncStatus.failed, errorMessage: e.toString());
      await _dao.update(working);
      rethrow;
    } finally {
      _currentlySyncing.remove(entry.transactionId);
    }
  }
}

class SyncSummary {
  const SyncSummary({
    required this.succeeded,
    required this.failed,
    required this.skippedNoAccount,
    required this.alreadyRunning,
  });

  final int succeeded;
  final int failed;
  final bool skippedNoAccount;
  final bool alreadyRunning;
}
