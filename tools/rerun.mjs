/* Students press Run repeatedly. Any sandbox that CREATEs a table must survive
   a second run. Report which ones do not. */
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
const r = createRequire('/Users/joepangallo/.nvm/versions/node/v24.11.1/lib/node_modules/md-to-pdf/package.json');
const puppeteer = r('puppeteer');
const c = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const boxes = [];
for (const g of c.groups) for (const s of g.sections) for (const b of s.blocks)
  if (b.type === 'sandbox') boxes.push({ id: s.id, seed: b.seed || 'kimtay_full', starter: b.starter || '', solution: b.solution || '' });
const br = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox'] });
const p = await br.newPage();
await p.goto('file:///Users/joepangallo/keiser/db/db.html', { waitUntil: 'domcontentloaded' });
await new Promise((r) => setTimeout(r, 1500));
const out = await p.evaluate(async (boxes) => {
  const SQL = await initSqlJs({ locateFile: (f) => 'https://cdn.jsdelivr.net/npm/sql.js@1.10.3/dist/' + f });
  const strip = (s) => String(s).replace(/--[^\n]*/g, ' ').replace(/\s+/g, ' ').trim();
  const res = [];
  for (const b of boxes) {
    const db = new SQL.Database();
    db.run(window.SANDBOX_SEEDS[b.seed]);
    const runs = [];
    for (const label of ['run1', 'run2', 'thenSolution']) {
      const sql = label === 'thenSolution' ? b.solution : b.starter;
      if (!strip(sql)) { runs.push(label + '=skip'); continue; }
      try { db.exec(sql); runs.push(label + '=ok'); }
      catch (e) { runs.push(label + '=' + e.message.slice(0, 55)); }
    }
    db.close();
    if (runs.some((x) => !/=(ok|skip)$/.test(x))) res.push({ id: b.id, runs });
  }
  return res;
}, boxes);
await br.close();
console.log(`${out.length} sandbox(es) fail on repeat use:`);
for (const o of out) console.log('  [' + o.id + '] ' + o.runs.join(' | '));
