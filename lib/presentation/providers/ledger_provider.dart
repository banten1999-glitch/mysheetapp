import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../domain/models/ledger_entry.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'settings_provider.dart';

class LedgerState {
  const LedgerState({
    this.entries = const [],
    this.nextSerial = 1,
    this.isLoading = true,
    this.isSubmitting = false,
    this.isSyncing = false,
    this.lastError,
    this.lastSuccessMessage,
  });

  final List<LedgerEntry> entries;
  final int nextSerial;
  final bool isLoading;
  final bool isSubmitting;
  final bool isSyncing;
  final String? lastError;
  final String? lastSuccessMessage;

  LedgerState copyWith({
    List<LedgerEntry>? entries,
    int? nextSerial,
    bool? isLoading,
    bool? isSubmitting,
    bool? isSyncing,
    String? lastError,
    bool clearError = false,
    String? lastSuccessMessage,
    bool clearSuccess = false,
  }) {
    return LedgerState(
      entries: entries ?? this.entries,
      nextSerial: nextSerial ?? this.nextSerial,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastSuccessMessage: clearSuccess ? null : (lastSuccessMessage ?? this.lastSuccessMessage),
    );
  }
}

class LedgerNotifier extends StateNotifier<LedgerState> {
  LedgerNotifier(this._ref, this._repository) : super(const LedgerState()) {
    refresh();
  }

  final Ref _ref;
  final LedgerRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _repository.getAll();
      final settings = _ref.read(settingsProvider);
      final account = _ref.read(authProvider).account;
      final nextSerial = settings.manualSerialEditable
          ? state.nextSerial
          : await _repository.computeNextSerial(settings: settings, account: account);
      state = state.copyWith(entries: entries, nextSerial: nextSerial, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, lastError: 'تعذّر تحميل السجل: $e');
    }
  }

  void setManualSerial(int serial) {
    state = state.copyWith(nextSerial: serial);
  }

  /// Returns true on success. Errors are surfaced via [LedgerState.lastError]
  /// without throwing, so the caller (UI) can just watch state.
  Future<bool> addEntry({
    required DateTime entryDate,
    required String statement,
    String? note,
    File? receiptImage,
    double? debitAmount,
    double? creditAmount,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final settings = _ref.read(settingsProvider);
      final account = _ref.read(authProvider).account;
      final saved = await _repository.addEntry(
        serial: state.nextSerial,
        entryDate: entryDate,
        statement: statement,
        note: note,
        receiptImage: receiptImage,
        debitAmount: debitAmount,
        creditAmount: creditAmount,
        settings: settings,
        account: account,
      );
      final message = saved.syncStatus.name == 'synced'
          ? 'تم حفظ العملية ورفعها بنجاح.'
          : 'تم حفظ العملية محلياً. سيتم رفعها عند توفر الاتصال.';
      state = state.copyWith(isSubmitting: false, lastSuccessMessage: message);
      await refresh();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, lastError: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, lastError: 'حدث خطأ غير متوقع: $e');
      return false;
    }
  }

  /// Returns true on success. Errors are surfaced via [LedgerState.lastError].
  Future<bool> updateEntry({
    required LedgerEntry original,
    required DateTime entryDate,
    required String statement,
    String? note,
    File? newReceiptImage,
    bool removeReceiptImage = false,
    double? debitAmount,
    double? creditAmount,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final settings = _ref.read(settingsProvider);
      final account = _ref.read(authProvider).account;
      final saved = await _repository.updateEntry(
        original: original,
        entryDate: entryDate,
        statement: statement,
        note: note,
        newReceiptImage: newReceiptImage,
        removeReceiptImage: removeReceiptImage,
        debitAmount: debitAmount,
        creditAmount: creditAmount,
        settings: settings,
        account: account,
      );
      final message = saved.syncStatus.name == 'synced'
          ? 'تم تحديث العملية ورفعها بنجاح.'
          : 'تم تحديث العملية محلياً. سيتم رفعها عند توفر الاتصال.';
      state = state.copyWith(isSubmitting: false, lastSuccessMessage: message);
      await refresh();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, lastError: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, lastError: 'حدث خطأ غير متوقع: $e');
      return false;
    }
  }

  /// Returns true on success. Errors are surfaced via [LedgerState.lastError].
  Future<bool> deleteEntry(LedgerEntry entry) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final settings = _ref.read(settingsProvider);
      final account = _ref.read(authProvider).account;
      await _repository.deleteEntry(entry, settings: settings, account: account);
      state = state.copyWith(isSubmitting: false, lastSuccessMessage: 'تم حذف العملية.');
      await refresh();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, lastError: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, lastError: 'حدث خطأ غير متوقع: $e');
      return false;
    }
  }

  Future<void> syncAll({bool interactive = true}) async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, clearError: true);
    try {
      final settings = _ref.read(settingsProvider);
      final account = _ref.read(authProvider).account;
      final summary = await _repository.syncAll(
        settings: settings,
        account: account,
        interactive: interactive,
      );
      if (summary.skippedNoAccount) {
        state = state.copyWith(isSyncing: false, lastError: 'يرجى تسجيل الدخول أولاً لمزامنة العمليات.');
      } else if (summary.failed > 0) {
        state = state.copyWith(
          isSyncing: false,
          lastError: 'تمت مزامنة ${summary.succeeded} عملية، وفشلت ${summary.failed}. سيُعاد المحاولة لاحقاً.',
        );
      } else if (summary.succeeded > 0) {
        state = state.copyWith(isSyncing: false, lastSuccessMessage: 'تمت مزامنة ${summary.succeeded} عملية بنجاح.');
      } else {
        state = state.copyWith(isSyncing: false);
      }
    } on AppException catch (e) {
      state = state.copyWith(isSyncing: false, lastError: e.message);
    } catch (e) {
      state = state.copyWith(isSyncing: false, lastError: 'تعذّرت المزامنة: $e');
    } finally {
      await refresh();
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final ledgerProvider = StateNotifierProvider<LedgerNotifier, LedgerState>((ref) {
  return LedgerNotifier(ref, ref.watch(ledgerRepositoryProvider));
});
