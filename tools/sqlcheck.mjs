import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve as resolvePath } from 'node:path';
import { execSync } from 'node:child_process';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = dirname(HERE);
const PAGE = 'file://' + resolvePath(REPO, 'db.html');
const SQL_JS_BASE = 'https://cdn.jsdelivr.net/npm/sql.js@1.10.3/dist/';

/* puppeteer is not a dependency of this repo - it comes from whatever global
   install happens to be present, and the path changes with every node upgrade.
   Resolve it rather than hard-coding one. */
function loadPuppeteer() {
  const tries = [];
  try { return createRequire(import.meta.url)('puppeteer'); } catch (e) { tries.push(e.message); }
  try {
    const root = execSync('npm root -g', { encoding: 'utf8' }).trim();
    return createRequire(root + '/')('puppeteer');
  } catch (e) { tries.push(e.message); }
  try {
    const root = execSync('npm root -g', { encoding: 'utf8' }).trim();
    return createRequire(root + '/md-to-pdf/package.json')('puppeteer');
  } catch (e) { tries.push(e.message); }
  console.error('cannot find puppeteer. Install it with:  npm i -g puppeteer\n' +
                tries.map((t) => '  - ' + t.split('\n')[0]).join('\n'));
  process.exit(2);
}
const puppeteer = loadPuppeteer();
const FILE = process.argv[2];
if (!FILE) { console.error('usage: sqlcheck.mjs <content.json>'); process.exit(2); }
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
await p.goto(PAGE, { waitUntil: 'domcontentloaded' });
await new Promise((r) => setTimeout(r, 1500));

/* The page loads sql.js lazily, from inside a closure, so initSqlJs does not
   exist until a student actually runs a sandbox - and loadSqlJs is not reachable
   from here. Pull the library in ourselves before evaluating. */
await p.addScriptTag({ url: SQL_JS_BASE + 'sql-wasm.js' });
await p.waitForFunction("typeof initSqlJs === 'function'", { timeout: 30000 });

const out = await p.evaluate(async (items, base) => {
  const SQL = await initSqlJs({ locateFile: (f) => base + f });
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
}, items, SQL_JS_BASE);
await b.close();

/* Not every statement in the course is meant to run in this engine. Modules 6-8
   carry MySQL, Oracle and T-SQL routines; several examples are deliberately
   invalid because the lesson teaches from the error message; and many sandbox
   starters are fill-in-the-blank. Each of those announces itself, either in its
   own leading comments or in its shape, so classify rather than counting every
   error as breakage. */
