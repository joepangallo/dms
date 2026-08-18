# Module 8 — SQL Inside Programs, Stored Procedures, Cursors

Every SQL statement from Module 8, extracted from the course page (`db.html`) and the sandbox seed
databases, as plain `.sql` files you can run outside the browser — plus a hand-written Postgres/PL-pgSQL
port of the procedure and cursor material, verified against a real Supabase project.

Use these when you want a real client — `sqlite3`, MySQL Workbench, DBeaver, VS Code, the Supabase SQL
Editor — instead of the in-page sandbox, or when you want the whole module's SQL in one place to study
or grade from.

These files carry the page's **line-by-line commentary**: every clause is explained on its own comment
line directly above the code it describes. Modules 4 and 5's labs are built the same way.

Module 8 is a different shape than Modules 4 and 5. Where those modules teach portable, single-engine
SQL, Module 8 teaches SQL that runs *inside a program* — embedded queries, MySQL stored procedures,
Oracle PL/SQL, and SQL Server T-SQL — and most of that code is deliberately non-portable. Read
"Engine differences" and "The Postgres/PL-pgSQL port" below before assuming a file will just run.

---

## Start here

```bash
# 1. build a fresh database with the KimTay and StayWell tables and sample rows
sqlite3 module8.db < 00-setup-both.sql

# 2. work through a lesson file
sqlite3 module8.db < 01-sql-in-programs.sql

# or open the database and paste statements one at a time
sqlite3 module8.db
```

Run `00-setup-both.sql` **first, into an empty database**. The lesson files only query and change data;
they never create the tables they read. Module 8 touches one StayWell table (`PAYMENT`, in the Case
Exercise) in addition to every KimTay table, so `00-setup-both.sql` is the setup file this module needs
— `00-setup-kimtay.sql` alone is not enough.

To work through the Postgres port instead, create a Supabase project, run `00-setup-both.sql` in the SQL
Editor, then run `12-postgres-procedures.sql`. See "The Postgres/PL-pgSQL port" below.

---

## The files

| File | What it holds |
|---|---|
| `00-setup-both.sql` | Both case databases: KimTay's `REP`, `CUSTOMER`, `ITEM`, `INVOICE`, `INVOICE_LINE` and StayWell's `MANAGER`, `PROPERTY`, `ROOM`, `STUDENT`, `LEASE`, `PAYMENT` |
| `01-sql-in-programs.sql` | Section 8-1 — embedded SQL, placeholders, a first look at a stored procedure and a trigger |
| `02-functions.sql` | Section 8-2 — `UPPER`/`LOWER`, `SUBSTR`, `LENGTH`, `TRIM`, `ROUND`, `ABS`, `CAST`, date functions |
| `03-concatenating-columns.sql` | Section 8-3 — `CONCAT`, `\|\|`, `NULL` in concatenation, `COALESCE` |
| `04-stored-procedures-mysql.sql` | Section 8-4 — `DELIMITER`, `CREATE PROCEDURE`, `IN`/`OUT` parameters, `CALL` |
| `05-error-handling.sql` | Section 8-5 — `DECLARE HANDLER`, `NOT FOUND`, `SQLEXCEPTION`, `CONTINUE` vs `EXIT` |
| `06-update-procedures.sql` | Section 8-6 — procedures that change data, transactions, `GRANT`/`CREATE USER` |
| `07-selecting-multiple-rows.sql` | Section 8-7 — cursors: `DECLARE CURSOR`, `OPEN`, `FETCH`, `LOOP`, `CLOSE` |
| `08-plsql-oracle.sql` | Section 8-8 — the same procedures and cursors, in Oracle PL/SQL |
| `09-tsql-sql-server.sql` | Section 8-9 — the same procedures and cursors, in SQL Server T-SQL |
| `10-using-a-trigger.sql` | Section 8-10 — SQLite triggers: `AFTER`/`BEFORE`, `WHEN`, `RAISE(ABORT)` |
| `11-review-and-cases.sql` | Module summary, review questions, case exercises |
| `12-postgres-procedures.sql` | **Hand-written, not regenerated.** Working PL/pgSQL translations of the MySQL/Oracle procedure and cursor material, verified live against Supabase |
| `13-mysql-port-of-8.8-8.9.sql` | **Hand-written, not regenerated.** Working MySQL translations of section 8-8's Oracle PL/SQL and 8-9's T-SQL procedure and cursor material, verified live against MySQL 9.7 |
| `90-exercise-solutions.sql` | Finished query for all 42 sandbox exercises, with the starter each began from |
| `91-verification-queries.sql` | All 134 statements the module asserts a result for, each with its expected result as a comment |

Numbered files `01`–`11` are meant to be read in order. `00-` is setup, `12-` is the Postgres port,
`90-`/`91-` are reference.

Inside each `01`–`11` lesson file:

