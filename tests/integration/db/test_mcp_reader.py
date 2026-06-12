"""mcp_reader: grants on the two views ONLY. Draft specs structurally unreachable —
a role-grant fact, not an if-statement (PRD F3.5 hard rule).
"""
import psycopg
import pytest

from .conftest import as_role

DENIED_TABLES = [
    "specs", "spec_sections", "spec_versions", "chunks", "documents", "workspaces", "verdicts"
]


@pytest.mark.parametrize("table", DENIED_TABLES)
def test_base_tables_structurally_denied(db, table):
    with as_role(db, "mcp_reader") as cur, pytest.raises(psycopg.errors.InsufficientPrivilege):
        cur.execute(f"SELECT * FROM {table} LIMIT 1")  # noqa: S608


def test_approved_specs_shows_only_approved(db):
    with as_role(db, "mcp_reader") as cur:
        cur.execute("SELECT ticket_key FROM approved_specs")
        keys = {r[0] for r in cur.fetchall()}
    assert "SPF-2" in keys          # approved
    assert "SPF-1" not in keys      # draft — unreachable
    assert "SPF-3" not in keys      # draft (ws_b) — unreachable


def test_approved_specs_serves_approved_snapshot(db):
    with as_role(db, "mcp_reader") as cur:
        cur.execute("SELECT snapshot FROM approved_specs WHERE ticket_key = 'SPF-2'")
        snapshot = cur.fetchone()[0]
    assert snapshot[0]["content"]["text"] == "approved story"


def test_opportunity_frequency_view_readable(db):
    with as_role(db, "mcp_reader") as cur:
        cur.execute("SELECT count(*) FROM opportunity_frequency")
        assert cur.fetchone()[0] >= 0


def test_draft_spec_unreachable_via_view_predicates(db):
    """Even probing the view by a draft's ticket_key returns empty, never an error."""
    with as_role(db, "mcp_reader") as cur:
        cur.execute("SELECT count(*) FROM approved_specs WHERE ticket_key = 'SPF-1'")
        assert cur.fetchone()[0] == 0


def test_views_not_readable_by_authenticated(db):
    """Definer views bypass RLS — any tenant JWT must NOT reach them (PostgREST surface)."""
    from .conftest import user_a

    for view in ("approved_specs", "opportunity_frequency"):
        with user_a(db) as cur, pytest.raises(psycopg.errors.InsufficientPrivilege):
            cur.execute(f"SELECT * FROM {view} LIMIT 1")  # noqa: S608
