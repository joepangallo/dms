#!/usr/bin/env node
/* Headless verification of the rebuilt course site.
   Drives every quiz and every matcher in a real browser, then checks
   responsive overflow at four widths. Exits non-zero on any failure. */

import { createRequire } from 'node:module';
const require_ = createRequire('/Users/joepangallo/.nvm/versions/node/v24.11.1/lib/node_modules/md-to-pdf/package.json');
const puppeteer = require_('puppeteer');

const URL = 'file:///Users/joepangallo/keiser/db/db.html';
const PAGES = ['home', 'module1', 'module2', 'module3', 'module4', 'module5', 'module6', 'module7', 'module8', 'supabase', 'project'];

const fails = [];
const note = (ok, msg) => { console.log(`${ok ? '  ok ' : '  FAIL '} ${msg}`); if (!ok) fails.push(msg); };

const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox'] });
const page = await browser.newPage();

const consoleErrors = [];
page.on('console', (m) => { if (m.type() === 'error') consoleErrors.push(m.text()); });
page.on('pageerror', (e) => consoleErrors.push('pageerror: ' + e.message));

await page.setViewport({ width: 1280, height: 900 });
await page.goto(URL, { waitUntil: 'domcontentloaded' });
await new Promise((r) => setTimeout(r, 900));

/* ---------------------------------------------------------- inventory */
const inv = await page.evaluate(() => ({
  quizzes: document.querySelectorAll('.quiz').length,
  questions: document.querySelectorAll('.quiz-question').length,
  matchers: document.querySelectorAll('.matcher').length,
  cards: document.querySelectorAll('.mcard').length,
  legacySubmit: document.querySelectorAll('.quiz-submit').length,
  legacyExplain: document.querySelectorAll('[data-explain]').length,
  chip: !!document.querySelector('.progress-chip .chip-text'),
}));
console.log('\ninventory', inv);
note(inv.quizzes > 0 && inv.questions > 0, `found ${inv.questions} questions in ${inv.quizzes} quizzes`);
note(inv.matchers > 0, `found ${inv.matchers} matchers with ${inv.cards} cards`);
note(inv.legacySubmit === 0, 'no leftover "Check my answers" buttons');
note(inv.legacyExplain === 0, 'no leftover data-explain attributes');
note(inv.chip, 'progress chip present');

/* ------------------------------------------- structural sanity in DOM */
console.log('\nstructure');
const structure = await page.evaluate(() => {
  const bad = [];
  document.querySelectorAll('.quiz-question').forEach((q, i) => {
    const answer = parseInt(q.getAttribute('data-answer'), 10);
    const opts = q.querySelectorAll('.quiz-option').length;
    const notes = q.querySelectorAll('.quiz-notes li').length;
    const id = (q.closest('.quiz') || {}).getAttribute
      ? q.closest('.quiz').getAttribute('data-quiz-id') + '#' + i : 'q' + i;
    if (!(answer >= 0 && answer < opts)) bad.push(`${id}: data-answer ${answer} out of range (${opts} options)`);
    if (opts !== 4) bad.push(`${id}: ${opts} options, expected 4`);
    if (notes !== opts) bad.push(`${id}: ${notes} notes for ${opts} options`);
    if (q.querySelectorAll('.quiz-notes li.note-right').length !== 1) bad.push(`${id}: not exactly one correct note`);
    if (!q.querySelector('.quiz-takeaway')) bad.push(`${id}: missing takeaway`);
  });
  const seen = new Set();
  document.querySelectorAll('.quiz').forEach((z) => {
    const id = z.getAttribute('data-quiz-id');
    if (seen.has(id)) bad.push(`duplicate quiz id ${id}`);
    seen.add(id);
  });
  document.querySelectorAll('.matcher').forEach((m) => {
    const id = m.getAttribute('data-match-id');
    if (seen.has(id)) bad.push(`duplicate matcher id ${id}`);
    seen.add(id);
    const zones = new Set([...m.querySelectorAll('.mzone')].map((z) => z.getAttribute('data-zone-key')));
    m.querySelectorAll('.mcard').forEach((c) => {
      if (!zones.has(c.getAttribute('data-zone'))) bad.push(`${id}: card "${c.dataset.text}" -> unknown zone`);
      if (!c.getAttribute('data-why')) bad.push(`${id}: card "${c.dataset.text}" has no why line`);
    });
    const n = parseInt(m.getAttribute('data-card-count'), 10);
    if (n !== m.querySelectorAll('.mcard').length) bad.push(`${id}: card-count mismatch`);
  });
  return bad;
});
structure.forEach((b) => note(false, b));
note(structure.length === 0, `structural checks (${inv.questions} questions, ${inv.matchers} matchers)`);

