import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════
// METAL PRICES
// ══════════════════════════════════════════════════════════════
class MetalPrices {
  final double goldUsd;    // USD per troy oz
  final double silverUsd;  // USD per troy oz
  final double goldChange;   // 24h $ change
  final double silverChange; // 24h $ change
  const MetalPrices({
    required this.goldUsd,
    required this.silverUsd,
    required this.goldChange,
    required this.silverChange,
  });
}

final metalPricesProvider = FutureProvider<MetalPrices?>((ref) async {
  try {
    final res = await http.get(
      Uri.parse('https://data-asg.goldprice.org/dbXRates/USD'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final items = (json['items'] as List?)?.first as Map<String, dynamic>?;
      if (items != null) {
        return MetalPrices(
          goldUsd: (items['xauPrice'] as num?)?.toDouble() ?? 0,
          silverUsd: (items['xagPrice'] as num?)?.toDouble() ?? 0,
          goldChange: (items['chgXau'] as num?)?.toDouble() ?? 0,
          silverChange: (items['chgXag'] as num?)?.toDouble() ?? 0,
        );
      }
    }
  } catch (_) {}
  return null;
});

// ══════════════════════════════════════════════════════════════
// CRYPTO PRICES
// ══════════════════════════════════════════════════════════════
class CryptoPrice {
  final String id;
  final String symbol;
  final String name;
  final double usdPrice;
  final double change24h; // percent
  const CryptoPrice({
    required this.id,
    required this.symbol,
    required this.name,
    required this.usdPrice,
    required this.change24h,
  });
}

final cryptoPricesProvider = FutureProvider<List<CryptoPrice>>((ref) async {
  const ids = 'bitcoin,ethereum,solana,binancecoin';
  try {
    final res = await http.get(
      Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price'
          '?ids=$ids&vs_currencies=usd&include_24hr_change=true'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return [
        _parseCrypto('bitcoin', 'BTC', 'Bitcoin', json),
        _parseCrypto('ethereum', 'ETH', 'Ethereum', json),
        _parseCrypto('solana', 'SOL', 'Solana', json),
        _parseCrypto('binancecoin', 'BNB', 'BNB', json),
      ].whereType<CryptoPrice>().toList();
    }
  } catch (_) {}
  return [];
});

CryptoPrice? _parseCrypto(
    String id, String symbol, String name, Map<String, dynamic> json) {
  final data = json[id] as Map<String, dynamic>?;
  if (data == null) return null;
  return CryptoPrice(
    id: id,
    symbol: symbol,
    name: name,
    usdPrice: (data['usd'] as num?)?.toDouble() ?? 0,
    change24h: (data['usd_24h_change'] as num?)?.toDouble() ?? 0,
  );
}
