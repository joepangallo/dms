# Module 9 — Connecting Python to MySQL: Parameterized CRUD, an API, and Migrations

A small, real Python application that talks to the same **KimTay Pet Supplies** database Module 8
built stored procedures against — except this time the client is a Python program instead of a SQL
client, the queries are built with the driver's own placeholder syntax instead of hand-typed SQL, and
change to the schema itself is tracked as a numbered migration instead of a one-off `ALTER TABLE` you
have to remember you already ran.

This is where the course's two halves meet: Module 8 taught you what a database does when a program
sends it SQL (stored procedures, cursors, error handling, all from *inside* the engine). Module 9
teaches the other side of that same conversation — what the program sending the SQL has to get right,
and specifically, why it has to get parameterization right or the entire security model of the
database underneath it stops mattering.

---

## Start here

**Prerequisite:** a real MySQL server with Module 8's `00-setup-both.sql` already run against it, into
a database you can point this module at (the examples below assume it's named `practice_db`, matching
`.env.example` — any name works as long as `.env` says the same one). This module reads and writes the
`ITEM` table that setup file creates; nothing here creates its own tables.

```bash
# 1. from labs/module9/, create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate            # Windows: .venv\Scripts\activate

# 2. install the runtime dependencies (add requirements-dev.txt to also run the tests)
pip install -r requirements.txt
pip install -r requirements-dev.txt

# 3. copy the credential template and fill in real values
cp .env.example .env
# then edit .env — see "Use a least-privilege database user" below before you fill in DB_USER

# 4. apply the one schema migration this module ships (adds ITEM.NOTES)
python3 migrations/migrate.py

# 5. try the CRUD functions and the injection demo directly
python3 injection_demo.py

# 6. run the API
flask --app api run --debug
# in another terminal:
curl http://127.0.0.1:5000/items
curl http://127.0.0.1:5000/items/DG04

# 7. run the automated test suite (fully mocked — no live database needed for this step)
pytest
```

`.env` is never committed — it holds a real password, this repository is public, and `.gitignore` was
updated alongside this module specifically so that mistake isn't possible by accident. Only
`.env.example`, which holds placeholders, is tracked.

---

## The files

| File | What it holds |
|---|---|
| `db.py` | `get_connection()` — loads `DB_HOST`/`DB_PORT`/`DB_USER`/`DB_PASSWORD`/`DB_NAME` from `.env` and the environment, fails closed (raises, naming the missing variable) rather than defaulting, returns a `mysql.connector` connection |
| `crud.py` | Parameterized `create_item` / `get_item` / `list_items` / `update_item_price` / `delete_item` against `ITEM` — every value travels through a `%s` placeholder, never string-built into the SQL text |
| `injection_demo.py` | A manually-run classroom script (not a test) proving the difference between a parameterized lookup and a string-built one, with a real injection payload |
| `api.py` | A minimal Flask CRUD API wrapping `crud.py` — `GET`/`POST` `/items`, `GET`/`PUT`/`DELETE` `/items/<item_id>` — with input validation before any database call and no raw driver errors ever returned to a client |
| `migrations/0001_add_item_notes_column.sql` | The one schema change this module ships: a nullable `NOTES VARCHAR(200)` column on `ITEM` |
| `migrations/migrate.py` | A dependency-free migration runner — tracks applied migrations in a `schema_migrations` table, applies whatever's pending, skips what's already run, safe to run repeatedly |
| `requirements.txt` / `requirements-dev.txt` | Runtime dependencies, and the same plus `pytest` for the test suite |
| `.env.example` | The credential template to copy to `.env` — placeholders only, never real values |

---

## Use a least-privilege database user

The "Start here" walkthrough above works fine with whatever MySQL account you already used to run
Module 8's `00-setup-both.sql` — that's a reasonable first pass through this module on a personal
sandbox. Before pointing this module (or anything like it) at a database anyone else depends on, though,
read this section.

`.env.example` calls this out in a comment, but it deserves more than a comment: **do not point
`DB_USER` at `root`** beyond a throwaway sandbox on your own machine that nothing else depends on. A
web application — and this module's `api.py` is a small one — only ever needs to run `SELECT`,
`INSERT`, `UPDATE`, and `DELETE` against one database. The `root` account can do that *and* create and
drop any database on the server, create and delete other users, and change server configuration. If
this application (or a bug in it, or an attacker who finds one) ever does something it shouldn't, the
account it's running as is the only thing standing between "one bad `DELETE`" and "the whole server."
Handing an app more privilege than its job requires doesn't make it more capable of doing its job — it
only makes a mistake, or a successful attack, more expensive when it happens. This is the same
principle Module 8's `GRANT`/`CREATE USER` material introduced from the SQL side; here it's the reason
your `.env` file should point at a dedicated account, not the same lesson repeated for its own sake.

