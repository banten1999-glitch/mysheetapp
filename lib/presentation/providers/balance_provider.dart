import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/google_sheets_service.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'ledger_provider.dart';
import 'settings_provider.dart';

/// Credit/debit totals read live from the linked sheet.
///
/// Read from the sheet rather than computed locally on purpose: the sheet
/// holds the full history (hundreds of rows entered before this app
/// existed), while the local database only knows the entries this app
/// created.
///
/// Returns null when there's nothing to read yet - not signed in, sheet not
/// configured, or authorization would need a prompt.
final sheetTotalsProvider = FutureProvider.autoDispose<SheetTotals?>((ref) async {
  final settings = ref.watch(settingsProvider);
  final account = ref.watch(authProvider).account;

  // Re-read whenever the ledger changes so the balance follows a new entry.
  ref.watch(ledgerProvider.select((s) => s.entries.length));

  if (account == null || !settings.isSheetsConfigured) return null;

  final online = await ref.read(connectivityServiceProvider).isOnlineNow();
  if (!online) return null;

  // Silent-only: this runs on screen build, not from a user tap, so it must
  // never pop an authorization dialog.
  final client = await ref
      .read(googleAuthServiceProvider)
      .getSilentAuthorizedClient(account);
  if (client == null) return null;

  try {
    return await GoogleSheetsService(
      client: client,
      spreadsheetId: settings.spreadsheetId,
      sheetName: settings.sheetName,
      columnLetters: settings.effectiveColumnLetters,
    ).fetchTotals();
  } finally {
    client.close();
  }
});
