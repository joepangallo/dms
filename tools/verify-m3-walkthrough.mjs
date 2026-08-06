#!/usr/bin/env node
/* Headless verification of the Module 3 walkthrough: the visible "Starting
   data" rack that replaced the dataset dropdown, and the step-by-step runner
   that walks a script one statement at a time.

   Drives a real browser against the real sql.js engine, so every assertion
   here is about what a student would actually see on screen.
   Exits non-zero on any failure. */

import { createRequire } from 'node:module';
const require_ = createRequire('/Users/joepangallo/.nvm/versions/node/v24.11.1/lib/node_modules/md-to-pdf/package.json');
const puppeteer = require_('puppeteer');

const PAGE = new URL('../db.html', import.meta.url).href;
const fails = [];
const note = (ok, msg) => { console.log(`${ok ? '  ok  ' : '  FAIL'} ${msg}`); if (!ok) fails.push(msg); };

const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox'] });
const page = await browser.newPage();

const pageErrors = [];
page.on('console', (m) => { if (m.type() === 'error') pageErrors.push(m.text()); });
page.on('pageerror', (e) => pageErrors.push('pageerror: ' + e.message));

await page.setViewport({ width: 1280, height: 950 });
await page.goto(PAGE, { waitUntil: 'domcontentloaded' });
await new Promise((r) => setTimeout(r, 900));
await page.evaluate(() => { location.hash = '#module3'; });
await new Promise((r) => setTimeout(r, 700));

/* ------------------------------------------------- 1. the dataset rack */
console.log('\nstarting-data rack');
const rack = await page.evaluate(() => {
  const boxes = [...document.querySelectorAll('#module3 .sandbox')];
  return {
    total: boxes.length,
    withRack: boxes.filter((b) => b.querySelector('.sandbox-datasets')).length,
    selectHidden: boxes.every((b) => {
      const sel = b.querySelector('.sandbox-load');
      return !sel || getComputedStyle(sel).display === 'none';
    }),
    cardCounts: [...new Set(boxes.map((b) => b.querySelectorAll('.ds-card').length))],
    activeMatchesSeed: boxes.every((b) => {
      const active = b.querySelector('.ds-card.is-active');
      return active && active.getAttribute('data-seed-key') === (b.getAttribute('data-seed') || 'empty');
    }),
    exactlyOneActive: boxes.every((b) => b.querySelectorAll('.ds-card.is-active').length === 1),
    ariaPressed: boxes.every((b) => [...b.querySelectorAll('.ds-card')]
      .every((c) => c.getAttribute('aria-pressed') === (c.classList.contains('is-active') ? 'true' : 'false'))),
    everyCardHasDesc: boxes.every((b) => [...b.querySelectorAll('.ds-card')]
      .every((c) => (c.querySelector('.ds-desc')?.textContent || '').trim().length > 5)),
    /* No lab-only Module 2 datasets leaked into the Module 3 rack. */
    noLabSeeds: boxes.every((b) => ![...b.querySelectorAll('.ds-card')]
      .some((c) => /flat|_1nf|_2nf|_3nf|sheet/.test(c.getAttribute('data-seed-key')))),
    module2Untouched: document.querySelectorAll('#module2 .sandbox-datasets').length,
    module2SelectVisible: [...document.querySelectorAll('#module2 .sandbox-load')]
      .every((s) => getComputedStyle(s).display !== 'none'),
  };
});
note(rack.total === 11, `11 Module 3 sandboxes found (${rack.total})`);
note(rack.withRack === rack.total, `every sandbox has a visible dataset rack (${rack.withRack}/${rack.total})`);
note(rack.selectHidden, 'the old <select> is hidden in Module 3');
note(rack.cardCounts.length === 1 && rack.cardCounts[0] === 7, `7 dataset cards per sandbox (${rack.cardCounts})`);
note(rack.activeMatchesSeed, "each rack's active card matches that lesson's data-seed");
note(rack.exactlyOneActive, 'exactly one active card per rack');
note(rack.ariaPressed, 'aria-pressed tracks the active card');
note(rack.everyCardHasDesc, 'every card carries a plain-English description');
note(rack.noLabSeeds, 'Module 2 normalization-lab datasets stay out of Module 3');
note(rack.module2Untouched === 0, 'Module 2 sandboxes are unchanged');
note(rack.module2SelectVisible, 'Module 2 keeps its dropdown');

