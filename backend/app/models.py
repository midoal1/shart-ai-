from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum

class SignalAction(str, Enum):
    STRONG_BUY = "STRONG_BUY"
    BUY = "BUY"
    NEUTRAL_WAIT = "NEUTRAL_WAIT"
    SELL = "SELL"
    STRONG_SELL = "STRONG_SELL"

class MarketType(str, Enum):
    CRYPTO = "CRYPTO"
    FOREX = "FOREX"
    STOCK = "STOCK"
    COMMODITY = "COMMODITY"
    UNKNOWN = "UNKNOWN"

class ChartExtraction(BaseModel):
    symbol: str = Field(description="Detected asset symbol e.g., BTCUSDT, EURUSD, XAUUSD, NVDA")
    market_type: MarketType = Field(default=MarketType.CRYPTO)
    timeframe: str = Field(default="1h", description="Detected timeframe e.g., 15m, 1h, 4h, 1D")
    visual_trend: str = Field(description="Uptrend, Downtrend, Sideways")
    patterns: List[str] = Field(default_factory=list, description="Detected patterns like Double Bottom, Head and Shoulders, Bull Flag")
    support_levels: List[float] = Field(default_factory=list)
    resistance_levels: List[float] = Field(default_factory=list)
    confidence: float = Field(default=0.8, description="Vision model confidence 0.0 to 1.0")

class TechnicalIndicators(BaseModel):
    current_price: float
    rsi_14: float
    ema_20: float
    ema_50: float
    ema_200: Optional[float] = None
    atr: float
    trend_summary: str
    is_choppy: bool = False

class NewsItem(BaseModel):
    title: str
    source: str
    sentiment: str  # BULLISH, BEARISH, NEUTRAL
    sentiment_score: float  # -1.0 to 1.0
    url: Optional[str] = None

class EconomicAlert(BaseModel):
    has_high_impact_event: bool = False
    event_title: Optional[str] = None
    warning_message: Optional[str] = None

class TradeSetup(BaseModel):
    action: SignalAction
    confidence_score: int = Field(description="Percentage 0 to 100")
    entry_price: float
    stop_loss: float
    take_profit_1: float
    take_profit_2: float
    risk_reward_ratio: float
    invalidation_level: float
    risk_assessment: str  # LOW, MEDIUM, HIGH

class AnalysisResponse(BaseModel):
    symbol: str
    timeframe: str
    market_type: str
    current_price: float
    setup: TradeSetup
    technical_summary: str
    indicators: TechnicalIndicators
    recent_news: List[NewsItem]
    economic_alert: EconomicAlert
    reasons: List[str]
    disclaimer: str = (
        "تنبيه هام: هذا التحليل هو لأغراض تعليمية واستشارية فقط ولا يمثل نصيحة مالية أو استثمارية ملزمة. "
        "التداول في الأسواق المالية ينطوي على مخاطر عالية لخسارة رأس المال. قم بإدارة مخاطرك دائماً."
    )
