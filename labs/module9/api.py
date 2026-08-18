"""
Minimal CRUD API over the KimTay ITEM table.

SECURITY WARNING: this app has no authentication or authorization of any
kind -- anyone who can reach it can create, read, update, and delete rows.
That's an acceptable trade for a local classroom sandbox where the only
thing on the other end of the port is you and curl/Postman; it is not
acceptable anywhere network-reachable. Do not deploy this as written, put it
behind a public hostname, or bind it to anything but localhost.

Run it with:

    flask --app api run --debug

after copying .env.example to .env and filling in real credentials (see the
module README).
"""

import logging
import math

import mysql.connector
from flask import Flask, g, jsonify, request
from werkzeug.exceptions import RequestEntityTooLarge

import crud
from db import get_connection

app = Flask(__name__)

# Bounds how much of a request body Werkzeug will buffer into memory before
# any route code -- even request.get_json() -- gets a chance to look at it.
# Without this, a multi-gigabyte POST body (valid JSON or not) is read
# entirely into memory first, which can exhaust the box running the dev
# server. 1 MB is far larger than any legitimate ITEM payload this API
# accepts, so no real request is ever affected by the cap.
app.config["MAX_CONTENT_LENGTH"] = 1_000_000  # 1 MB

# Column-shape limits mirrored from labs/module8/00-setup-both.sql's ITEM
# table, so a request that would only fail later with an opaque MySQL
# DataError instead gets a specific, field-named 400 right here.
ITEM_ID_MAX_LEN = 4            # ITEM_ID CHAR(4)
DESCRIPTION_MAX_LEN = 30       # DESCRIPTION VARCHAR(30)
CATEGORY_MAX_LEN = 15          # CATEGORY VARCHAR(15)
SMALLINT_MAX = 32767           # ON_HAND / REORDER_LEVEL SMALLINT
PRICE_MAX = 99999.99           # PRICE DECIMAL(7,2)

# Configured at import time so logger.exception() calls below actually land
# somewhere visible -- Flask's own logger stays quiet below WARNING outside
# debug mode, and the whole point of logging the real error server-side is
# defeated if it's dropped on the floor instead.
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _db():
    """Return this request's connection, opening one on first use.

    One connection per request, stashed on Flask's request-scoped `g` and
    closed in teardown_appcontext below, rather than one shared module-level
    connection -- so a rollback (or a connection that dies mid-request) can
    never bleed into whatever a different, possibly concurrent, request does
    with "the" connection.
    """
    if "db" not in g:
        g.db = get_connection()
    return g.db


@app.teardown_appcontext
def close_db(exception=None):
    conn = g.pop("db", None)
    if conn is not None:
        conn.close()


def _error(status, error, message, field=None):
    body = {"error": error, "message": message}
    if field is not None:
        body["field"] = field
    return jsonify(body), status


def _validate_price(price):
    """Return None if price is a valid ITEM.PRICE value, else an error message.

    Shared by create_item_route and update_item_route so the rule lives in
    exactly one place -- the two routes previously carried separate copies
    of this check that had already drifted (only this version rejects
    NaN/Infinity, below). math.isfinite() is the part that matters most:
    Python's json module accepts the non-standard tokens NaN/Infinity/
    -Infinity by default, and neither one satisfies a plain `price <= 0`
    comparison (NaN compares False to everything; Infinity is not <= 0
    either), so without this check both sail past validation and reach
    mysql-connector, which renders a float as a bare unquoted token --
    producing a confusing SQL-syntax 500 instead of the clean 400 this
    function exists to give instead.
    """
    if isinstance(price, bool) or not isinstance(price, (int, float)):
        return "price must be a positive number."
    if not math.isfinite(price):
        return "price must be a positive number."
    if price <= 0:
        return "price must be a positive number."
    if price > PRICE_MAX:
        return f"price must be at most {PRICE_MAX} (the column is DECIMAL(7,2))."
    return None


