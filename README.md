# DeepSeek Monitor Skill

![screenshot](https://raw.githubusercontent.com/PK0071/deepseek-monitor-skill/master/images/screenshot.png)

[English](#english) | [中文](#中文)

---

## English

### What is this?

A Windows desktop floating window that monitors your DeepSeek API usage in real-time. Data comes directly from DeepSeek's official dashboard API — identical to what you see at platform.deepseek.com. Zero dependencies, double-click `run.bat` to start.

### Changelog

**V1.1 (2026-05-14)**
- Separate v4-pro and v4-flash token breakdown
- Big-unit display: shows "123.4万" or "1.2亿" alongside precise numbers
- Monthly cost (本月消费) calculated from official 2.5-zhe pricing
- Correct pricing: v4-pro ¥3/¥6 per M tokens, cache hit ¥0.025/M; v4-flash ¥1/¥2, cache hit ¥0.02/M
- Compact layout: auto-fit height, no wasted space
- Date display below title
- Balance & cost moved above model breakdown
- 60-second DispatcherTimer refresh (WPF-native, no thread issues)
- UTF-16 LE encoding for Windows PowerShell compatibility

**V1.0 (2026-05-13)**
- Initial release: balance + token display from platform.deepseek.com API

### Display Fields

| Row | Source | Description |
|-----|--------|-------------|
| Date | Local | Current date (YYYY-MM-DD) |
| 余额 | `/user/balance` API | Account balance in CNY |
| 本月消费 | Calculated from pricing | Monthly cost (2.5-zhe promotion) |
| v4-pro 输入(命中) | `PROMPT_CACHE_HIT_TOKEN` | Cached input — ~0.025 CNY/M |
| v4-pro 输入(未命中) | `PROMPT_CACHE_MISS_TOKEN` | New input — 3.00 CNY/M |
| v4-pro 输出 | `RESPONSE_TOKEN` | Output — 6.00 CNY/M |
| v4-flash * | Same as above | Flash pricing: 1/2 CNY per M |
| * Flash rows may show 0 if not used | | |

### Setup

1. Get API key: https://platform.deepseek.com → API Keys
2. Get platform token:
   - Chrome → platform.deepseek.com → login
   - `F12` → **Network** tab → click **Usage** page
   - Filter: `amount` → copy `authorization: Bearer xxx`
3. Edit `scripts/config.ini`:
   ```ini
   [deepseek]
   api_key = sk-your-key
   platform_token = your-token
   ```
4. Double-click `scripts/run.bat`

### Token Expiry

Platform token expires after days. When data shows zeros:
1. Login to platform.deepseek.com
2. `F12` → Network → Usage page → filter `amount`
3. Copy new `authorization: Bearer xxx` header
4. Update `config.ini` → restart `run.bat`

### Install via Skills CLI

```bash
npx skills add PK0071/deepseek-monitor-skill@deepseek-monitor -g
```

### Requirements

- Windows 10/11 (PowerShell + WPF built-in)
- DeepSeek API account

---

## 中文

### 这是什么？

Windows 桌面悬浮窗，实时监控 DeepSeek API 用量。数据直接从 DeepSeek 官方后台 API 拉取，与 platform.deepseek.com 后台数据完全一致。零依赖，双击 `run.bat` 即用。

### 更新日志

**V1.1 (2026-05-14)**
- v4-pro 和 v4-flash 分开显示各自 token 用量
- 大单位显示：如 "6070.8万"、"1.2亿"，后跟精确数字
- 本月消费：按官方 2.5 折活动价精确计算
- 定价修正：v4-pro ¥3/¥6 每百万 token, 缓存命中 ¥0.025/M
- 紧凑布局：窗口高度自适应内容，无多余空白
- 日期显示在标题下方居中
- 余额/消费移到模型明细上方
- DispatcherTimer 60 秒刷新（WPF 原生，无线程问题）
- UTF-16 LE 编码，Windows PowerShell 完美兼容中文

**V1.0 (2026-05-13)**
- 初始版本：余额 + 当日 token 展示

### 显示字段

| 字段 | 数据来源 | 说明 |
|------|---------|------|
| 日期 | 本地 | 当天日期 (YYYY-MM-DD) |
| 余额 | `/user/balance` 接口 | 账户实时余额 (CNY) |
| 本月消费 | 定价表计算 | 当月累计消费 (2.5折活动) |
| v4-pro 输入(命中) | `PROMPT_CACHE_HIT_TOKEN` | 缓存命中 — ¥0.025/M |
| v4-pro 输入(未命中) | `PROMPT_CACHE_MISS_TOKEN` | 新输入 — ¥3.00/M |
| v4-pro 输出 | `RESPONSE_TOKEN` | 输出 — ¥6.00/M |
| v4-flash * | 同上 | Flash 定价: ¥1/¥2 每M |
| * Flash 行未使用则显示 0 | | |

### 配置步骤

1. 获取 API Key：platform.deepseek.com → API Keys
2. 获取 Platform Token：
   - Chrome 登录 platform.deepseek.com
   - `F12` → **Network** → 点击 **Usage** 页面
   - 过滤 `amount` → 复制 `authorization: Bearer xxx`
3. 编辑 `scripts/config.ini`：
   ```ini
   [deepseek]
   api_key = sk-你的key
   platform_token = 你的token
   ```
4. 双击 `scripts/run.bat`

### Token 过期处理

Platform token 几天后过期，数据归零时：
1. 登录 platform.deepseek.com
2. `F12` → Network → Usage 页面 → 过滤 `amount`
3. 复制新的 `authorization: Bearer xxx`
4. 更新 `config.ini` → 重启 `run.bat`

### 环境要求

- Windows 10 或 11
- DeepSeek API 账户
