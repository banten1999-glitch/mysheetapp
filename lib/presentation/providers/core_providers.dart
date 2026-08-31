import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/transactions_dao.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/google_auth_service.dart';
import '../../data/services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => ConnectivityService());

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) => GoogleAuthService());

final transactionsDaoProvider =
    Provider<TransactionsDao>((ref) => TransactionsDao(AppDatabase.instance));

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(
    dao: ref.watch(transactionsDaoProvider),
    authService: ref.watch(googleAuthServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});
