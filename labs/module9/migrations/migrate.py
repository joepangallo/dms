"""
Dependency-free schema migration runner.

Tracks which migrations have already run in a schema_migrations table (one
row per applied filename), so this script is safe to run over and over --
each file in this folder is applied at most once, ever, against a given
database. That's the property that separates a real migration runner from
just handing a student a stack of .sql files to run in order by hand: nobody
has to remember which ones they've already run, and running this script
again after it's already fully caught up is a no-op rather than an error.

pending_migrations() below is kept deliberately separate from the apply
step that follows it, and does nothing but read: one SELECT against
schema_migrations, one directory listing of migrations_dir, and a set
difference between them. That split is what makes the "which migrations
are pending" logic testable with a mocked connection and a handful of
fake filenames -- no real migration files and no real database required,
because the interesting logic here is the diff, not the I/O around it.
"""

import os
import sys

# migrate.py lives in migrations/, but db.py (and its get_connection()) lives
# one level up in module9/ itself. Putting that parent directory on sys.path
# before importing it means this script works the same way whether it's run
# as `python migrations/migrate.py` from module9/, or as `python migrate.py`
# from inside migrations/ -- no PYTHONPATH to set by hand, and no need to
# turn a four-file teaching lab into an installed package just to satisfy
# Python's import system.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from db import get_connection  # noqa: E402 -- must follow the sys.path fix above

MIGRATIONS_DIR = os.path.dirname(os.path.abspath(__file__))

CREATE_TRACKING_TABLE = """
CREATE TABLE IF NOT EXISTS schema_migrations (
    filename    VARCHAR(255) PRIMARY KEY,
    applied_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
"""


def ensure_schema_migrations_table(conn):
    """Create the tracking table if it doesn't exist yet.

    IF NOT EXISTS makes this safe to call on every single run, including the
    very first one against a brand-new database that has never seen a
    migration -- there's no separate "bootstrap" step a student has to
    remember to run once, by hand, before the real migrations can start.
    """
    cursor = conn.cursor()
    try:
        cursor.execute(CREATE_TRACKING_TABLE)
        conn.commit()
    finally:
        cursor.close()


def _migration_filenames(migrations_dir):
    """The .sql files in migrations_dir, sorted by filename.

    Sorting by plain filename is why every migration is named with a
    zero-padded number prefix (0001_..., 0002_...) -- lexicographic sort
    then happens to match the order the migrations are meant to run in,
    with no separate ordering list to keep in sync with the filenames.
    """
    return sorted(
        name for name in os.listdir(migrations_dir)
        if name.endswith(".sql")
    )


def pending_migrations(conn, migrations_dir):
    """Return the filenames in migrations_dir that schema_migrations does not
    yet list, in the order they should be applied.

    Read-only on purpose: this issues one SELECT and never touches table
    creation or the migration files' own contents, so it can be unit-tested
    against a mocked connection (whose cursor.fetchall() returns whatever
    rows a test wants) and a plain temp directory holding empty placeholder
    files -- no real database and no real migration SQL required.
    """
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT filename FROM schema_migrations")
        applied = {row[0] for row in cursor.fetchall()}
    finally:
        cursor.close()

    return [
        name for name in _migration_filenames(migrations_dir)
        if name not in applied
    ]


def apply_migrations(conn, migrations_dir=MIGRATIONS_DIR):
    """Apply every pending migration in migrations_dir, in order, recording
    each one as it succeeds. Returns the list of filenames actually applied.

    Every already-applied file is skipped entirely rather than re-run --
    re-running an ADD COLUMN or CREATE TABLE a second time is exactly the
    kind of thing that fails loudly (MySQL error 1060, "Duplicate column
    name") the moment two people sharing a database both run the "same"
    migration once each.

    One honest limitation, instead of a false promise of atomicity: MySQL's
    DDL statements (CREATE TABLE, ALTER TABLE, and friends) commit
    implicitly the instant they run, no matter what transaction is wrapped
    around them. So if a migration's own SQL succeeds but recording it into
    schema_migrations fails right after, the schema change is already
    permanent even though it isn't marked applied. Running this script
    again in that situation re-attempts the same SQL and MySQL rejects it
    (a duplicate column, a table that already exists) -- an annoying but
    loud failure rather than silent drift, and the fix is just to insert
    that one filename into schema_migrations by hand.
    """
    ensure_schema_migrations_table(conn)
    applied = []

    for filename in pending_migrations(conn, migrations_dir):
        path = os.path.join(migrations_dir, filename)
        with open(path, "r") as f:
            sql_text = f.read()

        cursor = conn.cursor()
        try:
            # cursor.execute() only accepts a single statement, but a
            # migration file isn't guaranteed to stay a single statement
            # forever. mysql-connector-python's own multi-statement support
            # (execute(..., multi=True), or connection.cmd_query_iter()) only
            # works under its pure-Python connection implementation -- both
            # raise under the default, faster C-extension implementation this
            # driver installs from PyPI, which is what pip actually gives you
            # when you `pip install mysql-connector-python`. So this splits
            # the file on ';' and runs each non-empty statement on its own.
            # The real limitation that trade leaves behind: a semicolon
            # inside a string literal or a stored-procedure body (the kind
            # Module 8's DELIMITER dance exists to handle) would be split in
            # the wrong place. Fine for this lab's plain DDL/DML migrations;
            # a migration that needs a procedure body belongs in its own
            # file, run by hand the way Module 8 already teaches, not through
            # this runner.
            statements = [s.strip() for s in sql_text.split(";")]
            for statement in statements:
                if statement:
                    cursor.execute(statement)
            cursor.execute(
                "INSERT INTO schema_migrations (filename) VALUES (%s)",
                (filename,),
            )
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            cursor.close()

        applied.append(filename)

    return applied


if __name__ == "__main__":
    connection = get_connection()
    try:
        newly_applied = apply_migrations(connection, MIGRATIONS_DIR)
    finally:
        connection.close()

    if newly_applied:
        print("Applied:")
        for name in newly_applied:
            print(f"  {name}")
    else:
        print("Nothing to apply -- already up to date.")
