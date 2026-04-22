#!/bin/bash
# 自动将新 HTML demo 添加到管理后台
# 用法: ./scripts/add-demo.sh <html文件路径>

set -e

FILE_PATH="$1"
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  echo "❌ 文件不存在: $FILE_PATH"
  exit 1
fi

FILENAME=$(basename "$FILE_PATH")
EXT="${FILENAME##*.}"
if [ "$EXT" != "html" ]; then
  echo "⏭️ 跳过非HTML文件: $FILENAME"
  exit 0
fi

# 检查是否已存在
if grep -q "\"demos/$FILENAME\"" index.html 2>/dev/null; then
  echo "⏭️ 已存在: $FILENAME"
  exit 0
fi

# 提取标题
TITLE=$(grep -oP '(?<=<title>).*?(?=</title>)' "$FILE_PATH" 2>/dev/null | head -1)
if [ -z "$TITLE" ]; then
  TITLE="$FILENAME"
fi

# 提取日期
MOD_DATE=$(stat -f '%Sm' -t '%Y-%m-%d' "$FILE_PATH" 2>/dev/null || date +%Y-%m-%d)
MOD_TIME=$(stat -f '%Sm' -t '%H:%M' "$FILE_PATH" 2>/dev/null || date +%H:%M)

# 复制到 demos 目录
cp "$FILE_PATH" "demos/$FILENAME"

echo "✅ 已添加: $FILENAME"
echo "   标题: $TITLE"
echo "   日期: $MOD_DATE $MOD_TIME"
echo "   📌 请在 Kiro 中确认分类并更新 index.html"
echo "DEMO_FILE=demos/$FILENAME"
echo "DEMO_TITLE=$TITLE"
echo "DEMO_DATE=$MOD_DATE"
echo "DEMO_TIME=$MOD_TIME"
