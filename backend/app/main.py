from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
import uvicorn

from app.models import AnalysisResponse, MarketType
from app.services.vision_service import VisionService
from app.services.market_data_service import MarketDataService
from app.services.news_service import NewsService
from app.services.decision_engine import DecisionEngine

app = FastAPI(
    title="Smart Trader AI Engine",
    description="High-precision Trading Chart & News Analysis API",
    version="1.0.0"
)

# Enable CORS for Android Emulators (10.0.2.2) and mobile devices
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize service singletons
vision_service = VisionService()
market_service = MarketDataService()
news_service = NewsService()
decision_engine = DecisionEngine()

@app.get("/")
async def root():
    return {
        "status": "healthy",
        "service": "Smart Trader AI Engine",
        "version": "1.5.0"
    }

@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "Smart Trader AI Engine",
        "version": "1.5.0"
    }

@app.get("/api/debug-vision")
async def debug_vision():
    available_models = []
    if vision_service.client:
        try:
            for m in vision_service.client.models.list():
                available_models.append(getattr(m, "name", str(m)))
        except Exception as e:
            available_models = [f"Error listing: {e}"]
    return {
        "has_key": bool(vision_service.api_key),
        "key_length": len(vision_service.api_key),
        "key_prefix": vision_service.api_key[:6] if vision_service.api_key else "NONE",
        "has_client": bool(vision_service.client),
        "available_models": available_models[:20],
        "last_error": vision_service.last_error
    }

@app.get("/api/market-summary")
async def get_market_summary():
    """Fetch live real-time tickers for Home screen"""
    return await market_service.get_market_overview()

@app.post("/api/analyze-chart", response_model=AnalysisResponse)
async def analyze_chart(
    file: UploadFile = File(...),
    symbol: Optional[str] = Form(None),
    timeframe: Optional[str] = Form(None),
):
    try:
        # Read uploaded image bytes
        image_bytes = await file.read()
        if len(image_bytes) == 0:
            raise HTTPException(status_code=400, detail="Uploaded file is empty.")

        # Step 1: Vision Extraction
        extraction = await vision_service.analyze_chart_image(
            image_bytes=image_bytes,
            manual_symbol=symbol,
            manual_timeframe=timeframe
        )
        print(f"[ANALYZE] Extracted: sym={extraction.symbol}, tf={extraction.timeframe}, price={extraction.current_price}, bias={extraction.signal_bias}")

        # Step 2: Live Market Data & Deterministic Math Validation
        indicators, s_levels, r_levels = await market_service.get_live_market_data(
            symbol=extraction.symbol,
            timeframe=extraction.timeframe,
            market_type=extraction.market_type,
            extracted_price=extraction.current_price
        )

        # Step 3: News & High-Impact Event Radar
        news, alert = await news_service.get_news_and_events(
            symbol=extraction.symbol,
            market_type=extraction.market_type
        )

        # Step 4: Decision & Risk Synthesis
        analysis = decision_engine.synthesize_analysis(
            extraction=extraction,
            indicators=indicators,
            news=news,
            alert=alert,
            support_levels=s_levels or extraction.support_levels,
            resistance_levels=r_levels or extraction.resistance_levels
        )

        return analysis

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@app.get("/api/market/{symbol}")
async def get_market(symbol: str, timeframe: str = "1h"):
    indicators, s_levels, r_levels = await market_service.get_live_market_data(
        symbol=symbol,
        timeframe=timeframe,
        market_type=MarketType.CRYPTO
    )
    return {
        "indicators": indicators,
        "support_levels": s_levels,
        "resistance_levels": r_levels
    }

@app.get("/api/news/{symbol}")
async def get_news(symbol: str):
    news, alert = await news_service.get_news_and_events(
        symbol=symbol,
        market_type=MarketType.CRYPTO
    )
    return {
        "news": news,
        "alert": alert
    }

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
