import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_model.dart';

class ApiService {
  static const String _defaultBaseUrl = 'https://shart-ai.onrender.com'; // Live Cloud URL on Render

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_base_url') ?? _defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_base_url', url);
  }

  static Future<bool> checkHealth() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<AnalysisModel> analyzeChart({
    required File imageFile,
    String? symbol,
    String? timeframe,
  }) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/analyze-chart');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    if (symbol != null && symbol.trim().isNotEmpty) {
      request.fields['symbol'] = symbol.trim().toUpperCase();
    }
    if (timeframe != null && timeframe.trim().isNotEmpty) {
      request.fields['timeframe'] = timeframe.trim();
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return AnalysisModel.fromJson(data);
    } else {
      String message = 'فشل في تحليل الشارت (${response.statusCode})';
      try {
        final err = json.decode(utf8.decode(response.bodyBytes));
        if (err['detail'] != null) message = err['detail'];
      } catch (_) {}
      throw Exception(message);
    }
  }

  static Future<List<Map<String, dynamic>>> getMarketSummary() async {
    // 1. Try fetching from Backend
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/market-summary'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List list = json.decode(utf8.decode(response.bodyBytes));
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    // 2. Fallback: Fetch directly from Binance live public ticker API
    try {
      final response = await http
          .get(Uri.parse('https://api.binance.com/api/v3/ticker/24hr'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List list = json.decode(response.body);
        final Map<String, dynamic> dataMap = {
          for (var item in list) item['symbol']: item
        };

        final targets = [
          {'name': 'BTC/USDT', 'symbol': 'BTCUSDT'},
          {'name': 'ETH/USDT', 'symbol': 'ETHUSDT'},
          {'name': 'SOL/USDT', 'symbol': 'SOLUSDT'},
          {'name': 'EUR/USD', 'symbol': 'EURUSDT'},
          {'name': 'GOLD (XAU)', 'symbol': 'PAXGUSDT'},
        ];

        final List<Map<String, dynamic>> results = [];
        for (var t in targets) {
          final sym = t['symbol']!;
          if (dataMap.containsKey(sym)) {
            final item = dataMap[sym];
            final price = double.tryParse(item['lastPrice'].toString()) ?? 0.0;
            final change = double.tryParse(item['priceChangePercent'].toString()) ?? 0.0;
            results.add({
              'name': t['name'],
              'price': price >= 10 ? price.toStringAsFixed(2) : price.toStringAsFixed(4),
              'change': '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
              'up': change >= 0,
            });
          }
        }
        if (results.isNotEmpty) return results;
      }
    } catch (_) {}

    // 3. Static fallback if device is completely offline
    return [
      {'name': 'BTC/USDT', 'price': '68,450.00', 'change': '+2.40%', 'up': true},
      {'name': 'ETH/USDT', 'price': '3,520.00', 'change': '+1.80%', 'up': true},
      {'name': 'SOL/USDT', 'price': '152.40', 'change': '+3.10%', 'up': true},
      {'name': 'EUR/USD', 'price': '1.0855', 'change': '-0.15%', 'up': false},
      {'name': 'GOLD (XAU)', 'price': '2,364.50', 'change': '+0.65%', 'up': true},
    ];
  }
}
