"""
Tests for api.py's Flask routes.

Flask's own test client drives every request here -- no real HTTP socket,
no real Flask dev server. The crud layer is monkeypatched per test (via
api.crud.<function>, since api.py does `import crud` and calls crud.X(...),
so replacing the attribute on the shared `crud` module object is what
actually reaches the route handlers) so a route test never touches real SQL
at all. db.get_connection is monkeypatched too, to a function that returns
a bare MagicMock -- _db() stores that on Flask's request-scoped `g` and
passes it straight through to the (also mocked) crud functions, so it is
never actually used for anything beyond being a harmless placeholder
"connection" object.
"""

from unittest.mock import MagicMock

import mysql.connector
import pytest

import api as api_module


@pytest.fixture
def client(monkeypatch):
    # Every route calls _db() at least once, which calls get_connection()
    # (imported into api.py's own namespace via `from db import
    # get_connection`) -- patching the name on api_module is what actually
    # intercepts it, since api.py already holds its own reference to the
    # original function.
    monkeypatch.setattr(api_module, "get_connection", lambda: MagicMock(name="fake_conn"))
    with api_module.app.test_client() as test_client:
        yield test_client


def valid_item_payload(**overrides):
    payload = {
        "item_id": "DG09",
        "description": "Dog Treats",
        "category": "Food",
        "on_hand": 5,
        "price": 9.99,
        "reorder_level": 2,
    }
    payload.update(overrides)
    return payload


# ---------------------------------------------------------------------------
# GET /items
# ---------------------------------------------------------------------------

def test_list_items_route_returns_all_rows_as_json(client, monkeypatch):
    rows = [{"ITEM_ID": "DG04"}, {"ITEM_ID": "DG09"}]
    seen = {}

    def fake_list_items(conn, category=None):
        seen["category"] = category
        return rows

    monkeypatch.setattr(api_module.crud, "list_items", fake_list_items)

    resp = client.get("/items")

    assert resp.status_code == 200
    assert resp.get_json() == rows
    assert seen["category"] is None


def test_list_items_route_forwards_category_query_param(client, monkeypatch):
    seen = {}

    def fake_list_items(conn, category=None):
        seen["category"] = category
        return []

    monkeypatch.setattr(api_module.crud, "list_items", fake_list_items)

    resp = client.get("/items?category=Food")

    assert resp.status_code == 200
    assert seen["category"] == "Food"


# ---------------------------------------------------------------------------
# GET /items/<item_id>
# ---------------------------------------------------------------------------

def test_get_item_route_found(client, monkeypatch):
    monkeypatch.setattr(
        api_module.crud, "get_item",
        lambda conn, item_id: {"ITEM_ID": item_id, "DESCRIPTION": "Dog food"},
    )

    resp = client.get("/items/DG04")

    assert resp.status_code == 200
    assert resp.get_json() == {"ITEM_ID": "DG04", "DESCRIPTION": "Dog food"}


def test_get_item_route_missing_returns_404(client, monkeypatch):
    monkeypatch.setattr(api_module.crud, "get_item", lambda conn, item_id: None)

    resp = client.get("/items/ZZZZ")

    assert resp.status_code == 404
    body = resp.get_json()
    assert body["error"] == "not_found"


def test_get_item_route_rejects_oversized_item_id_with_400(client, monkeypatch):
    # Regression test: item_id from the URL used to reach crud.get_item
    # completely unvalidated on GET/PUT/DELETE, unlike POST. A mock that
    # raises if it's ever called proves the oversized id is rejected before
    # any database call is attempted, not just that the final status code
    # happens to match what a 404 would also produce.
    called = MagicMock(side_effect=AssertionError("crud.get_item should not be reached"))
    monkeypatch.setattr(api_module.crud, "get_item", called)

    resp = client.get("/items/" + "X" * 500)

    assert resp.status_code == 400
    body = resp.get_json()
    assert body["error"] == "invalid_request"
    assert body["field"] == "item_id"
    called.assert_not_called()


# ---------------------------------------------------------------------------
# POST /items
# ---------------------------------------------------------------------------

def test_create_item_route_success(client, monkeypatch):
    # get_item is called twice by the route: once as the pre-insert
    # duplicate check (must say "doesn't exist yet") and once after the
    # insert to build the 201 response body (must return the new row).
    call_count = {"n": 0}

    def fake_get_item(conn, item_id):
        call_count["n"] += 1
        if call_count["n"] == 1:
            return None
        return {"ITEM_ID": item_id, "DESCRIPTION": "Dog Treats", "PRICE": 9.99}

    created = {}

    def fake_create_item(conn, item_id, description, category, on_hand, price, reorder_level):
        created.update(
            item_id=item_id, description=description, category=category,
            on_hand=on_hand, price=price, reorder_level=reorder_level,
        )

    monkeypatch.setattr(api_module.crud, "get_item", fake_get_item)
    monkeypatch.setattr(api_module.crud, "create_item", fake_create_item)

    resp = client.post("/items", json=valid_item_payload())

    assert resp.status_code == 201
    body = resp.get_json()
    assert body["ITEM_ID"] == "DG09"
    assert created["item_id"] == "DG09"
    assert created["price"] == 9.99


