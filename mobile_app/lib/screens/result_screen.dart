import 'package:flutter/material.dart';
import '../models/analysis_model.dart';
import '../theme/app_theme.dart';
import '../widgets/confluence_gauge.dart';
import '../widgets/trade_card.dart';
import '../widgets/risk_calculator_dialog.dart';

class ResultScreen extends StatelessWidget {
  final AnalysisModel analysis;

  const ResultScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير تحليل ${analysis.symbol}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: AppTheme.buyGreen),
            tooltip: 'حاسبة إدارة المخاطر',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => RiskCalculatorDialog(setup: analysis.setup),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asset Info Header
            _buildAssetHeader(),
            const SizedBox(height: 16),

            // High-Impact Economic Alert (If any)
            if (analysis.economicAlert.hasHighImpactEvent) ...[
              _buildHighImpactAlert(),
              const SizedBox(height: 16),
            ],

            // Confluence Score Gauge
            ConfluenceGauge(
              score: analysis.setup.confidenceScore,
              action: analysis.setup.action,
            ),
            const SizedBox(height: 16),

            // Trade Parameters Card
            TradeCard(
              setup: analysis.setup,
              symbol: analysis.symbol,
            ),
            const SizedBox(height: 12),

            // Calculate Lot Size CTA
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.buyGreen,
                  side: const BorderSide(color: AppTheme.buyGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: const Text('احسب حجم الصفقة المناسب لمحفظتك (Lot Size)'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => RiskCalculatorDialog(setup: analysis.setup),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Analysis Reasons Section
            _buildReasonsSection(),
            const SizedBox(height: 20),

            // Technical Indicators Grid
            _buildIndicatorsSection(),
            const SizedBox(height: 20),

            // News & Sentiment Section
            if (analysis.recentNews.isNotEmpty) ...[
              _buildNewsSection(),
              const SizedBox(height: 20),
            ],

            // Legal Disclaimer Card
            _buildDisclaimerCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.currency_exchange, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        analysis.symbol,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          analysis.timeframe,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'نوع الأصل: ${analysis.marketType}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('السعر الحالي المحدث', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              Text(
                analysis.currentPrice >= 10
                    ? '\$${analysis.currentPrice.toStringAsFixed(2)}'
                    : '\$${analysis.currentPrice.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighImpactAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.sellRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.sellRed.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.sellRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.economicAlert.eventTitle ?? 'تحذير خبر اقتصادي عالي الخطورة',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.sellRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.economicAlert.warningMessage ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonsSection() {
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
          const Row(
            children: [
              Icon(Icons.checklist, color: AppTheme.buyGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'مسببات التحليل الفني والأساسي (لماذا هذا القرار؟)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...analysis.reasons.map((reason) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.buyGreen, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIndicatorsSection() {
    final ind = analysis.indicators;

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
          const Row(
            children: [
              Icon(Icons.speed, color: AppTheme.primaryBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'المؤشرات الفنية الرقمية المحسوبة بدقة (Ground Truth)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildIndicatorItem('RSI (14)', ind.rsi14.toString(), _getRsiColor(ind.rsi14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildIndicatorItem('متوسط EMA 20', ind.ema20.toString(), AppTheme.textPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildIndicatorItem('متوسط EMA 50', ind.ema50.toString(), AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildIndicatorItem('مؤشر التذبذب ATR', ind.atr.toString(), AppTheme.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildIndicatorItem(
                  'حالة السوق',
                  ind.isChoppy ? 'متذبذب (Chop)' : 'اتجاه واضح',
                  ind.isChoppy ? AppTheme.waitAmber : AppTheme.buyGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRsiColor(double rsi) {
    if (rsi > 70) return AppTheme.sellRed;
    if (rsi < 30) return AppTheme.buyGreen;
    return AppTheme.primaryBlue;
  }

  Widget _buildIndicatorItem(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
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
          const Row(
            children: [
              Icon(Icons.newspaper, color: AppTheme.primaryBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'آخر الأخبار ذات الصلة ومعنويات السوق',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...analysis.recentNews.map((news) {
            final isBull = news.sentiment == 'BULLISH';
            final isBear = news.sentiment == 'BEARISH';
            final badgeColor = isBull ? AppTheme.buyGreen : (isBear ? AppTheme.sellRed : AppTheme.waitAmber);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(news.source, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          news.sentiment,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppTheme.waitAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              analysis.disclaimer,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