/* ------------------------------------------- 2. the step plan is drawn */
console.log('\nstep plan (drawn before anything runs)');
const plan = await page.evaluate(() => {
  const boxes = [...document.querySelectorAll('#module3 .sandbox')];
  return boxes.map((b, i) => {
    const p = b.querySelector('.sandbox-steps');
    return {
      i,
      seed: b.getAttribute('data-seed'),
      hidden: !p || p.hidden,
      rows: p ? p.querySelectorAll('.step-row').length : 0,
      badge: p ? (p.querySelector('.panel-badge')?.textContent || '') : '',
      current: p ? p.querySelectorAll('.step-row.is-current').length : 0,
      done: p ? p.querySelectorAll('.step-row.is-done').length : 0,
    };
  });
});
const shown = plan.filter((p) => !p.hidden);
note(shown.length > 0, `${shown.length} of ${plan.length} sandboxes show a step rail (multi-statement scripts)`);
note(plan.filter((p) => p.hidden).length > 0, `${plan.filter((p) => p.hidden).length} single-statement sandboxes hide it`);
note(shown.every((p) => p.rows >= 2), 'every visible rail lists at least 2 steps');
note(shown.every((p) => p.rows === Number((p.badge.match(/^(\d+)/) || [])[1])), 'badge count matches the rows drawn');
note(shown.every((p) => p.current === 1 && p.done === 0), 'each rail starts at step 1 with nothing done');
console.log('   rails:', shown.map((p) => `#${p.i}(${p.seed}):${p.rows}`).join(' '));

/* --------------------------------- 3. drive the biggest script one step
      at a time and prove the database really changes between steps */
console.log('\nstepping through a real script');
const target = shown.slice().sort((a, b) => b.rows - a.rows)[0];
console.log(`   using sandbox #${target.i} (${target.seed}) with ${target.rows} steps`);

const step = await page.evaluate(async (idx) => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const box = document.querySelectorAll('#module3 .sandbox')[idx];
  box.scrollIntoView();
  await box._ensureSqlBoot();
  await sleep(400);

  const panel = box.querySelector('.sandbox-steps');
  const out = box.querySelector('.sandbox-output');
  const stepBtn = panel.querySelector('.walk-step');
  const backBtn = panel.querySelector('.walk-back');
  const restBtn = panel.querySelector('.walk-rest');
  const restartBtn = panel.querySelector('.walk-restart');
  const chipText = () => [...box.querySelectorAll('.schema-chip')].map((c) => c.textContent).join(' | ');
  const log = {};

  log.startLabel = stepBtn.textContent;
  log.backDisabledAtStart = backBtn.disabled;
  log.chipsBefore = chipText();
  log.blocksBefore = out.querySelectorAll('[data-walk-step]').length;

  stepBtn.click(); await sleep(250);
  log.afterStep1 = {
    label: stepBtn.textContent,
    blocks: out.querySelectorAll('[data-walk-step]').length,
    done: panel.querySelectorAll('.step-row.is-done').length,
    current: panel.querySelectorAll('.step-row.is-current').length,
    latest: out.querySelectorAll('.stmt-block.is-latest').length,
    head: out.querySelector('[data-walk-step] .stmt-head')?.textContent || '',
    backDisabled: backBtn.disabled,
    status: panel.querySelector('.steps-status').textContent,
    chips: chipText(),
  };

  stepBtn.click(); await sleep(250);
  log.afterStep2 = {
    blocks: out.querySelectorAll('[data-walk-step]').length,
    done: panel.querySelectorAll('.step-row.is-done').length,
    chips: chipText(),
  };

  backBtn.click(); await sleep(250);
  log.afterBack = {
    blocks: out.querySelectorAll('[data-walk-step]').length,
    done: panel.querySelectorAll('.step-row.is-done').length,
    chips: chipText(),
    label: stepBtn.textContent,
  };

  restBtn.click(); await sleep(1200);
  log.afterRest = {
    blocks: out.querySelectorAll('[data-walk-step]').length,
    done: panel.querySelectorAll('.step-row.is-done').length,
    rows: panel.querySelectorAll('.step-row').length,
    stepDisabled: stepBtn.disabled,
    restDisabled: restBtn.disabled,
    label: stepBtn.textContent,
    status: panel.querySelector('.steps-status').textContent,
    chips: chipText(),
    errorRows: panel.querySelectorAll('.step-row.is-error').length,
  };

  restartBtn.click(); await sleep(500);
  log.afterRestart = {
    blocks: out.querySelectorAll('[data-walk-step]').length,
    done: panel.querySelectorAll('.step-row.is-done').length,
    current: panel.querySelectorAll('.step-row.is-current').length,
    label: stepBtn.textContent,
    chips: chipText(),
  };
  return log;
}, target.i);

