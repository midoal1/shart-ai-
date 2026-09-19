class AnalysisModel {
  final String symbol;
  final String timeframe;
  final String marketType;
  final double currentPrice;
  final TradeSetupModel setup;
  final String technicalSummary;
  final TechnicalIndicatorsModel indicators;
  final List<NewsItemModel> recentNews;
  final EconomicAlertModel economicAlert;
  final List<String> reasons;
  final String disclaimer;
  final DateTime analyzedAt;

  AnalysisModel({
    required this.symbol,
    required this.timeframe,
    required this.marketType,
    required this.currentPrice,
    required this.setup,
    required this.technicalSummary,
    required this.indicators,
    required this.recentNews,
    required this.economicAlert,
    required this.reasons,
    required this.disclaimer,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      symbol: json['symbol'] ?? 'UNKNOWN',
      timeframe: json['timeframe'] ?? '1h',
      marketType: json['market_type'] ?? 'CRYPTO',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      setup: TradeSetupModel.fromJson(json['setup'] ?? {}),
      technicalSummary: json['technical_summary'] ?? '',
      indicators: TechnicalIndicatorsModel.fromJson(json['indicators'] ?? {}),
      recentNews: (json['recent_news'] as List? ?? [])
          .map((item) => NewsItemModel.fromJson(item))
          .toList(),
      economicAlert: EconomicAlertModel.fromJson(json['economic_alert'] ?? {}),
      reasons: List<String>.from(json['reasons'] ?? []),
      disclaimer: json['disclaimer'] ?? '',
      analyzedAt: json['analyzed_at'] != null 
          ? DateTime.tryParse(json['analyzed_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'timeframe': timeframe,
      'market_type': marketType,
      'current_price': currentPrice,
      'setup': setup.toJson(),
      'technical_summary': technicalSummary,
      'indicators': indicators.toJson(),
      'recent_news': recentNews.map((n) => n.toJson()).toList(),
      'economic_alert': economicAlert.toJson(),
      'reasons': reasons,
      'disclaimer': disclaimer,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }
}

class TradeSetupModel {
  final String action; // STRONG_BUY, BUY, NEUTRAL_WAIT, SELL, STRONG_SELL
  final int confidenceScore;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit1;
  final double takeProfit2;
  final double riskRewardRatio;
  final double invalidationLevel;
  final String riskAssessment; // LOW, MEDIUM, HIGH

  TradeSetupModel({
    required this.action,
    required this.confidenceScore,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.riskRewardRatio,
    required this.invalidationLevel,
    required this.riskAssessment,
  });

  factory TradeSetupModel.fromJson(Map<String, dynamic> json) {
    return TradeSetupModel(
      action: json['action'] ?? 'NEUTRAL_WAIT',
      confidenceScore: (json['confidence_score'] as num?)?.toInt() ?? 50,
      entryPrice: (json['entry_price'] as num?)?.toDouble() ?? 0.0,
      stopLoss: (json['stop_loss'] as num?)?.toDouble() ?? 0.0,
      takeProfit1: (json['take_profit_1'] as num?)?.toDouble() ?? 0.0,
      takeProfit2: (json['take_profit_2'] as num?)?.toDouble() ?? 0.0,
      riskRewardRatio: (json['risk_reward_ratio'] as num?)?.toDouble() ?? 1.0,
      invalidationLevel: (json['invalidation_level'] as num?)?.toDouble() ?? 0.0,
      riskAssessment: json['risk_assessment'] ?? 'MEDIUM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'confidence_score': confidenceScore,
      'entry_price': entryPrice,
      'stop_loss': stopLoss,
      'take_profit_1': takeProfit1,
      'take_profit_2': takeProfit2,
      'risk_reward_ratio': riskRewardRatio,
      'invalidation_level': invalidationLevel,
      'risk_assessment': riskAssessment,
    };
  }
}

class TechnicalIndicatorsModel {
  final double currentPrice;
  final double rsi14;
  final double ema20;
  final double ema50;
  final double? ema200;
  final double atr;
  final String trendSummary;
  final bool isChoppy;

  TechnicalIndicatorsModel({
    required this.currentPrice,
    required this.rsi14,
    required this.ema20,
    required this.ema50,
    this.ema200,
    required this.atr,
    required this.trendSummary,
    required this.isChoppy,
  });

  factory TechnicalIndicatorsModel.fromJson(Map<String, dynamic> json) {
    return TechnicalIndicatorsModel(
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      rsi14: (json['rsi_14'] as num?)?.toDouble() ?? 50.0,
      ema20: (json['ema_20'] as num?)?.toDouble() ?? 0.0,
      ema50: (json['ema_50'] as num?)?.toDouble() ?? 0.0,
      ema200: (json['ema_200'] as num?)?.toDouble(),
      atr: (json['atr'] as num?)?.toDouble() ?? 0.0,
      trendSummary: json['trend_summary'] ?? '',
      isChoppy: json['is_choppy'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_price': currentPrice,
      'rsi_14': rsi14,
      'ema_20': ema20,
      'ema_50': ema50,
      'ema_200': ema200,
      'atr': atr,
      'trend_summary': trendSummary,
      'is_choppy': isChoppy,
    };
  }
}

class NewsItemModel {
  final String title;
  final String source;
  final String sentiment;
  final double sentimentScore;
  final String? url;

  NewsItemModel({
    required this.title,
    required this.source,
    required this.sentiment,
    required this.sentimentScore,
    this.url,
  });

  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    return NewsItemModel(
      title: json['title'] ?? '',
      source: json['source'] ?? '',
      sentiment: json['sentiment'] ?? 'NEUTRAL',
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0.0,
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'source': source,
      'sentiment': sentiment,
      'sentiment_score': sentimentScore,
      'url': url,
    };
  }
}

class EconomicAlertModel {
  final bool hasHighImpactEvent;
  final String? eventTitle;
  final String? warningMessage;

  EconomicAlertModel({
    required this.hasHighImpactEvent,
    this.eventTitle,
    this.warningMessage,
  });

  factory EconomicAlertModel.fromJson(Map<String, dynamic> json) {
    return EconomicAlertModel(
      hasHighImpactEvent: json['has_high_impact_event'] ?? false,
      eventTitle: json['event_title'],
      warningMessage: json['warning_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_high_impact_event': hasHighImpactEvent,
      'event_title': eventTitle,
      'warning_message': warningMessage,
    };
  }
}
