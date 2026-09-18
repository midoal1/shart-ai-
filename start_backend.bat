@echo off
title Smart Trader AI - Backend Engine
echo ========================================================
echo   Starting Smart Trader AI Backend Engine (FastAPI)
echo ========================================================
echo.

cd backend
call venv\Scripts\activate.bat
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
