# Module 4 — Single-Table Queries

Every SQL statement from Module 4, extracted from the course page (`db.html`) and the sandbox seed
databases, as plain `.sql` files you can run outside the browser.

Use these when you want a real client — `sqlite3`, MySQL Workbench, DBeaver, VS Code — instead of
the in-page sandbox, or when you want the whole module's SQL in one place to study or grade from.

These files carry the page's **line-by-line commentary**: every clause is explained on its own
comment line directly above the code it describes. The Module 5 labs are built the same way.

---

## Start here

```bash
# 1. build a fresh database with the KimTay tables and sample rows
sqlite3 module4.db < 00-setup-kimtay.sql

# 2. work through a lesson file
sqlite3 module4.db < 01-simple-queries.sql

# or open the database and paste statements one at a time
sqlite3 module4.db
```

Run a setup file **first, into an empty database**. The lesson files only query; they never create
the tables they read.

MySQL works the same way — `CREATE DATABASE`, `USE`, then run the same setup file. The one caveat is
in "Engine differences" below.

---

## The files

| File | What it holds |
|---|---|
| `00-setup-kimtay.sql` | KimTay Pet Supplies: `REP`, `CUSTOMER`, `ITEM`, `INVOICES`, `INVOICE_LINE` |
| `00-setup-staywell.sql` | StayWell: `MANAGER`, `PROPERTY`, `ROOM`, `STUDENT`, `LEASE`, `PAYMENT` |
| `00-setup-both.sql` | Both case databases in one file |
| `01-simple-queries.sql` | Section 4-1 — `SELECT`, `FROM`, `WHERE`, comparison and compound conditions |
| `02-sorting.sql` | Section 4-2 — `ORDER BY`, multiple sort keys, `ASC` / `DESC` |
| `03-functions.sql` | Section 4-3 — `COUNT`, `SUM`, `AVG`, `MAX`, `MIN`, `DISTINCT` |
| `04-nesting-queries.sql` | Section 4-4 — subqueries in `WHERE`, `IN`, correlated ideas |
| `05-grouping.sql` | Section 4-5 — `GROUP BY`, `HAVING`, and why `WHERE` cannot hold an aggregate |
| `06-nulls.sql` | Section 4-6 — `IS NULL`, `IS NOT NULL`, how nulls behave in comparisons |
| `07-clause-summary.sql` | Section 4-7 — the clause-order summary |
| `08-review-and-cases.sql` | Module summary, key terms, review questions, case exercises |
| `90-exercise-solutions.sql` | Finished query for all 20 sandbox exercises, with the starter each began from |
| `91-verification-queries.sql` | All 219 statements the module asserts a result for, each with its expected result as a comment |

Numbered files are meant to be read in order. `00-` files are setup, `90-`/`91-` are reference.

Inside each lesson file:

- **`-- Example 4-1.3`** — a statement shown in the lesson. Run it and read the output.
- **`-- >>> EXERCISE n`** — a starter query from a live sandbox. Edit it to answer the question, then
  re-run. The hint from the page is included as a comment.

---

## Statements that are supposed to fail

Seven statements across the module are **deliberately invalid**. The lesson uses the error message
itself to teach something — that unquoted text is read as a column name, that an aggregate cannot
appear in `WHERE`, that a subquery after `IN` must return exactly one column.

They are marked in place:

```sql
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
```

Run them, read the error, and leave them alone. All seven appear in `91-verification-queries.sql`
with the exact error text both engines produce; one of them is also a lesson example, so it appears
again in `04-nesting-queries.sql`.

The `sqlite3` CLI prints each error and keeps going, so these files still run straight through — you
just see the error text in place, and the command exits non-zero at the end. Running
`91-verification-queries.sql` against a freshly seeded database prints exactly seven errors and
nothing else. If you pass `-bail`, sqlite3 stops at the first one instead.

---

## Engine differences

The course teaches MySQL-flavoured SQL, and Module 4 is almost entirely portable. Two differences
show up in this module and are called out where they matter:

- **Trailing zeros.** MySQL prints `42.50`; SQLite prints `42.5`. Same stored value, different
  display. This affects a lot of expected results in `91-verification-queries.sql`.
- **`COUNT(DISTINCT a, b)`.** MySQL accepts multiple columns; SQLite raises
  *wrong number of arguments*. The lesson names this as an engine difference rather than offering it
  as a working example.

Everything else in Module 4 runs identically in both.

---

## Where this came from

Generated from the course page itself, so it stays in step with the site:

- statements and commentary — the Module 4 section of `db.html` (65 lesson examples, 20 sandbox
  exercises)
- expected results — `sqlChecks` in `content/module4.json` (219 checks)
- table definitions and sample rows — `window.SANDBOX_SEEDS` in `db.html`

Regenerate with:

```bash
python3 tools/gen-module-labs.py module4
```

It is idempotent — running it against an unchanged page reproduces these files byte for byte. The
`00-*.sql` setup files are the seed databases and are not regenerated.

Every statement meant to succeed was executed against SQLite 3.51 and passes. The only failures are
the intentional ones listed above: one in `04-nesting-queries.sql` and seven in
`91-verification-queries.sql`. Statements marked INTENTIONALLY INVALID are marked by observed
behaviour — the generator runs each one — so the marker count and the error count always agree.

One query the earlier hand-built version of these labs carried twice, as both a lesson example and an
exercise solution, now appears only as the solution: the page has it as a sandbox and not as a code
block. Nothing is lost.
