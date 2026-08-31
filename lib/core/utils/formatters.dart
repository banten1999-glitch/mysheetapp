import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFmt = DateFormat('HH:mm');
  static final DateFormat _fileStampFmt = DateFormat('yyyy-MM-dd_HH-mm');
  static final DateFormat _displayDateTimeFmt = DateFormat('yyyy-MM-dd  HH:mm');

  static String date(DateTime dt) => _dateFmt.format(dt);
  static String time(DateTime dt) => _timeFmt.format(dt);
  static String fileTimestamp(DateTime dt) => _fileStampFmt.format(dt);
  static String displayDateTime(DateTime dt) => _displayDateTimeFmt.format(dt);

  static final NumberFormat _amountFmt = NumberFormat.decimalPattern('en');

  /// Formats an amount with thousands separators, dropping a trailing ".0".
  static String amount(double value) {
    if (value == value.roundToDouble()) {
      return _amountFmt.format(value.round());
    }
    return _amountFmt.format(value);
  }

  static String amountWithCurrency(double value, String currency) =>
      '${amount(value)} $currency';

  /// Parses user-entered amount text (accepts "1,234.50" or "1234.5").
  static double? parseAmount(String input) {
    final cleaned = input.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static String receiptFileName({required int serial, required DateTime at}) {
    return 'Receipt_${serial}_${fileTimestamp(at)}.jpg';
  }
}
