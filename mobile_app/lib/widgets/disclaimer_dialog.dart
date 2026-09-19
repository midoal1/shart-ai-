import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DisclaimerDialog extends StatelessWidget {
  const DisclaimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.waitAmber, size: 24),
                SizedBox(width: 10),
                Text(
                  'إخلاء المسؤولية القانونية والأمان',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '• تطبيق Smart Trader AI هو أداة مساعدة تعتمد على الذكاء الاصطناعي وخوارزميات التحليل الفني لمساعدة المتداول في قراءة السوق.\n\n'
              '• التحليلات والإشارات المقدمة لا تشكل بأي حال من الأحوال توصيات أو استشارات مالية ملزمة.\n\n'
              '• أسواق التداول (الكريبتو، الفوركس، الأسهم) تنطوي على مخاطر عالية قد تؤدي لخسارة رأس المال بالكامل.\n\n'
              '• أنت المسؤول الوحيد عن أي قرار استثماري تتخذه، ويجب دوماً الالتزام بإدارة رأس المال وتحديد وقف الخسارة.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('أوافق وأتفهم المخاطر', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