A minimal user for this module, run once as an admin:

```sql
CREATE USER 'module9_app'@'localhost' IDENTIFIED BY 'choose-a-real-password-here';
GRANT SELECT, INSERT, UPDATE, DELETE ON practice_db.ITEM TO 'module9_app'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON practice_db.schema_migrations TO 'module9_app'@'localhost';
FLUSH PRIVILEGES;
```

Notice this account cannot run `migrations/migrate.py`'s `ALTER TABLE` or `CREATE TABLE IF NOT EXISTS`
— schema changes need `ALTER`/`CREATE` privileges the running application itself should not have day to
day. In a real deployment, migrations run under a separate, more-privileged account (often by a human,
or by a deploy pipeline, but not by the same credential the live application uses); this module keeps
one `.env` for simplicity, but knowing that split exists — and why — is the actual lesson.

---

## What this module intentionally does not do

- **`api.py` has no authentication.** Every route is open to anyone who can reach the port. That's an
  acceptable trade for a local sandbox where the only thing on the other end is you and `curl`; it is
  not acceptable anywhere network-reachable. Do not deploy it as written.
- **No down-migrations.** `migrations/migrate.py` only ever moves forward. Undoing
  `0001_add_item_notes_column.sql` is a second, hand-written migration that drops the column — the same
  way a real migration tool would have you fix a mistake, rather than a magic "undo" this runner
  doesn't attempt to provide.
- **One connection per request, not a pool.** `api.py` opens a fresh `mysql.connector` connection for
  each incoming request and closes it when the request ends. That's the right amount of complexity for
  a teaching app handling one request at a time; a real service under real concurrent load would reach
  for a connection pool instead, at the cost of more moving parts than this lab needs.
- **MySQL's DDL commits immediately, migration or not.** `CREATE TABLE` and `ALTER TABLE` take effect
  the instant they run, regardless of any transaction wrapped around them. `migrations/migrate.py`
  documents this honestly rather than pretending the runner has an atomic all-or-nothing story it
  doesn't actually have — see the comment above `apply_migrations`.
- **`injection_demo.py` needs a live database and is not run by the test suite.** It is a classroom
  demonstration meant to be read and run by hand, not an automated check. The test suite for this
  module runs against fully mocked connections, per this repo's rule that tests never require a real
  external service.

---

## Where this came from

Hand-written for this module's topic — Python/MySQL connectivity, secure query construction, a CRUD
API, and schema migrations — the same way `labs/module8/12-postgres-procedures.sql` and
`labs/module8/13-mysql-port-of-8.8-8.9.sql` are hand-written rather than generated from `db.html`.
There is no Module 9 section on the course page (`db.html`) for `tools/gen-module-labs.py` to read, so
nothing here is regenerated from it and there is nothing to keep in sync.

`ITEM` is the CRUD target because it's the one KimTay table with exactly the shape this lesson needs: a
single dependent table (`INVOICE_LINE`), no dependents of its own, and a seeded row (`DG04`) that's
already referenced by an invoice line. That means `delete_item("DG04")` fails with a foreign-key
conflict on the very first try, for the identical reason `09-tsql-sql-server.sql`'s `DELETE_ITEM`
procedure and its MySQL port in `13-mysql-port-of-8.8-8.9.sql` do — this module's `crud.delete_item` is
the Python-side mirror of that exact lesson, right down to catching the same MySQL error (1451) the SQL
versions do.

Every piece of this module was run for real — a live MySQL 9.7 server, a dedicated least-privilege
`module9_app` user, the actual Flask API driven with `curl`, and `migrations/migrate.py` executed twice
in a row to confirm the second run is a genuine no-op — not just reasoned about, the same standard of
proof `12-postgres-procedures.sql` holds itself to. That live run is what caught the one thing the fully
mocked `pytest` suite structurally could not: `migrations/migrate.py` originally ran a migration file
with `cursor.execute(sql_text, multi=True)`, which is real, documented mysql-connector-python API — but
only under its pure-Python connection implementation. The C-extension implementation `pip install
mysql-connector-python` actually gives you raises `NotImplementedError` on both `multi=True` and the
connection-level `cmd_query_iter()` fallback. Fifty-seven passing mocked tests never noticed, because
every one of them replaced `cursor.execute` with a mock before this ever mattered — mocking the driver
verifies your code calls the driver correctly by *your* model of its behavior, not that your model of
its behavior is still true. The fix was to split a migration file on `;` and run each non-empty
statement through a plain `cursor.execute()` — documented in `migrate.py` itself, right down to the
honest limitation that trade leaves behind (a semicolon inside a string literal or a stored-procedure
body would split in the wrong place; a migration needing one belongs in its own hand-run file, the way
Module 8's `DELIMITER` material already teaches, not through this runner).
