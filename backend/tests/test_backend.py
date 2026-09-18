import io
import pytest
from PIL import Image
from fastapi.testclient import TestClient

from app.main import app
from app.models import ChartExtraction, MarketType, TechnicalIndicators, EconomicAlert, SignalAction
from app.services.decision_engine import DecisionEngine
from app.services.market_data_service import MarketDataService

client = TestClient(app)

def create_sample_chart_image() -> bytes:
    """Create a minimal PNG image simulating a chart screenshot"""
    img = Image.new("RGB", (300, 300), color=(18, 22, 28))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()

def test_health_check():
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_rsi_and_ema_calculation():
    service = MarketDataService()
    # 20 strictly increasing closes -> RSI should be 100 or very high
    bullish_closes = [float(100 + i * 2) for i in range(25)]
    rsi = service._calculate_rsi(bullish_closes, period=14)
    assert rsi > 70

    # Test EMA calculation
    ema = service._calculate_ema(bullish_closes, period=10)
    assert ema > 0
    assert ema < bullish_closes[-1]

def test_decision_engine_neutral_on_choppy():
    engine = DecisionEngine()
    extraction = ChartExtraction(
        symbol="BTCUSDT",
        market_type=MarketType.CRYPTO,
        timeframe="1h",
        visual_trend="Sideways",
        patterns=[],
        confidence=0.85
    )
    indicators = TechnicalIndicators(
        current_price=65000.0,
        rsi_14=50.0,  # Dead neutral
        ema_20=65010.0,
        ema_50=65005.0,
        atr=500.0,
        trend_summary="Choppy",
        is_choppy=True  # Flagged choppy
    )
    alert = EconomicAlert(has_high_impact_event=False)

    analysis = engine.synthesize_analysis(
        extraction=extraction,
        indicators=indicators,
        news=[],
        alert=alert,
        support_levels=[64000.0],
        resistance_levels=[66000.0]
    )

    assert analysis.setup.action == SignalAction.NEUTRAL_WAIT
    assert any("تذبذب" in r or "Chop" in r for r in analysis.reasons)

def test_decision_engine_neutral_on_high_impact_news():
    engine = DecisionEngine()
    extraction = ChartExtraction(
        symbol="EURUSD",
        market_type=MarketType.FOREX,
        timeframe="15m",
        visual_trend="Uptrend",
        patterns=["Bull Flag"],
        confidence=0.9
    )
    indicators = TechnicalIndicators(
        current_price=1.0850,
        rsi_14=60.0,
        ema_20=1.0840,
        ema_50=1.0820,
        atr=0.0020,
        trend_summary="Uptrend",
        is_choppy=False
    )
    alert = EconomicAlert(
        has_high_impact_event=True,
        event_title="FOMC Interest Rate Decision",
        warning_message="Avoid trading due to FOMC!"
    )

    analysis = engine.synthesize_analysis(
        extraction=extraction,
        indicators=indicators,
        news=[],
        alert=alert,
        support_levels=[1.0800],
        resistance_levels=[1.0900]
    )

    # Even with strong technicals, high-impact news forces NEUTRAL_WAIT to protect trader
    assert analysis.setup.action == SignalAction.NEUTRAL_WAIT
    assert "Avoid trading" in analysis.reasons[0]

def test_analyze_chart_endpoint_end_to_end():
    img_bytes = create_sample_chart_image()
    response = client.post(
        "/api/analyze-chart",
        files={"file": ("chart.png", img_bytes, "image/png")},
        data={"symbol": "BTCUSDT", "timeframe": "1h"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["symbol"] == "BTCUSDT"
    assert "setup" in data
    assert data["setup"]["action"] in ["STRONG_BUY", "BUY", "NEUTRAL_WAIT", "SELL", "STRONG_SELL"]
    assert data["setup"]["entry_price"] > 0
    assert data["setup"]["stop_loss"] > 0
    assert data["setup"]["take_profit_1"] > 0
    assert len(data["reasons"]) > 0
    assert "disclaimer" in data
