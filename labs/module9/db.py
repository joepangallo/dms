"""
Connection helper for the Module 9 labs.

Loads DB_HOST / DB_PORT / DB_USER / DB_PASSWORD / DB_NAME from a local .env
file (via python-dotenv) and the process environment, then hands back a live
mysql.connector connection. Every other file in this module calls
get_connection() rather than building its own connection -- that way there is
exactly one place that knows how to reach the database, and exactly one place
to change if the credential story ever changes (a connection pool, a socket
instead of a host/port, etc.).
"""

import os

import mysql.connector
from dotenv import load_dotenv

# A no-op if there is no .env file in the working directory (for example in a
# CI job that exports real environment variables another way). load_dotenv()
# never overwrites a variable the environment already has, so an exported
# shell variable always beats whatever .env says -- the same override order
# most twelve-factor tooling uses, and it means a student's real shell export
# can't be silently shadowed by a stale .env left over from an earlier lab.
load_dotenv()

REQUIRED_VARS = ("DB_HOST", "DB_USER", "DB_PASSWORD", "DB_NAME")

# Bounds how long a single connect() attempt can hang against a slow or
# unreachable DB_HOST. Without a driver-imposed timeout, a dead network path
# falls back to OS-level TCP defaults, which can take tens of seconds to
# minutes -- and because api.py opens one connection per request and the
# Flask dev server handles one request at a time, a single hung connect
# attempt stalls the entire app for every other client until it resolves.
# 10 seconds is generous for a real local or LAN database and still short
# enough that a genuinely unreachable host fails fast and visibly instead.
CONNECTION_TIMEOUT_SECONDS = 10


def get_connection():
    """Return a live mysql.connector connection built from the environment.

    Deliberately fails closed: if any of the four required variables is
    missing, this raises a RuntimeError naming exactly which one, instead of
    quietly falling back to a "convenient" default like host=localhost,
    user=root, password="". That kind of silent default is precisely the
    insecure-by-default pattern this module is teaching students to avoid --
    it would let a half-configured app "just work" against a wide-open local
    root account in the sandbox, then fail in a confusing way (or, worse,
    connect to the wrong database without complaint) the first time it's
    pointed at a real server. Naming the missing variable means the fix is
    obvious straight from the error message, with no guessing.
    """
    config = {}
    for var in REQUIRED_VARS:
        value = os.environ.get(var)
        if not value:
            raise RuntimeError(
                f"{var} is not set. Copy .env.example to .env and fill in a "
                f"real value, or export {var} in your shell before running "
                f"this script."
            )
        config[var] = value

    return mysql.connector.connect(
        host=config["DB_HOST"],
        # DB_PORT is the one optional setting here -- 3306 is MySQL's own
        # default, and forcing every .env to spell it out would just be one
        # more line a student can copy wrong for zero added safety.
        port=int(os.environ.get("DB_PORT", "3306")),
        user=config["DB_USER"],
        password=config["DB_PASSWORD"],
        database=config["DB_NAME"],
        connection_timeout=CONNECTION_TIMEOUT_SECONDS,
    )