note(/Run step 1/.test(step.startLabel), `Step button starts as "${step.startLabel}"`);
note(step.backDisabledAtStart, 'Back is disabled before anything runs');
note(step.blocksBefore === 0, 'no transcript blocks before the first step');
note(step.afterStep1.blocks >= 1, 'step 1 appends its own result block');
note(step.afterStep1.done === 1 && step.afterStep1.current === 1, 'step 1 marked done, step 2 becomes current');
note(/^Step 1 of /.test(step.afterStep1.head), `the block is labelled "${step.afterStep1.head}"`);
note(step.afterStep1.latest === 1, 'exactly one block is ringed as the newest');
note(!step.afterStep1.backDisabled, 'Back becomes available after step 1');
note(/Step 1 done/.test(step.afterStep1.status), `status reads "${step.afterStep1.status.slice(0, 60)}..."`);
note(/Run step 2/.test(step.afterStep1.label), 'the button now offers step 2');
note(step.afterStep2.done === 2, 'step 2 runs and is marked done');
note(step.afterBack.done === 1, 'Back returns the rail to one completed step');
note(step.afterBack.blocks < step.afterStep2.blocks, 'Back removes the undone step\'s block from the transcript');
note(step.afterBack.chips === step.afterStep1.chips, 'Back restores the database to its state after step 1');
note(step.afterRest.done === step.afterRest.rows, `Run the rest completes all ${step.afterRest.rows} steps`);
note(step.afterRest.errorRows === 0, 'no step errored while walking the script');
note(step.afterRest.stepDisabled && step.afterRest.restDisabled, 'both run controls disable at the end');
note(/All \d+ steps run/.test(step.afterRest.label), `end state reads "${step.afterRest.label}"`);
note(step.afterRest.chips !== step.chipsBefore, 'the table strip really changed as the script ran');
note(step.afterRestart.done === 0 && step.afterRestart.current === 1, 'Restart returns to step 1');
note(step.afterRestart.blocks === 0, 'Restart clears the transcript');
note(step.afterRestart.chips === step.chipsBefore, 'Restart rebuilds the original starting data');

/* ------------------------------------ 4. clicking a dataset card works */
console.log('\ndataset cards actually load data');
const ds = await page.evaluate(async (idx) => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const box = document.querySelectorAll('#module3 .sandbox')[idx];
  await box._ensureSqlBoot();
  await sleep(300);
  const chipText = () => [...box.querySelectorAll('.schema-chip')].map((c) => c.textContent).join(' | ');
  const before = chipText();
  const card = box.querySelector('.ds-card[data-seed-key="both_full"]');
  card.click();
  await sleep(700);
  return {
    before,
    after: chipText(),
    activeKey: box.querySelector('.ds-card.is-active')?.getAttribute('data-seed-key'),
    selectValue: box.querySelector('.sandbox-load').value,
    activeCount: box.querySelectorAll('.ds-card.is-active').length,
    tables: box.querySelectorAll('.schema-chip').length,
    status: box.querySelector('.steps-status')?.textContent || '',
    hint: box.querySelector('.sandbox-hint')?.textContent || '',
  };
}, target.i);
note(ds.activeKey === 'both_full', 'clicking a card moves the active highlight');
note(ds.activeCount === 1, 'still exactly one active card');
note(ds.selectValue === 'both_full', 'the hidden <select> stays in sync (Reset/Download still work)');
note(ds.tables === 11, `KimTay + StayWell loads 11 tables (${ds.tables})`);
note(ds.after !== ds.before, 'the table strip updated to the new dataset');
note(!/from the menu/i.test(ds.hint), 'hint text no longer points at a dropdown that is not there');

