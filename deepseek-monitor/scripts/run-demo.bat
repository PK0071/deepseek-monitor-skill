@echo off
cd /d "%~dp0"
echo Starting DeepSeek Token Monitor (DEMO MODE)...
powershell -ExecutionPolicy Bypass -File "TokenMonitor.ps1" -Demo
if errorlevel 1 ( echo Startup failed. & pause )
