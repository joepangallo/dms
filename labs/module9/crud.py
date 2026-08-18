"""
Parameterized CRUD operations against the KimTay ITEM table.

Every statement below passes values through the driver's %s placeholders and
a separate params tuple -- never an f-string, %-format, or .format() call
built into the SQL text itself. That's the one property that actually matters
in this file: it's what keeps a value like O'Brien's or a deliberately hostile
string like "' OR '1'='1" a plain, inert literal instead of a fragment of SQL
the database has to interpret. See injection_demo.py for what goes wrong the
moment that rule is dropped, even "just this once."

Design note on raise-vs-return (read this once; it's not re-argued per
function below): every function here distinguishes between an UNEXPECTED
engine failure -- a dropped connection, a permissions error, a genuine bug in
the SQL -- and an EXPECTED outcome that already has a name, like "no row with
that id" or "a foreign key is in the way." Unexpected failures are left to
propagate as exceptions, because catching them here and inventing some string
status to describe them would just push the real "now what?" decision onto
every single caller. Expected outcomes are reported as ordinary return values
instead, because forcing a caller to wrap a try/except around "the item
doesn't exist yet" invites exactly the kind of blanket except-and-ignore code
that quietly swallows real bugs along with the expected case.

create_item() and update_item_price() let MySQL's own response describe the
outcome (a duplicate-key IntegrityError from the driver, an affected-row
count of 0) and pass it straight through, raising or returning accordingly.
delete_item() is the one function that deliberately catches a driver-level
exception and converts it to a value: a foreign-key violation on DELETE
(errno 1451) is exactly the outcome Module 8's DELETE_ITEM procedure already
treats as a normal, expected branch rather than a crash -- see
labs/module8/09-tsql-sql-server.sql's BEGIN CATCH block and its MySQL port in
labs/module8/13-mysql-port-of-8.8-8.9.sql's DECLARE EXIT HANDLER FOR
SQLEXCEPTION. This file makes the Python layer handle that case the same way
its stored-procedure counterpart already does, instead of letting a
classroom demo crash on the exact error the SQL lesson spent a whole section
explaining.
"""

import mysql.connector


def create_item(conn, item_id, description, category, on_hand, price, reorder_level):
    """Insert one row into ITEM.

    Raises on any failure, including a duplicate item_id -- mysql.connector
    surfaces that as an IntegrityError on the PRIMARY KEY, which is exactly
    the signal api.py uses to answer a POST with 409 instead of a generic 500.
    """
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO ITEM (ITEM_ID, DESCRIPTION, CATEGORY, ON_HAND, PRICE, REORDER_LEVEL) "
            "VALUES (%s, %s, %s, %s, %s, %s)",
            (item_id, description, category, on_hand, price, reorder_level),
        )
        conn.commit()
    except mysql.connector.Error:
        # Roll back before re-raising so a half-applied write never lingers
        # on the connection for whatever the caller does next with it.
        conn.rollback()
        raise
    finally:
        cursor.close()


def get_item(conn, item_id):
    """Return the ITEM row for item_id as a dict, or None if it doesn't exist.

    cursor(dictionary=True) hands back column-name keys instead of a bare
    positional tuple. That costs a little more than a plain cursor, but it's
    worth it here: api.py turns this result straight into a JSON body, and
    matching tuple positions to column names by hand is exactly the kind of
    place an unnoticed schema change (or a reordered SELECT *) quietly
    corrupts a response instead of raising anything.
    """
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM ITEM WHERE ITEM_ID = %s", (item_id,))
        return cursor.fetchone()
    finally:
        cursor.close()


def list_items(conn, category=None):
    """Return every ITEM row, or only the rows in one category if given.

    category is bound with %s exactly like every other parameter in this
    file, even though today it only ever arrives here already validated by
    api.py. Building this particular WHERE clause by string interpolation
    "just this once, because it's a simple filter" is exactly the habit that
    later produces an injectable code path somewhere less carefully reviewed.
    """
    cursor = conn.cursor(dictionary=True)
    try:
        if category is None:
            cursor.execute("SELECT * FROM ITEM ORDER BY ITEM_ID")
        else:
            cursor.execute(
                "SELECT * FROM ITEM WHERE CATEGORY = %s ORDER BY ITEM_ID",
                (category,),
            )
        return cursor.fetchall()
    finally:
        cursor.close()


def update_item_price(conn, item_id, new_price):
    """Update ITEM.PRICE for one item_id.

    Returns the number of rows affected rather than raising when nothing
    matches -- 0 rows means "no such item_id," which is an expected outcome
    with a name, not an engine failure (see the module docstring above).
    """
    cursor = conn.cursor()
    try:
        cursor.execute(
            "UPDATE ITEM SET PRICE = %s WHERE ITEM_ID = %s",
            (new_price, item_id),
        )
        conn.commit()
        return cursor.rowcount
    except mysql.connector.Error:
        conn.rollback()
        raise
    finally:
        cursor.close()


def delete_item(conn, item_id):
    """Delete one ITEM row.

    Returns a structured result instead of raising for either of ITEM's two
    expected non-success outcomes:

        {"deleted": True}
        {"deleted": False, "reason": "not_found"}
        {"deleted": False, "reason": "referenced"}

    "referenced" is MySQL error 1451 -- some row in INVOICE_LINE still points
    at this item_id, so the foreign key refuses the delete. See the module
    docstring for why that's caught here rather than left to propagate, and
    labs/module8's DELETE_ITEM procedures for the SQL-side version of the
    identical lesson: DG04 is exactly the seeded item this will happen to,
    because invoice 50710 orders it.
    """
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM ITEM WHERE ITEM_ID = %s", (item_id,))
        if cursor.rowcount == 0:
            # Nothing matched -- this isn't a driver error, so there is
            # nothing to roll back; the DELETE simply touched zero rows.
            conn.rollback()
            return {"deleted": False, "reason": "not_found"}
        conn.commit()
        return {"deleted": True}
    except mysql.connector.errors.IntegrityError as exc:
        conn.rollback()
        # errno 1451: "Cannot delete or update a parent row: a foreign key
        # constraint fails" -- the exact error a real MySQL server raises for
        # this table shape, matching what 13-mysql-port-of-8.8-8.9.sql's
        # DECLARE EXIT HANDLER FOR SQLEXCEPTION catches on the SQL side.
        if exc.errno == 1451:
            return {"deleted": False, "reason": "referenced"}
        # Some other integrity error -- not the one FK case this function
        # is written to expect, so re-raise rather than mislabel it.
        raise
    finally:
        cursor.close()
