/* Simulate each sandbox the way a student uses it: fresh seeded DB, run the
   starter, then run the solution in the SAME database. */
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
const r = createRequire('/Users/joepangallo/.nvm/versions/node/v24.11.1/lib/node_modules/md-to-pdf/package.json');
const puppeteer = r('puppeteer');
const content = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const boxes = [];
for (const g of content.groups) for (const s of g.sections) for (const b of s.blocks)
  if (b.type === 'sandbox') boxes.push({ id: s.id, seed: b.seed || 'kimtay_full', starter: b.starter || '', solution: b.solution || '', hint: b.hint || '' });

const br = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox'] });
const p = await br.newPage();
await p.goto('file:///Users/joepangallo/keiser/db/db.html', { waitUntil: 'domcontentloaded' });
await new Promise((r) => setTimeout(r, 1500));
const out = await p.evaluate(async (boxes) => {
  const SQL = await initSqlJs({ locateFile: (f) => 'https://cdn.jsdelivr.net/npm/sql.js@1.10.3/dist/' + f });
  const strip = (s) => String(s).replace(/--[^\n]*/g, ' ').replace(/\s+/g, ' ').trim();
  return boxes.map((b) => {
    const db = new SQL.Database();
    try { db.run(window.SANDBOX_SEEDS[b.seed]); } catch (e) { return { ...b, seedErr: e.message }; }
    const res = { id: b.id, blanks: /___/.test(b.starter + b.solution) };
    if (strip(b.starter)) { try { db.exec(b.starter); res.starter = 'ok'; } catch (e) { res.starter = e.message; } }
    else res.starter = 'comments-only';
    if (strip(b.solution)) { try { db.exec(b.solution); res.solution = 'ok'; } catch (e) { res.solution = e.message; } }
    else res.solution = 'none';
    db.close();
    return res;
  });
}, boxes);
await br.close();
const bad = out.filter((o) => (o.starter !== 'ok' && o.starter !== 'comments-only' && !o.blanks) || (o.solution !== 'ok' && o.solution !== 'none'));
console.log(`${out.length} sandboxes; ${out.filter(o=>o.blanks).length} use fill-in blanks; ${bad.length} genuinely broken`);
for (const b of bad) console.log(`  [${b.id}] starter=${String(b.starter).slice(0,60)} | solution=${String(b.solution).slice(0,60)}`);
const blanks = out.filter((o) => o.blanks);
if (blanks.length) console.log('\nfill-in-blank sandboxes:', blanks.map(b=>b.id).join(', '));
