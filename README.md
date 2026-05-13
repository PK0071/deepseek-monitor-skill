# DeepSeek Monitor Skill

[English](#english) | [中文](#中文)

---

## English

### What is this?

A Windows desktop floating window that monitors your DeepSeek API usage in real-time. It pulls data directly from DeepSeek's official dashboard API — the same numbers you see when you log into platform.deepseek.com.

No installation required. Just double-click `run.bat`.

### Features

| Feature | Detail |
|---------|--------|
| Always on top | Floating window stays visible above other apps |
| Drag to move | Click anywhere on the window and drag |
| Right-click menu | Refresh now / Toggle always-on-top / Exit |
| Auto-refresh | Updates every 60 seconds from DeepSeek dashboard |
| Chinese UI | All labels in Chinese, matches dashboard terminology |
| Zero dependencies | Uses Windows built-in PowerShell + WPF |

### Display Fields

| Row | Source | Description |
|-----|--------|-------------|
| 余额 | `/user/balance` API | Account balance in CNY |
| 输入(命中) | `PROMPT_CACHE_HIT_TOKEN` | Cached input tokens — billed at ~10% of full price |
| 输入(未命中) | `PROMPT_CACHE_MISS_TOKEN` | New input tokens — billed at full input price |
| 输出 | `RESPONSE_TOKEN` | Output/generated tokens |
| 今日合计 | Sum of all above | Total tokens consumed today |

### Setup

1. Get your API key from https://platform.deepseek.com → API Keys
2. Get your platform token:
   - Login to platform.deepseek.com in Chrome
   - Press `F12` → **Network** tab
   - Click **Usage** in the sidebar
   - Filter requests: `amount`
   - Click the request, copy `authorization: Bearer xxx` header value
3. Edit `scripts/config.ini`:
   ```ini
   [deepseek]
   api_key = sk-your-key-here
   platform_token = your-platform-token-here
   ```
4. Double-click `scripts/run.bat`

### Token Expiry

The `platform_token` expires after a few days. When the window shows zeros:
1. Login to platform.deepseek.com
2. `F12` → Network → click Usage page
3. Copy new `authorization: Bearer xxx` header
4. Update `config.ini` → restart `run.bat`

### Install via Skills CLI

```bash
npx skills add PK0071/deepseek-monitor-skill@deepseek-monitor -g
```

### Requirements

- Windows 10 or 11
- DeepSeek API account

---

## 中文

### 这是什么？

一个 Windows 桌面悬浮窗，实时监控你的 DeepSeek API 用量。数据直接从 DeepSeek 官方后台 API 拉取，和你在 platform.deepseek.com 后台看到的数据完全一致。

无需安装任何东西，双击 `run.bat` 即可运行。

### 功能特性

| 功能 | 说明 |
|------|------|
| 始终置顶 | 浮窗始终悬浮在其他窗口之上 |
| 拖拽移动 | 鼠标按住浮窗任意位置拖动 |
| 右键菜单 | 手动刷新 / 取消/恢复置顶 / 退出 |
| 自动刷新 | 每 60 秒从 DeepSeek 后台拉取最新数据 |
| 中文界面 | 大字体中文标签，与后台术语一致 |
| 零依赖 | 纯 PowerShell + WPF，Windows 自带 |

### 显示字段

| 字段 | 数据来源 | 说明 |
|------|---------|------|
| 余额 | `/user/balance` 接口 | DeepSeek 账户实时余额（人民币） |
| 输入(命中) | `PROMPT_CACHE_HIT_TOKEN` | 缓存命中的输入 token，约 1 折计费 |
| 输入(未命中) | `PROMPT_CACHE_MISS_TOKEN` | 未命中缓存的输入 token，按全价计费 |
| 输出 | `RESPONSE_TOKEN` | 模型生成的输出 token |
| 今日合计 | 以上三项之和 | 今日消耗的全部 token |

### 配置步骤

1. 获取 API Key：打开 https://platform.deepseek.com → API Keys
2. 获取 Platform Token（Dashboard 鉴权令牌）：
   - Chrome 打开 https://platform.deepseek.com 并登录
   - 按 `F12` → **Network（网络）** 标签
   - 点击左侧菜单 **Usage（用量管理）**
   - Network 过滤栏搜索：`amount`
   - 点击请求 → **Headers** → 找到 `authorization: Bearer xxx`
   - 复制 `Bearer` 后面那串 token
3. 编辑 `scripts/config.ini`：
   ```ini
   [deepseek]
   api_key = sk-你的api-key
   platform_token = 你的platform-token
   ```
4. 双击 `scripts/run.bat` 启动浮窗

### Token 过期处理

`platform_token` 约几天后过期，浮窗数据会显示 0。刷新步骤：

1. Chrome 登录 platform.deepseek.com
2. `F12` → Network → 点击 Usage 页面
3. 搜索 `amount`，复制新的 `authorization: Bearer xxx`
4. 更新 `config.ini` 中的 `platform_token`
5. 重启 `run.bat`

### 通过 Skills CLI 安装

```bash
npx skills add PK0071/deepseek-monitor-skill@deepseek-monitor -g
```

### 环境要求

- Windows 10 或 11
- DeepSeek API 账户
