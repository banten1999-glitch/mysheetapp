import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_settings.dart';
import '../../data/services/settings_service.dart';
import 'core_providers.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._service) : super(const AppSettings()) {
    _load();
  }

  final SettingsService _service;

  Future<void> _load() async {
    state = await _service.load();
  }

  Future<void> update(AppSettings Function(AppSettings current) updater) async {
    final next = updater(state);
    state = next;
    await _service.save(next);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});
