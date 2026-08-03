import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
const r = createRequire('/Users/joepangallo/.nvm/versions/node/v24.11.1/lib/node_modules/md-to-pdf/package.json');
const puppeteer = r('puppeteer');
const FILE = process.argv[2];
const content = JSON.parse(readFileSync(FILE, 'utf8'));
const groups = content.groups || [content];

// collect every statement: declared sqlChecks + every code block + every sandbox starter/solution
const items = [];
for (const g of groups) {
  for (const c of (g.sqlChecks || [])) items.push({ src: 'sqlCheck', sql: c.sql, engine: c.engine || 'sandbox', expect: c.expect });
  for (const s of (g.sections || [])) for (const b of s.blocks) {
    if (b.type === 'code') items.push({ src: `code:${s.id}`, sql: b.text, engine: 'code' });
    if (b.type === 'sandbox') {
      if (b.starter) items.push({ src: `starter:${s.id}`, sql: b.starter, engine: 'sandbox' });
      if (b.solution) items.push({ src: `solution:${s.id}`, sql: b.solution, engine: 'sandbox' });
    }
  }
}
const b = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox'] });
const p = await b.newPage();
await p.goto('file:///Users/joepangallo/keiser/db/db.html', { waitUntil: 'domcontentloaded' });
await new Promise((r) => setTimeout(r, 1500));

const out = await p.evaluate(async (items) => {
  const SQL = await initSqlJs({ locateFile: (f) => 'https://cdn.jsdelivr.net/npm/sql.js@1.10.3/dist/' + f });
  const strip = (s) => String(s).replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/--[^\n]*/g, ' ').replace(/\s+/g, ' ').trim();
  const res = [];
  for (const it of items) {
    if (!strip(it.sql)) { res.push({ ...it, status: 'comments-only' }); continue; }
    const db = new SQL.Database();
    try { db.run(window.SANDBOX_SEEDS.both_full); } catch (e) {}
    try {
      const r = db.exec(it.sql);
      res.push({ ...it, status: 'ok', rows: r.length ? r[0].values.length : 0,
                 cols: r.length ? r[0].columns.join(',') : '' });
    } catch (e) {
      res.push({ ...it, status: 'ERROR', err: e.message });
    }
    db.close();
  }
  return res;
}, items);
await b.close();

const errs = out.filter((o) => o.status === 'ERROR');
const bySrc = {};
for (const o of out) bySrc[o.status] = (bySrc[o.status] || 0) + 1;
console.log('totals:', bySrc, '\n');
// an error is only a real problem when the statement was meant to run in the sandbox
const real = errs.filter((e) => e.engine === 'sandbox' || e.engine === 'code');
console.log(`${real.length} statement(s) failed that were expected to run:\n`);
for (const e of real.slice(0, 40)) {
  console.log(`  [${e.src}] ${e.err}`);
  console.log(`     ${String(e.sql).replace(/\s+/g, ' ').slice(0, 150)}`);
}
const declaredNonSandbox = errs.filter((e) => e.engine && !['sandbox', 'code'].includes(e.engine));
if (declaredNonSandbox.length) console.log(`\n(${declaredNonSandbox.length} more failed but are declared ${[...new Set(declaredNonSandbox.map(e=>e.engine))].join('/')} - expected)`);
process.exit(real.length ? 1 : 0);
