"""Cross-tenant denial: reads return EMPTY (never an error — errors leak existence).

Runs as `authenticated` with request.jwt.claims per case. service_role proves nothing.
"""
import psycopg
import pytest

from .conftest import OPP_B, RUN_B, SPEC_B_DRAFT, WS_A, WS_B, user_a, user_a_member, user_b
from .tables import IMMUTABLE, OWNER_GATED, PARENT_TABLES, WS_TABLES

PARENT_B_ID = {"opportunities": OPP_B, "specs": SPEC_B_DRAFT, "pipeline_runs": RUN_B}


@pytest.mark.parametrize("table", WS_TABLES)
def test_select_cross_tenant_empty(db, table):
    with user_a(db) as cur:
        cur.execute(  # noqa: S608 — table from fixed registry
            f"SELECT count(*) FROM {table} WHERE workspace_id = %s", (WS_B,)
        )
        assert cur.fetchone()[0] == 0


def test_select_workspaces_cross_tenant_empty(db):
    with user_a(db) as cur:
        cur.execute("SELECT count(*) FROM workspaces WHERE id = %s", (WS_B,))
        assert cur.fetchone()[0] == 0


@pytest.mark.parametrize("table,fk", [(t, fk) for t, (fk, _) in PARENT_TABLES.items()])
def test_select_parent_scoped_cross_tenant_empty(db, table, fk):
    parent_b = {"opportunity_id": OPP_B, "spec_id": SPEC_B_DRAFT, "run_id": RUN_B}[fk]
    with user_a(db) as cur:
        cur.execute(f"SELECT count(*) FROM {table} WHERE {fk} = %s", (parent_b,))  # noqa: S608
        assert cur.fetchone()[0] == 0


@pytest.mark.parametrize("table", [t for t in WS_TABLES if t not in OWNER_GATED])
def test_select_own_tenant_visible(db, table):
    with user_a_member(db) as cur:
        cur.execute(f"SELECT count(*) FROM {table} WHERE workspace_id = %s", (WS_A,))  # noqa: S608
        assert cur.fetchone()[0] >= 1


@pytest.mark.parametrize("table", [t for t in WS_TABLES if t not in OWNER_GATED])
def test_select_ws_b_sees_own_rows(db, table):
    """Guards the cross-tenant-empty tests against vacuous passes (missing WS B seed)."""
    with user_b(db) as cur:
        cur.execute(f"SELECT count(*) FROM {table} WHERE workspace_id = %s", (WS_B,))  # noqa: S608
        assert cur.fetchone()[0] >= 1


@pytest.mark.parametrize("table", sorted(OWNER_GATED))
def test_owner_gated_owner_sees_member_does_not(db, table):
    with user_a(db) as cur:
        cur.execute(f"SELECT count(*) FROM {table} WHERE workspace_id = %s", (WS_A,))  # noqa: S608
        assert cur.fetchone()[0] >= 1
    with user_a_member(db) as cur:
        cur.execute(f"SELECT count(*) FROM {table} WHERE workspace_id = %s", (WS_A,))  # noqa: S608
        assert cur.fetchone()[0] == 0


@pytest.mark.parametrize("table", [t for t in WS_TABLES if t not in IMMUTABLE])
def test_update_cross_tenant_zero_rows(db, table):
    with user_a(db) as cur:
        cur.execute(  # noqa: S608
            f"UPDATE {table} SET workspace_id = workspace_id WHERE workspace_id = %s", (WS_B,)
        )
        assert cur.rowcount == 0


@pytest.mark.parametrize("table", [t for t in WS_TABLES if t not in IMMUTABLE])
def test_delete_cross_tenant_zero_rows(db, table):
    with user_a(db) as cur:
        cur.execute(f"DELETE FROM {table} WHERE workspace_id = %s", (WS_B,))  # noqa: S608
        assert cur.rowcount == 0


@pytest.mark.parametrize(
    "stmt",
    [
        "INSERT INTO documents (id, workspace_id, kind, title, status) "
        f"VALUES (gen_random_uuid(), '{WS_B}', 'transcript', 'x', 'queued')",
        "INSERT INTO identities (id, workspace_id, display_name) "
        f"VALUES (gen_random_uuid(), '{WS_B}', 'Eve')",
        "INSERT INTO opportunities (id, workspace_id, name, status, cluster_state) "
        f"VALUES (gen_random_uuid(), '{WS_B}', 'evil', 'candidate', 'pending_review')",
        "INSERT INTO glossary_terms (id, workspace_id, term, definition) "
        f"VALUES (gen_random_uuid(), '{WS_B}', 'x', 'y')",
    ],
)
def test_insert_cross_tenant_rejected(db, stmt):
    with user_a(db) as cur, pytest.raises(psycopg.errors.Error) as exc:
        cur.execute(stmt)
    assert isinstance(
        exc.value, psycopg.errors.InsufficientPrivilege | psycopg.errors.RaiseException
    ) or "row-level security" in str(exc.value)


def test_signal_cannot_link_foreign_chunk(db):
    """Own opportunity + another tenant's chunk must be rejected — frequency-pollution hole."""
    from .conftest import CHUNK_B, OPP_A

    with user_a(db) as cur, pytest.raises(psycopg.errors.Error):
        cur.execute(
            "INSERT INTO opportunity_signals "
            "(opportunity_id, chunk_id, stance, similarity, assigned_by) "
            "VALUES (%s, %s, 'support', 0.9, 'auto')",
            (OPP_A, CHUNK_B),
        )
