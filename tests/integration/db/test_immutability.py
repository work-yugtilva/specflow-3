"""audit_log + verdicts: append-only via BOTH locks — REVOKE and trigger."""
import psycopg
import pytest

from .conftest import WS_A, user_a

TABLES = ["audit_log", "verdicts"]


@pytest.mark.parametrize("table", TABLES)
def test_revoke_lock_update_denied_for_authenticated(db, table):
    with user_a(db) as cur, pytest.raises(psycopg.errors.InsufficientPrivilege):
        cur.execute(  # noqa: S608
            f"UPDATE {table} SET workspace_id = workspace_id WHERE workspace_id = %s", (WS_A,)
        )


@pytest.mark.parametrize("table", TABLES)
def test_revoke_lock_delete_denied_for_authenticated(db, table):
    with user_a(db) as cur, pytest.raises(psycopg.errors.InsufficientPrivilege):
        cur.execute(f"DELETE FROM {table} WHERE workspace_id = %s", (WS_A,))  # noqa: S608


@pytest.mark.parametrize("table", TABLES)
def test_trigger_lock_update_raises_even_for_superuser(db, table):
    with pytest.raises(psycopg.errors.RaiseException, match="append-only"):
        db.execute(f"UPDATE {table} SET workspace_id = workspace_id")  # noqa: S608


@pytest.mark.parametrize("table", TABLES)
def test_trigger_lock_delete_raises_even_for_superuser(db, table):
    with pytest.raises(psycopg.errors.RaiseException, match="append-only"):
        db.execute(f"DELETE FROM {table}")  # noqa: S608


@pytest.mark.parametrize("table", TABLES)
def test_truncate_denied_for_authenticated(db, table):
    with user_a(db) as cur, pytest.raises(psycopg.errors.InsufficientPrivilege):
        cur.execute(f"TRUNCATE {table}")  # noqa: S608


@pytest.mark.parametrize("table", TABLES)
def test_truncate_trigger_raises_even_for_superuser(db, table):
    with pytest.raises(psycopg.errors.RaiseException, match="append-only"):
        db.execute(f"TRUNCATE {table}")  # noqa: S608