def _invalid_item_id_response(item_id):
    """Return a 400 Response if item_id doesn't fit ITEM_ID's CHAR(4) shape,
    else None.

    create_item_route already enforced this on POST; GET/PUT/DELETE did not,
    which was a real inconsistency in what this module claims to validate
    even though every one of those calls is parameterized and so could not
    be abused for anything worse than a guaranteed-empty lookup. Applying
    the same check uniformly closes that gap and gives a clear 400 instead
    of a 404 for input that was never going to name a real row.
    """
    if not (1 <= len(item_id) <= ITEM_ID_MAX_LEN):
        return _error(
            400, "invalid_request",
            f"item_id must be 1-{ITEM_ID_MAX_LEN} characters (the column is CHAR({ITEM_ID_MAX_LEN})).",
            field="item_id",
        )
    return None


@app.errorhandler(RequestEntityTooLarge)
def handle_too_large(exc):
    return _error(
        413, "payload_too_large",
        f"Request body exceeds the {app.config['MAX_CONTENT_LENGTH']}-byte limit for this API.",
    )


@app.errorhandler(Exception)
def handle_unexpected_error(exc):
    # The only place a database or programming error is allowed to reach a
    # client at all -- and only ever as this one generic message. The real
    # exception, including whatever table, column, or query detail it
    # contains, goes to the server log instead. Returning it to the client
    # would hand anyone probing this API a free look at schema and driver
    # internals -- exactly the kind of information disclosure this module's
    # "never leak a raw DB error" rule exists to prevent. Flask routes
    # HTTPException instances (the 400/404/409s this file returns on
    # purpose via _error()) around this handler on its own, so it only ever
    # fires for the genuinely unexpected case.
    logger.exception("Unhandled error in %s %s", request.method, request.path)
    return _error(500, "internal_error", "Something went wrong. Check the server log.")


@app.get("/items")
def list_items_route():
    category = request.args.get("category")
    rows = crud.list_items(_db(), category=category)
    return jsonify(rows)


@app.get("/items/<item_id>")
def get_item_route(item_id):
    error = _invalid_item_id_response(item_id)
    if error is not None:
        return error

    row = crud.get_item(_db(), item_id)
    if row is None:
        return _error(404, "not_found", f"No item with id {item_id!r}.")
    return jsonify(row)


