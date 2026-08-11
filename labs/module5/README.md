# Module 5 — Multiple-Table Queries

Every SQL statement from Module 5, extracted from the course page (`db.html`) and the sandbox seed
databases, as plain `.sql` files you can run outside the browser.

Use these when you want a real client — `sqlite3`, MySQL Workbench, DBeaver, VS Code — instead of
the in-page sandbox, or when you want the whole module's SQL in one place to study or grade from.

These files carry the page's **line-by-line commentary**: every clause is explained on its own
comment line directly above the code it describes. The Module 4 labs are built the same way.

---

## Start here

```bash
# 1. build a fresh database with both case databases
sqlite3 module5.db < 00-setup-both.sql

# 2. work through a lesson file
sqlite3 module5.db < 01-querying-multiple-tables.sql

# or open the database and paste statements one at a time
sqlite3 module5.db
```

Run a setup file **first, into an empty database**. The lesson files only query; they never create
the tables they read.

Module 5 joins tables from both case databases, and three exercises use StayWell while most use
KimTay, so `00-setup-both.sql` is the one to load unless you have a reason not to.

MySQL works the same way — `CREATE DATABASE`, `USE`, then run the same setup file. The caveats are
in "Engine differences" below, and they matter more in this module than in Module 4.

---

## The files

| File | What it holds |
|---|---|
| `00-setup-kimtay.sql` | KimTay Pet Supplies: `REP`, `CUSTOMER`, `ITEM`, `INVOICES`, `INVOICE_LINE` |
| `00-setup-staywell.sql` | StayWell: `MANAGER`, `PROPERTY`, `ROOM`, `STUDENT`, `LEASE`, `PAYMENT` |
| `00-setup-both.sql` | Both case databases in one file |
| `01-querying-multiple-tables.sql` | Section 5-1 — the join, matching conditions, filtered and grouped joins |
| `02-joins-in-exists.sql` | Section 5-2 — `IN`, `EXISTS`, `NOT EXISTS`, correlated subqueries, nested subqueries |
| `03-aliases-and-self-joins.sql` | Sections 5-2e to 5-2h — aliases, self-joins, joining several tables |
| `04-set-operations.sql` | Section 5-3 — `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT`, union compatibility |
| `05-all-and-any.sql` | Section 5-4 — `ALL` and `ANY`, and the `MAX`/`MIN` rewrites that run everywhere |
| `06-special-operations.sql` | Section 5-5 — inner join, outer joins, the product |
| `07-review-and-cases.sql` | Module summary, key terms, review questions, case exercises |
| `90-exercise-solutions.sql` | Finished query for all 30 sandbox exercises, with the starter each began from |
| `91-verification-queries.sql` | All 123 statements the module asserts a result for, each with its expected result as a comment |

Numbered files are meant to be read in order. `00-` files are setup, `90-`/`91-` are reference.

Inside each lesson file:

- **`-- Example 5-1.3`** — a statement shown in the lesson, with its commentary. Run it and read the
  output.
- **`-- >>> EXERCISE n`** — a starter query from a live sandbox. Edit it to answer the question, then
  re-run. The hint from the page is included as a comment.

---

## Unfinished starters

Module 5 leans on fill-in-the-blank exercises far more than Module 4 did. Thirteen of the thirty
starters are **deliberately incomplete** — they contain a `___` blank, or stop mid-statement waiting
for you to add the `INTERSECT` half or the `ON` condition.

Those starters cannot run as written, so they are commented out in the lesson files:

```sql
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
```

That is the exercise, not a defect. Uncomment, finish the statement, and run it. The finished
version is in `90-exercise-solutions.sql`.

---

## Statements that are supposed to fail

Five lesson examples across the module are **deliberately invalid**. The lesson uses the error
message itself to teach something — that a table name is unusable once you alias it, that a column
present in two copies of a table is ambiguous, that both halves of a `UNION` need the same number of
columns, and that SQLite has no `ALL`/`ANY` subquery comparison.

They are marked in place:

```sql
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
```

Run them, read the error, and leave them alone. Sixteen statements in
`91-verification-queries.sql` are invalid for the same reasons and carry the same marker.

The `sqlite3` CLI prints each error and keeps going, so these files still run straight through — you
just see the error text in place, and the command exits non-zero at the end. Against a freshly
seeded database the counts are exactly:

| File | Errors expected |
|---|---|
| `01`, `02`, `06`, `07`, `90` | 0 |
| `03-aliases-and-self-joins.sql` | 2 |
| `04-set-operations.sql` | 1 |
| `05-all-and-any.sql` | 2 |
| `91-verification-queries.sql` | 16 |

Anything else is a real problem. If you pass `-bail`, sqlite3 stops at the first error instead.

---

## Engine differences

Module 5 is the least portable module in the course, because the set operations and the quantified
comparisons are exactly where the engines disagree.

- **`ALL` and `ANY` do not exist in SQLite.** `BALANCE > ALL (SELECT ...)` is a syntax error here and
  ordinary SQL in MySQL and Oracle. The lesson shows both the MySQL form and the rewrite that runs
  everywhere — `> ALL` becomes `> (SELECT MAX(...))`, `> ANY` becomes `> (SELECT MIN(...))`. Only the
  rewrites are runnable in these files; the originals are marked invalid.
- **Oracle spells `EXCEPT` as `MINUS`.** Same meaning, same sensitivity to operand order. Oracle 21c
  added `EXCEPT` too, but `MINUS` is what you will meet in most Oracle code.
- **`FULL OUTER JOIN` needs SQLite 3.39 or newer** (released 2022). It is used in one exercise, and it
  runs on the version below. On an older SQLite it is a syntax error; MySQL 8.0 does not support it
  at all, and the usual workaround is a `LEFT JOIN` unioned with a `RIGHT JOIN`.
- **Trailing zeros.** MySQL prints `42.50`; SQLite prints `42.5`. Same stored value, different
  display. This affects a lot of expected results in `91-verification-queries.sql`.

Everything else in Module 5 — joins, `IN`, `EXISTS`, aliases, self-joins, `UNION`, `INTERSECT`,
`LEFT JOIN` — runs identically in both.

---

## Where this came from

Generated from the course page itself:

- statements and commentary — the Module 5 section of `db.html` (37 lesson examples, 30 sandbox
  exercises)
- expected results — `sqlChecks` in `content/module5.json` (123 checks)
- table definitions and sample rows — `window.SANDBOX_SEEDS` in `db.html`

**Note on the source.** These read `db.html`, which is where the line-by-line commentary was first
written. It has since been backfilled into `content/module5.json`, so the two sources agree on every
statement *and* every comment.

Regenerate with:

```bash
python3 tools/gen-module-labs.py module5
```

It is idempotent — running it against an unchanged page reproduces these files byte for byte. The
`00-*.sql` setup files are copied from `labs/module4/` and are not regenerated.

Every statement meant to succeed was executed against SQLite 3.51 and passes. The only failures are
the intentional ones listed above.
