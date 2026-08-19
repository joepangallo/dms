#!/usr/bin/env node
/* Reusable renderer: drops an authored module into db.html as a new page,
   wired into the nav, the home-page table of contents, and the site's quiz,
   matcher and sandbox machinery.

   Usage:  node render-module.mjs <content.json> <pageId> "<Module N>" "<Title>" "<lede>" [afterPageId]

   The content JSON is the shape the authoring workflow returns:
     { groups: [ { sections: [...], quizzes: [...], matchers: [...] } ] }
   Idempotent per pageId: refuses to run if that page already exists. */

import { readFileSync, writeFileSync, copyFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const [, , CONTENT, PAGE_ID, KICKER, TITLE, LEDE, AFTER = 'supabase'] = process.argv;
if (!CONTENT || !PAGE_ID || !KICKER || !TITLE) {
  console.error('usage: render-module.mjs <content.json> <pageId> "<Kicker>" "<Title>" "<lede>" [afterPageId]');
  process.exit(2);
}

const FILE = '/Users/joepangallo/keiser/db/db.html';
// A fixed OS temp path, not a Claude session's scratchpad -- a scratchpad
// directory is deleted once its session ends, so a backup path pinned to
// one would silently stop working (ENOENT on copyFileSync) for anyone who
// runs this tool later, in a different session or from a plain terminal.
const BAK = join(tmpdir(), `db.pre-${PAGE_ID}.html`);

let html = readFileSync(FILE, 'utf8');
if (html.includes(`<section class="page" id="${PAGE_ID}"`)) {
  console.error(`page "${PAGE_ID}" already exists - remove it first or pick another id`);
  process.exit(1);
}
copyFileSync(FILE, BAK);

const data = JSON.parse(readFileSync(CONTENT, 'utf8'));
const groups = data.groups || [data];
let bad = 0;
const fail = (m) => { console.error('RENDER ERROR: ' + m); bad++; };

/* ------------------------------------------------------------- helpers */
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                            .replace(/"/g, '&quot;').replace(/'/g, '&#39;');

const inlineMarkup = (t) => t
  .replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g,
    (_, l, u) => `<a href="${u}" target="_blank" rel="noopener noreferrer">${l}</a>`)
  .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');

function rich(text) {
  return String(text).split(/(`[^`]*`)/g).map((p) => {
    if (!p.startsWith('`') || !p.endsWith('`') || p.length < 2) return inlineMarkup(esc(p));
    const body = p.slice(1, -1);
    return body.includes('\n')
      ? `<pre class="code-block">${esc(body.trim())}</pre>`
      : `<code class="inline-code">${esc(body)}</code>`;
  }).join('');
}

const ICONS = { tip: '&#128161;', note: '&#128221;', warning: '&#9888;&#65039;', definition: '&#128214;' };
const SEEDS = ['empty', 'rep_table_empty', 'rep_customer_data', 'kimtay_partial', 'kimtay_full', 'staywell_full', 'both_full'];

/* the sandbox markup must match what the page script expects, including the
   schema strip, the data picker and the .db import/export buttons */
function renderSandbox(b) {
  const seed = SEEDS.includes(b.seed) ? b.seed : 'kimtay_full';
  const solution = b.solution ? esc(b.solution) : '';
  const hint = b.hint
    ? rich(b.hint)
    : 'The strip above lists every table in this database right now &mdash; click one to see its rows.';
  return `      <div class="sandbox" data-sandbox data-seed="${seed}" data-starter="${esc(b.starter || '')}" data-solution="${solution}">
        <div class="sandbox-toolbar">
          <span class="sandbox-label">SQL Sandbox &middot; SQLite engine</span>
          <select class="sandbox-load" aria-label="Load sample data"></select>
          <button type="button" class="sandbox-io sandbox-download" title="Save this database as a .sqlite file">&#11015; .db</button>
          <button type="button" class="sandbox-io sandbox-open" title="Open a .sqlite file you saved earlier">&#11014; .db</button>
          <button type="button" class="sandbox-reset">Reset</button>
          ${solution ? '<button type="button" class="sandbox-solution" data-showing="0">Show solution</button>' : ''}
          <button type="button" class="sandbox-run">&#9654; Run (Ctrl+Enter)</button>
        </div>
        <div class="sandbox-schema"><span class="schema-label">In this database<em>click a table to see its rows</em></span><div class="schema-chips"></div></div>
        <textarea class="sandbox-editor" spellcheck="false" aria-label="SQL editor"></textarea>
        <div class="sandbox-output" aria-live="polite"></div>
        <div class="sandbox-hint">${hint}</div>
      </div>`;
}

function renderBlock(b) {
  switch (b.type) {
    case 'h4': return `      <h4>${rich(b.text)}</h4>`;
    case 'p': return `      <p>${rich(b.text)}</p>`;
    case 'callout': {
      const v = ICONS[b.variant] ? b.variant : 'note';
      const label = b.label ? `<strong class="callout-label">${rich(b.label)}</strong>` : '';
      return `      <div class="callout callout-${v}">
        <div class="callout-icon" aria-hidden="true">${ICONS[v]}</div>
        <div class="callout-body">${label}<p>${rich(b.text)}</p></div>
      </div>`;
    }
    case 'code': return `      <pre class="code-block">${esc(String(b.text).replace(/\r/g, ''))}</pre>`;
    case 'table': {
      if (!Array.isArray(b.headers) || !Array.isArray(b.rows)) { fail('malformed table block'); return ''; }
      const cap = b.caption ? `\n        <caption>${rich(b.caption)}</caption>` : '';
      const extraClass = b.className ? ` ${esc(b.className)}` : '';
      return `      <div class="table-scroll${extraClass}"><table class="data-table wrap-cells">${cap}
        <thead><tr>${b.headers.map((h) => `<th>${rich(h)}</th>`).join('')}</tr></thead>
        <tbody>${b.rows.map((r) => `<tr>${r.map((c) => `<td>${rich(c)}</td>`).join('')}</tr>`).join('')}</tbody>
      </table></div>`;
    }
    case 'steps':
      return `      <div class="stepper">${(b.items || []).map((s, i) => `
        <div class="step"><div class="step-dot">${i + 1}</div><div class="step-body"><h4>${rich(s.title)}</h4><p>${rich(s.body)}</p></div></div>`).join('')}
      </div>`;
    case 'checklist':
      return `      <ul class="checklist">${(b.items || []).map((i) => `<li><span>${rich(i)}</span></li>`).join('')}</ul>`;
    case 'twocol':
      return `      <div class="two-col">${(b.cards || []).slice(0, 2)
        .map((c) => `<div class="card"><h4>${rich(c.title)}</h4><p>${rich(c.body)}</p></div>`).join('')}</div>`;
    case 'list':
      return `      <ul>${(b.items || []).map((i) => `<li>${rich(i)}</li>`).join('')}</ul>`;
    case 'sandbox': return renderSandbox(b);
    default: fail(`unknown block type "${b.type}"`); return '';
  }
}

function renderQuiz(q) {
  const questions = q.questions.map((item, qi) => {
    const opts = item.options.map((opt, oi) => `
          <button type="button" class="quiz-option" aria-pressed="false"><span class="opt-letter">${String.fromCharCode(97 + oi)}.</span><span class="opt-body">${rich(opt)}</span><span class="opt-mark" aria-hidden="true"></span></button>`).join('');
    const notes = item.optionNotes.map((note, oi) => {
      const right = oi === item.answerIndex;
      return `
            <li class="${right ? 'note-right' : 'note-wrong'}"><span class="note-mark" aria-hidden="true">${right ? '✔' : '✘'}</span><span><strong>${String.fromCharCode(97 + oi)}.</strong> ${rich(note)}</span></li>`;
    }).join('');
    return `
        <div class="quiz-question" data-answer="${item.answerIndex}">
          <div class="quiz-q-head"><span class="quiz-q-num">Q${qi + 1}</span><span class="quiz-q-title">${rich(item.scenarioTitle)}</span></div>
          <p class="quiz-q-text">${rich(item.stem)}</p>
          <div class="quiz-options">${opts}
          </div>
          <div class="quiz-explain">
            <p class="quiz-verdict"></p>
            <ul class="quiz-notes">${notes}
            </ul>
            <p class="quiz-takeaway"><strong>Remember:</strong> ${rich(item.takeaway)}</p>
            <button type="button" class="btn btn-sm btn-outline quiz-again">Try this one again</button>
          </div>
        </div>`;
  }).join('');
  return `
      <div class="quiz" data-quiz-id="${esc(q.quizId)}">
        <div class="quiz-head"><h4>&#128269; ${rich(q.heading)}</h4><span class="quiz-hint">Pick an answer &mdash; the explanation opens right away.</span></div>${questions}
        <p class="visually-hidden quiz-live" role="status" aria-live="polite"></p>
        <div class="quiz-footer">
          <span class="quiz-score"></span>
          <span class="quiz-bar" aria-hidden="true"><span></span></span>
          <button type="button" class="btn btn-sm btn-ghost quiz-reset">Reset this quiz</button>
        </div>
      </div>`;
}

function renderMatcher(m) {
  const zoneKeys = new Set(m.zones.map((z) => z.key));
  m.cards.forEach((c) => { if (!zoneKeys.has(c.zone)) fail(`${m.matchId}: card "${c.text}" -> unknown zone`); });
  m.zones.forEach((z) => { if (!m.cards.some((c) => c.zone === z.key)) fail(`${m.matchId}: zone "${z.key}" empty`); });
  const cards = m.cards.map((c, ci) => `<button type="button" class="mcard" aria-pressed="false" data-card-id="c${ci}" data-zone="${esc(c.zone)}" data-text="${esc(c.text)}" data-why="${esc(c.why)}">${esc(c.text)}</button>`).join('');
  const zones = m.zones.map((z) => `
          <div><button type="button" class="mzone" data-zone-key="${esc(z.key)}"><span class="mzone-label">${esc(z.label)}</span><span class="mzone-hint">${esc(z.hint)}</span></button><ul class="mzone-drop"></ul></div>`).join('');
  return `
      <div class="matcher" data-match-id="${esc(m.matchId)}" data-card-count="${m.cards.length}">
        <div class="matcher-head"><h4>&#129513; ${rich(m.heading)}</h4><span class="matcher-hint">Click a card, then click where it belongs.</span></div>
        <p class="matcher-prompt">${rich(m.prompt)}</p>
        <div class="mcards">${cards}</div>
        <div class="mzones">${zones}
        </div>
        <div class="matcher-footer">
          <p class="mstatus">0 / ${m.cards.length} placed</p>
          <p class="mfeedback" role="status"></p>
          <button type="button" class="btn btn-sm btn-ghost matcher-reset">Reset</button>
        </div>
      </div>`;
}

/* ------------------------------------------------------ assemble the page */
const sections = [];
const byAnchor = new Map();
const add = (a, h) => { if (!byAnchor.has(a)) byAnchor.set(a, []); byAnchor.get(a).push(h); };

for (const g of groups) {
  for (const s of (g.sections || [])) sections.push(s);
  for (const q of (g.quizzes || [])) add(q.anchor, renderQuiz(q));
  for (const m of (g.matchers || [])) add(m.anchor, renderMatcher(m));
}
if (!sections.length) fail('no sections in the content file');

// existing ids must not collide with anything already on the page
const existing = new Set([...html.matchAll(/\sid="([^"]+)"/g)].map((m) => m[1]));
for (const s of sections) if (existing.has(s.id)) fail(`section id "${s.id}" already exists in the document`);
for (const [, blocks] of byAnchor) void blocks;
for (const g of groups) {
  for (const q of (g.quizzes || [])) if (html.includes(`data-quiz-id="${q.quizId}"`)) fail(`quiz id ${q.quizId} already exists`);
  for (const m of (g.matchers || [])) if (html.includes(`data-match-id="${m.matchId}"`)) fail(`matcher id ${m.matchId} already exists`);
}
const anchorIds = new Set(sections.map((s) => s.id));
for (const a of byAnchor.keys()) if (!anchorIds.has(a)) fail(`quiz/matcher anchored to unknown section "${a}"`);

const body = sections.map((s) => {
  const blocks = s.blocks.map(renderBlock).filter(Boolean).join('\n');
  const extras = (byAnchor.get(s.id) || []).join('\n');
  return `<section class="lesson-section" id="${esc(s.id)}" data-slide data-slide-title="${esc(s.num + '. ' + s.title)}">
      <h3><span class="num">${esc(s.num)}</span> ${esc(s.title)}</h3>
${blocks}${extras ? '\n' + extras : ''}
    </section>`;
}).join('');

const sideList = sections.map((s) =>
  `<li><a href="#${PAGE_ID}:${esc(s.id)}">${esc(s.num + '. ' + s.title)}</a></li>`).join('');

const PAGE = `
<section class="page" id="${PAGE_ID}">
    <section class="page-hero no-present">
      <div class="shell">
        <span class="page-kicker">${esc(KICKER)}</span>
        <h1>${esc(TITLE)}</h1>
        <p class="lede">${rich(LEDE || '')}</p>
      </div>
    </section>
    <div class="content-wrap">
      <aside class="lesson-sidebar no-present">
      <h2>${esc(KICKER)}</h2>
      <ul class="side-list">${sideList}</ul>
    </aside>
      <div class="lesson-content">${body}</div>
    </div>
    </section>
`;

if (bad) { console.error(`aborted with ${bad} error(s); file untouched`); process.exit(1); }

/* place the page, then wire up nav and the home table of contents */
{
  const marker = `<section class="page" id="${AFTER}"`;
  if (!html.includes(marker)) { console.error(`anchor page "${AFTER}" not found`); process.exit(1); }
  html = html.replace(marker, PAGE + marker);

  const navAnchor = `<a href="#${AFTER}" class="nav-link" data-page-link="${AFTER}">`;
  const i = html.indexOf(navAnchor);
  if (i === -1) { console.error('nav anchor not found'); process.exit(1); }
  html = html.slice(0, i) +
    `<a href="#${PAGE_ID}" class="nav-link" data-page-link="${PAGE_ID}">${esc(KICKER)}</a>` +
    html.slice(i);

  const tocPanel = `toc-panel-${PAGE_ID}`;
  const tocEntry = `<div class="toc-module">
          <button type="button" class="toc-module-btn" aria-expanded="false" aria-controls="${tocPanel}">${esc(KICKER + '. ' + TITLE)}
            <svg class="accordion-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M6 9l6 6 6-6" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </button>
          <ul class="toc-leaves" id="${tocPanel}" hidden>${sections.map((s) =>
            `<li><a href="#${PAGE_ID}:${esc(s.id)}" class="toc-leaf">${esc(s.num + '. ' + s.title)}</a></li>`).join('')}</ul>
        </div>`;
  const tocAfter = '<div class="toc-module">\n          <button type="button" class="toc-module-btn" aria-expanded="false" aria-controls="toc-panel-supa">';
  if (!html.includes(tocAfter)) { console.error('home TOC anchor not found'); process.exit(1); }
  html = html.replace(tocAfter, tocEntry + tocAfter);
}

writeFileSync(FILE, html);
const nQ = groups.reduce((n, g) => n + (g.quizzes || []).reduce((m, q) => m + q.questions.length, 0), 0);
const nM = groups.reduce((n, g) => n + (g.matchers || []).length, 0);
const nS = sections.reduce((n, s) => n + s.blocks.filter((b) => b.type === 'sandbox').length, 0);
console.log(`rendered ${PAGE_ID}: ${sections.length} sections, ${nQ} questions, ${nM} matchers, ${nS} sandboxes`);
console.log(`wrote ${FILE} (${(html.length / 1024).toFixed(0)} KB); backup at ${BAK}`);
