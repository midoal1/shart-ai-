import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfluenceGauge extends StatelessWidget {
  final int score; // 0 to 100
  final String action;

  const ConfluenceGauge({
    super.key,
    required this.score,
    required this.action,
  });

  Color _getScoreColor() {
    if (action.contains('BUY')) {
      return AppTheme.buyGreen;
    } else if (action.contains('SELL')) {
      return AppTheme.sellRed;
    } else {
      return AppTheme.waitAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress with score
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const Text(
                        'ثقة',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      action.contains('BUY')
                          ? Icons.trending_up
                          : action.contains('SELL')
                              ? Icons.trending_down
                              : Icons.hourglass_top,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getActionTitle(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _getActionSubtitle(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getActionTitle() {
    switch (action) {
      case 'STRONG_BUY':
        return 'فرصة شراء قوية';
      case 'BUY':
        return 'إشارة شراء';
      case 'STRONG_SELL':
        return 'فرصة بيع قوية';
      case 'SELL':
        return 'إشارة بيع';
      default:
        return 'وضع الانتظار (تذبذب)';
    }
  }

  String _getActionSubtitle() {
    if (action.contains('BUY')) {
      return 'توافق فني وإخباري إيجابي يدعم الاتجاه الصاعد مع إدارة مخاطر منضبطة.';
    } else if (action.contains('SELL')) {
      return 'ضغط بيعي ونماذج انعكاسية سلبية مع مستويات وقف خسارة قريبة.';
    } else {
      return 'حركة السوق غير واضحة أو عالية المخاطر. لا ينصح بالدخول الآن للحفاظ على رأس المال.';
    }
  }
}
