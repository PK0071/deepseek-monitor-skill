# deepseek-monitor

Windows desktop floating window for real-time DeepSeek API usage monitoring. Syncs with your official DeepSeek dashboard at `platform.deepseek.com`.

## Install

```bash
npx skills add <your-username>/deepseek-monitor-skill@deepseek-monitor -g
```

## What it does

- Floating always-on-top window with DeepSeek usage stats
- Pulls data from `platform.deepseek.com` dashboard API (same as what you see in browser)
- Auto-refreshes every 60 seconds
- Shows: Balance, Cache Hit/Miss tokens, Output tokens, Daily total

## Requires

- Windows 10/11 (uses built-in PowerShell + WPF, nothing to install)
- DeepSeek API key + platform token

## Setup

1. Edit `scripts/config.ini` with your API key and platform token
2. Double-click `scripts/run.bat`