- **`-- Example 8-N.n`** — a statement shown in the lesson. Run it and read the output.
- **`-- >>> EXERCISE n`** — a starter query from a live sandbox. Edit it to answer the question, then
  re-run. The hint from the page is included as a comment.

---

## Statements that are supposed to fail

Sixty-six statements across `01`–`11` are **deliberately invalid** — the overwhelming majority of them
because they are MySQL, Oracle, or T-SQL code that cannot run in the SQLite sandbox at all, not because
the lesson made a mistake on purpose. They are marked in place:

```sql
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
```

The marker is placed by *observed behaviour*, the same way Modules 4 and 5 do it: the generator actually
runs every statement against a fresh SQLite database and marks whichever ones raise. `sqlite3`'s CLI
prints each error and keeps going, so files `01`–`11` still run straight through — you just see the error
text in place, and the command exits non-zero at the end.

Two files are almost entirely marked this way — `04-stored-procedures-mysql.sql` (12 of 13
examples/exercises) and `05-error-handling.sql` (8 of 9) — because every procedure in them uses
`DELIMITER`, `CREATE PROCEDURE`, or `CALL`, none of which exist in SQLite. Read those two files for the
commentary; run `12-postgres-procedures.sql` to see the same procedures actually execute.

---

## Engine differences

The course teaches MySQL-flavoured SQL, and Modules 4 and 5 are almost entirely portable across engines.
Module 8 is not — it is *about* the ways engines differ, so treat every dialect-specific block as a
worked example of a difference rather than an error to fix. A few differences are worth calling out
because they are not obvious from the lesson text alone:

- **SQLite's own date functions are not portable either.** `01-sql-in-programs.sql`'s trigger example
  uses `DATE('now')` inside the trigger body — fine in SQLite, a flat syntax error in Postgres (see
  below). `02-functions.sql`'s Exercises 14, 16, 17, and 18 use `DATETIME('now')`, `DATE(col, '+15
  days')`, and `julianday()` — all three run cleanly in SQLite (so the generator does not mark them
  invalid) and all three are undefined functions in Postgres: `42883: function datetime(unknown) does
  not exist`, `42883: function date(date, unknown) does not exist`, `42883: function julianday(date)
  does not exist`. `DATE('now')` alone, with no second argument, happens to work on both engines. The
  Postgres equivalents are `now()`/`CURRENT_TIMESTAMP` for `DATETIME('now')`, `(col + INTERVAL 'n
  days')::date` for the modifier form, and plain date subtraction (`CURRENT_DATE - col`, which returns
  an integer day count directly) for `julianday()` differences.
- **`COUNT(DISTINCT a, b)`.** MySQL accepts multiple columns; SQLite raises *wrong number of arguments*.
  Postgres accepts it too, counting distinct combinations of the argument list — closer to MySQL than to
  SQLite here, though the module's own examples only use the single-column form.
- **MySQL's `SELECT ... INTO`, unhandled, is not the same bug in Postgres.** `05-error-handling.sql`'s
  whole point is that a miss leaves the target holding a *stale* value from a previous call. Tested
  directly: Postgres's plain `SELECT INTO` (no `STRICT`) resets the target to `NULL` on a miss instead —
  safer by accident, but still silent. See `12-postgres-procedures.sql` for the live comparison.

---

## The Postgres/PL-pgSQL port

`12-postgres-procedures.sql` is **hand-written, not regenerated** by `tools/gen-module-labs.py` — it
exists because most of Module 8's own code is MySQL, Oracle, or T-SQL, and none of those dialects run on
the PostgreSQL engine Supabase provides. Every procedure, cursor, and trigger in it was written, applied,
and `CALL`ed against a real Supabase (Postgres 17) project — not merely reasoned about — and where the
straightforward translation did *not* work on the first try, the file shows both the broken attempt and
the exact error Postgres raised, alongside the working fix.

### Six things Postgres does differently

1. **A stored routine cannot end in a bare `SELECT` the way MySQL's can.** MySQL streams a trailing
   `SELECT`'s result set straight back to the caller; the identical statement inside a PL/pgSQL
   *procedure* raises `42601: query has no destination for result data`. The fix is to write a
   *function* that `RETURNS TABLE` instead, and call it with `SELECT * FROM routine_name()` rather than
   `CALL`.
2. **A parameter name that collides with a column name is a silent bug in MySQL and a runtime error in
   Postgres.** `WHERE REP_NUM = REP_NUM`, with `REP_NUM` used as both a parameter and a column name,
   compiles fine on both engines. MySQL quietly matches every row. Postgres raises `42702: column
   reference "rep_num" is ambiguous` the first time the statement actually runs — worse ergonomics up
   front, a safer engine in the end.
