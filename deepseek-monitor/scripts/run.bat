@echo off
cd /d "%~dp0"
echo Starting DeepSeek Token Monitor...
powershell -ExecutionPolicy Bypass -File "TokenMonitor.ps1"
if errorlevel 1 ( echo Startup failed. & pause )