@pytest.mark.parametrize(
    "overrides, expected_field",
    [
        ({"item_id": None}, "item_id"),
        ({"item_id": "TOOLONGID"}, "item_id"),
        ({"description": ""}, "description"),
        ({"category": 123}, "category"),
        ({"on_hand": -1}, "on_hand"),
        ({"on_hand": True}, "on_hand"),  # bool must not pass as an int
        ({"on_hand": 32768}, "on_hand"),  # exceeds SMALLINT's 32767 max
        ({"reorder_level": -1}, "reorder_level"),
        ({"reorder_level": 32768}, "reorder_level"),  # exceeds SMALLINT max
        ({"price": 0}, "price"),
        ({"price": -5}, "price"),
        ({"price": 100000.00}, "price"),  # exceeds DECIMAL(7,2)'s ~99999.99 max
        ({"price": float("nan")}, "price"),
        ({"price": float("inf")}, "price"),
        ({"price": float("-inf")}, "price"),
        ({"description": "x" * 31}, "description"),  # exceeds VARCHAR(30)
        ({"category": "x" * 16}, "category"),  # exceeds VARCHAR(15)
    ],
)
def test_create_item_route_rejects_invalid_fields_with_400(client, overrides, expected_field):
    resp = client.post("/items", json=valid_item_payload(**overrides))

    assert resp.status_code == 400
    body = resp.get_json()
    assert body["error"] == "invalid_request"
    assert body["field"] == expected_field


def test_create_item_route_rejects_missing_field_with_400(client):
    payload = valid_item_payload()
    del payload["price"]

    resp = client.post("/items", json=payload)

    assert resp.status_code == 400
    assert resp.get_json()["field"] == "price"


def test_create_item_route_rejects_non_json_body_with_400(client):
    resp = client.post("/items", data="not json", content_type="text/plain")

    assert resp.status_code == 400
    assert resp.get_json()["error"] == "invalid_request"


def test_create_item_route_duplicate_via_precheck_returns_409(client, monkeypatch):
    monkeypatch.setattr(
        api_module.crud, "get_item",
        lambda conn, item_id: {"ITEM_ID": item_id},  # already exists
    )

    resp = client.post("/items", json=valid_item_payload(item_id="DG04"))

    assert resp.status_code == 409
    assert resp.get_json()["error"] == "already_exists"


def test_create_item_route_duplicate_via_race_condition_returns_409(client, monkeypatch):
    # The pre-check says "doesn't exist," but the insert itself hits a
    # duplicate key -- the race the route's own comment describes, where a
    # second concurrent request beat this one to the insert.
    monkeypatch.setattr(api_module.crud, "get_item", lambda conn, item_id: None)

    def fake_create_item(conn, *args, **kwargs):
        raise mysql.connector.errors.IntegrityError(
            msg="Duplicate entry 'DG09' for key 'PRIMARY'", errno=1062,
        )

    monkeypatch.setattr(api_module.crud, "create_item", fake_create_item)

    resp = client.post("/items", json=valid_item_payload())

    assert resp.status_code == 409
    assert resp.get_json()["error"] == "already_exists"


# ---------------------------------------------------------------------------
# PUT /items/<item_id>
# ---------------------------------------------------------------------------

def test_update_item_route_success(client, monkeypatch):
    monkeypatch.setattr(api_module.crud, "update_item_price", lambda conn, item_id, price: 1)
    monkeypatch.setattr(
        api_module.crud, "get_item",
        lambda conn, item_id: {"ITEM_ID": item_id, "PRICE": 12.5},
    )

    resp = client.put("/items/DG04", json={"price": 12.5})

    assert resp.status_code == 200
    assert resp.get_json()["PRICE"] == 12.5


def test_update_item_route_missing_item_returns_404(client, monkeypatch):
    monkeypatch.setattr(api_module.crud, "update_item_price", lambda conn, item_id, price: 0)

    resp = client.put("/items/ZZZZ", json={"price": 12.5})

    assert resp.status_code == 404
    assert resp.get_json()["error"] == "not_found"


def test_update_item_route_missing_price_field_returns_400(client):
    resp = client.put("/items/DG04", json={})

    assert resp.status_code == 400
    assert resp.get_json()["field"] == "price"


@pytest.mark.parametrize(
    "bad_price",
    [0, -5, "12.50", True, float("nan"), float("inf"), float("-inf"), 100000.00],
)
def test_update_item_route_rejects_bad_price_with_400(client, bad_price):
    resp = client.put("/items/DG04", json={"price": bad_price})

    assert resp.status_code == 400
    assert resp.get_json()["field"] == "price"


