/**
 * 修复 Git LFS 指针文件: HowToCook 压缩包里的图片大多是 130 字节的 LFS 指针文本,
 * 本脚本通过 GitHub LFS batch API 按_oid 批量换取下载链接, 用真实图片覆盖指针文件。
 *
 * 用法: node scripts/fix-lfs.mjs
 */
import fs from 'node:fs'
import path from 'node:path'

const ROOT = path.resolve(import.meta.dirname, '..')
const DISHES_DIR = path.join(ROOT, 'HowToCook-1.6.0', 'dishes')
const LFS_API = 'https://github.com/Anduin1997/HowToCook.git/info/lfs/objects/batch'
const CONCURRENCY = 6
const IMG_EXTS = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif'])

function walk(dir) {
  const out = []
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f)
    if (fs.statSync(p).isDirectory()) {
      out.push(...walk(p))
    } else {
      out.push(p)
    }
  }
  return out
}

function parsePointer(file) {
  const raw = fs.readFileSync(file, 'utf8')
  if (!raw.startsWith('version https://git-lfs.github.com/spec/v1')) {
    return null
  }
  const oid = raw.match(/oid sha256:([0-9a-f]{64})/)
  const size = raw.match(/size (\d+)/)
  if (!oid || !size) {
    return null
  }
  return { oid: oid[1], size: Number(size[1]) }
}

async function batchDownload(objects) {
  const res = await fetch(LFS_API, {
    method: 'POST',
    headers: {
      'Accept': 'application/vnd.git-lfs+json',
      'Content-Type': 'application/vnd.git-lfs+json'
    },
    body: JSON.stringify({ operation: 'download', transfers: ['basic'], objects })
  })
  if (!res.ok) {
    throw new Error(`batch API HTTP ${res.status}`)
  }
  const data = await res.json()
  return data.objects
}

async function downloadFile(url, dest, expectedSize) {
  const res = await fetch(url)
  if (!res.ok) {
    throw new Error(`download HTTP ${res.status}`)
  }
  const buf = Buffer.from(await res.arrayBuffer())
  if (buf.length !== expectedSize) {
    throw new Error(`size mismatch: got ${buf.length}, expect ${expectedSize}`)
  }
  fs.writeFileSync(dest, buf)
}

// ---------- main ----------
const files = walk(DISHES_DIR).filter((p) => IMG_EXTS.has(path.extname(p).toLowerCase()))
const pointers = []
for (const p of files) {
  if (fs.statSync(p).size < 200) {
    const info = parsePointer(p)
    if (info) {
      pointers.push({ file: p, ...info })
    }
  }
}
console.log(`扫描到 ${files.length} 个图片文件, 其中 ${pointers.length} 个是 LFS 指针`)
if (pointers.length === 0) {
  console.log('无需修复')
  process.exit(0)
}

// 分批换链接 (batch API 每次最多 100 个对象)
const hrefs = new Map()
for (let i = 0; i < pointers.length; i += 100) {
  const chunk = pointers.slice(i, i + 100).map((p) => ({ oid: p.oid, size: p.size }))
  const objs = await batchDownload(chunk)
  for (const obj of objs) {
    const href = obj.actions?.download?.href
    if (href) {
      hrefs.set(obj.oid, href)
    } else {
      console.warn(`无下载链接: ${obj.oid.slice(0, 12)} (${obj.error?.message ?? 'unknown'})`)
    }
  }
  console.log(`换链接进度: ${Math.min(i + 100, pointers.length)}/${pointers.length}`)
}
console.log(`取得 ${hrefs.size} 个下载链接`)

// 并发下载覆盖
let ok = 0
let fail = 0
const queue = pointers.filter((p) => hrefs.has(p.oid))
async function worker() {
  while (queue.length > 0) {
    const p = queue.shift()
    try {
      await downloadFile(hrefs.get(p.oid), p.file, p.size)
      ok++
    } catch (e) {
      fail++
      console.warn(`下载失败 ${path.relative(DISHES_DIR, p.file)}: ${e.message}`)
    }
    if ((ok + fail) % 25 === 0) {
      console.log(`下载进度: ${ok + fail}/${pointers.length} (成功 ${ok})`)
    }
  }
}
await Promise.all(Array.from({ length: CONCURRENCY }, worker))
console.log(`完成: 成功 ${ok}, 失败 ${fail}`)
console.log('下一步: 重新执行 node scripts/md2json.mjs 生成真实封面图')
