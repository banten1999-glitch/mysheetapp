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
    Map<String, String> headers = AppConstants.defaultColumnHeaders;
    final rawHeaders = prefs.getString(AppConstants.prefsColumnHeaders);
    if (rawHeaders != null) {
      try {
        final decoded = jsonDecode(rawHeaders) as Map<String, dynamic>;
        headers = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        headers = AppConstants.defaultColumnHeaders;
      }
    }

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
      autoSync: prefs.getBool(AppConstants.prefsAutoSync) ?? true,
    );
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
    await prefs.setBool(AppConstants.prefsAutoSync, settings.autoSync);
  }
}