/* ------------------------- instant reveal: wrong answer, then correct */
console.log('\ninstant reveal');
const reveal = await page.evaluate(async () => {
  const out = [];
  const q = document.querySelector('#module2 .quiz-question') || document.querySelector('.quiz-question');
  const opts = [...q.querySelectorAll('.quiz-option')];
  const answer = parseInt(q.getAttribute('data-answer'), 10);
  const wrong = opts.findIndex((_, i) => i !== answer);

  const explain = q.querySelector('.quiz-explain');
  out.push(['explanation hidden before answering', getComputedStyle(explain).display === 'none']);

  opts[wrong].click();
  out.push(['locks on a single click', q.classList.contains('is-answered')]);
  out.push(['explanation revealed immediately', getComputedStyle(explain).display !== 'none']);
  out.push(['marked wrong', q.classList.contains('is-wrong')]);
  out.push(['chosen option flagged incorrect', opts[wrong].classList.contains('is-incorrect')]);
  out.push(['correct option revealed', opts[answer].classList.contains('is-correct')]);
  out.push(['all options locked', opts.every((o) => o.disabled)]);
  out.push(['verdict names the letter', /answer is [a-d]\./.test(q.querySelector('.quiz-verdict').textContent)]);
  out.push(['reasons shown for every option', q.querySelectorAll('.quiz-notes li').length === opts.length]);

  q.querySelector('.quiz-again').click();
  out.push(['retry clears the question', !q.classList.contains('is-answered') && !opts[0].disabled]);
  out.push(['explanation hidden again', getComputedStyle(explain).display === 'none']);

  opts[answer].click();
  out.push(['correct answer marked right', q.classList.contains('is-right')]);
  const score = q.closest('.quiz').querySelector('.quiz-score').textContent;
  out.push(['score line updated: ' + score, /\d+ \/ \d+ correct/.test(score)]);
  return out;
});
reveal.forEach(([m, ok]) => note(ok, m));

/* --------------------------------------------------- persistence check */
console.log('\npersistence');
await page.reload({ waitUntil: 'domcontentloaded' });
await new Promise((r) => setTimeout(r, 700));
const persisted = await page.evaluate(() => {
  const q = document.querySelector('#module2 .quiz-question') || document.querySelector('.quiz-question');
  return { answered: q.classList.contains('is-answered'), right: q.classList.contains('is-right') };
});
note(persisted.answered && persisted.right, 'answer survives a reload');

