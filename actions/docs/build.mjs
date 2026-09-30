#!/usr/bin/env node
// Markdown docs → static pages in the docs.melchard.org shell (tokens.css + style.css from the
// docs root, one centred column, mono). SUMMARY.md is the nav: nested list items, links to .md
// files become nav entries, external links stay links, plain items are section labels. Every
// .md under src is rendered, listed or not; everything else (images, css) is copied as is.
//
//   node build.mjs --src docs --out site/docs --title flatplan \
//     --assets https://docs.melchard.org/assets --repo https://github.com/owner/name
import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { dirname, join, relative, resolve, sep } from 'node:path'
import { marked } from 'marked'

const args = Object.fromEntries(
  process.argv.slice(2).map((a, i, all) => (a.startsWith('--') ? [a.slice(2), all[i + 1]] : [])).filter((p) => p.length),
)
const SRC = resolve(args.src ?? 'docs')
const OUT = resolve(args.out ?? 'site/docs')
const TITLE = args.title ?? 'docs'
const ASSETS = (args.assets ?? 'https://docs.melchard.org/assets').replace(/\/$/, '')
const REPO = args.repo ?? ''
const SKIP = new Set(['SUMMARY.md', 'book.json', 'dark.css', '_book', 'node_modules'])

const inside = (a, b) => a === b || a.startsWith(b + sep)
if (inside(OUT, SRC) || inside(SRC, OUT)) throw new Error(`out (${OUT}) and src (${SRC}) must not overlap`)

/** @typedef {{ title: string, href?: string, page?: string, hash?: string, depth: number }} Entry */

/** `- [Title](file.md#frag)` lines of SUMMARY.md with their indent → flat entries. @returns {Entry[]} */
function nav() {
  const entries = []
  for (const line of readFileSync(join(SRC, 'SUMMARY.md'), 'utf8').split('\n')) {
    const m = /^(\s*)[-*]\s+(?:\[([^\]]+)\]\(([^)]+)\)|(.+))\s*$/.exec(line)
    if (!m) continue
    const depth = Math.floor(m[1].length / 2)
    if (m[4]) entries.push({ title: m[4].trim(), depth })
    else if (/^[a-z]+:/.test(m[3])) entries.push({ title: m[2], href: m[3], depth })
    else {
      const [page, hash] = m[3].replace(/^\.\//, '').split('#')
      entries.push({ title: m[2], page, hash: hash ? `#${hash}` : '', depth })
    }
  }
  return entries
}

/** All markdown files under src, as paths relative to src. */
function pages(dir = SRC, acc = []) {
  for (const f of readdirSync(dir)) {
    if (SKIP.has(f) || f.startsWith('.')) continue
    const p = join(dir, f)
    if (statSync(p).isDirectory()) pages(p, acc)
    else if (f.endsWith('.md')) acc.push(relative(SRC, p))
  }
  return acc.sort()
}

/** docs/x.md → x.html, README.md → index.html, keeps subdirectories. */
const out = (page) => page.replace(/README\.md$/, 'index.html').replace(/\.md$/, '.html')
/** A markdown href (maybe with a fragment) → the html one; external, absolute and pure fragments untouched. */
const html = (href) =>
  /^[a-z]+:|^#|^\//.test(href) ? href : href.replace(/README\.md(#.*)?$/, 'index.html$1').replace(/\.md(#.*)?$/, '.html$1')

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
const slug = (s) =>
  s
    .toLowerCase()
    .replace(/<[^>]+>/g, '')
    .replace(/&[a-z]+;/g, '')
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')

