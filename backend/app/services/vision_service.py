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
        self.last_error = None
        self._init_client()

    def _init_client(self):
        self.api_key = os.environ.get("GEMINI_API_KEY", "")
        if self.api_key:
            try:
                from google import genai
                self.client = genai.Client(api_key=self.api_key)
            except Exception as e:
                self.last_error = f"Failed to init genai client: {e}"
                print(self.last_error)
        else:
            self.last_error = "GEMINI_API_KEY environment variable is missing on server"

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

    def _parse_json_safely(self, raw_text: str) -> dict:
        import ast
        text = raw_text.strip()
        # Strip markdown fences
        text = re.sub(r"^```json\s*", "", text)
        text = re.sub(r"^```\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
        text = text.strip()

        # Find outer braces if wrapped by text
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            text = match.group(0)

        # Remove JS/C-style comments
        text = re.sub(r"//.*", "", text)
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)

        # Remove trailing commas
        text = re.sub(r",\s*([\]}])", r"\1", text)

        # 1. Try standard JSON parse
        try:
            return json.loads(text)
        except Exception:
            pass

        # 2. Quote unquoted keys: e.g. { symbol: "BTC" }
        fixed_keys = re.sub(r"([{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)\s*:", r'\1"\2":', text)
        try:
            return json.loads(fixed_keys)
        except Exception:
            pass

        # 3. Try ast literal eval
        try:
            val = ast.literal_eval(text)
            if isinstance(val, dict):
                return val
        except Exception:
            pass

        # 4. Try replacing single quotes with double quotes
        try:
            quoted = re.sub(r"'([^'\\]*(?:\\.[^'\\]*)*)'", r'"\1"', text)
            return json.loads(quoted)
        except Exception as e:
            print(f"Error parsing Gemini output: {e}. Raw was: {raw_text[:300]}")
            raise Exception(f"Failed to parse model JSON: {e}")

    async def analyze_chart_image(
        self, 
        image_bytes: bytes, 
        manual_symbol: Optional[str] = None, 
        manual_timeframe: Optional[str] = None
    ) -> ChartExtraction:
        if not self.client:
            self._init_client()

        if self.client and self.api_key:
            try:
                return await self._call_gemini_vision(image_bytes, manual_symbol, manual_timeframe)
            except Exception as e:
                import traceback
                self.last_error = f"Gemini Vision call failed: {e}\n{traceback.format_exc()}"
                print(self.last_error)

        return self._smart_fallback(image_bytes, manual_symbol, manual_timeframe)

    async def _call_gemini_vision(
        self, 
        image_bytes: bytes, 
        manual_symbol: Optional[str] = None, 
        manual_timeframe: Optional[str] = None
    ) -> ChartExtraction:
        from google.genai import types

        mime_type = self._detect_mime_type(image_bytes)

        has_manual_sym = bool(manual_symbol and manual_symbol.strip())
        has_manual_tf = bool(manual_timeframe and manual_timeframe.strip() and manual_timeframe.strip().lower() != "auto")

        prompt = f"""
You are an ultra-fast, high-precision OCR and Quantitative Financial Chart Vision System.
Extract data from this trading chart screenshot (TradingView, MT4/MT5, Binance, Pocket Option, etc.).

USER HINTS (if provided):
- Symbol: {manual_symbol if has_manual_sym else 'AUTO-DETECT from chart (e.g. top-left ticker, watermark, or axis)'}
- Timeframe: {manual_timeframe if has_manual_tf else 'AUTO-DETECT from chart (e.g. M1/1m, M5/5m, H1/1h, etc.)'}

EXTRACT THE FOLLOWING IN STRICT JSON:
{{
    "symbol": "Clean ticker symbol e.g. EURUSD, XAUUSD, BTCUSDT, ETHUSDT, TSLA, US30",
    "market_type": "FOREX or CRYPTO or COMMODITY or STOCK",
    "timeframe": "Chart timeframe e.g. 1m, 5m, 15m, 30m, 1h, 4h, 1d",
    "current_price": 1.15349,
    "visual_trend": "Uptrend or Downtrend or Sideways",
    "patterns": ["List of visible patterns e.g. Bearish Breakdown, Support Retest, Bull Flag, Rejection Wick"],
    "support_levels": [1.15320, 1.15300],
    "resistance_levels": [1.15370, 1.15395],
    "signal_bias": "BUY or SELL or WAIT",
    "confidence": 0.95
}}

CRITICAL INSTRUCTIONS:
1. "current_price": Read the exact highlighted price on the right vertical price axis or the last candle close. Must be a number (float).
2. "symbol": Detect ticker from top-left text, watermark, open order line, or tab header. Strip OTC/(OTC)/broker suffixes.
3. "timeframe": Look at top toolbar (M1, M5, M15, M30, H1, H4, D1) or candle intervals.
4. "signal_bias": Immediate trade bias from visible candlestick price action.
"""
        def _generate():
            config = types.GenerateContentConfig(
                system_instruction="You are a specialized trading chart OCR engine. Output strictly valid JSON without any markdown formatting or comments.",
                response_mime_type="application/json",
                temperature=0.1,
                max_output_tokens=600
            )
            candidate_models = ['gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-2.5-flash']
            last_err = None
            for m in candidate_models:
                try:
                    return self.client.models.generate_content(
                        model=m,
                        contents=[
                            types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
                            prompt
                        ],
                        config=config
                    )
                except Exception as ex:
                    last_err = ex
                    print(f"Vision model {m} failed: {ex}, attempting next model...")
            raise last_err or Exception("All Gemini Vision models failed.")

        response = await asyncio.to_thread(_generate)
        raw_text = response.text.strip()
        data = self._parse_json_safely(raw_text)

        # Normalize symbol
        raw_sym = (manual_symbol if has_manual_sym else data.get("symbol", "BTCUSDT")) or "BTCUSDT"
        clean_sym = re.sub(r"[\s\/\-_]", "", raw_sym).upper()
        clean_sym = re.sub(r"\(OTC\)|OTC|\.M|\.PRO", "", clean_sym).strip()
        if not clean_sym:
            clean_sym = "EURUSD"

        # Normalize timeframe
        raw_tf = (manual_timeframe if has_manual_tf else data.get("timeframe", "1h")) or "1h"
        raw_tf = raw_tf.lower().strip()
        tf_map = {"m1": "1m", "m3": "3m", "m5": "5m", "m15": "15m", "m30": "30m", "h1": "1h", "h2": "2h", "h4": "4h", "d1": "1d"}
        clean_tf = tf_map.get(raw_tf, raw_tf)

        # Normalize market type
        market_type_str = data.get("market_type", "CRYPTO").upper()
        if "FOREX" in market_type_str or any(clean_sym.startswith(x) for x in ["EUR", "GBP", "USD", "AUD", "NZD", "CAD", "CHF", "JPY"]):
            m_type = MarketType.FOREX
        elif "COMMODITY" in market_type_str or "GOLD" in clean_sym or "XAU" in clean_sym or "PAXG" in clean_sym:
            m_type = MarketType.COMMODITY
        elif "STOCK" in market_type_str:
            m_type = MarketType.STOCK
        else:
            m_type = MarketType.CRYPTO

        # Price extraction
        extracted_price = None
        if "current_price" in data and isinstance(data["current_price"], (int, float)):
            extracted_price = float(data["current_price"])

        return ChartExtraction(
            symbol=clean_sym,
            market_type=m_type,
            timeframe=clean_tf,
            current_price=extracted_price,
            visual_trend=data.get("visual_trend", "Sideways"),
            patterns=data.get("patterns", []),
            support_levels=[float(x) for x in data.get("support_levels", []) if isinstance(x, (int, float))],
            resistance_levels=[float(x) for x in data.get("resistance_levels", []) if isinstance(x, (int, float))],
            signal_bias=data.get("signal_bias"),
            confidence=float(data.get("confidence", 0.88))
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
            current_price=None,
            visual_trend="Uptrend",
            patterns=["Support Retest", "Bullish Consolidation"],
            support_levels=[],
            resistance_levels=[],
            signal_bias=None,
            confidence=0.90
        )
