---
name: deepseek-monitor
description: Set up/fix Windows floating window for real-time DeepSeek token usage + balance. Triggers on "deepseek浮窗", "token监控", "用量", "platform_token过期", "余额".
version: 1.2
---

# DeepSeek Usage Monitor (V1.2)

Floating window synced with platform.deepseek.com dashboard.

## Quick start

`double-click run.bat`

## V1.2 layout

```
DeepSeek 用量监控             x
─────────────────────────
      2026-05-14
余额:              82.50 CNY
本月消费:          6.54 CNY

v4-pro
  输入(命中):      6070.8万  60,707,840
  输入(未命中):     14.4万     144,096
  输出:              7.9万      79,059

v4-flash
  输入(命中):       207.8万   2,078,080
  输入(未命中):      11.0万     110,074
  输出:               1.6万      16,319

今日合计:          1623.5万  较昨天-88% ↓
昨日合计:          5390.2万
```

## New in V1.2
- Yesterday vs today comparison with colored arrows
- Two-column grid for consistent alignment
- WidthAndHeight auto-size

## Setup

`config.ini`: api_key + platform_token

## Platform token refresh

1. Chrome → platform.deepseek.com → login
2. F12 → Network → Usage page → filter `amount`
3. Copy `authorization: Bearer xxx`
4. Update config.ini → restart run.bat

## Pricing (2.5-zhe)

| Model | Type | CNY/M |
|-------|------|-------|
| v4-pro | cache hit | 0.025 |
| v4-pro | cache miss | 3.00 |
| v4-pro | output | 6.00 |
| v4-flash | cache hit | 0.02 |
| v4-flash | cache miss | 1.00 |
| v4-flash | output | 2.00 |
