#!/usr/bin/env node
/**
 * HowToCook Markdown 菜谱批量转换脚本
 * 输入:  HowToCook-1.6.0/dishes 下各分类目录中的 .md 菜谱文件
 * 输出:  entry/src/main/ets/data/recipes.json
 *        entry/src/main/resources/rawfile/ (菜谱封面图, 扁平化命名, '--' 连接)
 * 用法:  node scripts/md2json.mjs
 */
import fs from 'node:fs'
import path from 'node:path'

const ROOT = path.resolve(import.meta.dirname, '..')
const DISHES_DIR = path.join(ROOT, 'HowToCook-1.6.0', 'dishes')
const OUT_JSON = path.join(ROOT, 'entry', 'src', 'main', 'ets', 'data', 'recipes.json')
const RAWFILE_DIR = path.join(ROOT, 'entry', 'src', 'main', 'resources', 'rawfile')
const IMG_EXTS = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif'])

const CATEGORY_ORDER = [
  'breakfast', 'meat_dish', 'vegetable_dish', 'aquatic', 'soup',
  'staple', 'dessert', 'drink', 'condiment', 'semi-finished'
]
const CATEGORY_CN = {
  breakfast: '早餐',
  meat_dish: '荤菜',
  vegetable_dish: '素菜',
  aquatic: '水产',
  soup: '汤类',
  staple: '主食',
  dessert: '甜品',
  drink: '饮品',
  condiment: '调料',
  'semi-finished': '半成品'
}
// 难度星级 -> 预估时长 (依据 HowToCook 模板中的星级定义)
const TIME_BY_DIFFICULTY = {
  1: '约5分钟',
  2: '约10分钟',
  3: '约15分钟',
  4: '40分钟以内',
  5: '40分钟以上'
}

function walkMdFiles(dir) {
  const out = []
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      out.push(...walkMdFiles(full))
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      out.push(full)
    }
  }
  return out
}

