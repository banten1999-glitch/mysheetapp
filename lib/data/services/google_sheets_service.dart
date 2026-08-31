import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;

import '../../core/errors/app_exception.dart';

/// Talks to a single Google Sheet (spreadsheet + tab) configured by the
/// user in Settings. Column order is fixed (A..I); only header labels are
/// customizable.
class GoogleSheetsService {
  GoogleSheetsService({
    required gapis.AuthClient client,
    required String spreadsheetId,
    required String sheetName,
  })  : _api = sheets.SheetsApi(client),
        _spreadsheetId = spreadsheetId,
        _sheetName = sheetName;

  final sheets.SheetsApi _api;
  final String _spreadsheetId;
  final String _sheetName;

  String get _dataColumnsRange => "'$_sheetName'!A:I";
  String get _serialColumnRange => "'$_sheetName'!A2:A";
  String get _transactionIdColumnRange => "'$_sheetName'!I2:I";
  String get _headerRowRange => "'$_sheetName'!A1:I1";

  Future<void> testConnection() async {
    try {
      await _api.spreadsheets.get(_spreadsheetId);
    } catch (e) {
      throw SheetsException('تعذّر الوصول إلى Google Sheets. تحقق من Spreadsheet ID والصلاحيات.\n($e)');
    }
  }

  Future<void> ensureHeaderRow(List<String> headers) async {
    try {
      final existing = await _api.spreadsheets.values.get(_spreadsheetId, _headerRowRange);
      final hasHeader = existing.values != null && existing.values!.isNotEmpty;
      if (hasHeader) return;
      await _api.spreadsheets.values.update(
        sheets.ValueRange(values: [headers]),
        _spreadsheetId,
        _headerRowRange,
        valueInputOption: 'USER_ENTERED',
      );
    } catch (e) {
      throw SheetsException('تعذّر كتابة صف العناوين في الشيت.\n($e)');
    }
  }

  /// Highest serial number currently present in column A (excluding the
  /// header row). Returns null if the sheet has no data rows yet.
  Future<int?> getMaxSerial() async {
    try {
      final resp = await _api.spreadsheets.values.get(_spreadsheetId, _serialColumnRange);
      final rows = resp.values ?? const [];
      int? max;
      for (final row in rows) {
        if (row.isEmpty) continue;
        final n = int.tryParse(row.first.toString());
        if (n != null && (max == null || n > max)) max = n;
      }
      return max;
    } catch (e) {
      throw SheetsException('تعذّرت قراءة آخر رقم رديف من الشيت.\n($e)');
    }
  }

  /// Row number (1-based, matching the sheet's own row numbering) of the row
  /// whose transactionId column (I) matches, or null if not present yet.
  /// Used both to avoid writing a retried operation twice, and to locate the
  /// row to overwrite when an already-synced entry gets edited.
  Future<int?> findRowNumber(String transactionId) async {
    try {
      final resp = await _api.spreadsheets.values.get(_spreadsheetId, _transactionIdColumnRange);
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

  Future<void> appendRow(List<Object?> rowValues) async {
    try {
      await _api.spreadsheets.values.append(
        sheets.ValueRange(values: [rowValues]),
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
  Future<void> updateRow(int rowNumber, List<Object?> rowValues) async {
    try {
      await _api.spreadsheets.values.update(
        sheets.ValueRange(values: [rowValues]),
        _spreadsheetId,
        "'$_sheetName'!A$rowNumber:I$rowNumber",
        valueInputOption: 'USER_ENTERED',
      );
    } catch (e) {
      throw SheetsException('فشل تحديث الصف في Google Sheets.\n($e)');
    }
  }

  /// Physically removes a row (1-based [rowNumber]) - rows below it shift up.
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
