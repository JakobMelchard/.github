#!/usr/bin/env node
// Markdown docs → static pages in the docs.melchard.org shell (tokens.css + style.css from the
// docs root, doc.css from this action, one centred column, mono). SUMMARY.md is the nav: nested
// list items, links to .md files become nav entries, external links stay links, plain items are
// section labels. Every .md under src is rendered, listed or not; everything else (images, css)
// is copied as is.
//
//   node build.mjs --src docs --out site/docs --title flatplan \
//     --assets https://docs.melchard.org/assets --repo https://github.com/owner/name
import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { dirname, join, relative, resolve, sep } from 'node:path'
import { parseArgs } from 'node:util'
import { marked } from 'marked'

const { values: args } = parseArgs({
  options: {
    src: { type: 'string', default: 'docs' },
    out: { type: 'string', default: 'site/docs' },
    title: { type: 'string', default: 'docs' },
    assets: { type: 'string', default: 'https://docs.melchard.org/assets' },
    repo: { type: 'string', default: '' },
  },
})
const SRC = resolve(args.src)
const OUT = resolve(args.out)
const TITLE = args.title
const ASSETS = args.assets.replace(/\/$/, '')
const REPO = args.repo
const SKIP = new Set(['SUMMARY.md', 'book.json', 'dark.css', '_book', 'node_modules'])
const STYLE = 'doc.css'

/** @param {string} a @param {string} b @returns {boolean} whether path a is b or inside it */
const inside = (a, b) => a === b || a.startsWith(b + sep)
if (inside(OUT, SRC) || inside(SRC, OUT)) throw new Error(`out (${OUT}) and src (${SRC}) must not overlap`)

/**
 * A SUMMARY.md item: a section label (title only), an external link (href) or a page with an
 * optional fragment (page, hash).
 * @typedef {{ title: string, href?: string, page?: string, hash?: string, depth: number }} Entry
 * @typedef {Entry & { page: string, hash: string }} PageEntry
 */

/** @param {Entry} e @returns {e is PageEntry} */
const isPage = (e) => Boolean(e.page)

/** `- [Title](file.md#frag)` lines of SUMMARY.md with their indent → flat entries. @returns {Entry[]} */
function nav() {
  /** @type {Entry[]} */
  const entries = []
  for (const line of readFileSync(join(SRC, 'SUMMARY.md'), 'utf8').split('\n')) {
    const m = /^(\s*)[-*]\s+(?:\[([^\]]+)\]\(([^)]+)\)|(.+))\s*$/.exec(line)
    if (!m) continue
    const [, indent, title, target, label] = m
    const depth = Math.floor(indent.length / 2)
    if (label) entries.push({ title: label.trim(), depth })
    else if (/^[a-z]+:/.test(target)) entries.push({ title, href: target, depth })
    else {
      const [page, hash] = target.replace(/^\.\//, '').split('#')
      entries.push({ title, page, hash: hash ? `#${hash}` : '', depth })
    }
  }
  return entries
}

/**
 * Files under dir, recursively, without SKIP and dotfiles.
 * @param {string} dir @returns {string[]} absolute paths
 */
function files(dir) {
  return readdirSync(dir)
    .filter((f) => !SKIP.has(f) && !f.startsWith('.'))
    .flatMap((f) => {
      const p = join(dir, f)
      return statSync(p).isDirectory() ? files(p) : [p]
    })
}

/** @param {string} page docs/x.md @returns {string} x.html; README.md → index.html, keeps subdirectories */
const out = (page) => page.replace(/README\.md$/, 'index.html').replace(/\.md$/, '.html')

/**
 * A markdown href (maybe with a fragment) → the html one; external, absolute and pure fragments untouched.
 * @param {string} href @returns {string}
 */
const html = (href) =>
  /^[a-z]+:|^#|^\//.test(href)
    ? href
    : href.replace(/README\.md(#.*)?$/, 'index.html$1').replace(/\.md(#.*)?$/, '.html$1')

/** @param {string} s @returns {string} s escaped for HTML text and attributes */
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

/** @param {string} s heading HTML @returns {string} its anchor id */
const slug = (s) =>
  s
    .toLowerCase()
    .replace(/<[^>]+>/g, '')
    .replace(/&[a-z]+;/g, '')
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')

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

/** @param {Entry} e @param {string} page @param {(target: string) => string} link @returns {string} */
function navItem(e, page, link) {
  if (e.href) return `<a href="${esc(e.href)}" target="_blank" rel="noopener">${esc(e.title)}</a>`
  if (!isPage(e)) return `<span>${esc(e.title)}</span>`
  const active = e.page === page && !e.hash ? ' class="active"' : ''
  return `<a href="${esc(link(out(e.page)) + e.hash)}"${active}>${esc(e.title)}</a>`
}

/** @param {Entry[]} entries @param {string} page path relative to src @returns {string} the page's HTML */
function render(entries, page) {
  const md = readFileSync(join(SRC, page), 'utf8')
  const up = relative(dirname(join(OUT, out(page))), OUT) || '.'
  /** @param {string} target @returns {string} */
  const link = (target) => `${up}/${target}`.replace(/^\.\//, '')
  const body = marked.parse(md, { async: false })
  const listed = entries.filter(isPage)
  const i = listed.findIndex((e) => e.page === page)
  const name = listed[i]?.title ?? page.replace(/\.md$/, '')
  const navHtml = entries.map((e) => navItem(e, page, link)).join('\n      ')
  const before = i > 0 ? listed[i - 1] : undefined
  const after = i >= 0 ? listed[i + 1] : undefined
  const prev = before ? `<a href="${esc(link(out(before.page)))}">← ${esc(before.title)}</a>` : ''
  const next = after ? `<a href="${esc(link(out(after.page)))}">${esc(after.title)} →</a>` : ''
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${esc(name)} · ${esc(TITLE)}</title>
  <link rel="stylesheet" href="${ASSETS}/tokens.css">
  <link rel="stylesheet" href="${ASSETS}/style.css">
  <link rel="stylesheet" href="${esc(link(STYLE))}">
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
  <footer class="doc-foot"><span>${prev}</span><span>${next}</span></footer>
</main>
</body>
</html>
`
}

const entries = nav()
for (const e of entries.filter(isPage))
  if (!existsSync(join(SRC, e.page))) throw new Error(`SUMMARY.md links ${e.page}, which does not exist`)
mkdirSync(OUT, { recursive: true })
const all = files(SRC).map((p) => relative(SRC, p))
const pages = all.filter((f) => f.endsWith('.md')).sort()
for (const page of pages) {
  const dest = join(OUT, out(page))
  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, render(entries, page))
}
for (const f of all.filter((f) => !f.endsWith('.md'))) {
  const dest = join(OUT, f)
  mkdirSync(dirname(dest), { recursive: true })
  cpSync(join(SRC, f), dest)
}
cpSync(new URL(STYLE, import.meta.url), join(OUT, STYLE))
console.log(`docs: ${pages.length} pages → ${OUT}`)
