import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exchange rates relative to USD (fetched once per session).
/// Falls back to approximate rates if network is unavailable.
final fxRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  try {
    final res = await http
        .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return (json['rates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
  } catch (_) {}
  return {
    'USD': 1.0, 'EGP': 50.0, 'EUR': 0.92, 'GBP': 0.79,
    'SAR': 3.75, 'AED': 3.67, 'JPY': 150.0, 'CNY': 7.2,
  };
});

/// Convert [amount] from currency [from] to [to] using [rates] (all vs USD).
double convertCurrency(
  double amount, {
  required String from,
  required String to,
  required Map<String, double> rates,
}) {
  if (from == to) return amount;
  final fromRate = rates[from] ?? 1.0;
  final toRate = rates[to] ?? 1.0;
  return amount / fromRate * toRate;
}
