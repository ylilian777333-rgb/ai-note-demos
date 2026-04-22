#!/bin/bash
# 安装 demo-watcher 为 macOS 后台服务（launchd）
# 开机自启动，完全无感

set -e

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_NAME="com.ainotes.demo-watcher"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
NODE_PATH=$(which node)
LOG_DIR="$HOME/Library/Logs/demo-watcher"

mkdir -p "$LOG_DIR"

cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${NODE_PATH}</string>
        <string>${WORKSPACE}/scripts/demo-watcher.mjs</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${WORKSPACE}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF

# 如果已在运行，先停掉
launchctl unload "$PLIST_PATH" 2>/dev/null || true

# 启动服务
launchctl load "$PLIST_PATH"

echo "✅ Demo 自动同步服务已安装并启动"
echo ""
echo "   服务名: ${PLIST_NAME}"
echo "   日志: ${LOG_DIR}/stdout.log"
echo "   状态: launchctl list | grep demo-watcher"
echo "   停止: launchctl unload ${PLIST_PATH}"
echo "   卸载: rm ${PLIST_PATH}"
echo ""
echo "🔄 现在起，你在以下目录新建 HTML demo 会自动同步到管理后台："
echo "   ~/Downloads"
echo "   ~/Desktop/飞书文档助手/MiClaw产品"
echo "   ~/演示效果demo"
echo "   ~/项目时间"
