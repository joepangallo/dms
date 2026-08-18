"""
Tests for db.py's get_connection().

No real MySQL server is ever contacted here: mysql.connector.connect is
replaced with a MagicMock for every test, per this repo's rule that tests
never require a live external service. What's actually under test is
db.py's own logic -- which environment variables it requires, what error it
raises when one is missing, and exactly what it passes through to the
driver's connect() call when everything is present.
"""

from unittest.mock import MagicMock, patch

import pytest

import db


# The four variables get_connection() refuses to run without. Parametrizing
# over "which one is missing" -- rather than writing four near-identical
# tests -- is what makes it obvious at a glance that every required var is
# actually covered, and that adding a fifth one to db.py without a
# matching test case here would leave a visible gap instead of a silent one.
@pytest.mark.parametrize("missing_var", ["DB_HOST", "DB_USER", "DB_PASSWORD", "DB_NAME"])
def test_get_connection_raises_when_a_required_var_is_missing(monkeypatch, missing_var):
    all_vars = {
        "DB_HOST": "myhost",
        "DB_USER": "myuser",
        "DB_PASSWORD": "mypassword",
        "DB_NAME": "mydb",
    }
    for name, value in all_vars.items():
        monkeypatch.setenv(name, value)
    monkeypatch.delenv(missing_var, raising=False)

    # The connect() call must never even be attempted when a required
    # variable is missing -- get_connection() should fail before it gets
    # anywhere near the driver.
    with patch("db.mysql.connector.connect") as mock_connect:
        with pytest.raises(RuntimeError, match=missing_var):
            db.get_connection()
        mock_connect.assert_not_called()


def test_get_connection_raises_when_var_is_present_but_empty(monkeypatch):
    # An empty string is exactly as unusable as an unset variable (a .env
    # line like "DB_PASSWORD=" left blank by accident) -- get_connection()
    # treats the two the same way rather than passing an empty password
    # through to the driver as if it were a real value.
    monkeypatch.setenv("DB_HOST", "myhost")
    monkeypatch.setenv("DB_USER", "myuser")
    monkeypatch.setenv("DB_PASSWORD", "")
    monkeypatch.setenv("DB_NAME", "mydb")

    with pytest.raises(RuntimeError, match="DB_PASSWORD"):
        db.get_connection()


def test_get_connection_passes_env_vars_through_with_default_port(monkeypatch):
    monkeypatch.setenv("DB_HOST", "db.example.internal")
    monkeypatch.setenv("DB_USER", "module9_app")
    monkeypatch.setenv("DB_PASSWORD", "s3cret")
    monkeypatch.setenv("DB_NAME", "practice_db")
    monkeypatch.delenv("DB_PORT", raising=False)

    fake_connection = MagicMock(name="fake_mysql_connection")
    with patch("db.mysql.connector.connect", return_value=fake_connection) as mock_connect:
        result = db.get_connection()

    mock_connect.assert_called_once_with(
        host="db.example.internal",
        port=3306,  # MySQL's own default -- DB_PORT was never set above
        user="module9_app",
        password="s3cret",
        database="practice_db",
        connection_timeout=db.CONNECTION_TIMEOUT_SECONDS,
    )
    assert result is fake_connection


def test_get_connection_honors_an_explicit_port(monkeypatch):
    monkeypatch.setenv("DB_HOST", "db.example.internal")
    monkeypatch.setenv("DB_PORT", "3307")
    monkeypatch.setenv("DB_USER", "module9_app")
    monkeypatch.setenv("DB_PASSWORD", "s3cret")
    monkeypatch.setenv("DB_NAME", "practice_db")

    with patch("db.mysql.connector.connect") as mock_connect:
        db.get_connection()

    _, kwargs = mock_connect.call_args
    # int(), not the raw string "3307" -- mysql.connector expects an actual
    # int for port, and os.environ always hands back strings.
    assert kwargs["port"] == 3307
    assert isinstance(kwargs["port"], int)
