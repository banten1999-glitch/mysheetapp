import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';

/// Fetches the USD -> EGP rate.
///
/// Egyptian banks (NBE, CIB, Banque Misr...) don't publish an open API, so
/// this uses a free public reference feed that tracks the market rate. It
/// is close to, but not identical with, any single bank's counter rate -
/// which is why the app also lets the rate be typed in by hand from
/// whichever bank the user prefers.
class ExchangeRateService {
  static const String _endpoint = 'https://open.er-api.com/v6/latest/USD';
  static const Duration _timeout = Duration(seconds: 15);

  /// How many EGP one USD buys.
  Future<double> fetchUsdToEgp() async {
    http.Response response;
    try {
      response = await http.get(Uri.parse(_endpoint)).timeout(_timeout);
    } catch (e) {
      throw ExchangeRateException(
        'تعذّر جلب سعر الصرف. تحقق من الاتصال بالإنترنت.\n($e)',
      );
    }

    if (response.statusCode != 200) {
      throw ExchangeRateException(
        'تعذّر جلب سعر الصرف (رمز ${response.statusCode}).',
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = decoded['rates'] as Map<String, dynamic>?;
      final egp = rates?['EGP'];
      final rate = egp is num ? egp.toDouble() : double.tryParse('$egp');
      if (rate == null || rate <= 0) {
        throw const ExchangeRateException('لم يتم العثور على سعر الجنيه المصري.');
      }
      return rate;
    } on ExchangeRateException {
      rethrow;
    } catch (e) {
      throw ExchangeRateException('تعذّرت قراءة استجابة سعر الصرف.\n($e)');
    }
  }
}
