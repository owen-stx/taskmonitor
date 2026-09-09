#!/bin/bash
# TaskMonitor 安装脚本
# 用法: curl -sL <url> | bash
# 或者: bash install.sh

set -e

echo "🔧 TaskMonitor 安装向导"
echo "========================"
echo ""

# 选择语言
echo "Select language / 选择语言:"
echo "  1) English"
echo "  2) 中文"
read -p "Enter choice (1 or 2): " LANG_CHOICE

if [[ "$LANG_CHOICE" == "2" ]]; then
    LANG="zh"
    echo ""
    read -p "请输入你的 Slack User ID (例如 U0A5D44PQJE): " USER_ID
    read -p "请输入接收报告的 Channel ID (例如 C0BU1DF35SN): " CHANNEL_ID
    read -p "请输入你要监控的 channels，用逗号分隔 (例如 cop-engineers,cop-eng-adhoc-request): " MONITOR_CHANNELS
else
    LANG="en"
    echo ""
    read -p "Enter your Slack User ID (e.g. U0A5D44PQJE): " USER_ID
    read -p "Enter the Channel ID to receive reports (e.g. C0BU1DF35SN): " CHANNEL_ID
    read -p "Enter channels to monitor, comma-separated (e.g. cop-engineers,cop-eng-adhoc-request): " MONITOR_CHANNELS
fi

# 验证输入
if [[ -z "$USER_ID" || -z "$CHANNEL_ID" ]]; then
    if [[ "$LANG" == "zh" ]]; then
        echo "❌ User ID 和 Channel ID 是必填项"
    else
        echo "❌ User ID and Channel ID are required"
    fi
    exit 1
fi

echo ""
echo "📁 创建目录结构..."
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/scripts
mkdir -p ~/.claude/logs
mkdir -p ~/.claude/locks

# 生成 command 文件
if [[ "$LANG" == "zh" ]]; then
    echo "📝 生成 /taskmonitor 命令..."
    cat > ~/.claude/commands/taskmonitor.md << EOF
# @Mentions 每日报告 v0.2

执行以下任务生成今日报告：

## 任务 1: 收集昨日 @mentions

1. 搜索**昨天**在以下 channels 中直接 @${USER_ID} 的消息：
   - 监控的 channels: ${MONITOR_CHANNELS}

