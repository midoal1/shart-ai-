import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/analysis_model.dart';
import '../theme/app_theme.dart';

class TradeCard extends StatelessWidget {
  final TradeSetupModel setup;
  final String symbol;

  const TradeCard({
    super.key,
    required this.setup,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Header with Risk to Reward badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'خطة إدارة الصفقة المقترحة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
                  ),
                  child: Text(
                    'العائد:المخاطرة 1:${setup.riskRewardRatio}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Entry Price Row
                _buildPriceRow(
                  context,
                  title: 'سعر الدخول المقترح (Entry)',
                  price: setup.entryPrice,
                  color: AppTheme.textPrimary,
                  icon: Icons.login,
                  highlight: false,
                ),
                const Divider(color: AppTheme.border, height: 20),

                // Stop Loss Row
                _buildPriceRow(
                  context,
                  title: 'وقف الخسارة (Stop Loss)',
                  price: setup.stopLoss,
                  color: AppTheme.sellRed,
                  icon: Icons.shield_outlined,
                  highlight: true,
                  subtitle: 'مستوى إبطال فكرة التحليل الفني',
                ),
                const Divider(color: AppTheme.border, height: 20),

                // Take Profit 1
                _buildPriceRow(
                  context,
                  title: 'الهدف الأول (Take Profit 1)',
                  price: setup.takeProfit1,
                  color: AppTheme.buyGreen,
                  icon: Icons.flag_outlined,
                  highlight: false,
                ),
                const SizedBox(height: 12),

                // Take Profit 2
                _buildPriceRow(
                  context,
                  title: 'الهدف الثاني (Take Profit 2)',
                  price: setup.takeProfit2,
                  color: AppTheme.buyGreen,
                  icon: Icons.sports_score_outlined,
                  highlight: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context, {
    required String title,
    required double price,
    required Color color,
    required IconData icon,
    required bool highlight,
    String? subtitle,
  }) {
    final priceStr = price >= 10 ? price.toStringAsFixed(2) : price.toStringAsFixed(4);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ],
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: priceStr));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم نسخ السعر: $priceStr'),
                duration: const Duration(seconds: 1),
                backgroundColor: AppTheme.surfaceElevated,
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(
                  priceStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.copy, size: 14, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