@app.post("/items")
def create_item_route():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return _error(400, "invalid_request", "Request body must be a JSON object.")

    # Every field is checked before crud.create_item ever runs, so a bad
    # request never reaches the database at all. MySQL's default strict mode
    # would turn most of these mistakes into a driver error rather than
    # silent data loss, but that's a worse place to catch them than here --
    # a field-specific 400 beats a stack trace surfacing as an opaque 500.

    item_id = data.get("item_id")
    if not isinstance(item_id, str) or not (1 <= len(item_id) <= ITEM_ID_MAX_LEN):
        return _error(
            400, "invalid_request",
            f"item_id must be a string of 1-{ITEM_ID_MAX_LEN} characters "
            f"(the column is CHAR({ITEM_ID_MAX_LEN})).",
            field="item_id",
        )

    description = data.get("description")
    if (
        not isinstance(description, str)
        or not description.strip()
        or len(description) > DESCRIPTION_MAX_LEN
    ):
        return _error(
            400, "invalid_request",
            f"description must be a non-empty string of at most {DESCRIPTION_MAX_LEN} "
            f"characters (the column is VARCHAR({DESCRIPTION_MAX_LEN})).",
            field="description",
        )

    category = data.get("category")
    if category is not None and (
        not isinstance(category, str) or len(category) > CATEGORY_MAX_LEN
    ):
        return _error(
            400, "invalid_request",
            f"category must be null or a string of at most {CATEGORY_MAX_LEN} "
            f"characters (the column is VARCHAR({CATEGORY_MAX_LEN})).",
            field="category",
        )

    on_hand = data.get("on_hand")
    if (
        not isinstance(on_hand, int)
        or isinstance(on_hand, bool)
        or not (0 <= on_hand <= SMALLINT_MAX)
    ):
        # isinstance(x, bool) is excluded on purpose -- bool is a subclass of
        # int in Python, so True/False would otherwise sail through an
        # isinstance(x, int) check as 1/0, a surprising way for a boolean
        # typo in a JSON body to end up stored as a quantity. The upper
        # bound matches SMALLINT's actual range, so a value MySQL would
        # reject with a DataError is caught here as a named 400 instead.
        return _error(
            400, "invalid_request",
            f"on_hand must be an integer between 0 and {SMALLINT_MAX} (the column is SMALLINT).",
            field="on_hand",
        )

    reorder_level = data.get("reorder_level")
    if (
        not isinstance(reorder_level, int)
        or isinstance(reorder_level, bool)
        or not (0 <= reorder_level <= SMALLINT_MAX)
    ):
        return _error(
            400, "invalid_request",
            f"reorder_level must be an integer between 0 and {SMALLINT_MAX} "
            f"(the column is SMALLINT).",
            field="reorder_level",
        )

    price = data.get("price")
    price_error = _validate_price(price)
    if price_error is not None:
        return _error(400, "invalid_request", price_error, field="price")

    conn = _db()

    # Checking first gives the common case (the id is already taken) a fast,
    # friendly 409 without ever attempting the INSERT. The except below is
    # what actually protects correctness: two requests for the same new
    # item_id can both pass this check before either one commits, and it's
    # create_item's own IntegrityError -- not this check -- that's the real
    # source of truth for "does this row already exist."
    if crud.get_item(conn, item_id) is not None:
        return _error(409, "already_exists", f"Item {item_id!r} already exists.")

    try:
        crud.create_item(conn, item_id, description, category, on_hand, price, reorder_level)
    except mysql.connector.errors.IntegrityError:
        return _error(409, "already_exists", f"Item {item_id!r} already exists.")

    return jsonify(crud.get_item(conn, item_id)), 201


@app.put("/items/<item_id>")
def update_item_route(item_id):
    error = _invalid_item_id_response(item_id)
    if error is not None:
        return error

    data = request.get_json(silent=True)
    if not isinstance(data, dict) or "price" not in data:
        return _error(
            400, "invalid_request", "Request body must include a price field.",
            field="price",
        )

    price = data.get("price")
    price_error = _validate_price(price)
    if price_error is not None:
        return _error(400, "invalid_request", price_error, field="price")

    conn = _db()
    rows_affected = crud.update_item_price(conn, item_id, price)
    if rows_affected == 0:
        return _error(404, "not_found", f"No item with id {item_id!r}.")

    return jsonify(crud.get_item(conn, item_id))


@app.delete("/items/<item_id>")
def delete_item_route(item_id):
    error = _invalid_item_id_response(item_id)
    if error is not None:
        return error

    result = crud.delete_item(_db(), item_id)

    if result["deleted"]:
        return "", 204

    if result["reason"] == "not_found":
        return _error(404, "not_found", f"No item with id {item_id!r}.")

    # The only remaining reason is "referenced" -- see crud.delete_item's
    # docstring and Module 8's DELETE_ITEM procedures for why this is a
    # named, expected outcome rather than a crash.
    return _error(
        409, "referenced",
        f"Item {item_id!r} is still referenced by an invoice line and cannot be deleted.",
    )


if __name__ == "__main__":
    # 127.0.0.1, not 0.0.0.0 -- binding every interface here is exactly the
    # "expose it outside a local sandbox" mistake the module docstring above
    # warns against. debug=True is fine behind that same loopback restriction
    # (it's what gives you readable tracebacks and autoreload while working
    # through the lab) but should never travel together with a public bind.
    app.run(host="127.0.0.1", port=5000, debug=True)
