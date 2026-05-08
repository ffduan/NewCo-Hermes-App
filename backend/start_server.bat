@echo off
cd /d "%~dp0"

echo ========================================
echo NewCo Project - Backend Server
echo ========================================
echo.
echo Starting...
echo Open browser: http://localhost:8765/web_app/index.html
echo.
python server.py
pause
