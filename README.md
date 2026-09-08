# TaskMonitor - Slack @Mentions Daily Report Tool

Automatically collect your Slack @mentions and generate a daily task checklist.

## Features

- Daily auto-search for @mentions in specified channels
- Generate Slack Canvas task list (with checkboxes)
- Auto-compile unchecked backlog items from previous days
- Runs daily at 9 AM, with catch-up on login

## Sample
<img width="600" alt="image" src="https://github.com/user-attachments/assets/148d7b99-5231-4f71-b9c3-bf7a5fe2d11e" />



## Installation

### Prerequisites

1. [Claude Code CLI](https://claude.ai/code) installed
2. Slack MCP plugin configured
3. macOS

### Install Steps

```bash
# 1. Download the installer
curl -sL https://raw.githubusercontent.com/owen-stx/taskmonitor/main/install.sh -o install.sh

# 2. Run the installer
bash install.sh
```

The installer will prompt you for:
- **Language**: English or Chinese
- **Slack User ID**: Your Slack user ID (e.g., `U0A5D44PQJE`)
- **Channel ID**: Channel to receive reports (e.g., `C0BU1DF35SN`)
- **Channels to monitor**: Comma-separated channel names

### How to Find Slack IDs

1. **User ID**: Click your Slack avatar → Profile → Click `...` → Copy member ID
2. **Channel ID**: Right-click channel → View channel details → Scroll to bottom

## Usage

### Manual Report Generation

In Claude CLI, type:
```
/taskmonitor
```

### Automatic Runs

- Runs daily at 9:00 AM
- If computer was off at 9 AM, runs on login

### Management Commands

```bash
# View logs
cat ~/.claude/logs/taskmonitor.log

# Manual run
~/.claude/scripts/taskmonitor.sh

# Stop auto-run
launchctl unload ~/Library/LaunchAgents/com.taskmonitor.plist

# Restart auto-run
launchctl load ~/Library/LaunchAgents/com.taskmonitor.plist
```

## File Locations

| File | Path |
|------|------|
| Command definition | `~/.claude/commands/taskmonitor.md` |
| Automation script | `~/.claude/scripts/taskmonitor.sh` |
| LaunchAgent config | `~/Library/LaunchAgents/com.taskmonitor.plist` |
| Logs | `~/.claude/logs/taskmonitor.log` |

## Uninstall

```bash
# Stop auto-run
launchctl unload ~/Library/LaunchAgents/com.taskmonitor.plist

# Remove files
rm ~/Library/LaunchAgents/com.taskmonitor.plist
rm ~/.claude/commands/taskmonitor.md
rm ~/.claude/scripts/taskmonitor.sh
rm -rf ~/.claude/locks/taskmonitor-*
rm -rf ~/.claude/logs/taskmonitor*
```

## Customization

Edit `~/.claude/commands/taskmonitor.md` to modify:
- Channels to monitor
- Report format
- Categorization rules (customer vs internal)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v0.3 | 2026-09-08 | Fixed timezone issues; Added Monday special rule (includes Friday-Sunday mentions) |
| v0.2 | 2026-09-04 | Merged backlog into single report Canvas; Updated install.sh for new format |
| v0.1 | 2026-09-02 | Initial release: Daily @mentions collection, Canvas report generation, LaunchAgent automation |
