import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/language_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _testingConnection = false;
  String? _testResult;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    final ok = await ApiService.checkHealth();
    if (mounted) {
      setState(() {
        _isSuccess = ok;
      });
    }
  }

  Future<void> _testConnection() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    setState(() {
      _testingConnection = true;
      _testResult = null;
    });

    final ok = await ApiService.checkHealth();

    if (mounted) {
      setState(() {
        _testingConnection = false;
        _isSuccess = ok;
        _testResult = ok ? lang.tr('connected_success') : lang.tr('connection_failed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('settings_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Selection Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: AppTheme.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        lang.tr('language_select'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => lang.setLanguage('ar'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: lang.isArabic ? AppTheme.primaryBlue.withOpacity(0.2) : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: lang.isArabic ? AppTheme.primaryBlue : AppTheme.border,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'العربية (Arabic)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: lang.isArabic ? AppTheme.primaryBlue : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => lang.setLanguage('en'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !lang.isArabic ? AppTheme.primaryBlue.withOpacity(0.2) : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !lang.isArabic ? AppTheme.primaryBlue : AppTheme.border,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'English (الإنجليزية)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !lang.isArabic ? AppTheme.primaryBlue : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cloud Server Status Card (Clean & User-friendly)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_done, color: AppTheme.buyGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        lang.isArabic ? 'حالة السيرفر السحابي والذكاء الاصطناعي' : 'Cloud Server & AI Status',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSuccess ? AppTheme.buyGreen.withOpacity(0.3) : AppTheme.waitAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isSuccess ? AppTheme.buyGreen : AppTheme.waitAmber,
                            boxShadow: [
                              BoxShadow(
                                color: (_isSuccess ? AppTheme.buyGreen : AppTheme.waitAmber).withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isSuccess 
                                ? (lang.isArabic ? 'متصل وجاهز لتحليل الشارتات في أي وقت' : 'Online & ready to analyze charts')
                                : (lang.isArabic ? 'جاري التحقق من الاتصال بالسحابة...' : 'Checking cloud connection...'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isSuccess ? AppTheme.buyGreen : AppTheme.waitAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _testingConnection
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(lang.isArabic ? 'فحص الاتصال الآن' : 'Check Connection Now'),
                      onPressed: _testingConnection ? null : _testConnection,
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess ? AppTheme.buyGreen.withOpacity(0.12) : AppTheme.sellRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isSuccess ? AppTheme.buyGreen.withOpacity(0.4) : AppTheme.sellRed.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error_outline,
                            color: _isSuccess ? AppTheme.buyGreen : AppTheme.sellRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _testResult!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isSuccess ? AppTheme.buyGreen : AppTheme.sellRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // About App Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.tr('about_app'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    lang.tr('about_desc'),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
