#!/usr/bin/env node
/**
 * Demo 自动同步服务
 * 监控常用目录，发现新 HTML demo 自动添加到管理后台并部署到 GitHub Pages
 * 启动: node scripts/demo-watcher.mjs
 * 后台启动: nohup node scripts/demo-watcher.mjs &
 */
import { watch, readFileSync, writeFileSync, copyFileSync, existsSync, statSync } from 'fs';
import { execSync } from 'child_process';
import { basename, join } from 'path';
import { homedir } from 'os';

const HOME = homedir();
const WORKSPACE = join(import.meta.dirname, '..');
const DEMOS_DIR = join(WORKSPACE, 'demos');
const INDEX_FILE = join(WORKSPACE, 'index.html');
const HUB_DIR = '/tmp/demo-hub';

const WATCH_DIRS = [
  join(HOME, 'Downloads'),
  join(HOME, 'Desktop/飞书文档助手/MiClaw产品'),
  join(HOME, '演示效果demo'),
  join(HOME, '项目时间'),
];

// 忽略的文件名
const IGNORE = new Set(['index.html', 'preview.html']);

// 分类关键词映射
const CAT_RULES = [
  { match: /claw|光线|beam/i, cat: 'claw', catName: 'Claw光线', catIcon: '✨', color: 'cy' },
  { match: /roadmap|排期|发布|灰度|release|进度|汇报/i, cat: 'pm', catName: '项目管理', catIcon: '📊', color: 'rd' },
  { match: /严肃|serious|创作/i, cat: 'serious', catName: '严肃创作', catIcon: '✍️', color: 'pu' },
  { match: /完整|combined|合并/i, cat: 'combined', catName: '完整版', catIcon: '📦', color: 'gn' },
  { match: /架构|agent|需求|定义|requirement/i, cat: 'product', catName: '产品定义', catIcon: '📐', color: 'am' },
  { match: /./, cat: 'interaction', catName: '交互演示', catIcon: '🎯', color: 'bl' }, // 默认
];

// 防抖：同一文件 5 秒内不重复处理
const recentlyProcessed = new Map();
const DEBOUNCE_MS = 5000;

// 部署锁
let deploying = false;
const deployQueue = [];

function log(msg) {
  const t = new Date().toLocaleTimeString('zh-CN', { hour12: false });
  console.log(`[${t}] ${msg}`);
}

function safeName(filename) {
  return filename.replace(/ \(/g, '-').replace(/\)/g, '').replace(/ /g, '-');
}

function extractTitle(filepath) {
  try {
    const html = readFileSync(filepath, 'utf-8');
    const m = html.match(/<title>([^<]+)<\/title>/i);
    return m ? m[1].trim() : basename(filepath);
  } catch { return basename(filepath); }
}

function classifyDemo(filename, title) {
  const text = filename + ' ' + title;
  for (const rule of CAT_RULES) {
    if (rule.match.test(text)) return rule;
  }
  return CAT_RULES[CAT_RULES.length - 1];
}

function getFileDate(filepath) {
  const s = statSync(filepath);
  const d = s.mtime;
  const date = d.toISOString().split('T')[0];
  const time = `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`;
  return { date, time };
}

function makeVer(title, filename) {
  // 尝试从文件名提取版本号
  const vm = filename.match(/v(\d+)/i);
  if (vm) return `v${vm[1]}`;
  // 从标题取前几个字
  const short = title.replace(/^(AI Notes|MiClaw|Claw|AI笔记)\s*[·:：]\s*/i, '').slice(0, 6);
  return short || basename(filename, '.html');
}

function addToIndex(safename, title, cat, dateInfo) {
  let html = readFileSync(INDEX_FILE, 'utf-8');
  
  // 检查是否已存在
  if (html.includes(`"demos/${safename}"`)) {
    log(`  ⏭️  已在 index.html 中: ${safename}`);
    return false;
  }

  const ver = makeVer(title, safename);
  const entry = `  {file:"demos/${safename}",title:"${title}",desc:"",cat:"${cat.cat}",catName:"${cat.catName}",catIcon:"${cat.catIcon}",color:"${cat.color}",date:"${dateInfo.date}",time:"${dateInfo.time}",ver:"${ver}"},`;
  
  // 在 ]; 之前插入
  html = html.replace(/\n\];/, `,\n${entry}\n];`);
  // 修复：如果最后一条没有逗号
  html = html.replace(/}\s*,\s*,\n/, '},\n');
  
  writeFileSync(INDEX_FILE, html);
  log(`  ✏️  已更新 index.html`);
  return true;
}

