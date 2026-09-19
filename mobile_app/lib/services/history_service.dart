import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_model.dart';

class HistoryService {
  static const String _key = 'analysis_history_list';

  static Future<List<AnalysisModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    return rawList
        .map((str) {
          try {
            return AnalysisModel.fromJson(json.decode(str));
          } catch (_) {
            return null;
          }
        })
        .whereType<AnalysisModel>()
        .toList();
  }

  static Future<void> saveAnalysis(AnalysisModel analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    
    // Add to beginning of list
    rawList.insert(0, json.encode(analysis.toJson()));

    // Keep max 50 items
    if (rawList.length > 50) {
      rawList.removeRange(50, rawList.length);
    }

    await prefs.setStringList(_key, rawList);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