2. 过滤条件：
   - 排除 bot 消息
   - 只包含直接 @ 的消息（搜索 \`<@${USER_ID}>\`）

## 任务 2: 收集遗留任务 (Backlog)

1. 在 Slack 中搜索之前的 Canvas 文件（标题包含 "@Mentions Report"）
2. 读取这些 Canvas，提取所有未勾选的 checklist 项（\`- [ ]\` 开头的行）
3. 按原始报告日期分组整理遗留任务

## 任务 3: 创建合并报告

创建**单个** Slack Canvas，标题格式："@Mentions Report (YYYY-MM-DD)"

Canvas 内容结构：
\`\`\`
# 📬 @Mentions Report
**Date:** YYYY-MM-DD | **New:** X items | **Backlog:** Y items

---

## 🔵 Customer Channels (ext-*) — Yesterday
- [ ] **HH:MM** | #channel | From | 内容概要 | [→ thread](URL)
...

---

## 🟢 Internal Channels — Yesterday
- [ ] **HH:MM** | #channel | From | 内容概要 | [→ thread](URL)
...

---

# 📋 Backlog

## From YYYY-MM-DD
- [ ] ...
\`\`\`

格式要求：
- 使用 checklist 格式（\`- [ ]\`）
- 客户 channels (\`ext-*\`) 放最上面
- 内部 channels 放下面
- 每个分组内按时间排序，最老的在最上面
- 每行格式：\`- [ ] **HH:MM** | #channel | From | 内容概要 | [→ thread](URL)\`
- Backlog 部分按原始报告日期分组

## 任务 4: 发送通知

发送消息到 Channel ID: ${CHANNEL_ID}
- 包含 Canvas 的链接
- 简要统计：昨日新增 X 条，遗留 Y 条
EOF
else
    echo "📝 Generating /taskmonitor command..."
    cat > ~/.claude/commands/taskmonitor.md << EOF
# @Mentions Daily Report v0.2

Execute the following tasks to generate today's report:

## Task 1: Collect Yesterday's @mentions

1. Search for messages that directly @${USER_ID} in the following channels from **yesterday**:
   - Monitored channels: ${MONITOR_CHANNELS}

2. Filter conditions:
   - Exclude bot messages
   - Only include direct @ mentions (search \`<@${USER_ID}>\`)

## Task 2: Collect Backlog Items

1. Search Slack for previous Canvas files (title contains "@Mentions Report")
2. Read these Canvas files, extract all unchecked checklist items (\`- [ ]\` lines)
3. Group backlog items by original report date

## Task 3: Create Combined Report

Create a **single** Slack Canvas with title format: "@Mentions Report (YYYY-MM-DD)"

Canvas structure:
\`\`\`
# 📬 @Mentions Report
**Date:** YYYY-MM-DD | **New:** X items | **Backlog:** Y items

---

## 🔵 Customer Channels (ext-*) — Yesterday
- [ ] **HH:MM** | #channel | From | Summary | [→ thread](URL)
...

---

## 🟢 Internal Channels — Yesterday
- [ ] **HH:MM** | #channel | From | Summary | [→ thread](URL)
...

---

# 📋 Backlog

## From YYYY-MM-DD
- [ ] ...
\`\`\`

Format requirements:
- Use checklist format (\`- [ ]\`)
- Customer channels (\`ext-*\`) at the top
- Internal channels below
- Sort by time within each section, oldest first
- Each line format: \`- [ ] **HH:MM** | #channel | From | Summary | [→ thread](URL)\`
- Backlog section grouped by original report date

## Task 4: Send Notification

Send message to Channel ID: ${CHANNEL_ID}
- Include the Canvas link
- Brief summary: X new items yesterday, Y backlog items
EOF
fi

# 生成自动化脚本
echo "📝 生成自动化脚本..."
CLAUDE_PATH=$(which claude 2>/dev/null || echo "/usr/local/bin/claude")

cat > ~/.claude/scripts/taskmonitor.sh << EOF
#!/bin/bash
# TaskMonitor Daily Report - runs at 10am SGT Mon-Fri or on login if missed

LOG_FILE="\$HOME/.claude/logs/taskmonitor.log"
PROMPT_FILE="\$HOME/.claude/commands/taskmonitor.md"
LOCK_DIR="\$HOME/.claude/locks"
TODAY=\$(date +%Y-%m-%d)
LOCK_FILE="\$LOCK_DIR/taskmonitor-\$TODAY.lock"

mkdir -p "\$LOCK_DIR"

# Check if already ran today
if [ -f "\$LOCK_FILE" ]; then
    echo "\$(date): Report already generated today, skipping" >> "\$LOG_FILE"
    exit 0
fi

# Create lock file
touch "\$LOCK_FILE"

# Clean up old lock files (keep last 7 days)
find "\$LOCK_DIR" -name "taskmonitor-*.lock" -mtime +7 -delete 2>/dev/null

echo "\$(date): Starting TaskMonitor Report" >> "\$LOG_FILE"

# Run claude with the prompt file
${CLAUDE_PATH} -p "\$(cat "\$PROMPT_FILE")" --allowedTools "mcp__plugin_slack_slack__*" >> "\$LOG_FILE" 2>&1

echo "\$(date): Finished TaskMonitor Report" >> "\$LOG_FILE"
echo "---" >> "\$LOG_FILE"
EOF

chmod +x ~/.claude/scripts/taskmonitor.sh

# 生成 LaunchAgent
echo "📝 生成 macOS 定时任务..."
cat > ~/Library/LaunchAgents/com.taskmonitor.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.taskmonitor</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>\${HOME}/.claude/scripts/taskmonitor.sh</string>
    </array>

    <key>StartCalendarInterval</key>
    <array>
        <dict>
            <key>Weekday</key>
            <integer>1</integer>
            <key>Hour</key>
            <integer>10</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
        <dict>
            <key>Weekday</key>
            <integer>2</integer>
            <key>Hour</key>
            <integer>10</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
        <dict>
            <key>Weekday</key>
            <integer>3</integer>
            <key>Hour</key>
            <integer>10</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
        <dict>
            <key>Weekday</key>
            <integer>4</integer>
            <key>Hour</key>
            <integer>10</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
        <dict>
            <key>Weekday</key>
            <integer>5</integer>
            <key>Hour</key>
            <integer>10</integer>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>\${HOME}/.claude/logs/taskmonitor-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>\${HOME}/.claude/logs/taskmonitor-stderr.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:\${HOME}/.local/bin</string>
    </dict>
</dict>
</plist>
EOF

# 修复 plist 中的 HOME 变量
sed -i '' "s|\${HOME}|$HOME|g" ~/Library/LaunchAgents/com.taskmonitor.plist

# 加载定时任务
echo "🚀 启动定时任务..."
launchctl unload ~/Library/LaunchAgents/com.taskmonitor.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.taskmonitor.plist

echo ""
if [[ "$LANG" == "zh" ]]; then
    echo "✅ 安装完成！"
    echo ""
    echo "使用方法:"
    echo "  - 在 Claude CLI 中输入 /taskmonitor 手动生成报告"
    echo "  - 周一至周五新加坡时间 10:00 自动生成报告 (如果电脑开机)"
    echo "  - 开机时会自动补跑当天未生成的报告"
    echo ""
    echo "管理命令:"
    echo "  - 查看日志: cat ~/.claude/logs/taskmonitor.log"
    echo "  - 手动运行: ~/.claude/scripts/taskmonitor.sh"
    echo "  - 停止定时: launchctl unload ~/Library/LaunchAgents/com.taskmonitor.plist"
else
    echo "✅ Installation complete!"
    echo ""
    echo "Usage:"
    echo "  - Type /taskmonitor in Claude CLI to manually generate a report"
    echo "  - Reports auto-generate Mon-Fri at 10:00 AM SGT (if computer is on)"
    echo "  - Missed reports run automatically on login"
    echo ""
    echo "Management commands:"
    echo "  - View logs: cat ~/.claude/logs/taskmonitor.log"
    echo "  - Manual run: ~/.claude/scripts/taskmonitor.sh"
    echo "  - Stop auto-run: launchctl unload ~/Library/LaunchAgents/com.taskmonitor.plist"
fi
echo ""
