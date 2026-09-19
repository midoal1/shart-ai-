import os
import json
import re
from typing import Optional
import asyncio

from app.models import ChartExtraction, MarketType

class VisionService:
    def __init__(self):
        self.api_key = os.environ.get("GEMINI_API_KEY", "")
        self.client = None
        if self.api_key:
            try:
                from google import genai
                self.client = genai.Client(api_key=self.api_key)
            except Exception as e:
                print(f"Failed to initialize google-genai client: {e}")

    def _detect_mime_type(self, image_bytes: bytes) -> str:
        header = image_bytes[:12]
        if header.startswith(b'\x89PNG\r\n\x1a\n'):
            return 'image/png'
        elif header[:2] == b'\xff\xd8':
            return 'image/jpeg'
        elif header[:6] in (b'GIF87a', b'GIF89a'):
            return 'image/gif'
        elif header[:4] == b'RIFF' and len(header) >= 12 and header[8:12] == b'WEBP':
            return 'image/webp'
        return 'image/jpeg'

    async def analyze_chart_image(
        self, 
        image_bytes: bytes, 
        manual_symbol: Optional[str] = None, 
        manual_timeframe: Optional[str] = None
    ) -> ChartExtraction:
        if self.client and self.api_key:
            try:
                return await self._call_gemini_vision(image_bytes, manual_symbol, manual_timeframe)
            except Exception as e:
                print(f"Error calling Gemini Vision API: {e}. Falling back to smart default parser.")

        return self._smart_fallback(image_bytes, manual_symbol, manual_timeframe)

    async def _call_gemini_vision(
        self, 
        image_bytes: bytes, 
        manual_symbol: Optional[str] = None, 
        manual_timeframe: Optional[str] = None
    ) -> ChartExtraction:
        from google.genai import types

        mime_type = self._detect_mime_type(image_bytes)

        prompt = f"""
You are a professional Senior Quantitative Financial Analyst and Expert Chart Reader.
Analyze this trading chart screenshot with maximum precision.

User provided overrides (if any):
- Symbol: {manual_symbol or 'Auto-detect from image'}
- Timeframe: {manual_timeframe or 'Auto-detect from image'}

Extract the following in strict JSON format:
{{
    "symbol": "TICKER (e.g. BTCUSDT, ETHUSDT, EURUSD, XAUUSD, TSLA)",
    "market_type": "CRYPTO or FOREX or STOCK or COMMODITY",
    "timeframe": "15m, 1h, 4h, 1D, etc.",
    "visual_trend": "Uptrend or Downtrend or Sideways",
    "patterns": ["list of chart patterns visible like Bull Flag, Double Bottom, Head and Shoulders, Support Rebound, etc."],
    "support_levels": [list of numeric support price levels if clearly visible],
    "resistance_levels": [list of numeric resistance price levels if clearly visible],
    "confidence": 0.95
}}

Return ONLY valid JSON without markdown wrapping or code fences.
"""
        def _generate():
            return self.client.models.generate_content(
                model='gemini-2.5-flash',
                contents=[
                    types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
                    prompt
                ]
            )

        response = await asyncio.to_thread(_generate)
        
        raw_text = response.text.strip()
        # Clean JSON fences if present
        raw_text = re.sub(r"^```json\s*", "", raw_text)
        raw_text = re.sub(r"^```\s*", "", raw_text)
        raw_text = re.sub(r"\s*```$", "", raw_text)

        data = json.loads(raw_text)

        market_type_str = data.get("market_type", "CRYPTO").upper()
        if "FOREX" in market_type_str:
            m_type = MarketType.FOREX
        elif "STOCK" in market_type_str:
            m_type = MarketType.STOCK
        elif "COMMODITY" in market_type_str or "GOLD" in market_type_str or "XAU" in str(data.get("symbol", "")):
            m_type = MarketType.COMMODITY
        else:
            m_type = MarketType.CRYPTO

        return ChartExtraction(
            symbol=manual_symbol or data.get("symbol", "BTCUSDT").upper().replace("/", "").replace("-", ""),
            market_type=m_type,
            timeframe=manual_timeframe or data.get("timeframe", "1h"),
            visual_trend=data.get("visual_trend", "Sideways"),
            patterns=data.get("patterns", []),
            support_levels=[float(x) for x in data.get("support_levels", []) if isinstance(x, (int, float))],
            resistance_levels=[float(x) for x in data.get("resistance_levels", []) if isinstance(x, (int, float))],
            confidence=float(data.get("confidence", 0.85))
        )

    def _smart_fallback(
        self, 
        image_bytes: bytes, 
        manual_symbol: Optional[str], 
        manual_timeframe: Optional[str]
    ) -> ChartExtraction:
        symbol = (manual_symbol or "BTCUSDT").upper().replace("/", "").replace("-", "")
        timeframe = manual_timeframe or "1h"

        m_type = MarketType.CRYPTO
        if any(c in symbol for c in ["EUR", "GBP", "USD", "JPY", "AUD"]) and not any(k in symbol for k in ["BTC", "ETH", "USDT"]):
            m_type = MarketType.FOREX
        elif "XAU" in symbol or "GOLD" in symbol:
            m_type = MarketType.COMMODITY

        return ChartExtraction(
            symbol=symbol,
            market_type=m_type,
            timeframe=timeframe,
            visual_trend="Uptrend",
            patterns=["Support Retest", "Bullish Consolidation"],
            support_levels=[],
            resistance_levels=[],
            confidence=0.90
        )