/* ------------------------------------------------------ matcher drive */
console.log('\nmatchers');
const matchResults = await page.evaluate(async () => {
  const out = [];
  for (const m of document.querySelectorAll('.matcher')) {
    const id = m.getAttribute('data-match-id');
    const total = m.querySelectorAll('.mcard').length;

    // a deliberate mismatch must be rejected
    const first = m.querySelector('.mcard');
    const wrongZone = [...m.querySelectorAll('.mzone')]
      .find((z) => z.getAttribute('data-zone-key') !== first.getAttribute('data-zone'));
    if (wrongZone) {
      first.click(); wrongZone.click();
      if (!m.querySelector('.mcard[data-card-id="' + first.dataset.cardId + '"]')) {
        out.push([`${id}: rejects a wrong bucket`, false]); continue;
      }
      if (!m.querySelector('.mfeedback').textContent) { out.push([`${id}: explains the miss`, false]); continue; }
      first.click(); // deselect
    }

    // now place every card correctly
    let guard = 0;
    while (m.querySelectorAll('.mcard').length && guard++ < 40) {
      const card = m.querySelector('.mcard');
      const zone = m.querySelector('.mzone[data-zone-key="' + card.getAttribute('data-zone') + '"]');
      card.click(); zone.click();
    }
    const left = m.querySelectorAll('.mcard').length;
    const landed = m.querySelectorAll('.mzone-drop li').length;
    const whys = m.querySelectorAll('.mzone-drop li em').length;
    const status = m.querySelector('.mstatus').textContent;
    out.push([`${id}: all ${total} cards placed (${status.trim()})`,
      left === 0 && landed === total && whys === total && /all correct/.test(status)]);

    m.querySelector('.matcher-reset').click();
    out.push([`${id}: reset restores the pile`,
      m.querySelectorAll('.mcard').length === total && m.querySelectorAll('.mzone-drop li').length === 0]);
  }
  return out;
});
matchResults.forEach(([m, ok]) => note(ok, m));

/* -------------------------------------------------- progress chip math */
console.log('\nprogress chip');
const chip = await page.evaluate(() => document.querySelector('.progress-chip .chip-text').textContent);
note(/Progress \d+ \/ \d+/.test(chip), `chip reads "${chip}"`);

/* ------------------------------- seed integrity, run through real SQLite */
/* sql.js is fetched lazily: a sandbox only pulls it in once it scrolls within
   240px of the viewport. So initSqlJs is undefined here unless some earlier
   step happened to park a sandbox near the fold, which made this check depend
   on page length rather than on anything it is meant to test. Boot it on
   purpose instead. */
await page.evaluate(() => {
  if (typeof initSqlJs !== 'undefined') return;
  const box = document.querySelector('[data-sandbox]');
  if (box && box._ensureSqlBoot) { box._ensureSqlBoot(); return; }
  const s = document.createElement('script');            // fallback: load it directly
  s.src = 'https://cdn.jsdelivr.net/npm/sql.js@1.10.3/dist/sql-wasm.js';
  document.head.appendChild(s);
});
await page.waitForFunction(() => typeof initSqlJs !== 'undefined', { timeout: 30000 });

console.log('\nseed data (executed in the page\'s own sql.js engine)');
const seed = await page.evaluate(async () => {
  const SQL = await initSqlJs({ locateFile: (f) => 'https://cdn.jsdelivr.net/npm/sql.js@1.10.3/dist/' + f });
  const one = (sql, key) => {
    const db = new SQL.Database();
    db.run(window.SANDBOX_SEEDS[key]);
    const r = db.exec(sql);
    db.close();
    return r.length ? r[0].values : [];
  };
  const out = {};
  for (const key of Object.keys(window.SANDBOX_SEEDS)) {
    if (!window.SANDBOX_SEEDS[key]) continue;
    try { const db = new SQL.Database(); db.run(window.SANDBOX_SEEDS[key]); db.close(); out['seed_' + key] = 'ok'; }
    catch (e) { out['seed_' + key] = 'ERROR: ' + e.message; }
  }
  out.roomsNamed101 = one("SELECT PROPERTY_ID FROM ROOM WHERE ROOM_NUM='101' ORDER BY 1", 'staywell_full').map(r => r[0]);
  out.invoicesWithCF21 = one("SELECT INVOICE_NUM FROM INVOICE_LINE WHERE ITEM_ID='CF21' ORDER BY 1", 'kimtay_full').map(r => r[0]);
  out.roomCount = one('SELECT COUNT(*) FROM ROOM', 'staywell_full')[0][0];
  out.lineCount = one('SELECT COUNT(*) FROM INVOICE_LINE', 'kimtay_full')[0][0];
  out.bothFullRooms = one("SELECT COUNT(*) FROM ROOM WHERE ROOM_NUM='101'", 'both_full')[0][0];
  // every lease must still point at a room that exists
  out.orphanLeases = one(
    'SELECT COUNT(*) FROM LEASE l LEFT JOIN ROOM r ON l.PROPERTY_ID=r.PROPERTY_ID AND l.ROOM_NUM=r.ROOM_NUM WHERE r.ROOM_NUM IS NULL',
    'staywell_full')[0][0];
  return out;
});
console.log('  ', JSON.stringify(seed));
Object.entries(seed).filter(([k]) => k.startsWith('seed_'))
  .forEach(([k, v]) => note(v === 'ok', `${k} executes cleanly`));
