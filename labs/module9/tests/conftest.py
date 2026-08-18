"""
Shared pytest setup for Module 9's test suite.

The files under test (db.py, crud.py, api.py, migrations/migrate.py) are
flat teaching scripts, not an installed package -- there's no setup.py or
pyproject.toml giving them an import path. Adding both this module's root
directory and its migrations/ subdirectory to sys.path here, once, means
every test file below can just write `import db` / `import crud` /
`import api` / `import migrate`, exactly the way a student running these
scripts by hand from a plain checkout would -- regardless of whether pytest
itself is invoked from labs/module9/ or from somewhere else entirely.

This file deliberately does nothing else: no fixtures live here that are
specific to one module under test (those live next to the tests that need
them), and nothing here touches a network, a database, or the real
filesystem beyond this one path computation.
"""

import os
import sys

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
MODULE9_DIR = os.path.dirname(TESTS_DIR)
MIGRATIONS_DIR = os.path.join(MODULE9_DIR, "migrations")

for _path in (MODULE9_DIR, MIGRATIONS_DIR):
    if _path not in sys.path:
        sys.path.insert(0, _path)
