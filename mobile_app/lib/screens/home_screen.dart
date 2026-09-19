import 'package:flutter/material.dart';
import '../models/analysis_model.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/disclaimer_dialog.dart';
import 'scan_screen.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBackendOnline = false;
  List<AnalysisModel> _recentHistory = [];
  List<Map<String, dynamic>> _marketTickers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final isOnline = await ApiService.checkHealth();
    final history = await HistoryService.getHistory();
    final tickers = await ApiService.getMarketSummary();
    if (mounted) {
      setState(() {
        _isBackendOnline = isOnline;
        _recentHistory = history.take(5).toList();
        _marketTickers = tickers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.buyGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.candlestick_chart, color: AppTheme.buyGreen, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('Smart Trader AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
            tooltip: 'إخلاء المسؤولية',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const DisclaimerDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
            tooltip: 'الإعدادات',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadInitialData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: AppTheme.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Status Banner
              _buildServerStatusBadge(),
              const SizedBox(height: 16),

              // Hero Action Card
              _buildHeroScanCard(context),
              const SizedBox(height: 20),

              // Anti-Misleading Security Feature Card
              _buildAntiMisleadingShield(),
              const SizedBox(height: 24),

              // Live Market Watch Section
              _buildMarketTickerSection(),
              const SizedBox(height: 24),

              // Recent Analysis History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'آخر التحليلات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (_recentHistory.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                      child: const Text('عرض الكل', style: TextStyle(color: AppTheme.primaryBlue)),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue, strokeWidth: 2),
                  ),
                )
              else if (_recentHistory.isEmpty)
                _buildEmptyHistoryPlaceholder()
              else
                ..._recentHistory.map((item) => _buildHistoryCard(context, item)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.buyGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_photo_alternate, fontWeight: FontWeight.bold),
        label: const Text('رفع شارت جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
          if (result == true) {
            _loadInitialData();
          }
        },
      ),
    );
  }

  Widget _buildServerStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isBackendOnline ? AppTheme.buyGreen.withOpacity(0.3) : AppTheme.sellRed.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isBackendOnline ? AppTheme.buyGreen : AppTheme.sellRed,
                  boxShadow: [
                    BoxShadow(
                      color: (_isBackendOnline ? AppTheme.buyGreen : AppTheme.sellRed).withOpacity(0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isBackendOnline ? 'محرك التحليل والذكاء الاصطناعي متصل' : 'الخادم غير متصل (تأكد من تشغيل السيرفر)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isBackendOnline ? AppTheme.buyGreen : AppTheme.sellRed,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16, color: AppTheme.textMuted),
            onPressed: _loadInitialData,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScanCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162238), Color(0xFF101622)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.buyGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '⚡ تحليل فوري بالذكاء الاصطناعي',
              style: TextStyle(color: AppTheme.buyGreen, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'حول أي لقطة شاشة لشارت\nإلى صفقة مدروسة بدقة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تحليل هجين يدمج قراءة النماذج البصرية مع التحقق من أسعار السوق الحقيقية وموجات الأخبار.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.camera_enhance_outlined, size: 20),
            label: const Text('افتح الماسح الآن', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
              if (result == true) _loadInitialData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAntiMisleadingShield() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.buyGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_outlined, color: AppTheme.buyGreen, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'درع الحماية من التضليل (Anti-Misleading)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• تحقق رياضي من بيانات الشموع الحقيقية لمنع هلوسة الأرقام.\n• تفعيل وضع الانتظار عند التذبذب أو صدور أخبار عنيفة.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTickerSection() {
    final tickers = _marketTickers.isNotEmpty
        ? _marketTickers
        : [
            {'name': 'BTC/USDT', 'price': '...', 'change': '...', 'up': true},
            {'name': 'ETH/USDT', 'price': '...', 'change': '...', 'up': true},
            {'name': 'SOL/USDT', 'price': '...', 'change': '...', 'up': true},
            {'name': 'EUR/USD', 'price': '...', 'change': '...', 'up': false},
            {'name': 'GOLD (XAU)', 'price': '...', 'change': '...', 'up': true},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نظرة سريعة على الأسواق',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tickers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = tickers[index];
              final isUp = item['up'] as bool;
              return Container(
                width: 155,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['name'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '\$${item['price']}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item['change'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUp ? AppTheme.buyGreen : AppTheme.sellRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistoryPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off, size: 40, color: AppTheme.textMuted.withOpacity(0.5)),
          const SizedBox(height: 10),
          const Text(
            'لا توجد تحليلات سابقة حتى الآن',
            style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'اضغط على زر "رفع شارت جديد" لبدء تحليلك الأول',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AnalysisModel item) {
    final isBuy = item.setup.action.contains('BUY');
    final isSell = item.setup.action.contains('SELL');
    final color = isBuy ? AppTheme.buyGreen : (isSell ? AppTheme.sellRed : AppTheme.waitAmber);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isBuy ? Icons.trending_up : (isSell ? Icons.trending_down : Icons.hourglass_top),
            color: color,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Text(
              item.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.timeframe,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'نسبة الثقة: ${item.setup.confidenceScore}% • الدخول: ${item.setup.entryPrice}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(analysis: item)),
        ),
      ),
    );
  }
}
