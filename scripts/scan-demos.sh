#!/bin/bash
# 扫描常用目录，找出尚未添加到管理后台的 HTML demo
set -e

SCAN_DIRS=(
  "$HOME/Downloads"
  "$HOME/Desktop/飞书文档助手/MiClaw产品"
  "$HOME/演示效果demo"
  "$HOME/项目时间"
)

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NEW_COUNT=0

echo "🔍 扫描 demo 文件..."
echo ""

for DIR in "${SCAN_DIRS[@]}"; do
  if [ ! -d "$DIR" ]; then
    continue
  fi
  for f in "$DIR"/*.html; do
    [ -f "$f" ] || continue
    FNAME=$(basename "$f")
    # 跳过已存在的
    if [ -f "$WORKSPACE_ROOT/demos/$FNAME" ]; then
      continue
    fi
    # 跳过空文件
    if [ ! -s "$f" ]; then
      continue
    fi
    TITLE=$(grep -oP '(?<=<title>).*?(?=</title>)' "$f" 2>/dev/null | head -1)
    [ -z "$TITLE" ] && TITLE="$FNAME"
    MOD_DATE=$(stat -f '%Sm' -t '%Y-%m-%d' "$f" 2>/dev/null || date +%Y-%m-%d)
    MOD_TIME=$(stat -f '%Sm' -t '%H:%M' "$f" 2>/dev/null || date +%H:%M)
    echo "🆕 $FNAME"
    echo "   标题: $TITLE"
    echo "   路径: $f"
    echo "   日期: $MOD_DATE $MOD_TIME"
    echo ""
    NEW_COUNT=$((NEW_COUNT + 1))
  done
done

if [ "$NEW_COUNT" -eq 0 ]; then
  echo "✅ 没有发现新的 demo 文件"
else
  echo "📊 发现 $NEW_COUNT 个新 demo 文件"
  echo "💡 请告诉我要添加哪些，以及它们的分类"
fi
