#!/bin/bash
# TaskMonitor 安装脚本
# 用法: bash install.sh <template-name>
# 例如: bash install.sh owen

set -e

echo "🔧 TaskMonitor 安装向导"
echo "========================"
echo ""

# 检查参数
if [[ -z "$1" ]]; then
    echo "用法: bash install.sh <template-name>"
    echo ""
    echo "示例:"
    echo "  bash install.sh owen     # 使用 templates/owen.md"
    echo ""
    echo "请先在 templates/ 目录下创建你的配置文件"
    exit 1
fi

TEMPLATE_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/templates/${TEMPLATE_NAME}.md"

# 检查模板文件是否存在
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "❌ 模板文件不存在: $TEMPLATE_FILE"
    echo ""
    echo "请先创建模板文件，可以参考 monitor-template.md 模板"
    echo "将占位符替换为你的实际值："
    echo "  {{USER_ID}}            - 你的 Slack User ID"
    echo "  {{USER_NAME}}          - 你的名字"
    echo "  {{REPORT_CHANNEL_ID}}  - 接收报告的 Channel ID"
    echo "  {{REPORT_CHANNEL_NAME}} - 接收报告的 Channel 名称"
    exit 1
fi

echo "📄 使用模板: $TEMPLATE_FILE"
echo ""

# 创建目录结构
echo "📁 创建目录结构..."
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/scripts
mkdir -p ~/.claude/logs
mkdir -p ~/.claude/locks

# 复制模板到 commands 目录
echo "📝 安装 /taskmonitor 命令..."
cp "$TEMPLATE_FILE" ~/.claude/commands/taskmonitor.md

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

# 生成 LaunchAgent (周一至周五 10:00 SGT)
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
echo ""
