# TaskMonitor - Slack @Mentions 每日报告工具

自动收集你在 Slack 中被 @ 的消息，生成可勾选的任务清单。

## 功能

- 📬 每日自动搜索指定 channels 中 @你 的消息
- ✅ 生成 Slack Canvas 任务清单（支持勾选完成）
- 📋 自动汇总未完成的遗留任务
- ⏰ 每天 9 点自动运行，开机补跑

## 安装

### 前置要求

1. 已安装 [Claude Code CLI](https://claude.ai/code)
2. 已配置 Slack MCP 插件
3. macOS 系统

### 安装步骤

```bash
# 1. 下载安装脚本
curl -sL https://raw.githubusercontent.com/<your-repo>/taskmonitor/install.sh -o install.sh

# 2. 运行安装
bash install.sh
```

安装时会询问：
- **Slack User ID**: 你的 Slack 用户 ID（格式如 `U0A5D44PQJE`）
- **Channel ID**: 接收报告的 channel ID（格式如 `C0BU1DF35SN`）
- **监控 Channels**: 要监控的 channel 名称，逗号分隔

### 如何找到 Slack ID

1. **User ID**: 点击 Slack 头像 → Profile → 点击 `...` → Copy member ID
2. **Channel ID**: 右键点击 channel → View channel details → 滚动到底部

## 使用方法

### 手动生成报告

在 Claude CLI 中输入：
```
/taskmonitor
```

### 自动运行

- 每天 9:00 自动运行
- 如果 9 点电脑未开机，开机后会自动补跑

### 管理命令

```bash
# 查看日志
cat ~/.claude/logs/taskmonitor.log

# 手动运行脚本
~/.claude/scripts/taskmonitor.sh

# 停止定时任务
launchctl unload ~/Library/LaunchAgents/com.taskmonitor.plist

# 重启定时任务
launchctl load ~/Library/LaunchAgents/com.taskmonitor.plist
```

## 文件位置

| 文件 | 路径 |
|------|------|
| 命令定义 | `~/.claude/commands/taskmonitor.md` |
| 自动化脚本 | `~/.claude/scripts/taskmonitor.sh` |
| 定时任务配置 | `~/Library/LaunchAgents/com.taskmonitor.plist` |
| 日志 | `~/.claude/logs/taskmonitor.log` |

## 卸载

```bash
# 停止定时任务
launchctl unload ~/Library/LaunchAgents/com.taskmonitor.plist

# 删除文件
rm ~/Library/LaunchAgents/com.taskmonitor.plist
rm ~/.claude/commands/taskmonitor.md
rm ~/.claude/scripts/taskmonitor.sh
rm -rf ~/.claude/locks/taskmonitor-*
```

## 自定义

编辑 `~/.claude/commands/taskmonitor.md` 可以修改：
- 监控的 channels 列表
- 报告格式
- 分类规则
