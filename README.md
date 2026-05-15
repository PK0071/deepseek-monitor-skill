# DeepSeek Monitor Skill

**Detail Mode** | **Compact Mode**
--- | ---
![detail](https://raw.githubusercontent.com/PK0071/deepseek-monitor-skill/master/images/screenshot.png) | ![compact](https://raw.githubusercontent.com/PK0071/deepseek-monitor-skill/master/images/screenshot-compact.png)

[English](#english) | [中文](#中文)

---

## English

Windows desktop floating window for DeepSeek API usage monitoring. Data synced with platform.deepseek.com dashboard. Zero dependencies, double-click `run.bat`.

### Changelog

**V1.3 (2026-05-15)**
- Compact/detail toggle: click ▲/▼ to switch between full view and mini view (balance + today only)
- Compact mode collapses all hidden rows with zero spacing
- CNY values padded to align with token number column

**V1.2 (2026-05-14)**
- Yesterday comparison: auto-compares today vs yesterday token usage with percentage + colored arrow (green down / red up)
- Fixed two-column grid layout: all labels left-aligned, all values consistently positioned
- WidthAndHeight auto-size: zero wasted whitespace
- "较昨天" comparison text on today total line

**V1.1 (2026-05-14)**
- Separate v4-pro and v4-flash token breakdown
- Big-unit display: "1234.5万" / "1.2亿" with padded alignment
- Monthly cost from official 2.5-zhe pricing
- Compact SizeToContent layout
- Date display, balance/cost moved above models

**V1.0 (2026-05-13)**
- Initial release: balance + token display from platform.deepseek.com API

### Features

- **60-second auto-refresh** from platform.deepseek.com dashboard API
- **Drag to move** window anywhere on screen
- **Always on top** by default, toggle via right-click menu
- **Right-click menu**: manual refresh, topmost toggle, exit
- **Per-model breakdown**: v4-pro and v4-flash shown separately
- **Yesterday comparison**: today vs yesterday with colored arrows (green down / red up)
- **Dual-unit display**: big unit (万/亿) + precise number on each row
- **Monthly cost**: calculated in real-time from official 2.5-zhe pricing
- **Zero dependencies**: Windows built-in PowerShell + WPF, no install needed

### Display Fields

| Row | Source | Description |
|-----|--------|-------------|
| Date | Local | Current date (YYYY-MM-DD) |
| Balance (余额) | `/user/balance` | Account balance in CNY |
| Month Cost (本月消费) | Token * pricing | Monthly cost (2.5-zhe) |
| v4-pro Cache Hit | `PROMPT_CACHE_HIT_TOKEN` | ~0.025 CNY/M |
| v4-pro Cache Miss | `PROMPT_CACHE_MISS_TOKEN` | 3.00 CNY/M |
| v4-pro Output | `RESPONSE_TOKEN` | 6.00 CNY/M |
| v4-flash * | Same | 1.00/2.00 CNY/M |
| Today Total | Sum | With vs-yesterday comparison |
| Yesterday Total | Sum | Previous day total |

### Setup

1. Get API key: https://platform.deepseek.com → API Keys
2. Get platform token: Chrome → platform.deepseek.com → F12 → Network → Usage page → filter `amount` → copy `authorization: Bearer xxx`
3. Edit `scripts/config.ini`:
   ```ini
   [deepseek]
   api_key = sk-your-key
   platform_token = your-token
   ```
4. Double-click `scripts/run.bat`

### Token Expiry

When data shows zeros: login → F12 → Network → Usage → filter `amount` → copy new `authorization: Bearer xxx` → update `config.ini` → restart

### Install

```bash
npx skills add PK0071/deepseek-monitor-skill@deepseek-monitor -g
```

---

## 中文

Windows 桌面悬浮窗，实时监控 DeepSeek API 用量。数据与 platform.deepseek.com 后台完全一致，零依赖，双击 `run.bat` 即用。

### 更新日志

**V1.3 (2026-05-15)**
- 精简/详细模式切换：点击 ▲/▼ 在全视图和迷你视图（仅余额+今日合计）间切换
- 精简模式隐藏行零间距压缩
- CNY 数值左补空格，与 token 数字列对齐

**V1.2 (2026-05-14)**
- 昨日对比：自动对比今日 vs 昨日 token 用量，显示百分比 + 彩色箭头（绿↓/红↑）
- 双列网格布局：标签统一左对齐，数值列位置一致
- WidthAndHeight 自适应：零多余空白
- 今日合计行增加 "较昨天" 对比文字

**V1.1 (2026-05-14)**
- v4-pro / v4-flash 分开显示
- 大单位显示：1234.5万 / 1.2亿，固定宽度对齐
- 本月消费按官方 2.5 折定价计算
- SizeToContent 紧凑布局
- 日期、余额/消费移到模型上方

**V1.0 (2026-05-13)**
- 初始版本

### 核心功能

- **60 秒自动刷新**：从 DeepSeek 后台 API 实时拉取
- **鼠标拖拽**：按住任意位置拖动窗口
- **始终置顶**：默认悬浮在最前，右键可切换
- **右键菜单**：手动刷新 / 置顶开关 / 退出
- **模型分开显示**：v4-pro 和 v4-flash 各自展示
- **昨日对比**：今日 vs 昨日用量，彩色箭头（绿↓/红↑）
- **双单位显示**：每行同时显示万/亿 + 精确数字
- **本月消费**：按官方 2.5 折活动价实时计算
- **零依赖**：Windows 自带 PowerShell + WPF，无需安装

### 显示字段

| 字段 | 数据来源 | 说明 |
|------|---------|------|
| 日期 | 本地 | YYYY-MM-DD |
| 余额 | `/user/balance` | 账户 CNY 余额 |
| 本月消费 | Token * 定价 | 2.5折活动价 |
| v4-pro 输入(命中) | `PROMPT_CACHE_HIT_TOKEN` | ~0.025 元/百万 |
| v4-pro 输入(未命中) | `PROMPT_CACHE_MISS_TOKEN` | 3.00 元/百万 |
| v4-pro 输出 | `RESPONSE_TOKEN` | 6.00 元/百万 |
| v4-flash * | 同上 | 1.00/2.00 元/百万 |
| 今日合计 | 全部累计 | 含较昨天对比 |
| 昨日合计 | 昨日累计 | 前一日总量 |

### 配置步骤

1. 获取 API Key：platform.deepseek.com → API Keys
2. 获取 Platform Token：Chrome 登录 → F12 → Network → Usage → 过滤 `amount` → 复制 `authorization: Bearer xxx`
3. 编辑 `scripts/config.ini`
4. 双击 `scripts/run.bat`

### Token 过期

数据归零时：登录 → F12 → Network → Usage → `amount` → 复制新 token → 更新 `config.ini` → 重启

### 安装

```bash
npx skills add PK0071/deepseek-monitor-skill@deepseek-monitor -g
```
