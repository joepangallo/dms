"""
Tests for crud.py's parameterized CRUD functions.

Every connection and cursor here is a unittest.mock.MagicMock -- no real
MySQL server is ever contacted, per this repo's rule that tests never
require a live external service.

The property that matters most in this file, and the one nearly every test
below checks explicitly, is that every value crud.py sends to the database
travels as a *separate* parameter, never baked into the SQL text itself.
That's why every assertion inspects cursor.execute()'s call_args as
(sql_string, params_tuple) and checks the params tuple for the value --
never a substring check against an f-string-interpolated SQL statement.
Asserting against a fully-interpolated literal would mean the test only
passes if crud.py is *not* using placeholders, which is exactly backwards
for a module whose whole point is proving parameterization is used
everywhere.
"""

from unittest.mock import MagicMock

import mysql.connector
import mysql.connector.errors as mysql_errors
import pytest

import crud


def make_mock_connection():
    """A connection double whose .cursor() (with or without keyword
    arguments, matching both the plain cursor() calls in create/update/
    delete and the cursor(dictionary=True) calls in get/list) returns the
    same mock cursor, so a test can set expectations on that one cursor
    regardless of which flavor the function under test asked for.
    """
    conn = MagicMock(name="mock_connection")
    cursor = MagicMock(name="mock_cursor")
    conn.cursor.return_value = cursor
    return conn, cursor


# ---------------------------------------------------------------------------
# create_item
# ---------------------------------------------------------------------------

def test_create_item_success_uses_placeholders_and_commits():
    conn, cursor = make_mock_connection()

    crud.create_item(conn, "DG09", "Dog Treats", "Food", 5, 9.99, 2)

    cursor.execute.assert_called_once()
    sql, params = cursor.execute.call_args[0]
    assert "%s" in sql
    assert "INSERT INTO ITEM" in sql
    # The values must travel as a separate tuple, never spliced into sql.
    assert params == ("DG09", "Dog Treats", "Food", 5, 9.99, 2)
    assert "DG09" not in sql
    assert "Dog Treats" not in sql

    conn.commit.assert_called_once()
    conn.rollback.assert_not_called()
    cursor.close.assert_called_once()


def test_create_item_duplicate_id_raises_and_rolls_back():
    conn, cursor = make_mock_connection()
    cursor.execute.side_effect = mysql_errors.IntegrityError(
        msg="Duplicate entry 'DG04' for key 'PRIMARY'", errno=1062,
    )

    with pytest.raises(mysql.connector.Error):
        crud.create_item(conn, "DG04", "Duplicate item", "Food", 1, 1.00, 1)

    conn.rollback.assert_called_once()
    conn.commit.assert_not_called()
    cursor.close.assert_called_once()


# ---------------------------------------------------------------------------
# get_item
# ---------------------------------------------------------------------------

def test_get_item_found_returns_dict_row():
    conn, cursor = make_mock_connection()
    cursor.fetchone.return_value = {"ITEM_ID": "DG04", "DESCRIPTION": "Dog food"}

    result = crud.get_item(conn, "DG04")

    assert result == {"ITEM_ID": "DG04", "DESCRIPTION": "Dog food"}
    conn.cursor.assert_called_once_with(dictionary=True)
    sql, params = cursor.execute.call_args[0]
    assert "%s" in sql
    assert params == ("DG04",)
    cursor.close.assert_called_once()


def test_get_item_not_found_returns_none():
    conn, cursor = make_mock_connection()
    cursor.fetchone.return_value = None

    result = crud.get_item(conn, "ZZZZ")

    assert result is None
    sql, params = cursor.execute.call_args[0]
    assert params == ("ZZZZ",)


# ---------------------------------------------------------------------------
# list_items
# ---------------------------------------------------------------------------

def test_list_items_without_category_returns_every_row():
    conn, cursor = make_mock_connection()
    cursor.fetchall.return_value = [{"ITEM_ID": "DG04"}, {"ITEM_ID": "DG09"}]

    result = crud.list_items(conn)

    assert len(result) == 2
    args, kwargs = cursor.execute.call_args
    # No category means no WHERE clause and no params tuple at all -- a
    # single positional SQL string is the entire call.
    assert len(args) == 1
    assert "WHERE" not in args[0]
    assert kwargs == {}


