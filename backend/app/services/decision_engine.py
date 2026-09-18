from typing import List
from app.models import (
    ChartExtraction, TechnicalIndicators, NewsItem, 
    EconomicAlert, TradeSetup, SignalAction, AnalysisResponse
)

class DecisionEngine:
    def synthesize_analysis(
        self,
        extraction: ChartExtraction,
        indicators: TechnicalIndicators,
        news: List[NewsItem],
        alert: EconomicAlert,
        support_levels: List[float],
        resistance_levels: List[float]
    ) -> AnalysisResponse:
        current_price = indicators.current_price
        atr = indicators.atr if indicators.atr > 0 else (current_price * 0.015)

        reasons: List[str] = []
        tech_score = 0
        
        # 1. Evaluate Moving Averages
        if current_price > indicators.ema_20 > indicators.ema_50:
            tech_score += 35
            reasons.append(f"تمركز السعر ({current_price}) فوق المتوسطين المتحركين السريعين EMA 20 و EMA 50 يؤكد قوة الزخم الصاعد.")
        elif current_price < indicators.ema_20 < indicators.ema_50:
            tech_score -= 35
            reasons.append(f"هبوط السعر ({current_price}) أسفل المتوسطين المتحركين EMA 20 و EMA 50 يشير إلى استمرار الضغط البيعي.")
        else:
            reasons.append("السعر يتذبذب بالقرب من المتوسطات المتحركة، مما يعكس توازناً مؤقتاً بين المشترين والبائعين.")

        # 2. Evaluate RSI
        rsi = indicators.rsi_14
        if rsi > 70:
            tech_score -= 20
            reasons.append(f"مؤشر القوة النسبية RSI يقع عند {rsi} (منطقة تشبع شرائي Overbought)، مما قد يحفز جني أرباح وتصحيح هابط.")
        elif rsi < 30:
            tech_score += 25
            reasons.append(f"مؤشر القوة النسبية RSI عند {rsi} (منطقة تشبع بيعي Oversold)، مما يوفر فرصة ارتداد صاعد قوية.")
        elif 52 <= rsi <= 68:
            tech_score += 20
            reasons.append(f"مؤشر RSI مستقر عند {rsi} في المنطقة الإيجابية مع مساحة جيدة لمواصلة الصعود دون تشبع.")
        elif 32 <= rsi <= 48:
            tech_score -= 20
            reasons.append(f"مؤشر RSI مستقر عند {rsi} في المنطقة السلبية مما يدعم استكمال الاتجاه الهابط.")

        # 3. Chart Patterns
        pattern_str = ", ".join(extraction.patterns) if extraction.patterns else "نموذج حركة سعر كلاسيكي"
        if extraction.visual_trend.lower() == "uptrend":
            tech_score += 20
            reasons.append(f"التحليل البصري يظهر اتجاهاً عاماً صاعداً (Uptrend) مع نماذج إيجابية: ({pattern_str}).")
        elif extraction.visual_trend.lower() == "downtrend":
            tech_score -= 20
            reasons.append(f"التحليل البصري يظهر اتجاهاً عاماً هابطاً (Downtrend) مع نماذج سلبية: ({pattern_str}).")
        else:
            reasons.append("الشارت يظهر حركة جانبية (Sideways Consolidation) داخل نطاق سعري محدد.")

        # 4. News Sentiment Score
        sentiment_score = 0.0
        if news:
            avg_news = sum(item.sentiment_score for item in news) / len(news)
            sentiment_score = avg_news * 30  # Max +/- 30
            if avg_news > 0.3:
                reasons.append("الأخبار والبيانات المتدفقة إيجابية وداعمة لثقة المستثمرين في هذا الأصل.")
            elif avg_news < -0.3:
                reasons.append("البيانات الإخبارية الحالية تشير إلى حذر وسلبية قد تضغط على الأسعار.")

        total_score = tech_score + sentiment_score

        # 5. Anti-Misleading Protection Rules
        is_wait = False
        wait_reason = ""

        # Check high-impact news event alert
        if alert.has_high_impact_event:
            is_wait = True
            wait_reason = f"تم إيقاف إشارة الدخول: {alert.warning_message}"
            reasons.insert(0, f"⚠️ {wait_reason}")

        # Check market chop
        elif indicators.is_choppy or (-15 <= total_score <= 15):
            is_wait = True
            wait_reason = "السوق يمر بمرحلة تذبذب عرضي ضيق (Chop / Consolidation). الدخول الآن عالي الخطورة، والأفضل انتظار كسر النطاق."
            reasons.insert(0, f"⏳ {wait_reason}")

        # Determine Signal Action
        if is_wait:
            action = SignalAction.NEUTRAL_WAIT
            confidence = 50
            risk_assessment = "HIGH"
            entry = current_price
            sl = current_price - atr
            tp1 = current_price + atr
            tp2 = current_price + (atr * 2)
            rrr = 1.0
        elif total_score >= 50:
            action = SignalAction.STRONG_BUY if total_score >= 70 else SignalAction.BUY
            confidence = min(96, int(60 + (total_score / 2.5)))
            risk_assessment = "LOW" if confidence >= 85 else "MEDIUM"
            entry = round(current_price, 4 if current_price < 10 else 2)
            
            # SL placed safely below support or 1.5x ATR
            sup = support_levels[0] if support_levels and support_levels[0] < current_price else (current_price - 1.5 * atr)
            sl = round(min(sup, current_price - atr), 4 if current_price < 10 else 2)
            risk_distance = max(entry - sl, atr * 0.5)

            tp1 = round(entry + (risk_distance * 1.5), 4 if current_price < 10 else 2)
            tp2 = round(entry + (risk_distance * 2.5), 4 if current_price < 10 else 2)
            rrr = round((tp1 - entry) / max(0.0001, entry - sl), 2)

        else:
            action = SignalAction.STRONG_SELL if total_score <= -70 else SignalAction.SELL
            confidence = min(96, int(60 + (abs(total_score) / 2.5)))
            risk_assessment = "LOW" if confidence >= 85 else "MEDIUM"
            entry = round(current_price, 4 if current_price < 10 else 2)

            res = resistance_levels[0] if resistance_levels and resistance_levels[0] > current_price else (current_price + 1.5 * atr)
            sl = round(max(res, current_price + atr), 4 if current_price < 10 else 2)
            risk_distance = max(sl - entry, atr * 0.5)

            tp1 = round(entry - (risk_distance * 1.5), 4 if current_price < 10 else 2)
            tp2 = round(entry - (risk_distance * 2.5), 4 if current_price < 10 else 2)
            rrr = round((entry - tp1) / max(0.0001, sl - entry), 2)

        setup = TradeSetup(
            action=action,
            confidence_score=confidence,
            entry_price=entry,
            stop_loss=sl,
            take_profit_1=tp1,
            take_profit_2=tp2,
            risk_reward_ratio=rrr,
            invalidation_level=sl,
            risk_assessment=risk_assessment
        )

        return AnalysisResponse(
            symbol=extraction.symbol,
            timeframe=extraction.timeframe,
            market_type=extraction.market_type.value,
            current_price=current_price,
            setup=setup,
            technical_summary=indicators.trend_summary,
            indicators=indicators,
            recent_news=news,
            economic_alert=alert,
            reasons=reasons
        )