const EXPECTED = [
  /mysql only/i, /mysql or oracle/i, /mysql and oracle/i, /mysql 8/i,
  /\boracle\b/i, /sql server/i, /t-sql/i, /postgres/i, /psql/i,
  /not runnable/i, /cannot run/i, /does not run/i, /neither of these runs/i,
  /syntax error in sqlite/i, /not implemented in sqlite/i, /no \w+ in sqlite/i,
  /does not exist in sqlite/i, /has no create procedure/i,
  /deliberate error/i, /intentionally/i, /this one fails/i, /fails on purpose/i,
  /supposed to fail/i, /\bBROKEN\b/, /^\s*--\s*rejected/im, /each of these is rejected/i,
];
/* Syntax that simply is not SQLite, whatever the comments say. */
const OTHER_ENGINE = [
  /^\s*DELIMITER\b/im, /\bCREATE\s+(OR\s+REPLACE\s+)?PROCEDURE\b/i, /^\s*CALL\s/im,
  /^\s*EXEC\s/im, /^\s*GO\s*$/im, /\bDECLARE\s+\w+\s+CURSOR\b/i,
  /\bDECLARE\s+(CONTINUE|EXIT)\s+HANDLER\b/i, /@@\w+/, /^\s*SET\s+@/im,
  /\bDBMS_OUTPUT\b/i, /\bRAISE_APPLICATION_ERROR\b/i, /\bINFORMATION_SCHEMA\b/i,
  /^\s*SHOW\s/im, /\bCREATE\s+(USER|ROLE)\b/i, /^\s*(GRANT|REVOKE)\s/im,
  /\bALTER\s+TABLE\s+\w+\s+(MODIFY|CHANGE)\b/i, /\bADD\s+CONSTRAINT\b/i,
  /\bDROP\s+CONSTRAINT\b/i, /[<>=]\s*(ALL|ANY|SOME)\s*\(\s*SELECT/i,
  /\bWITH\s+CHECK\s+OPTION\b/i, /\bSET\s+autocommit\b/i, /\bSET\s+AUTOCOMMIT\b/i,
  /\bTRUNCATE\s*\(/i, /\b(CURDATE|DATEDIFF|DATE_ADD|CONCAT_WS)\s*\(/i,
];

/* Every scratch table the file creates somewhere. A "no such table" for one of
   these means the statement depends on an earlier one, not that it is broken -
   this checker gives each statement its own freshly seeded database. */
const CREATED = new Set();
for (const it of items) {
  const re = /\bCREATE\s+(?:TEMP\s+|TEMPORARY\s+)?(?:TABLE|VIEW)\s+(?:IF\s+NOT\s+EXISTS\s+)?[`"']?(\w+)/gi;
  let m; while ((m = re.exec(String(it.sql || '')))) CREATED.add(m[1].toUpperCase());
}

function expectedToFail(o) {
  const sql = String(o.sql || '');
  if (/___/.test(sql)) return 'unfinished starter';        // a blank to fill in
  // a starter that stops mid-statement is also the exercise, not a defect
  if (o.src && o.src.startsWith('starter:') && !/;\s*$/.test(sql)) return 'unfinished starter';
  // a syntax template rather than a statement: SELECT column_list FROM table_list
  if (/\b(view_name|table_name|column_list|table_list|condition|index_name)\b/.test(sql))
    return 'syntax template';
  if (/^\s*#/.test(sql)) return 'shell, not SQL';
  if (/^\s*\\/.test(sql)) return 'psql meta-command';
  const lead = sql.split('\n').filter((l) => /^\s*(--|#)/.test(l)).join('\n');
  for (const re of EXPECTED) if (re.test(lead)) return 'another engine or a taught error';
  /* A declared check whose expected RESULT is the error itself is a lesson about
     that error, not a broken statement. */
  if (o.expect && /\berrors?\b|\bfails?\b|\brefuses?\b|\brejects?\b|\binvalid\b|not allowed|cannot\b/i.test(o.expect))
    return 'a taught error';
  if (o.expect && EXPECTED.some((re) => re.test(o.expect))) return 'another engine or a taught error';
  for (const re of OTHER_ENGINE) if (re.test(sql)) return 'another engine';
  const missing = /no such table:\s*(\w+)/i.exec(o.err || '');
  if (missing && CREATED.has(missing[1].toUpperCase())) return 'needs an earlier statement';
  if (/^\s*ROLLBACK|^\s*COMMIT/im.test(sql) && /no transaction is active/i.test(o.err || ''))
    return 'needs an earlier statement';
  return null;
}

const errs = out.filter((o) => o.status === 'ERROR');
const bySrc = {};
for (const o of out) bySrc[o.status] = (bySrc[o.status] || 0) + 1;
console.log('totals:', bySrc, '\n');
// an error is only a real problem when the statement was meant to run in the sandbox
const runnable = errs.filter((e) => e.engine === 'sandbox' || e.engine === 'code');
const explained = [];
const real = [];
for (const e of runnable) {
  const why = expectedToFail(e);
  if (why) explained.push({ ...e, why }); else real.push(e);
}
if (explained.length) {
  const byWhy = {};
  for (const e of explained) byWhy[e.why] = (byWhy[e.why] || 0) + 1;
  console.log(`${explained.length} expected failure(s):`,
              Object.entries(byWhy).map(([k, v]) => `${v} ${k}`).join(', '), '\n');
}
console.log(`${real.length} statement(s) failed that were expected to run:\n`);
if (real.length) console.log('  (read these - most are lessons taught from an error message,\n' +
                             '   but anything unfamiliar here is worth checking)\n');
for (const e of real.slice(0, 40)) {
  console.log(`  [${e.src}] ${e.err}`);
  console.log(`     ${String(e.sql).replace(/\s+/g, ' ').slice(0, 150)}`);
}
const declaredNonSandbox = errs.filter((e) => e.engine && !['sandbox', 'code'].includes(e.engine));
if (declaredNonSandbox.length) console.log(`\n(${declaredNonSandbox.length} more failed but are declared ${[...new Set(declaredNonSandbox.map(e=>e.engine))].join('/')} - expected)`);
process.exit(real.length ? 1 : 0);