def test_list_items_with_category_filters_by_bound_parameter():
    conn, cursor = make_mock_connection()
    cursor.fetchall.return_value = [{"ITEM_ID": "DG04", "CATEGORY": "Food"}]

    result = crud.list_items(conn, category="Food")

    assert len(result) == 1
    sql, params = cursor.execute.call_args[0]
    assert "%s" in sql
    assert "WHERE" in sql
    assert params == ("Food",)
    # The category value must never be interpolated into the SQL text.
    assert "Food" not in sql


# ---------------------------------------------------------------------------
# update_item_price
# ---------------------------------------------------------------------------

def test_update_item_price_success_returns_rowcount_and_commits():
    conn, cursor = make_mock_connection()
    cursor.rowcount = 1

    result = crud.update_item_price(conn, "DG04", 19.99)

    assert result == 1
    sql, params = cursor.execute.call_args[0]
    assert "%s" in sql
    assert params == (19.99, "DG04")
    conn.commit.assert_called_once()
    conn.rollback.assert_not_called()


def test_update_item_price_missing_item_returns_zero_rows_affected():
    conn, cursor = make_mock_connection()
    cursor.rowcount = 0

    result = crud.update_item_price(conn, "ZZZZ", 19.99)

    # Zero rows affected is an expected outcome with a name ("no such
    # item_id"), not a driver error -- so this still commits (there was
    # nothing to roll back) and simply reports 0 rather than raising.
    assert result == 0
    conn.commit.assert_called_once()


def test_update_item_price_driver_error_raises_and_rolls_back():
    conn, cursor = make_mock_connection()
    cursor.execute.side_effect = mysql.connector.Error("connection lost mid-statement")

    with pytest.raises(mysql.connector.Error):
        crud.update_item_price(conn, "DG04", 19.99)

    conn.rollback.assert_called_once()
    conn.commit.assert_not_called()


# ---------------------------------------------------------------------------
# delete_item
# ---------------------------------------------------------------------------

def test_delete_item_success():
    conn, cursor = make_mock_connection()
    cursor.rowcount = 1

    result = crud.delete_item(conn, "DG09")

    assert result == {"deleted": True}
    sql, params = cursor.execute.call_args[0]
    assert "%s" in sql
    assert params == ("DG09",)
    conn.commit.assert_called_once()
    conn.rollback.assert_not_called()


def test_delete_item_not_found():
    conn, cursor = make_mock_connection()
    cursor.rowcount = 0

    result = crud.delete_item(conn, "ZZZZ")

    assert result == {"deleted": False, "reason": "not_found"}
    conn.rollback.assert_called_once()
    conn.commit.assert_not_called()


def test_delete_item_foreign_key_conflict_returns_referenced():
    # This is the module's headline failure path: DG04 is referenced by
    # invoice 50710's INVOICE_LINE row in the seeded KimTay data, so a real
    # MySQL server raises errno 1451 on this exact delete -- the identical
    # error Module 8's DELETE_ITEM procedures catch on the SQL side.
    conn, cursor = make_mock_connection()
    cursor.execute.side_effect = mysql_errors.IntegrityError(
        msg="Cannot delete or update a parent row: a foreign key constraint fails",
        errno=1451,
    )

    result = crud.delete_item(conn, "DG04")

    assert result == {"deleted": False, "reason": "referenced"}
    conn.rollback.assert_called_once()
    conn.commit.assert_not_called()


def test_delete_item_other_integrity_error_is_not_swallowed():
    # Only errno 1451 is the named, expected "referenced" outcome. Any other
    # integrity error is a real surprise and must still propagate, rather
    # than being mislabeled as the foreign-key case.
    conn, cursor = make_mock_connection()
    cursor.execute.side_effect = mysql_errors.IntegrityError(
        msg="some other integrity failure", errno=9999,
    )

    with pytest.raises(mysql_errors.IntegrityError):
        crud.delete_item(conn, "DG04")

    conn.rollback.assert_called_once()