async function deploy(message) {
  if (deploying) {
    deployQueue.push(message);
    log(`  ⏳ 部署队列中...`);
    return;
  }
  deploying = true;
  try {
    // 同步文件到 hub
    execSync(`cp "${INDEX_FILE}" "${HUB_DIR}/index.html"`, { stdio: 'pipe' });
    execSync(`cp -r "${DEMOS_DIR}/"*.html "${HUB_DIR}/demos/" 2>/dev/null || true`, { stdio: 'pipe' });
    
    // git push
    execSync(`git -C "${HUB_DIR}" add -A`, { stdio: 'pipe' });
    try {
      execSync(`git -C "${HUB_DIR}" commit -m "${message}"`, { stdio: 'pipe' });
      execSync(`git -C "${HUB_DIR}" push origin main`, { stdio: 'pipe' });
      log(`  🚀 已部署到 GitHub Pages`);
    } catch (e) {
      if (e.message.includes('nothing to commit')) {
        log(`  ℹ️  无变更需要部署`);
      } else {
        log(`  ❌ 部署失败: ${e.message.slice(0, 100)}`);
      }
    }
  } finally {
    deploying = false;
    if (deployQueue.length > 0) {
      const next = deployQueue.shift();
      setTimeout(() => deploy(next), 1000);
    }
  }
}

function processNewFile(filepath) {
  const filename = basename(filepath);
  
  // 基本过滤
  if (!filename.endsWith('.html')) return;
  if (IGNORE.has(filename)) return;
  if (filename.startsWith('.')) return;
  
  // 防抖
  const now = Date.now();
  if (recentlyProcessed.has(filepath) && now - recentlyProcessed.get(filepath) < DEBOUNCE_MS) return;
  recentlyProcessed.set(filepath, now);
  
  // 检查文件是否存在且非空
  try {
    const s = statSync(filepath);
    if (s.size < 100) return; // 太小，可能是空文件
  } catch { return; }
  
  const safename = safeName(filename);
  
  // 检查是否已存在
  if (existsSync(join(DEMOS_DIR, safename)) || existsSync(join(DEMOS_DIR, filename))) {
    return;
  }
  
  log(`🆕 发现新 demo: ${filename}`);
  
  // 提取信息
  const title = extractTitle(filepath);
  const cat = classifyDemo(filename, title);
  const dateInfo = getFileDate(filepath);
  
  log(`  📄 标题: ${title}`);
  log(`  🏷️  分类: ${cat.catName}`);
  log(`  📅 日期: ${dateInfo.date} ${dateInfo.time}`);
  
  // 复制文件
  copyFileSync(filepath, join(DEMOS_DIR, safename));
  log(`  📁 已复制到 demos/${safename}`);
  
  // 更新 index.html
  const updated = addToIndex(safename, title, cat, dateInfo);
  
  // 部署
  if (updated) {
    deploy(`auto-sync: add ${safename}`);
  }
}

// 启动监听
log('🔄 Demo 自动同步服务启动');
log(`📂 监控目录:`);

let watchCount = 0;
for (const dir of WATCH_DIRS) {
  if (!existsSync(dir)) {
    log(`  ⚠️  目录不存在，跳过: ${dir}`);
    continue;
  }
  log(`  👁️  ${dir}`);
  
  watch(dir, (eventType, filename) => {
    if (eventType === 'rename' && filename && filename.endsWith('.html')) {
      const filepath = join(dir, filename);
      // 延迟处理，等文件写入完成
      setTimeout(() => {
        if (existsSync(filepath)) {
          processNewFile(filepath);
        }
      }, 2000);
    }
  });
  watchCount++;
}

if (watchCount === 0) {
  log('❌ 没有可监控的目录，退出');
  process.exit(1);
}

log(`\n✅ 正在监听 ${watchCount} 个目录，新 demo 将自动同步到管理后台`);
log(`   管理后台: https://ylilian777333-rgb.github.io/ai-notes-demo-hub/`);
log(`   按 Ctrl+C 停止\n`);

// 保持进程运行
process.on('SIGINT', () => {
  log('\n👋 同步服务已停止');
  process.exit(0);
});
