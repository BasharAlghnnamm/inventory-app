@echo off
rem Single-click run of the web build on Windows. No installs needed.
setlocal
cd /d "%~dp0"

if not exist "web\index.html" (
  echo Web build missing. Run: flutter build web --release
  pause
  exit /b 1
)

set "PORT=8080"
set "URL=http://localhost:%PORT%"
echo Inventory app running at %URL%
echo Close this window to stop the server.

start "Inventory Server" /min powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1" -Port %PORT%
timeout /t 2 /nobreak >nul
start "" "%URL%"