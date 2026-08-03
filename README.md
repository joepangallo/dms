# Database Concepts &amp; SQL — interactive course site

A single self-contained HTML file covering all eight modules of the course, built around the
**KimTay Pet Supplies** and **StayWell Student Accommodation** case databases.

Open `db.html` in a browser. No install, no server, no build step, no account.

---

## What's in it

| Module | Title | Sections |
|---|---|---|
| 1 | Introduction to the KimTay and StayWell Databases | 6 |
| 2 | Database Design Fundamentals | 10 |
| 3 | Creating Tables | 15 |
| 4 | Single-Table Queries | 11 |
| 5 | Multiple-Table Queries | 10 |
| 6 | Updating Data | 13 |
| 7 | Database Administration | 11 |
| 8 | Functions, Procedures, and Triggers | 14 |
| — | Supabase &amp; SQL on Mac and Windows | 7 |
| — | Project &amp; Setup (capstone brief) | 3 |

Roughly **287 questions across 75 quizzes**, **42 matching drills** (316 cards), **168 live SQL
sandboxes**, and 7 slider labs.

### The interactive pieces

- **Live SQL sandboxes** — SQLite compiled to WebAssembly (`sql.js`), running in the browser tab.
  Each one shows a strip of the tables currently in its database with row counts (click a table to
  query it), a menu to load KimTay, StayWell, or a blank database, and **⬇ .db / ⬆ .db** buttons to
  export the database as a real `.sqlite` file or load one back.
- **Instant-reveal quizzes** — pick an answer and the explanation opens immediately, marking your
  choice and giving a reason for *every* option, not only the right one.
- **Matching drills** — click a card, click the bucket it belongs in.
- **Slider labs** — drag a control and watch the database react: redundancy turning into
  inconsistency, a table walked from unnormalized to 3NF, `CHAR` vs `VARCHAR` storage, `DECIMAL(p,s)`
  capacity, a live `WHERE` filter, and a row-by-row `JOIN` stepper.
- **Study Mode / Present Mode** — the same content as a scrolling page or one idea per screen with
  arrow-key navigation, for projecting in class.

Progress is saved in the browser's `localStorage`, so students can close the page and come back.

---

## Repository layout

```
db.html                      the entire course site — this is the deliverable
content/                     authored source for each module, as structured JSON
  module4.json … module8.json
  modules1-3-assessments.json
  supabase.json
tools/                       maintenance scripts (Node, no dependencies to install)
  render-module.mjs          render a content JSON into db.html as a new page
  verify.mjs                 full-site check: quizzes, matchers, sandboxes, responsive, console
  sqlcheck.mjs               execute every SQL statement in a content file
  sbsim.mjs                  simulate each sandbox the way a student uses it
  rerun.mjs                  confirm every sandbox survives being run twice
```

`content/` holds what each module *says*; `db.html` is what that content was rendered into. Edit the
JSON and re-render when changing a module wholesale; edit `db.html` directly for small fixes.

---

## Working on it

The tools drive a real headless browser, so they need Puppeteer. They resolve it from the global
`md-to-pdf` install rather than requiring a local `node_modules`; if that isn't present, change the
`createRequire` path at the top of each script.

```bash
# check the whole site: structure, quizzes, matchers, seed data, responsive widths, console errors
node tools/verify.mjs

# execute every SQL statement in a module and report anything that fails
node tools/sqlcheck.mjs content/module7.json

# make sure each sandbox works the way a student uses it, and survives a second Run
node tools/sbsim.mjs content/module7.json
node tools/rerun.mjs content/module7.json

# render a new module into the site (creates the page, nav entry and TOC entry)
node tools/render-module.mjs content/module9.json module9 "Module 9" "Title" "One-line lede."
```

`verify.mjs` is the gate: it drives every quiz and matcher, runs the seeded databases through the
page's own SQL engine, and checks for horizontal overflow at 320/375/768/1280 px on every page.

---

## Notes on the SQL engine

The in-page sandbox is SQLite 3.45. Module 3 onward teaches MySQL-flavoured SQL, and most of it is
identical, but a few things differ and the course says so wherever it matters.

**Runs in the sandbox:** views (including over joins and aggregates), indexes and unique indexes,
`CHECK` and `FOREIGN KEY` constraints, `PRAGMA foreign_keys=ON` for real referential-integrity
enforcement, transactions, `ALTER TABLE`, set operations, every join type, and triggers end to end.

**Needs MySQL or Oracle, and is labelled as such in the lessons:** updating through a view, `GRANT` /
`REVOKE`, `ALTER TABLE ... ADD CONSTRAINT`, `INFORMATION_SCHEMA`, stored procedures, cursors, PL/SQL
and T-SQL, and the MySQL-only date functions (`CURDATE`, `NOW`, `YEAR`, `DATEDIFF`, `DATE_ADD`).
Where a construct can't run, the lesson gives the nearest thing that can.

The sample data is deliberately small enough to check by hand: 3 reps, 4 customers, 5 items, 3
invoices, 6 invoice lines on the KimTay side; 2 managers, 2 properties, 5 rooms, 4 students, 4 leases
and 4 payments on the StayWell side.
