---
name: deepseek-monitor
description: Set up or fix Windows desktop floating window for real-time DeepSeek token usage monitoring. Use when user asks about DeepSeek usage display, token tracking, platform balance check, or expired platform token refresh.
version: 1.1
---

# DeepSeek Usage Monitor (V1.1)

Windows desktop floating window for DeepSeek API usage monitoring. Data synced with platform.deepseek.com dashboard.

## When to trigger

- User mentions "deepseek浮窗", "token监控", "用量显示"
- Floating window shows zeros or errors
- Platform token expired — walk through refresh
- "本月消费多少钱" — show monthly cost

## Quick start

Double-click `scripts/run.bat`

## V1.1 field layout

```
DeepSeek 用量监控          x
──────────────────────────
      2026-05-14

余额:          82.50 CNY
本月消费:      6.54 CNY

v4-pro
  输入(命中):   6070.8万  60,707,840
  输入(未命中): 98.8万    987,742
  输出:         29.6万    296,222

v4-flash
  输入(命中):   207.8万   2,078,080
  输入(未命中): 11.0万    110,074
  输出:         1.6万     16,319
```

## Setup

### config.ini

```ini
[deepseek]
api_key = sk-your-key-here
platform_token = your-platform-token-here
```

### Getting platform_token

1. Chrome → login to platform.deepseek.com
2. `F12` → **Network** tab
3. Click **Usage** in sidebar
4. Filter: `amount`
5. Click the `usage/amount?month=X&year=2026` request
6. Copy `authorization: Bearer xxx` header value
7. Paste as `platform_token` in config.ini

## Token expiry refresh

When window shows all zeros:

1. Login platform.deepseek.com
2. F12 → Network → Usage page → filter `amount`
3. Copy new `authorization: Bearer xxx`
4. Update `config.ini` → restart `run.bat`

## Pricing (V1.1 — 2.5-zhe promotion)

| Model | Type | CNY / 1M tokens |
|-------|------|----------------|
| v4-pro | cache hit | ¥0.025 |
| v4-pro | cache miss | ¥3.00 |
| v4-pro | output | ¥6.00 |
| v4-flash | cache hit | ¥0.02 |
| v4-flash | cache miss | ¥1.00 |
| v4-flash | output | ¥2.00 |

## Troubleshooting

**Chinese garbled (乱码):** Run `to_utf16.ps1` or re-save TokenMonitor.ps1 as UTF-8 BOM.

**All zeros:** platform_token expired. Follow refresh procedure.

**Window not visible:** Change `CenterScreen` to `Manual` and set explicit coordinates.
