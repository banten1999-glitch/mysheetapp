import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/app_settings.dart';

/// Persists non-sensitive app configuration (which Sheet/Folder to use,
/// display prefs). Nothing here is a credential - tokens are never stored
/// by this service.
class SettingsService {
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final headers = _decodeMap(
      prefs.getString(AppConstants.prefsColumnHeaders),
      AppConstants.defaultColumnHeaders,
    );
    // A saved mapping from before the current layout revision refers to
    // fields/columns that no longer apply, so fall back to the defaults
    // rather than merging stale entries forward.
    final savedVersion = prefs.getInt(AppConstants.prefsColumnMappingVersion) ?? 1;
    final letters = savedVersion < AppConstants.columnMappingVersion
        ? AppConstants.defaultColumnLetters
        : _decodeMap(
            prefs.getString(AppConstants.prefsColumnLetters),
            AppConstants.defaultColumnLetters,
          );

    final themeIndex = prefs.getInt(AppConstants.prefsThemeMode) ?? ThemeMode.system.index;

    return AppSettings(
      spreadsheetId: prefs.getString(AppConstants.prefsSpreadsheetId) ?? '',
      sheetName: prefs.getString(AppConstants.prefsSheetName) ?? AppConstants.defaultSheetName,
      driveFolderId: prefs.getString(AppConstants.prefsDriveFolderId) ?? '',
      startingSerial:
          prefs.getInt(AppConstants.prefsStartingSerial) ?? AppConstants.defaultStartingSerial,
      manualSerialEditable: prefs.getBool(AppConstants.prefsManualSerialEditable) ?? false,
      currency: prefs.getString(AppConstants.prefsCurrency) ?? AppConstants.defaultCurrency,
      allowBothAmounts: prefs.getBool(AppConstants.prefsAllowBothAmounts) ?? false,
      appName: prefs.getString(AppConstants.prefsAppName) ?? AppConstants.defaultAppName,
      themeMode: ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
      columnHeaders: headers,
      columnLetters: letters,
      autoSync: prefs.getBool(AppConstants.prefsAutoSync) ?? true,
      usdRate: prefs.getDouble(AppConstants.prefsUsdRate) ?? 0,
      usdRateUpdatedAt: switch (prefs.getInt(AppConstants.prefsUsdRateUpdatedAt)) {
        final int millis => DateTime.fromMillisecondsSinceEpoch(millis),
        null => null,
      },
    );
  }

  Map<String, String> _decodeMap(String? raw, Map<String, String> fallback) {
    if (raw == null) return fallback;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      // Merge over the defaults so a field added in a later app version
      // still has a value when older saved settings are loaded.
      return <String, String>{
        ...fallback,
        ...decoded.map((k, v) => MapEntry(k, v.toString())),
      };
    } catch (_) {
      return fallback;
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsSpreadsheetId, settings.spreadsheetId);
    await prefs.setString(AppConstants.prefsSheetName, settings.sheetName);
    await prefs.setString(AppConstants.prefsDriveFolderId, settings.driveFolderId);
    await prefs.setInt(AppConstants.prefsStartingSerial, settings.startingSerial);
    await prefs.setBool(AppConstants.prefsManualSerialEditable, settings.manualSerialEditable);
    await prefs.setString(AppConstants.prefsCurrency, settings.currency);
    await prefs.setBool(AppConstants.prefsAllowBothAmounts, settings.allowBothAmounts);
    await prefs.setString(AppConstants.prefsAppName, settings.appName);
    await prefs.setInt(AppConstants.prefsThemeMode, settings.themeMode.index);
    await prefs.setString(AppConstants.prefsColumnHeaders, jsonEncode(settings.columnHeaders));
    await prefs.setString(AppConstants.prefsColumnLetters, jsonEncode(settings.columnLetters));
    await prefs.setInt(
      AppConstants.prefsColumnMappingVersion,
      AppConstants.columnMappingVersion,
    );
    await prefs.setBool(AppConstants.prefsAutoSync, settings.autoSync);
    await prefs.setDouble(AppConstants.prefsUsdRate, settings.usdRate);
    final rateUpdatedAt = settings.usdRateUpdatedAt;
    if (rateUpdatedAt != null) {
      await prefs.setInt(
        AppConstants.prefsUsdRateUpdatedAt,
        rateUpdatedAt.millisecondsSinceEpoch,
      );
    }
  }
}