const CSS = `
.doc-head{display:flex;flex-wrap:wrap;align-items:baseline;gap:6px 18px;padding-bottom:12px;border-bottom:1px solid var(--line,rgba(255,255,255,.16))}
.doc-head .brand{font-weight:700;color:var(--fg,#eef2f7)}
.doc-nav{display:flex;flex-wrap:wrap;gap:2px 14px;font-size:.9rem}
.doc-nav span{color:var(--muted,#9aa4b2)}
.doc-nav a.active{color:var(--fg,#eef2f7);background:color-mix(in srgb,var(--link,#9ee7ff) 25%,transparent);outline:1px solid color-mix(in srgb,var(--link,#9ee7ff) 50%,transparent);outline-offset:2px;border-radius:2px}
.doc{padding-top:8px}
.doc h1{font-size:1.5rem;margin:1.2em 0 .5em}
.doc h2{font-size:1.15rem;margin:1.8em 0 .5em;padding-top:.6em;border-top:1px solid var(--line,rgba(255,255,255,.16))}
.doc h3{font-size:1rem;margin:1.4em 0 .4em;color:var(--muted,#9aa4b2)}
.doc p,.doc ul,.doc ol{margin:.7em 0}
.doc li{margin:.25em 0}
.doc code{background:var(--card,#15171f);padding:.1em .35em;border-radius:3px;font-size:.92em}
.doc pre{background:var(--card,#15171f);padding:12px 14px;border-radius:4px;overflow-x:auto;line-height:1.5}
.doc pre code{background:none;padding:0;font-size:.9em}
.doc table{margin:.8em 0;font-size:.95em}
.doc th,.doc td{padding:6px 10px 6px 0;vertical-align:top}
.doc img{max-width:100%;height:auto;display:block;margin:.8em 0}
.doc blockquote{margin:.8em 0;padding-left:12px;border-left:2px solid var(--line,rgba(255,255,255,.16));color:var(--muted,#9aa4b2)}
.doc hr{border:0;border-top:1px solid var(--line,rgba(255,255,255,.16));margin:1.5em 0}
.doc-foot{display:flex;justify-content:space-between;gap:12px;margin-top:36px;padding-top:12px;border-top:1px solid var(--line,rgba(255,255,255,.16));font-size:.85rem;color:var(--muted,#9aa4b2)}
`

marked.use({
  renderer: {
    link({ href, title, tokens }) {
      const text = this.parser.parseInline(tokens)
      const ext = /^[a-z]+:/.test(href) ? ' target="_blank" rel="noopener"' : ''
      return `<a href="${esc(html(href))}"${title ? ` title="${esc(title)}"` : ''}${ext}>${text}</a>`
    },
    heading({ tokens, depth }) {
      const text = this.parser.parseInline(tokens)
      return `<h${depth} id="${slug(text)}">${text}</h${depth}>\n`
    },
  },
})

/** @param {Entry[]} entries @param {string} page */
function render(entries, page) {
  const md = readFileSync(join(SRC, page), 'utf8')
  const here = out(page)
  const up = relative(dirname(join(OUT, here)), OUT) || '.'
  const link = (target) => `${up}/${target}`.replace(/^\.\//, '')
  const body = marked.parse(md)
  const listed = entries.filter((e) => e.page)
  const i = listed.findIndex((e) => e.page === page)
  const name = listed[i]?.title ?? page.replace(/\.md$/, '')
  const navHtml = entries
    .map((e) =>
      e.href
        ? `<a href="${esc(e.href)}" target="_blank" rel="noopener">${esc(e.title)}</a>`
        : e.page
          ? `<a href="${esc(link(out(e.page)) + e.hash)}"${e.page === page && !e.hash ? ' class="active"' : ''}>${esc(e.title)}</a>`
          : `<span>${esc(e.title)}</span>`,
    )
    .join('\n      ')
  const prev = listed[i - 1] && `<a href="${esc(link(out(listed[i - 1].page)))}">← ${esc(listed[i - 1].title)}</a>`
  const next = listed[i + 1] && `<a href="${esc(link(out(listed[i + 1].page)))}">${esc(listed[i + 1].title)} →</a>`
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${esc(name)} · ${esc(TITLE)}</title>
  <link rel="stylesheet" href="${ASSETS}/tokens.css">
  <link rel="stylesheet" href="${ASSETS}/style.css">
  <style>${CSS}</style>
</head>
<body>
<main class="shell">
  <header class="doc-head">
    <a class="brand" href="${esc(link('index.html'))}">${esc(TITLE)}</a>
    <nav class="doc-nav">
      ${navHtml}${REPO ? `\n      <a href="${esc(REPO)}" target="_blank" rel="noopener">GitHub</a>` : ''}
    </nav>
  </header>
  <article class="doc">
${body}
  </article>
  <footer class="doc-foot"><span>${prev ?? ''}</span><span>${next ?? ''}</span></footer>
</main>
</body>
</html>
`
}

function copyAssets(dir = SRC) {
  for (const f of readdirSync(dir)) {
    if (SKIP.has(f) || f.startsWith('.')) continue
    const p = join(dir, f)
    if (statSync(p).isDirectory()) copyAssets(p)
    else if (!f.endsWith('.md')) {
      const dest = join(OUT, relative(SRC, p))
      mkdirSync(dirname(dest), { recursive: true })
      cpSync(p, dest)
    }
  }
}

const entries = nav()
for (const e of entries)
  if (e.page && !existsSync(join(SRC, e.page))) throw new Error(`SUMMARY.md links ${e.page}, which does not exist`)
mkdirSync(OUT, { recursive: true })
const all = pages()
for (const page of all) {
  const dest = join(OUT, out(page))
  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, render(entries, page))
}
copyAssets()
console.log(`docs: ${all.length} pages → ${OUT}`)