note(seed.roomsNamed101.join(',') === 'P100,P200', 'room 101 now exists at BOTH properties (composite key is justified)');
note(seed.invoicesWithCF21.join(',') === '50710,50711', 'CF21 now appears on two invoices (many-to-many is visible)');
note(seed.roomCount === 5 && seed.lineCount === 6, `row counts updated (ROOM ${seed.roomCount}, INVOICE_LINE ${seed.lineCount})`);
note(seed.bothFullRooms === 2, 'both_full seed carries the new ROOM row too');
note(seed.orphanLeases === 0, 'no LEASE row orphaned by the ROOM change');

/* ------------- rendered tables must agree with the seed they illustrate */
const tables = await page.evaluate(() => {
  // textContent, not innerText: inactive .page sections are display:none
  const text = document.body.textContent;
  return {
    roomTableHas101atP200: [...document.querySelectorAll('table.data-table')].some((t) => {
      const rows = [...t.querySelectorAll('tbody tr')].map((r) => [...r.cells].map((c) => c.textContent.trim()).join('|'));
      return rows.some((r) => r.startsWith('P200|101|'));
    }),
    lineTableHasCF21on50711: [...document.querySelectorAll('table.data-table')].some((t) => {
      const rows = [...t.querySelectorAll('tbody tr')].map((r) => [...r.cells].map((c) => c.textContent.trim()).join('|'));
      return rows.some((r) => r.startsWith('50711|CF21|'));
    }),
    scriptHasCF21on50711: text.includes("VALUES ('50711', 'CF21', '2', '42.50')"),
  };
});
note(tables.roomTableHas101atP200, 'printed ROOM table shows P200 room 101');
note(tables.lineTableHasCF21on50711, 'printed INVOICE_LINE table shows 50711/CF21');
note(tables.scriptHasCF21on50711, 'Lesson 3-10 build script inserts 50711/CF21');

/* -------------------------------------------- responsive overflow scan */
console.log('\nresponsive');
for (const width of [320, 375, 768, 1280]) {
  await page.setViewport({ width, height: 900 });
  await new Promise((r) => setTimeout(r, 250));
  for (const p of PAGES) {
    await page.evaluate((id) => { location.hash = '#' + id; }, p);
    await new Promise((r) => setTimeout(r, 220));
    const over = await page.evaluate(() => {
      const de = document.documentElement;
      const wide = [...document.querySelectorAll('.quiz, .matcher, .quiz-option, .mcard, .mzone')]
        .filter((el) => el.scrollWidth - el.clientWidth > 1)
        .map((el) => el.className + ' by ' + (el.scrollWidth - el.clientWidth) + 'px');
      return { doc: de.scrollWidth - de.clientWidth, wide: wide.slice(0, 3) };
    });
    note(over.doc <= 0 && over.wide.length === 0,
      `${width}px #${p} no horizontal overflow${over.wide.length ? ' — ' + over.wide.join('; ') : ''}`);
  }
}

/* ---------------------------------------------------- console cleanliness */
console.log('\nconsole');
const realErrors = consoleErrors.filter((e) => !/sql-wasm|jsdelivr|net::ERR|Failed to load resource/i.test(e));
realErrors.forEach((e) => note(false, 'console: ' + e));
note(realErrors.length === 0, `no page/script errors (${consoleErrors.length} suppressed network/CDN messages)`);

await browser.close();

console.log(`\n${fails.length ? '✗ ' + fails.length + ' FAILURES' : '✓ all checks passed'}`);
process.exit(fails.length ? 1 : 0);