3. **`SELECT ... INTO` needs the `STRICT` keyword to raise anything at all.** Without it, zero rows or
   several rows both pass silently — zero leaves the target `NULL` (see "Engine differences" above);
   several silently keep the first one, exactly like a bare `SELECT INTO` in SQLite's `GROUP BY`
   behaviour. `INTO STRICT` is what turns those into catchable `NO_DATA_FOUND` / `TOO_MANY_ROWS`
   exceptions — names Postgres borrowed directly from Oracle.
4. **PL/pgSQL's exception handling is exit-only; MySQL's `CONTINUE HANDLER` has no direct equivalent.**
   Catching an exception in PL/pgSQL always abandons the surrounding `BEGIN...END` block once the
   handler finishes — there is no way to resume on the very next line the way MySQL's `DECLARE CONTINUE
   HANDLER` does. To get the same "keep going after a miss" behaviour, wrap only the risky statement in
   its *own* nested block, so only that inner block is abandoned.
5. **`COMMIT`/`ROLLBACK` cannot appear inside a block that has its own `EXCEPTION` clause — including the
   procedure's outer body, if that body catches an exception.** Any block with an `EXCEPTION` clause runs
   inside an implicit subtransaction, and explicit transaction control is not allowed inside one, even
   one you never asked for. `12-postgres-procedures.sql`'s `SHIP_ITEM` and `ADD_TO_BALANCE` both hit this
   live (`2D000: cannot commit while a subtransaction is active`) on the first, literal translation
   attempt. The real fix is not to relocate the `COMMIT` — it is to drop it entirely: the `CALL`
   statement itself is already the transaction boundary, and PL/pgSQL's own nested exception blocks
   already roll back to their own savepoint the instant they catch something, which is everything MySQL's
   explicit `START TRANSACTION` / `COMMIT` / `ROLLBACK` triad was doing in the first place. (A second,
   independent restriction showed up chasing this down: a procedure that *does* keep an explicit `COMMIT`
   can only be `CALL`ed as the sole statement in its batch — pasted into a script alongside anything else,
   even a harmless `SELECT 1;`, the same `COMMIT` raises `2D000: invalid transaction termination`
   instead. `12-postgres-procedures.sql` avoids this altogether by not using `COMMIT` anywhere.)
6. **Oracle's PL/SQL is far closer to Postgres than MySQL or T-SQL are — but not identical.** `%TYPE`,
   `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `SQLERRM`, and cursor `FOR` loops all carry over close to unchanged.
   Two things do not: Oracle lets you declare your own named exception (`OVER_LIMIT EXCEPTION;`) and
   `RAISE`/catch it by name — PL/pgSQL has no equivalent, and the working substitute is a custom
   `SQLSTATE` (`RAISE EXCEPTION ... USING ERRCODE = 'P0001'`, caught with `WHEN SQLSTATE 'P0001'`).
   And Oracle's cursor `FOR` loop auto-declares its own loop record; PL/pgSQL requires that record
   declared by hand first, or it raises `42601: loop variable of loop over rows must be a record variable
   or list of scalar variables`. Oracle's *other* cursor style — explicit `OPEN`/`FETCH`/`CLOSE` with
   `%NOTFOUND`/`%ISOPEN` attributes — does not survive at all: `cursor_name%NOTFOUND` compiles with no
   complaint (PL/pgSQL has no idea it is a cursor attribute) and fails the first time it actually runs,
   with `42703: column "notfound" does not exist`. The only working substitute is PL/pgSQL's own implicit
   `FOUND` boolean, set automatically by the most recent `FETCH`.

`12-postgres-procedures.sql` is written to be pasted into the Supabase SQL Editor and run start to finish
in one click — every procedure in it avoids explicit `COMMIT`/`ROLLBACK` for exactly the reason in point 5
above, so nothing in the file requires its own separate Run. It is also idempotent: every `CREATE
PROCEDURE`/`CREATE FUNCTION` is preceded by a matching `DROP ... IF EXISTS`, and every example that
changes seeded data (a balance, a price, an item's stock) restores it before the file ends, so running it
twice in a row against the same project gives the same answers both times.

---

## Where this came from

Generated from the course page itself, so it stays in step with the site:

- statements and commentary — the Module 8 section of `db.html` (66 lesson code blocks, 42 sandbox
  exercises)
- expected results — `sqlChecks` in `content/module8.json` (134 checks, tagged by which engine each one
  actually runs on)
- table definitions and sample rows — `window.SANDBOX_SEEDS` in `db.html`

Regenerate `00-11` and `90`/`91` with:

```bash
python3 tools/gen-module-labs.py module8
```

It is idempotent — running it against an unchanged page reproduces those files byte for byte. The
`00-*.sql` setup file, `12-postgres-procedures.sql`, and `13-mysql-port-of-8.8-8.9.sql` are not touched
by the generator and are not regenerated; edit them by hand.
