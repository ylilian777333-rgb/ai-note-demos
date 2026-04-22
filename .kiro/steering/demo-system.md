---
inclusion: auto
---

# Demo 系统规范

## 项目概述
这是 AI Notes / MiClaw 产品的 Demo 管理系统。所有 demo 都是单文件 HTML，部署在 GitHub Pages：
- 管理后台：https://ylilian777333-rgb.github.io/ai-notes-demo-hub/
- 仓库：ylilian777333-rgb/ai-notes-demo-hub
- 本地部署缓存：/tmp/demo-hub

## Demo 技术栈规范
所有 demo 都是纯前端单 HTML 文件，特征如下：

### 通用工具函数
```js
function mk(tag, cls, html) // 创建 DOM 元素
function qs(sel, ctx)       // querySelector 简写
function delay(ms)          // Promise 延时
function clearTimers(arr)   // 清理定时器
```

### 设计系统 - CSS 变量
```css
:root {
  /* Light 模式 */
  --bg: #f6f8fb;  --card: #ffffff;  --card2: #f8f9fa;
  --bd: #e5e7eb;  --tx: #1d1d1f;
  --su: #6b7280;  --mu: #9ca3af;
  --bl: #007AFF;  --am: #FF9500;  --pu: #AF52DE;  --gn: #34C759;
  /* 对应浅色背景 */
  --bl-bg: #EBF5FF;  --am-bg: #FFF8EB;  --pu-bg: #F8EEFF;  --gn-bg: #EDFCF0;
}
```

### 核心 UI 组件
1. **手机模拟器** (.phone) - 296x618px 圆角容器，含 notch、状态栏、屏幕区
2. **Tab 切换** (.tab) - 顶部场景切换，带颜色标识 (on-bl/on-am/on-pu/on-gn)
3. **笔记卡片** (.nc) - 左侧彩色条标识分类，含标题、预览、标签
4. **左右面板** (.panel) - 192px 宽，展示产品定义/类型分析/差异对比
5. **三栏布局** (.stage) - 左面板 + 手机 + 右面板，max-width 1080px
6. **Trust 模式** - 方案A确认框 / 方案B直接应用 的切换器
7. **Claw 光线** - 底部光线条交互，三层架构（系统层/对话层/内容层）

### 页面交互模式
- Tab 切换触发不同场景（研究指令/会议纪要/灵感速记/语音编辑）
- 手机内页面切换动画 (show/off-r/off-l)
- 录音模拟：按住录音 → 波形动画 → AI处理 → 结果展示
- 语音编辑：对已有内容说话修改 → Before/After 对比

### 字体
- 标题/正文：'Noto Sans SC'
- 代码/标签/数据：'JetBrains Mono'

## Demo 分类体系
| 分类 | 颜色 | 说明 |
|------|------|------|
| 交互演示 | bl(蓝) | 手机端交互流程演示 |
| 产品定义 | am(橙) | 产品定义画布、架构设计、需求文档 |
| 严肃创作 | pu(紫) | 长文写作、分段讨论模式 |
| 完整版 | gn(绿) | 多模式合并的完整演示 |
| Claw光线 | cy(青) | 系统级语音光线交互 |
| 项目管理 | rd(红) | 排期、发布策略、进度汇报 |

## 新建 Demo 流程
1. 在 demos/ 目录创建 HTML 文件
2. 更新 index.html 的 DEMOS 数组
3. 复制到 /tmp/demo-hub/demos/ 和 index.html
4. git add + commit + push 到 GitHub
5. 等待 GitHub Actions 自动部署（约30秒）

## 部署命令
```bash
cp index.html /tmp/demo-hub/index.html
cp demos/NEW_FILE.html /tmp/demo-hub/demos/
git -C /tmp/demo-hub add -A
git -C /tmp/demo-hub commit -m "MESSAGE"
git -C /tmp/demo-hub push origin main
```