def test_update_item_route_rejects_oversized_item_id_with_400(client, monkeypatch):
    called = MagicMock(side_effect=AssertionError("crud.update_item_price should not be reached"))
    monkeypatch.setattr(api_module.crud, "update_item_price", called)

    resp = client.put("/items/" + "X" * 500, json={"price": 12.5})

    assert resp.status_code == 400
    body = resp.get_json()
    assert body["error"] == "invalid_request"
    assert body["field"] == "item_id"
    called.assert_not_called()


# ---------------------------------------------------------------------------
# DELETE /items/<item_id>
# ---------------------------------------------------------------------------

def test_delete_item_route_success_returns_204(client, monkeypatch):
    monkeypatch.setattr(api_module.crud, "delete_item", lambda conn, item_id: {"deleted": True})

    resp = client.delete("/items/DG09")

    assert resp.status_code == 204
    assert resp.get_data() == b""


def test_delete_item_route_missing_returns_404(client, monkeypatch):
    monkeypatch.setattr(
        api_module.crud, "delete_item",
        lambda conn, item_id: {"deleted": False, "reason": "not_found"},
    )

    resp = client.delete("/items/ZZZZ")

    assert resp.status_code == 404
    assert resp.get_json()["error"] == "not_found"


def test_delete_item_route_foreign_key_conflict_returns_409(client, monkeypatch):
    # The Module 8 lesson's Python-side mirror: DG04 cannot be deleted
    # because invoice 50710 still references it in INVOICE_LINE.
    monkeypatch.setattr(
        api_module.crud, "delete_item",
        lambda conn, item_id: {"deleted": False, "reason": "referenced"},
    )

    resp = client.delete("/items/DG04")

    assert resp.status_code == 409
    body = resp.get_json()
    assert body["error"] == "referenced"


def test_delete_item_route_rejects_oversized_item_id_with_400(client, monkeypatch):
    called = MagicMock(side_effect=AssertionError("crud.delete_item should not be reached"))
    monkeypatch.setattr(api_module.crud, "delete_item", called)

    resp = client.delete("/items/" + "X" * 500)

    assert resp.status_code == 400
    body = resp.get_json()
    assert body["error"] == "invalid_request"
    assert body["field"] == "item_id"
    called.assert_not_called()


# ---------------------------------------------------------------------------
# Request body size cap
# ---------------------------------------------------------------------------

def test_post_items_rejects_body_over_max_content_length_with_413(client):
    # Regression test for MAX_CONTENT_LENGTH: a body larger than the
    # configured cap must be rejected before it is ever fully buffered into
    # memory, let alone reach request.get_json() or any route logic.
    oversized_body = b"a" * (api_module.app.config["MAX_CONTENT_LENGTH"] + 1)

    resp = client.post("/items", data=oversized_body, content_type="application/json")

    assert resp.status_code == 413
    body = resp.get_json()
    assert body["error"] == "payload_too_large"


# ---------------------------------------------------------------------------
# The "never leak raw DB internals to a client" property
# ---------------------------------------------------------------------------

def test_unexpected_exception_never_leaks_its_message_to_the_client(client, monkeypatch):
    # A regression test for the exact property api.py's module docstring and
    # handle_unexpected_error's comment both call out: whatever an
    # unexpected exception's own text says -- table names, column names,
    # driver-specific wording -- must never reach the HTTP response body.
    # This test fails the moment someone "helpfully" changes
    # handle_unexpected_error to return str(exc) to the client.
    secret_detail = "Unknown column 'ITEM_SECRET_INTERNAL_COST' in 'field list'"

    def boom(conn, category=None):
        raise RuntimeError(secret_detail)

    monkeypatch.setattr(api_module.crud, "list_items", boom)

    resp = client.get("/items")

    assert resp.status_code == 500
    raw_body = resp.get_data(as_text=True)
    assert secret_detail not in raw_body
    assert "ITEM_SECRET_INTERNAL_COST" not in raw_body

    body = resp.get_json()
    assert body["error"] == "internal_error"


def test_unexpected_database_error_never_leaks_its_message_to_the_client(client, monkeypatch):
    # Same property, but for a mysql.connector.Error specifically -- the
    # "database-flavored exception" case, which is the one most likely to
    # contain genuinely sensitive detail (credentials, schema layout).
    secret_detail = "Access denied for user 'root'@'localhost' (using password: YES)"

    def boom(conn, item_id):
        raise mysql.connector.Error(secret_detail)

    monkeypatch.setattr(api_module.crud, "get_item", boom)

    resp = client.get("/items/DG04")

    assert resp.status_code == 500
    raw_body = resp.get_data(as_text=True)
    assert "Access denied" not in raw_body
    assert "root" not in raw_body

    body = resp.get_json()
    assert body["error"] == "internal_error"