function splitSections(text) {
  const map = new Map()
  const parts = text.split(/^##\s+/m)
  for (const part of parts.slice(1)) {
    const nl = part.indexOf('\n')
    if (nl === -1) {
      continue
    }
    map.set(part.slice(0, nl).trim(), part.slice(nl + 1))
  }
  return map
}

/**
 * 提取顶层列表项 (支持 -、*、+、1. 各种标记); 缩进的子列表项合并到上一项 (换行拼接)
 */
function parseBullets(body) {
  const out = []
  for (const line of body.split('\n')) {
    const top = line.match(/^(?:[-*+]|\d+[.])\s+(.*)$/)
    const sub = line.match(/^\s{2,}(?:[-*+]|\d+[.])\s+(.*)$/)
    if (top) {
      out.push(top[1].trim())
    } else if (sub && out.length > 0) {
      out[out.length - 1] += '\n' + sub[1].trim()
    }
  }
  return out.filter((t) => t.length > 0)
}

/**
 * 解析"操作"章节: ### 小节标题作为步骤前缀; 图片整行已被提前移除
 */
function parseSteps(body) {
  const steps = []
  let prefix = ''
  for (const line of body.split('\n')) {
    const h3 = line.match(/^###\s+(.*)$/)
    if (h3) {
      prefix = `【${h3[1].trim()}】`
      continue
    }
    const top = line.match(/^(?:[-*+]|\d+[.])\s+(.*)$/)
    if (top) {
      const t = top[1].trim()
      if (t.length > 0) {
        steps.push(prefix + t)
      }
      continue
    }
    const sub = line.match(/^\s{2,}(?:[-*+]|\d+[.])\s+(.*)$/)
    if (sub && steps.length > 0) {
      const t = sub[1].trim()
      if (t.length > 0) {
        steps[steps.length - 1] += '\n' + t
      }
    }
  }
  return steps
}

function resolveCoverImage(ref, mdDir, copied) {
  if (/^https?:\/\//i.test(ref)) {
    return ref
  }
  const imgAbs = path.resolve(mdDir, ref.trim())
  if (!fs.existsSync(imgAbs) || !IMG_EXTS.has(path.extname(imgAbs).toLowerCase())) {
    return ''
  }
  const flat = path.relative(DISHES_DIR, imgAbs).replace(/[\\/]+/g, '--')
  if (!copied.has(flat)) {
    fs.copyFileSync(imgAbs, path.join(RAWFILE_DIR, flat))
    copied.set(flat, true)
  }
  return flat
}

// ---------- main ----------
fs.mkdirSync(path.dirname(OUT_JSON), { recursive: true })
fs.mkdirSync(RAWFILE_DIR, { recursive: true })
// 清理上次生成的图片 (仅清理带 '--' 命名规则的图片, 不动其他 rawfile 资源)
if (fs.existsSync(RAWFILE_DIR)) {
  for (const f of fs.readdirSync(RAWFILE_DIR)) {
    if (IMG_EXTS.has(path.extname(f).toLowerCase()) && f.includes('--')) {
      fs.rmSync(path.join(RAWFILE_DIR, f))
    }
  }
}

const recipes = []
const copied = new Map()
let noImageCount = 0

for (const cat of CATEGORY_ORDER) {
  const catDir = path.join(DISHES_DIR, cat)
  if (!fs.existsSync(catDir)) {
    continue
  }
  for (const md of walkMdFiles(catDir)) {
    const raw = fs.readFileSync(md, 'utf8').replace(/\r\n?/g, '\n')
    const noComments = raw.replace(/<!--[\s\S]*?-->/g, '')
    const name = path.basename(md, '.md')
    if (name === '示例菜') {
      continue
    }

    const starMatch = noComments.match(/预估烹饪难度[：:]\s*(★+)/)
    const difficulty = starMatch ? starMatch[1].length : 2

    // 封面图 = 文中第一张图; 同时从正文中整体移除图片语法
    let imageUrl = ''
    const imgMatch = noComments.match(/!\[[^\]]*\]\(([^)]+)\)/)
    const noImages = noComments.replace(/!\[[^\]]*\]\([^)]*\)/g, '')
    if (imgMatch) {
      imageUrl = resolveCoverImage(imgMatch[1], path.dirname(md), copied)
    }
    if (imageUrl === '') {
      noImageCount++
    }

    // 清理 markdown 行内标记: 粗体/斜体/行内代码/链接 (均不跨行, 斜体要求紧贴非空白文本)
    const content = noImages
      .replace(/\*\*([^*]+)\*\*/g, '$1')
      .replace(/\*(\S(?:[^*\n]*\S)?)\*/g, '$1')
      .replace(/`([^`\n]+)`/g, '$1')
      .replace(/\[([^\]]*)\]\(([^)]+)\)/g, '$1')

    const sections = splitSections(content)
    // 用料: 优先"计算"章节(带用量), 回退"必备原料和工具"
    let ingredients = parseBullets(sections.get('计算') ?? '')
    if (ingredients.length === 0) {
      ingredients = parseBullets(sections.get('必备原料和工具') ?? '')
    }
    const steps = parseSteps(sections.get('操作') ?? '')

    recipes.push({
      id: path.relative(DISHES_DIR, md).replace(/\\/g, '/').replace(/\.md$/, ''),
      name,
      category: CATEGORY_CN[cat],
      ingredients,
      steps,
      imageUrl,
      difficulty,
      cookingTime: TIME_BY_DIFFICULTY[difficulty] ?? '约15分钟'
    })
  }
}

fs.writeFileSync(OUT_JSON, JSON.stringify(recipes, null, 1), 'utf8')

const byCat = {}
for (const r of recipes) {
  byCat[r.category] = (byCat[r.category] ?? 0) + 1
}
console.log(`共转换 ${recipes.length} 篇菜谱 (无封面图 ${noImageCount} 篇)`)
console.log(`封面图复制 ${copied.size} 张 -> entry/src/main/resources/rawfile/`)
console.log('分类统计:', JSON.stringify(byCat))
console.log(`recipes.json 大小: ${(fs.statSync(OUT_JSON).size / 1024).toFixed(1)} KB`)
