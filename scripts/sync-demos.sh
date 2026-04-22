#!/bin/bash
# 一键同步：扫描所有常用目录，找到新 HTML demo，自动添加到管理后台并部署
set -e

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCAN_DIRS=(
  "$HOME/Downloads"
  "$HOME/Desktop/飞书文档助手/MiClaw产品"
  "$HOME/演示效果demo"
  "$HOME/项目时间"
)

NEW_FILES=()
echo "🔍 扫描新 demo 文件..."

for DIR in "${SCAN_DIRS[@]}"; do
  [ -d "$DIR" ] || continue
  for f in "$DIR"/*.html; do
    [ -f "$f" ] || continue
    [ -s "$f" ] || continue
    FNAME=$(basename "$f")
    # 跳过非 demo 文件（index.html、preview 等）
    case "$FNAME" in
      index.html|preview.html) continue ;;
    esac
    # 规范化文件名：空格和括号替换
    SAFE_NAME=$(echo "$FNAME" | sed 's/ (/-/g; s/)//g; s/ /-/g')
    # 检查是否已存在（原名或规范名）
    if [ -f "$WORKSPACE_ROOT/demos/$FNAME" ] || [ -f "$WORKSPACE_ROOT/demos/$SAFE_NAME" ]; then
      continue
    fi
    # 提取标题
    TITLE=$(grep -oP '(?<=<title>).*?(?=</title>)' "$f" 2>/dev/null | head -1)
    [ -z "$TITLE" ] && TITLE="$FNAME"
    MOD_DATE=$(stat -f '%Sm' -t '%Y-%m-%d' "$f" 2>/dev/null || date +%Y-%m-%d)
    MOD_TIME=$(stat -f '%Sm' -t '%H:%M' "$f" 2>/dev/null || date +%H:%M)
    SIZE=$(wc -c < "$f" | tr -d ' ')

    echo "🆕 $FNAME → $SAFE_NAME"
    echo "   标题: $TITLE"
    echo "   来源: $DIR"
    echo "   日期: $MOD_DATE $MOD_TIME"
    echo "   大小: ${SIZE}B"
    
    # 复制到 demos 目录
    cp "$f" "$WORKSPACE_ROOT/demos/$SAFE_NAME"
    NEW_FILES+=("$SAFE_NAME|$TITLE|$MOD_DATE|$MOD_TIME")
    echo ""
  done
done

if [ ${#NEW_FILES[@]} -eq 0 ]; then
  echo "✅ 没有发现新的 demo 文件，已是最新状态"
  exit 0
fi

echo "📊 共发现 ${#NEW_FILES[@]} 个新文件，已复制到 demos/"
echo ""
echo "=== 新文件清单 ==="
for item in "${NEW_FILES[@]}"; do
  IFS='|' read -r name title date time <<< "$item"
  echo "  📄 $name | $title | $date $time"
done
echo ""
echo "💡 请让 Kiro agent 更新 index.html 并部署"
