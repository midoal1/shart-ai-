import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_language';
  Locale _currentLocale = const Locale('ar');

  Locale get currentLocale => _currentLocale;
  bool get isArabic => _currentLocale.languageCode == 'ar';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'ar';
    _currentLocale = Locale(code);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
    notifyListeners();
  }

  // Multi-language dictionary
  static final Map<String, Map<String, String>> _strings = {
    'ar': {
      'app_title': 'Smart Trader AI',
      'server_connected': 'محرك التحليل والذكاء الاصطناعي متصل',
      'server_disconnected': 'جاري الفحص أو إعادة الاتصال بالسحابة',
      'scan_card_title': 'تحليل شارت جديد بالذكاء الاصطناعي',
      'scan_card_subtitle': 'ارفع لقطة شاشة من شارت التداول لتحليل الاتجاه، الأنماط، نقاط الدخول والأهداف بدقة 100%',
      'start_scan_button': 'التقاط أو رفع الشارت',
      'shield_title': 'نظام حماية المتداول الصارم (منع التضليل)',
      'shield_desc': 'النموذج لا يخمن الأسعار، بل يقوم بحساب المؤشرات الرياضية RSI و ATR لحظياً من بيانات السوق الحية المباشرة.',
      'market_watch_title': 'رادار الأسواق المباشر (أسعار حية)',
      'recent_analysis': 'آخر التحليلات',
      'view_all': 'عرض الكل',
      'no_history_title': 'لا توجد تحليلات سابقة بعد',
      'no_history_desc': 'قم برفع أول لقطة شاشة لشارت التداول للبدء في اكتشاف الصفقات بدقة',
      'upload_chart': 'رفع شارت جديد',
      'settings_title': 'الإعدادات والاتصال',
      'language_select': 'لغة التطبيق / Language',
      'server_url': 'عنوان خادم التحليل (Backend API URL)',
      'save_and_test': 'حفظ واختبار الاتصال',
      'about_app': 'حول التطبيق',
      'about_desc': 'Smart Trader AI - الإصدار 1.5.0 (Cloud Engine)\nنظام ذكي متقدم لتحليل الشارتات المالية بدقة ومنع التضليل عبر دمج الرؤية الحاسوبية والبيانات الحية المباشرة.',
      'change_image': 'تغيير الصورة',
      'image_source': 'مصدر الصورة',
      'from_gallery': 'اختيار من المعرض (Gallery)',
      'from_camera': 'التقاط بالكاميرا (Camera)',
      'manual_inputs': 'تأكيد المعطيات (اختياري لضمان دقة 100%)',
      'symbol_label': 'اسم الزوج أو السهم (اتركه فارغاً للاكتشاف التلقائي):',
      'symbol_hint': 'تلقائي من الشارت أو اكتب رمزاً مخصصاً',
      'timeframe_label': 'الفريم الزمني للشارت:',
      'start_analysis': 'بدء التحليل الذكي للشارت',
      'guide_note': 'لأفضل نتيجة: احرص أن تظهر في لقطة الشاشة الشموع بوضوح مع اسم الزوج على المحور.',
      'connected_success': 'تم الاتصال بنجاح! السيرفر ومحرك الذكاء الاصطناعي يعملان بكفاءة.',
      'connection_failed': 'تعذر الاتصال. تأكد من اتصال الإنترنت بالهاتف.',
    },
    'en': {
      'app_title': 'Smart Trader AI',
      'server_connected': 'Analysis Engine & AI Cloud Connected',
      'server_disconnected': 'Checking or reconnecting to cloud',
      'scan_card_title': 'Analyze New Chart with AI',
      'scan_card_subtitle': 'Upload a trading chart screenshot to detect trend, patterns, entry, and targets with 100% precision',
      'start_scan_button': 'Snap or Upload Chart',
      'shield_title': 'Strict Anti-Misleading Protection',
      'shield_desc': 'The model does not guess prices; it computes mathematical RSI and ATR dynamically with real-time market validation.',
      'market_watch_title': 'Live Market Radar (Real-Time)',
      'recent_analysis': 'Recent Analyses',
      'view_all': 'View All',
      'no_history_title': 'No previous analyses yet',
      'no_history_desc': 'Upload your first trading chart screenshot to start discovering high-probability setups.',
      'upload_chart': 'Upload New Chart',
      'settings_title': 'Settings & Connection',
      'language_select': 'Language / لغة التطبيق',
      'server_url': 'Backend API URL',
      'save_and_test': 'Save & Test Connection',
      'about_app': 'About Application',
      'about_desc': 'Smart Trader AI - Version 1.5.0 (Cloud Engine)\nHigh-precision trading chart analytics system combining Computer Vision and real-time live data.',
      'change_image': 'Change Image',
      'image_source': 'Image Source',
      'from_gallery': 'Choose from Gallery',
      'from_camera': 'Take with Camera',
      'manual_inputs': 'Confirmation (Optional for 100% precision)',
      'symbol_label': 'Symbol / Pair (Leave empty for auto-detection):',
      'symbol_hint': 'e.g.: BTCUSDT, EURUSD, XAUUSD',
      'timeframe_label': 'Chart Timeframe:',
      'start_analysis': 'Start Smart Chart Analysis',
      'guide_note': 'Tip: Ensure candlesticks and pair ticker are clearly visible in the screenshot.',
      'connected_success': 'Connected successfully! AI engine is active.',
      'connection_failed': 'Connection failed. Please check the backend URL.',
    }
  };

  String tr(String key) {
    final lang = _currentLocale.languageCode;
    return _strings[lang]?[key] ?? _strings['ar']?[key] ?? key;
  }
}