/* --------------------------------------- 5. error handling mid-script */
console.log('\na broken statement holds the walkthrough');
const err = await page.evaluate(async (idx) => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const box = document.querySelectorAll('#module3 .sandbox')[idx];
  const editor = box.querySelector('.sandbox-editor');
  const panel = box.querySelector('.sandbox-steps');
  const out = box.querySelector('.sandbox-output');
  const stepBtn = panel.querySelector('.walk-step');

  editor.value = "CREATE TABLE T1 (A INT);\nSELECT * FROM NOPE;\nINSERT INTO T1 VALUES (1);";
  editor.dispatchEvent(new Event('input', { bubbles: true }));
  await sleep(120);
  const planned = panel.querySelectorAll('.step-row').length;

  stepBtn.click(); await sleep(250);
  stepBtn.click(); await sleep(250);
  return {
    planned,
    errorRows: panel.querySelectorAll('.step-row.is-error').length,
    done: panel.querySelectorAll('.step-row.is-done').length,
    errBlocks: out.querySelectorAll('.stmt-block.is-error').length,
    status: panel.querySelector('.steps-status').textContent,
    statusClass: panel.querySelector('.steps-status').className,
    label: stepBtn.textContent,
    backEnabled: !panel.querySelector('.walk-back').disabled,
  };
}, target.i);
note(err.planned === 3, `editing the SQL re-plans the rail (${err.planned} steps)`);
note(err.done === 1, 'the statement before the error stays done');
note(err.errorRows === 1, 'the failing step is marked as the error');
note(err.errBlocks === 1, 'an error block lands in the transcript');
note(/did not run/.test(err.status) && /is-error/.test(err.statusClass), 'the status explains the stop');
note(/Try step 2 again/.test(err.label), `the button offers a retry ("${err.label}")`);
note(err.backEnabled, 'Back is still available after a failure');

/* ------------------------------- 6. editing mid-walkthrough goes stale */
console.log('\nediting mid-walkthrough');
const stale = await page.evaluate(async (idx) => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const box = document.querySelectorAll('#module3 .sandbox')[idx];
  const editor = box.querySelector('.sandbox-editor');
  const panel = box.querySelector('.sandbox-steps');
  const stepBtn = panel.querySelector('.walk-step');

  panel.querySelector('.walk-restart').click();
  await sleep(400);
  editor.value = "CREATE TABLE A1 (X INT);\nCREATE TABLE A2 (X INT);\nCREATE TABLE A3 (X INT);";
  editor.dispatchEvent(new Event('input', { bubbles: true }));
  await sleep(120);
  stepBtn.click(); await sleep(250);          // one step in, now edit
  editor.value += "\nCREATE TABLE A4 (X INT);";
  editor.dispatchEvent(new Event('input', { bubbles: true }));
  await sleep(120);
  const staleState = {
    stepDisabled: stepBtn.disabled,
    restDisabled: panel.querySelector('.walk-rest').disabled,
    status: panel.querySelector('.steps-status').textContent,
    warn: /is-warn/.test(panel.querySelector('.steps-status').className),
  };
  panel.querySelector('.walk-restart').click();
  await sleep(500);
  return {
    ...staleState,
    afterRestartRows: panel.querySelectorAll('.step-row').length,
    afterRestartDisabled: stepBtn.disabled,
  };
}, target.i);
note(stale.stepDisabled && stale.restDisabled, 'editing mid-walkthrough freezes Step and Run the rest');
note(stale.warn && /Restart/.test(stale.status), `it says why: "${stale.status.slice(0, 70)}..."`);
note(stale.afterRestartRows === 4, 'Restart re-plans against the edited SQL (4 steps)');
note(!stale.afterRestartDisabled, 'and unfreezes the controls');

/* ---------------------------- 7. blanks exercises cannot be stepped */
console.log('\nexercises with ___ blanks');
const blanks = await page.evaluate(async (idx) => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const box = document.querySelectorAll('#module3 .sandbox')[idx];
  const editor = box.querySelector('.sandbox-editor');
  const panel = box.querySelector('.sandbox-steps');
  editor.value = "SELECT * FROM ___;\nSELECT 1;";
  editor.dispatchEvent(new Event('input', { bubbles: true }));
  await sleep(150);
  return {
    stepDisabled: panel.querySelector('.walk-step').disabled,
    status: panel.querySelector('.steps-status').textContent,
    warn: /is-warn/.test(panel.querySelector('.steps-status').className),
  };
}, target.i);
note(blanks.stepDisabled, 'Step is disabled while the exercise still has blanks');
note(blanks.warn && /blanks/.test(blanks.status), 'and the reason is on screen');

/* A refused run (the blanks are still there) must leave the rail alone
   rather than claiming the whole script is behind us. */
const refused = await page.evaluate(async (idx) => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const box = document.querySelectorAll('#module3 .sandbox')[idx];
  const panel = box.querySelector('.sandbox-steps');
  box.querySelector('.sandbox-run').click();
  await sleep(600);
  return {
    done: panel.querySelectorAll('.step-row.is-done').length,
    current: panel.querySelectorAll('.step-row.is-current').length,
    blocks: box.querySelectorAll('.sandbox-output [data-walk-step]').length,
  };
}, target.i);
note(refused.done === 0 && refused.current === 1, 'pressing Run on a blanks exercise does not mark any step done');
note(refused.blocks === 0, 'and adds nothing to the transcript');

