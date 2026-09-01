import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/sheet_columns.dart';

/// Credit/debit sums read back from the ledger rows of the sheet.
class SheetTotals {
  const SheetTotals({required this.credit, required this.debit});

  /// مدين عليه - amounts received.
  final double credit;

  /// مدين له - amounts paid.
  final double debit;

  /// الباقي - positive means owed to the account holder.
  double get remaining => credit - debit;
}

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

  int? _cachedSheetId;

  /// Numeric id of the configured tab, needed for structural (batchUpdate)
  /// operations. Resolved once per service instance.
  Future<int> _resolveSheetId() async {
    final cached = _cachedSheetId;
    if (cached != null) return cached;

    final spreadsheet = await _api.spreadsheets.get(_spreadsheetId);
    for (final sheet in spreadsheet.sheets ?? const <sheets.Sheet>[]) {
      if (sheet.properties?.title == _sheetName) {
        final id = sheet.properties?.sheetId;
        if (id != null) {
          _cachedSheetId = id;
          return id;
        }
      }
    }
    throw SheetsException('لم يتم العثور على تبويب "$_sheetName" داخل الشيت.');
  }

  String get _lastLetter => SheetColumns.maxLetterOf(_columnLetters);

  String _letterFor(String field) =>
      _columnLetters[field] ?? AppConstants.defaultColumnLetters[field] ?? 'A';

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

  /// Row number of the last row holding an actual ledger entry, found by
  /// scanning the serial column for the last parseable integer.
  ///
  /// Deliberately *not* "the last row with any content": sheets typically
  /// carry footer rows below the data (totals, remaining balance, notes),
  /// and those hold text rather than a serial number. Anchoring on the
  /// serial column is what keeps new entries above the footer.
  /// Returns 1 (the header row) when there are no entries yet.
  Future<int> findLastEntryRow() async {
    try {
      final resp = await _api.spreadsheets.values.get(
        _spreadsheetId,
        _singleColumnRange('serial'),
      );
      final rows = resp.values ?? const [];
      var lastRow = 1;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;
        if (int.tryParse(row.first.toString().trim()) != null) {
          lastRow = i + 2; // range starts at row 2
        }
      }
      return lastRow;
    } catch (e) {
      throw SheetsException('تعذّر تحديد موضع آخر عملية في الشيت.\n($e)');
    }
  }

  /// Sums the credit and debit columns across the ledger rows only.
  ///
  /// The range stops at the last entry row, so footer rows - including the
  /// sheet's own totals cells, which live in those same columns - are never
  /// counted twice. Values are read unformatted so currency formatting
  /// ("£312") doesn't have to be parsed back out.
  Future<SheetTotals> fetchTotals() async {
    try {
      final lastRow = await findLastEntryRow();
      if (lastRow < 2) return const SheetTotals(credit: 0, debit: 0);

      final credit = await _sumColumn(_letterFor('credit'), lastRow);
      final debit = await _sumColumn(_letterFor('debit'), lastRow);
      return SheetTotals(credit: credit, debit: debit);
    } on SheetsException {
      rethrow;
    } catch (e) {
      throw SheetsException('تعذّرت قراءة المجاميع من الشيت.\n($e)');
    }
  }

  Future<double> _sumColumn(String letter, int lastRow) async {
    final resp = await _api.spreadsheets.values.get(
      _spreadsheetId,
      "'$_sheetName'!${letter}2:$letter$lastRow",
      valueRenderOption: 'UNFORMATTED_VALUE',
    );
    var total = 0.0;
    for (final row in resp.values ?? const []) {
      if (row.isEmpty) continue;
      final cell = row.first;
      if (cell is num) {
        total += cell.toDouble();
      } else {
        final parsed = double.tryParse(
          cell.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
        );
        if (parsed != null) total += parsed;
      }
    }
    return total;
  }

  /// Inserts a fresh blank row directly beneath the last ledger entry and
  /// writes the operation into it.
  ///
  /// Inserting (rather than appending to the end of the sheet) shifts
  /// everything below - spacer rows, totals, footer - down by one, so the
  /// footer is never overwritten and stays beneath the data. The new row
  /// inherits the formatting of the entry above it.
  Future<void> insertEntryRow(Map<String, Object?> valuesByField) async {
    try {
      final sheetId = await _resolveSheetId();
      final targetRow = await findLastEntryRow() + 1;

      await _api.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: [
          sheets.Request(
            insertDimension: sheets.InsertDimensionRequest(
              // startIndex is > 0 here (targetRow >= 2), which this flag
              // requires, and it carries the data rows' styling down.
              inheritFromBefore: true,
              range: sheets.DimensionRange(
                sheetId: sheetId,
                dimension: 'ROWS',
                startIndex: targetRow - 1,
                endIndex: targetRow,
              ),
            ),
          ),
        ]),
        _spreadsheetId,
      );

      await updateRow(targetRow, valuesByField);
    } on SheetsException {
      rethrow;
    } catch (e) {
      throw SheetsException('فشل حفظ الصف في Google Sheets.\n($e)');
    }
  }

  /// Writes an entry into row [rowNumber], one cell per mapped field.
  ///
  /// Each mapped cell is written as its own range rather than blanking a
  /// contiguous A..N block, so columns the app doesn't own - manual notes,
  /// approval flags, formula columns such as a currency conversion - keep
  /// their contents.
  Future<void> updateRow(int rowNumber, Map<String, Object?> valuesByField) async {
    try {
      final data = <sheets.ValueRange>[];
      for (final field in valuesByField.keys) {
        final letter = _columnLetters[field];
        if (letter == null || !SheetColumns.isValid(letter)) continue;
        data.add(
          sheets.ValueRange(
            range: "'$_sheetName'!$letter$rowNumber",
            values: [
              [valuesByField[field] ?? ''],
            ],
          ),
        );
      }
      if (data.isEmpty) return;

      await _api.spreadsheets.values.batchUpdate(
        sheets.BatchUpdateValuesRequest(
          valueInputOption: 'USER_ENTERED',
          data: data,
        ),
        _spreadsheetId,
      );
    } catch (e) {
      throw SheetsException('فشل تحديث الصف في Google Sheets.\n($e)');
    }
  }

  /// Physically removes a row (1-based [rowNumber]) - rows below shift up,
  /// so the footer follows the data back up as entries are deleted.
  Future<void> deleteRow(int rowNumber) async {
    try {
      final sheetId = await _resolveSheetId();
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
