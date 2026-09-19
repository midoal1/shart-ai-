import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final _symbolController = TextEditingController();
  String _selectedTimeframe = 'auto';
  bool _isAnalyzing = false;
  String _loadingMessage = 'جاري الاتصال بالخادم...';

  final List<String> _timeframes = ['auto', '1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '1d'];

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر اختيار الصورة: $e'),
            backgroundColor: AppTheme.sellRed,
          ),
        );
      }
    }
  }

  Future<void> _runAnalysis() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار أو التقاط صورة الشارت أولاً'),
          backgroundColor: AppTheme.waitAmber,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _loadingMessage = 'جاري التعرف على الزوج والفريم والسعر بالذكاء الاصطناعي...';
    });

    // Fast progressive updates
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _isAnalyzing) {
        setState(() => _loadingMessage = 'جاري قراءة الشموع وحساب مستويات وقف الخسارة والهدف...');
      }
    });

    try {
      final analysis = await ApiService.analyzeChart(
        imageFile: _selectedImage!,
        symbol: _symbolController.text.trim().isNotEmpty ? _symbolController.text.trim() : null,
        timeframe: _selectedTimeframe == 'auto' ? null : _selectedTimeframe,
      );

      // Save to local history
      await HistoryService.saveAnalysis(analysis);

      if (mounted) {
        setState(() => _isAnalyzing = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(analysis: analysis)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.sellRed),
                SizedBox(width: 8),
                Text('تنبيه في التحليل', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
              ],
            ),
            content: Text(
              'حدث خطأ أثناء فحص الشارت:\n$e\n\nتأكد من وضوح أرقام الشارت أو تشغيل السيرفر المحلي.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً', style: TextStyle(color: AppTheme.primaryBlue)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع وتحليل الشارت'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Box
                _buildImagePickerBox(),
                const SizedBox(height: 20),

                // Manual Override / Verification Section
                _buildVerificationCard(),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buyGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _isAnalyzing ? null : _runAnalysis,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 20, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'بدء التحليل الذكي للشارت',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Guide note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 20, color: AppTheme.waitAmber),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'لأفضل نتيجة: احرص أن تظهر في لقطة الشاشة الشموع بوضوح مع اسم الزوج على المحور.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isAnalyzing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildImagePickerBox() {
    if (_selectedImage != null) {
      return Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.buyGreen.withOpacity(0.5), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_selectedImage!, fit: BoxFit.cover),
            Positioned(
              bottom: 12,
              right: 12,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface.withOpacity(0.9),
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('تغيير الصورة', style: TextStyle(fontSize: 12)),
                onPressed: () => _showPickerOptions(),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _showPickerOptions,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryBlue, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'اضغط هنا لرفع سكرين شوت الشارت',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'يدعم لقطات شاشة TradingView، Binance، MT4/MT5',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('مصدر الصورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryBlue),
                title: const Text('اختيار من المعرض (Gallery)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.buyGreen),
                title: const Text('التقاط بالكاميرا (Camera)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCard() {
    return Container(
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
              const Icon(Icons.auto_awesome, color: AppTheme.buyGreen, size: 18),
              const SizedBox(width: 8),
              const Text(
                'خيارات إضافية (اختياري - يكتشفها الذكاء الاصطناعي تلقائياً)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Symbol text field
          const Text('اسم الزوج أو السهم (اتركه فارغاً للاكتشاف التلقائي):', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _symbolController,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'تلقائي من لقطة الشاشة (أو اكتب رمزاً مخصصاً)',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Timeframe chips
          const Text('الفريم الزمني للشارت:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeframes.map((tf) {
              final isSel = _selectedTimeframe == tf;
              final label = tf == 'auto' ? 'تلقائي (اكتشاف ذكي)' : tf;
              return ChoiceChip(
                label: Text(
                  label, 
                  style: TextStyle(
                    color: isSel ? Colors.black : AppTheme.textPrimary, 
                    fontWeight: FontWeight.bold,
                    fontSize: tf == 'auto' ? 12 : 13,
                  )
                ),
                selected: isSel,
                selectedColor: AppTheme.buyGreen,
                backgroundColor: AppTheme.surfaceElevated,
                onSelected: (val) {
                  if (val) setState(() => _selectedTimeframe = tf);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: AppTheme.buyGreen,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'جاري التحليل المزدوج...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _loadingMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
