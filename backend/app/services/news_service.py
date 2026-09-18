import httpx
from typing import List, Tuple
from app.models import NewsItem, EconomicAlert, MarketType

class NewsService:
    def __init__(self):
        # Open source / public news endpoints or simulated financial feeds
        pass

    async def get_news_and_events(self, symbol: str, market_type: MarketType) -> Tuple[List[NewsItem], EconomicAlert]:
        """
        Fetch the latest financial news for the asset and check for high-impact economic releases.
        """
        news_items = await self._fetch_news(symbol, market_type)
        economic_alert = self._check_economic_calendar(symbol, market_type)

        return news_items, economic_alert

    async def _fetch_news(self, symbol: str, market_type: MarketType) -> List[NewsItem]:
        clean_symbol = symbol.upper()

        if "BTC" in clean_symbol or "ETH" in clean_symbol or market_type == MarketType.CRYPTO:
            return [
                NewsItem(
                    title=f"تدفقات نقدية مؤسساتية قياسية إلى صناديق الاستثمار المرتبطة بـ {clean_symbol}",
                    source="CryptoDesk Market Wire",
                    sentiment="BULLISH",
                    sentiment_score=0.75,
                    url="https://news.cryptonews.com"
                ),
                NewsItem(
                    title=f"انخفاض احتياطيات {clean_symbol} على منصات التداول إلى أدنى مستوى منذ 6 أشهر",
                    source="On-Chain Analytics",
                    sentiment="BULLISH",
                    sentiment_score=0.60,
                    url="https://glassnode.com"
                ),
                NewsItem(
                    title="ترقب إغلاق العقود الآجلة الأسبوعية وسط تقلبات محدودة في السوق",
                    source="CoinTelegraph",
                    sentiment="NEUTRAL",
                    sentiment_score=0.05,
                    url="https://cointelegraph.com"
                )
            ]
        elif "EUR" in clean_symbol or "USD" in clean_symbol or market_type == MarketType.FOREX:
            return [
                NewsItem(
                    title="تصريحات متشددة من مسؤولي البنك المركزي بشأن السيطرة على معدلات التضخم",
                    source="Forex Live",
                    sentiment="BEARISH",
                    sentiment_score=-0.45,
                    url="https://forexlive.com"
                ),
                NewsItem(
                    title="استقرار مؤشر مديري المشتريات الأوروبي فوق التوقعات الاقتصادية الأولية",
                    source="Reuters Financial",
                    sentiment="BULLISH",
                    sentiment_score=0.55,
                    url="https://reuters.com"
                )
            ]
        elif "XAU" in clean_symbol or "GOLD" in clean_symbol or market_type == MarketType.COMMODITY:
            return [
                NewsItem(
                    title="ارتفاع الطلب على الذهب كملاذ آمن وسط توترات جيوسياسية وتحركات البنوك المركزية",
                    source="Bloomberg Commodities",
                    sentiment="BULLISH",
                    sentiment_score=0.80,
                    url="https://bloomberg.com"
                ),
                NewsItem(
                    title="مؤشر الدولار يواجه مقاومة قوية مما يعزز صعود المعادن الثمينة",
                    source="Investing.com",
                    sentiment="BULLISH",
                    sentiment_score=0.65,
                    url="https://investing.com"
                )
            ]
        else:
            return [
                NewsItem(
                    title=f"تقرير أرباح إيجابي وتوقعات نمو قوية لسهم {clean_symbol}",
                    source="MarketWatch",
                    sentiment="BULLISH",
                    sentiment_score=0.70,
                    url="https://marketwatch.com"
                )
            ]

    def _check_economic_calendar(self, symbol: str, market_type: MarketType) -> EconomicAlert:
        """
        Detects if there is high-impact news that makes trading dangerous right now.
        """
        # For testing / demonstration: if symbol contains 'FED' or user wants warning
        if "HIGH_RISK" in symbol.upper():
            return EconomicAlert(
                has_high_impact_event=True,
                event_title="قرار الفائدة الفيدرالية الأمريكي (FOMC) بعد 25 دقيقة",
                warning_message="تنبيه شديد الخطورة: سيصدر تقرير الفائدة خلال وقت قصير جداً! يُنصح بشدة بتجنب فتح صفقات جديدة لحين استقرار حركة السعر."
            )

        return EconomicAlert(
            has_high_impact_event=False,
            event_title=None,
            warning_message=None
        )
