"""
Tests for migrations/migrate.py.

pending_migrations() is the star of this file: it is pure diff logic (one
SELECT against a mocked connection, one directory listing, a set
difference) and is exercised here with a mocked connection returning a
fake "already applied" set plus a monkeypatched os.listdir() standing in
for a fake list of migration filenames -- no real database and no real
.sql files anywhere in this module, exactly as migrate.py's own module
docstring says this function was written to allow.

apply_migrations() gets one additional test with builtins.open() replaced
by unittest.mock.mock_open, so that even the one real file read this
runner performs is mocked out -- per this repo's rule that tests never
require real external state, filesystem included.
"""

from unittest.mock import MagicMock, mock_open

import migrate


def make_mock_connection(applied_filenames):
    """A connection double whose cursor().fetchall() returns rows shaped
    exactly like the real driver would for a plain (non-dictionary) cursor
    running `SELECT filename FROM schema_migrations` -- one single-element
    tuple per already-applied filename.
    """
    conn = MagicMock(name="mock_connection")
    cursor = MagicMock(name="mock_cursor")
    conn.cursor.return_value = cursor
    cursor.fetchall.return_value = [(name,) for name in applied_filenames]
    return conn, cursor


# ---------------------------------------------------------------------------
# _migration_filenames
# ---------------------------------------------------------------------------

def test_migration_filenames_keeps_only_dot_sql_files_sorted(monkeypatch):
    monkeypatch.setattr(
        migrate.os, "listdir",
        lambda d: ["0002_b.sql", "README.md", "0001_a.sql", ".DS_Store", "notes.txt"],
    )

    result = migrate._migration_filenames("/fake/migrations/dir")

    assert result == ["0001_a.sql", "0002_b.sql"]


# ---------------------------------------------------------------------------
# pending_migrations -- the pure diff this module exists to make testable
# ---------------------------------------------------------------------------

def test_pending_migrations_returns_only_the_unapplied_ones_in_order(monkeypatch):
    monkeypatch.setattr(
        migrate.os, "listdir",
        lambda d: [
            "0002_add_bar.sql",
            "0001_add_item_notes_column.sql",
            "0003_add_baz.sql",
            "not_a_migration.txt",
        ],
    )
    conn, cursor = make_mock_connection(applied_filenames=["0001_add_item_notes_column.sql"])

    result = migrate.pending_migrations(conn, "/fake/migrations/dir")

    assert result == ["0002_add_bar.sql", "0003_add_baz.sql"]
    cursor.execute.assert_called_once_with("SELECT filename FROM schema_migrations")
    cursor.close.assert_called_once()


def test_pending_migrations_returns_empty_when_everything_is_applied(monkeypatch):
    monkeypatch.setattr(migrate.os, "listdir", lambda d: ["0001_add_item_notes_column.sql"])
    conn, cursor = make_mock_connection(applied_filenames=["0001_add_item_notes_column.sql"])

    result = migrate.pending_migrations(conn, "/fake/migrations/dir")

    assert result == []


def test_pending_migrations_returns_everything_on_a_brand_new_database(monkeypatch):
    # schema_migrations exists (ensure_schema_migrations_table already ran)
    # but is empty -- nothing has ever been applied against this database.
    monkeypatch.setattr(migrate.os, "listdir", lambda d: ["0003_c.sql", "0001_a.sql", "0002_b.sql"])
    conn, cursor = make_mock_connection(applied_filenames=[])

    result = migrate.pending_migrations(conn, "/fake/migrations/dir")

    assert result == ["0001_a.sql", "0002_b.sql", "0003_c.sql"]


# ---------------------------------------------------------------------------
# ensure_schema_migrations_table
# ---------------------------------------------------------------------------

def test_ensure_schema_migrations_table_creates_and_commits():
    conn = MagicMock(name="mock_connection")
    cursor = MagicMock(name="mock_cursor")
    conn.cursor.return_value = cursor

    migrate.ensure_schema_migrations_table(conn)

    cursor.execute.assert_called_once_with(migrate.CREATE_TRACKING_TABLE)
    conn.commit.assert_called_once()
    cursor.close.assert_called_once()


# ---------------------------------------------------------------------------
# apply_migrations
# ---------------------------------------------------------------------------

def test_apply_migrations_applies_pending_files_and_records_them(monkeypatch):
    monkeypatch.setattr(migrate.os, "listdir", lambda d: ["0001_test.sql"])
    # builtins.open is shadowed on the migrate module's own namespace here,
    # so apply_migrations's `open(path, "r")` call resolves to this fake
    # file object instead of touching a real .sql file on disk.
    monkeypatch.setattr(
        migrate, "open",
        mock_open(read_data="ALTER TABLE ITEM ADD COLUMN NOTES VARCHAR(200);"),
        raising=False,
    )

    conn = MagicMock(name="mock_connection")
    cursor = MagicMock(name="mock_cursor")
    conn.cursor.return_value = cursor
    cursor.fetchall.return_value = []          # nothing applied yet

    applied = migrate.apply_migrations(conn, "/fake/migrations/dir")

    assert applied == ["0001_test.sql"]
    # One INSERT into schema_migrations for the newly-applied file, on top of
    # the CREATE TABLE IF NOT EXISTS from ensure_schema_migrations_table, the
    # SELECT from pending_migrations, and the migration's own ALTER TABLE --
    # four execute() calls total.
    insert_calls = [
        call for call in cursor.execute.call_args_list
        if call.args and "INSERT INTO schema_migrations" in call.args[0]
    ]
    assert len(insert_calls) == 1
    assert insert_calls[0].args[1] == ("0001_test.sql",)


def test_apply_migrations_is_a_no_op_when_everything_is_already_applied(monkeypatch):
    monkeypatch.setattr(migrate.os, "listdir", lambda d: ["0001_test.sql"])
    monkeypatch.setattr(migrate, "open", mock_open(read_data="SELECT 1;"), raising=False)

    conn = MagicMock(name="mock_connection")
    cursor = MagicMock(name="mock_cursor")
    conn.cursor.return_value = cursor
    cursor.fetchall.return_value = [("0001_test.sql",)]   # already applied

    applied = migrate.apply_migrations(conn, "/fake/migrations/dir")

    assert applied == []
    insert_calls = [
        call for call in cursor.execute.call_args_list
        if call.args and "INSERT INTO schema_migrations" in call.args[0]
    ]
    assert insert_calls == []
