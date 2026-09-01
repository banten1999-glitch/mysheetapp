import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/sheet_columns.dart';

/// Talks to a single Google Sheet (spreadsheet + tab) configured by the
/// user in Settings.
///
/// Which spreadsheet column each field lands in is fully user-configurable
/// (Settings -> "تعديل الخلايا"); [columnLetters] carries that mapping and
/// every range/row built here is derived from it.
class GoogleSheetsService {
  GoogleSheetsService({
    required gapis.AuthClient client,
    required String spreadsheetId,
    required String sheetName,
    Map<String, String>? columnLetters,
  })  : _api = sheets.SheetsApi(client),
        _spreadsheetId = spreadsheetId,
        _sheetName = sheetName,
        _columnLetters = columnLetters ?? AppConstants.defaultColumnLetters;

  final sheets.SheetsApi _api;
  final String _spreadsheetId;
  final String _sheetName;
  final Map<String, String> _columnLetters;

  String get _lastLetter => SheetColumns.maxLetterOf(_columnLetters);

  String _letterFor(String field) =>
      _columnLetters[field] ?? AppConstants.defaultColumnLetters[field] ?? 'A';

  String get _dataColumnsRange => "'$_sheetName'!A:$_lastLetter";
  String get _headerRowRange => "'$_sheetName'!A1:${_lastLetter}1";

  String _singleColumnRange(String field) {
    final letter = _letterFor(field);
    return "'$_sheetName'!${letter}2:$letter";
  }

  Future<void> testConnection() async {
    try {
      await _api.spreadsheets.get(_spreadsheetId);
    } catch (e) {
      throw SheetsException(
        'تعذّر الوصول إلى Google Sheets. تحقق من Spreadsheet ID والصلاحيات.\n($e)',
      );
    }
  }

  /// Writes the header row only when row 1 is still empty, so a sheet that
  /// already has its own headers is never overwritten.
  Future<void> ensureHeaderRow(Map<String, Object?> headerValuesByField) async {
    try {
      final existing = await _api.spreadsheets.values.get(
        _spreadsheetId,
        _headerRowRange,
      );
      final hasHeader = existing.values != null && existing.values!.isNotEmpty;
      if (hasHeader) return;

      final row = SheetColumns.buildRow(
        valuesByField: headerValuesByField,
        columnLetters: _columnLetters,
      );
      await _api.spreadsheets.values.update(
        sheets.ValueRange(values: [row]),
        _spreadsheetId,
        _headerRowRange,
        valueInputOption: 'USER_ENTERED',
      );
    } catch (e) {
      throw SheetsException('تعذّر كتابة صف العناوين في الشيت.\n($e)');
    }
  }

  /// Highest serial number currently in the serial column (header excluded).
  /// Returns null if the sheet has no data rows yet.
  Future<int?> getMaxSerial() async {
    try {
      final resp = await _api.spreadsheets.values.get(
        _spreadsheetId,
        _singleColumnRange('serial'),
      );
      final rows = resp.values ?? const [];
      int? max;
      for (final row in rows) {
        if (row.isEmpty) continue;
        final n = int.tryParse(row.first.toString().trim());
        if (n != null && (max == null || n > max)) max = n;
      }
      return max;
    } catch (e) {
      throw SheetsException('تعذّرت قراءة آخر رقم رديف من الشيت.\n($e)');
    }
  }

  /// Row number (1-based, matching the sheet's own numbering) of the row
  /// whose transaction-id column matches, or null if not present yet. Used
  /// to avoid writing a retried operation twice, and to locate the row to
  /// overwrite or delete for an already-synced entry.
  Future<int?> findRowNumber(String transactionId) async {
    try {
      final resp = await _api.spreadsheets.values.get(
        _spreadsheetId,
        _singleColumnRange('transactionId'),
      );
      final rows = resp.values ?? const [];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isNotEmpty && row.first.toString() == transactionId) {
          return i + 2; // range starts at row 2 (row 1 is the header)
        }
      }
      return null;
    } catch (e) {
      throw SheetsException('تعذّر التحقق من تكرار العملية.\n($e)');
    }
  }

  Future<void> appendRow(Map<String, Object?> valuesByField) async {
    try {
      final row = SheetColumns.buildRow(
        valuesByField: valuesByField,
        columnLetters: _columnLetters,
      );
      await _api.spreadsheets.values.append(
        sheets.ValueRange(values: [row]),
        _spreadsheetId,
        _dataColumnsRange,
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );
    } catch (e) {
      throw SheetsException('فشل حفظ الصف في Google Sheets.\n($e)');
    }
  }

  /// Overwrites an existing row (1-based [rowNumber]) in place - used when
  /// re-syncing an entry that already has a row (a retry, or an edit made
  /// after the original sync).
  Future<void> updateRow(int rowNumber, Map<String, Object?> valuesByField) async {
    try {
      final row = SheetColumns.buildRow(
        valuesByField: valuesByField,
        columnLetters: _columnLetters,
      );
      await _api.spreadsheets.values.update(
        sheets.ValueRange(values: [row]),
        _spreadsheetId,
        "'$_sheetName'!A$rowNumber:$_lastLetter$rowNumber",
        valueInputOption: 'USER_ENTERED',
      );
    } catch (e) {
      throw SheetsException('فشل تحديث الصف في Google Sheets.\n($e)');
    }
  }

  /// Physically removes a row (1-based [rowNumber]) - rows below shift up.
  Future<void> deleteRow(int rowNumber) async {
    try {
      final spreadsheet = await _api.spreadsheets.get(_spreadsheetId);
      final sheetList = spreadsheet.sheets ?? const [];
      sheets.Sheet? match;
      for (final s in sheetList) {
        if (s.properties?.title == _sheetName) {
          match = s;
          break;
        }
      }
      final sheetId = match?.properties?.sheetId;
      if (sheetId == null) {
        throw SheetsException('لم يتم العثور على تبويب "$_sheetName" داخل الشيت.');
      }

      await _api.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: [
          sheets.Request(
            deleteDimension: sheets.DeleteDimensionRequest(
              range: sheets.DimensionRange(
                sheetId: sheetId,
                dimension: 'ROWS',
                startIndex: rowNumber - 1,
                endIndex: rowNumber,
              ),
            ),
          ),
        ]),
        _spreadsheetId,
      );
    } on SheetsException {
      rethrow;
    } catch (e) {
      throw SheetsException('فشل حذف الصف من Google Sheets.\n($e)');
    }
  }
}
