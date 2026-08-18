"""
Classroom demo: what SQL injection actually looks like, live.

This is a standalone script, not a pytest test -- it needs a real MySQL
server with Module 8's 00-setup-both.sql already loaded, and it prints its
results for a person to read rather than asserting anything. The automated
test suite for this module does not run it, and it does not run against a
real database itself, per this repo's rule that tests never require live
external services.

Run it with:

    python3 injection_demo.py

after copying .env.example to .env and filling in real credentials (see the
module README).
"""

import mysql.connector

from db import get_connection


def safe_lookup(conn, item_id):
    """Look up one ITEM row the way crud.py does: item_id travels as a bound
    parameter, so MySQL always treats it as a single string value -- never as
    a fragment of the SQL statement itself, no matter what characters it
    contains."""
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM ITEM WHERE ITEM_ID = %s", (item_id,))
        return cursor.fetchall()
    finally:
        cursor.close()


def unsafe_lookup(conn, item_id):
    # !! DELIBERATELY INSECURE -- do not copy this pattern.
    # item_id is spliced directly into the SQL text with an f-string, so
    # whatever the caller passes becomes part of the statement MySQL parses,
    # not a value it substitutes in afterward. Anything a caller can control
    # that reaches a line shaped like this is a SQL injection vulnerability.
    query = f"SELECT * FROM ITEM WHERE ITEM_ID = '{item_id}'"
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query)
        return cursor.fetchall()
    finally:
        cursor.close()


if __name__ == "__main__":
    conn = get_connection()

    # The payload: a closing quote ends the string literal early, and
    # OR '1'='1' turns the WHERE clause into something true for every row --
    # classic tautology-based injection, chosen because it's the simplest
    # payload that makes the difference between the two functions obvious.
    payload = "DG04' OR '1'='1"

    print("1. safe_lookup('DG04') -- a normal, legitimate id:")
    print("   ", safe_lookup(conn, "DG04"))

    print()
    print("2. safe_lookup(payload) -- the parameter is just a literal value,")
    print("   so MySQL looks for an item_id that literally equals the whole")
    print("   payload string, finds none, and returns nothing:")
    print("   ", safe_lookup(conn, payload))

    print()
    print("3. unsafe_lookup(payload) -- the same payload, but spliced into")
    print("   the SQL text. The trailing OR '1'='1' is no longer part of a")
    print("   string value -- it's now a second condition in the WHERE")
    print("   clause, true for every row, so the query returns the entire")
    print("   table to whoever sent the payload:")
    rows = unsafe_lookup(conn, payload)
    print("   ", rows)
    print()
    print(
        f"   {len(rows)} row(s) came back from a lookup that was supposed to "
        "match at most one item_id. That's the injection: the attacker never "
        "needed a password or a bug in the schema, just a single string this "
        "function trusted enough to paste straight into a SQL statement."
    )

    conn.close()