/* ---------------------------------------- 8. Run all still works, and
      leaves the rail telling the truth about where the database is */
console.log('\nRun (all at once) still works');
const SCRIPT = "CREATE TABLE B1 (X INT);\nINSERT INTO B1 VALUES (1);\nSELECT * FROM B1;";
const runAll = await page.evaluate(async (idx, sql) => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const box = document.querySelectorAll('#module3 .sandbox')[idx];
  const panel = box.querySelector('.sandbox-steps');
  const editor = box.querySelector('.sandbox-editor');
  editor.value = sql;
  editor.dispatchEvent(new Event('input', { bubbles: true }));
  await sleep(120);
  panel.querySelector('.walk-restart').click();
  await sleep(600);
  box.querySelector('.sandbox-run').click();
  await sleep(1200);
  return {
    done: panel.querySelectorAll('.step-row.is-done').length,
    rows: panel.querySelectorAll('.step-row').length,
    status: panel.querySelector('.steps-status').textContent,
    stmtBlocks: box.querySelectorAll('.sandbox-output .stmt-block').length,
    stepDisabled: panel.querySelector('.walk-step').disabled,
    backDisabled: panel.querySelector('.walk-back').disabled,
  };
}, target.i, SCRIPT);
note(runAll.rows === 3, `the 3-statement script plans 3 steps (${runAll.rows})`);
note(runAll.done === runAll.rows && runAll.rows > 1, `Run marks all ${runAll.rows} steps done`);
note(/ran at once/.test(runAll.status), 'the rail says the script ran all at once');
note(runAll.stmtBlocks > 1, 'the all-at-once output still renders one block per statement');
note(runAll.stepDisabled && runAll.backDisabled, 'Step and Back are off after a full run (nothing to step or undo)');

/* ------------------------------------------------ 9. keyboard driving */
console.log('\nkeyboard');
const keys = await page.evaluate(async (idx, sql) => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const box = document.querySelectorAll('#module3 .sandbox')[idx];
  const panel = box.querySelector('.sandbox-steps');
  const editor = box.querySelector('.sandbox-editor');
  editor.value = sql;
  editor.dispatchEvent(new Event('input', { bubbles: true }));
  await sleep(120);
  panel.querySelector('.walk-restart').click();
  await sleep(600);
  const fire = (shift) => editor.dispatchEvent(new KeyboardEvent('keydown', {
    key: 'Enter', ctrlKey: true, shiftKey: shift, bubbles: true, cancelable: true,
  }));
  fire(true); await sleep(300);
  const oneStep = panel.querySelectorAll('.step-row.is-done').length;
  fire(true); await sleep(300);
  const twoSteps = panel.querySelectorAll('.step-row.is-done').length;
  return { oneStep, twoSteps, focusable: [...panel.querySelectorAll('.walk-btn')].every((b) => b.tagName === 'BUTTON') };
}, target.i, SCRIPT);
note(keys.oneStep === 1 && keys.twoSteps === 2, 'Ctrl+Shift+Enter advances exactly one statement per press');
note(keys.focusable, 'every walk control is a real focusable <button>');

/* --------------------------------------------- 10. layout / projection */
console.log('\nlayout');
for (const width of [1440, 1280, 900, 390]) {
  await page.setViewport({ width, height: 900 });
  await new Promise((r) => setTimeout(r, 350));
  const overflow = await page.evaluate(() => {
    const bad = [];
    document.querySelectorAll('#module3 .sandbox').forEach((b, i) => {
      if (b.scrollWidth > b.clientWidth + 2) bad.push(`sandbox #${i} overflows by ${b.scrollWidth - b.clientWidth}px`);
    });
    if (document.documentElement.scrollWidth > window.innerWidth + 2) {
      bad.push(`page overflows by ${document.documentElement.scrollWidth - window.innerWidth}px`);
    }
    return bad;
  });
  overflow.forEach((b) => note(false, `${width}px: ${b}`));
  note(overflow.length === 0, `${width}px: no horizontal overflow`);
}

/* ---------------------------------------------------- console cleanliness */
console.log('\nconsole');
const realErrors = pageErrors.filter((e) => !/favicon|net::ERR_FILE_NOT_FOUND/i.test(e));
realErrors.forEach((e) => note(false, `console error: ${e}`));
note(realErrors.length === 0, 'no page or console errors');

await browser.close();
console.log(`\n${fails.length ? `FAILED (${fails.length})` : 'ALL CHECKS PASSED'}`);
fails.forEach((f) => console.log(' - ' + f));
process.exit(fails.length ? 1 : 0);
