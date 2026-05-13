---
name: deepseek-monitor
description: Set up Windows desktop floating window showing real-time DeepSeek token usage & balance. Use when user wants to monitor DeepSeek API consumption, check dashboard data, or fix expired platform token.
---

# DeepSeek Usage Monitor

Windows desktop floating window that displays real-time DeepSeek API usage data from `platform.deepseek.com`, synced with the official dashboard.

## When to use

- User asks to monitor/setup/fix DeepSeek token usage display
- Floating window shows 0 or error — re-run setup
- Platform token expired — walk through refresh procedure

## Quick start

```
double-click: run.bat
```

## Setup checklist

### 1. API Key (`config.ini` → `api_key`)

Get from https://platform.deepseek.com → API Keys. This key calls `/user/balance` for account balance.

### 2. Platform Token (`config.ini` → `platform_token`)

This is the dashboard auth token that accesses usage data. It EXPIRES after several days.

**How to get it:**
1. Open Chrome, go to https://platform.deepseek.com and login
2. Press `F12` → **Network** tab
3. Navigate to **Usage** page (用量管理)
4. In Network filter, search: `usage/amount`
5. Click the request → **Headers** tab
6. Find `authorization: Bearer pGWqIKiv...`
7. Copy the token (after `Bearer `) into `config.ini` → `platform_token`

### 3. Files

All files in `tools/token-float-window/`:
| File | Purpose |
|------|---------|
| `run.bat` | Launch real mode (production) |
| `run-demo.bat` | Launch with sample data |
| `TokenMonitor.ps1` | PowerShell WPF floating window |
| `config.ini` | API key + platform token |
| `fix_encoding.ps1` | Save TokenMonitor.ps1 with UTF-8 BOM (if Chinese garbled) |

### 4. Requirements

- Windows 10/11 (PowerShell + WPF built-in, no install needed)
- Valid DeepSeek account with API key

## Display fields

| Row | API Source | Description |
|-----|-----------|-------------|
| 余额 | `/user/balance` | Account balance in CNY |
| 输入(命中) | `PROMPT_CACHE_HIT_TOKEN` | Cached input tokens (discounted ~90%) |
| 输入(未命中) | `PROMPT_CACHE_MISS_TOKEN` | New input tokens (full price) |
| 输出 | `RESPONSE_TOKEN` | Output tokens |
| 今日合计 | Sum of above | Total tokens today |

Data refreshes every 60 seconds from `platform.deepseek.com/api/v0/usage/amount`.

## Platform token refresh procedure

When the floating window shows no data or hangs, the `platform_token` has likely expired.

1. Open Chrome → https://platform.deepseek.com → login
2. `F12` → **Network** tab → clear existing entries
3. Click **Usage** in the sidebar
4. Filter network requests: `amount`
5. Click the `usage/amount?month=X&year=2026` request
6. Copy `authorization: Bearer <token>` header value
7. Update `config.ini`:
   ```ini
   platform_token = <paste_new_token_here>
   ```
8. Restart: double-click `run.bat`

## Troubleshooting

**Chinese characters garbled (乱码):**
Run `powershell -ExecutionPolicy Bypass -File fix_encoding.ps1` then restart.

**Window not visible:**
Check Win+Tab to see if window exists but off-screen. Set `$window.WindowStartupLocation = "CenterScreen"` in TokenMonitor.ps1.

**All zeros:**
`platform_token` is expired — follow refresh procedure above.
