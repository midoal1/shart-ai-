import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/analysis_model.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/language_provider.dart';
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
    final lang = Provider.of<LanguageProvider>(context);

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
            Text(lang.tr('app_title')),
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
            tooltip: lang.tr('settings_title'),
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
        color: AppTheme.buyGreen,
        backgroundColor: AppTheme.surface,
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Status Banner
              _buildServerStatusBadge(lang),
              const SizedBox(height: 16),

              // Hero Action Card
              _buildHeroScanCard(context, lang),
              const SizedBox(height: 20),

              // Anti-Misleading Security Feature Card
              _buildAntiMisleadingShield(lang),
              const SizedBox(height: 24),

              // Live Market Watch Section
              _buildMarketTickerSection(lang),
              const SizedBox(height: 24),

              // Recent Analysis History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.tr('recent_analysis'),
                    style: const TextStyle(
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
                      child: Text(lang.tr('view_all'), style: const TextStyle(color: AppTheme.primaryBlue)),
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
                _buildEmptyHistoryPlaceholder(lang)
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
        label: Text(lang.tr('upload_chart'), style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildServerStatusBadge(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isBackendOnline ? AppTheme.buyGreen.withOpacity(0.3) : AppTheme.waitAmber.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isBackendOnline ? AppTheme.buyGreen : AppTheme.waitAmber,
                    boxShadow: [
                      BoxShadow(
                        color: (_isBackendOnline ? AppTheme.buyGreen : AppTheme.waitAmber).withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isBackendOnline ? lang.tr('server_connected') : lang.tr('server_disconnected'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isBackendOnline ? AppTheme.buyGreen : AppTheme.waitAmber,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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

  Widget _buildHeroScanCard(BuildContext context, LanguageProvider lang) {
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
              '⚡ AI Quantitative Trading',
              style: TextStyle(color: AppTheme.buyGreen, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            lang.tr('scan_card_title'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.tr('scan_card_subtitle'),
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
            label: Text(lang.tr('start_scan_button'), style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildAntiMisleadingShield(LanguageProvider lang) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.tr('shield_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.tr('shield_desc'),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTickerSection(LanguageProvider lang) {
    final tickers = _marketTickers.isNotEmpty
        ? _marketTickers
        : [
            {'name': 'BTC/USDT', 'price': '81,380.00', 'change': '+2.85%', 'up': true},
            {'name': 'ETH/USDT', 'price': '2,620.00', 'change': '+1.40%', 'up': true},
            {'name': 'SOL/USDT', 'price': '113.60', 'change': '+3.20%', 'up': true},
            {'name': 'EUR/USD', 'price': '1.1508', 'change': '-0.05%', 'up': false},
            {'name': 'GOLD (XAU)', 'price': '4,367.05', 'change': '+0.28%', 'up': true},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.tr('market_watch_title'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
                width: 175,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['name'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: isUp ? AppTheme.buyGreen : AppTheme.sellRed,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item['price'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['change'],
                          style: TextStyle(
                            fontSize: 10,
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

  Widget _buildEmptyHistoryPlaceholder(LanguageProvider lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.analytics_outlined, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            lang.tr('no_history_title'),
            style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            lang.tr('no_history_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AnalysisModel item) {
    final isBuy = item.setup.action.contains('BUY');
    final isWait = item.setup.action == 'WAIT';
    final badgeColor = isWait ? AppTheme.waitAmber : (isBuy ? AppTheme.buyGreen : AppTheme.sellRed);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isWait ? Icons.hourglass_empty : (isBuy ? Icons.arrow_upward : Icons.arrow_downward),
            color: badgeColor,
            size: 20,
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
          'دخول: ${item.setup.entryPrice ?? item.currentPrice}  |  الثقة: ${item.setup.confidenceScore}%',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.setup.action,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 11),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ResultScreen(analysis: item)),
          );
        },
      ),
    );
  }
}
