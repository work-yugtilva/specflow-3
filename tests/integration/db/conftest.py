"""Real-Postgres fixtures: local supabase stack only, no mocks (plan §2 non-negotiable).

RLS cases run as `authenticated` with request.jwt.claims set per case;
superuser conn is only for seeding and trigger-lock proofs.
"""
import json
import os
from collections.abc import Iterator
from contextlib import contextmanager

import psycopg
import pytest

DB_URL = os.environ.get(
    "SUPABASE_DB_URL", "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
)

WS_A = "00000000-0000-0000-0000-00000000000a"
WS_B = "00000000-0000-0000-0000-00000000000b"
USER_A = "00000000-0000-0000-0001-00000000000a"   # owner of ws_a
USER_A2 = "00000000-0000-0000-0002-00000000000a"  # member of ws_a
USER_B = "00000000-0000-0000-0001-00000000000b"   # owner of ws_b
USER_OP = "00000000-0000-0000-0003-00000000000f"  # operator-flagged
IDENT_A1 = "00000000-0000-0001-0001-00000000000a"
IDENT_A2 = "00000000-0000-0001-0002-00000000000a"
IDENT_A3 = "00000000-0000-0001-0003-00000000000a"
IDENT_B1 = "00000000-0000-0001-0001-00000000000b"
DOC_A = "00000000-0000-0002-0001-00000000000a"
DOC_B = "00000000-0000-0002-0001-00000000000b"
CHUNK_A = "00000000-0000-0003-0001-00000000000a"
CHUNK_B = "00000000-0000-0003-0001-00000000000b"
OPP_A = "00000000-0000-0004-0001-00000000000a"
OPP_B = "00000000-0000-0004-0001-00000000000b"
SPEC_A_DRAFT = "00000000-0000-0005-0001-00000000000a"
SPEC_A_APPROVED = "00000000-0000-0005-0002-00000000000a"
SPEC_B_DRAFT = "00000000-0000-0005-0001-00000000000b"
RUN_A = "00000000-0000-0006-0001-00000000000a"
RUN_B = "00000000-0000-0006-0001-00000000000b"

ZVEC = "[" + ",".join(["0"] * 1536) + "]"


def _claims(
    user_id: str, workspace_ids: list[str], roles: dict[str, str], is_operator: bool
) -> str:
    return json.dumps(
        {
            "sub": user_id,
            "role": "authenticated",
            "app_metadata": {
                "workspace_ids": workspace_ids,
                "roles": roles,
                "is_operator": is_operator,
            },
        }
    )


@pytest.fixture(scope="session")
def pg() -> Iterator[psycopg.Connection]:
    try:
        conn = psycopg.connect(DB_URL, autocommit=True)
    except psycopg.OperationalError as e:  # pragma: no cover
        raise RuntimeError(
            f"Local supabase stack unreachable at {DB_URL} — run `supabase start`. "
            "Mocked DB is forbidden for this suite."
        ) from e
    yield conn
    conn.close()


@pytest.fixture()
def db(pg: psycopg.Connection) -> Iterator[psycopg.Connection]:
    """Per-test superuser connection inside a rolled-back transaction."""
    conn = psycopg.connect(DB_URL)
    yield conn
    conn.rollback()
    conn.close()


@contextmanager
def as_user(
    conn: psycopg.Connection,
    user_id: str,
    workspace_ids: list[str],
    roles: dict[str, str],
    is_operator: bool = False,
) -> Iterator[psycopg.Cursor]:
    """Run statements as `authenticated` with JWT claims set (Tech Stack §5 shape)."""
    cur = conn.cursor()
    cur.execute("SET LOCAL ROLE authenticated")
    cur.execute(
        "SELECT set_config('request.jwt.claims', %s, true)",
        (_claims(user_id, workspace_ids, roles, is_operator),),
    )
    try:
        yield cur
    finally:
        _reset_role(conn, cur)


def _reset_role(conn: psycopg.Connection, cur: psycopg.Cursor) -> None:
    try:
        cur.execute("RESET ROLE")
    except psycopg.errors.InFailedSqlTransaction:
        conn.rollback()  # aborted txn: rollback ends it, SET LOCAL ROLE dies with it


@contextmanager
def as_role(conn: psycopg.Connection, role: str) -> Iterator[psycopg.Cursor]:
    cur = conn.cursor()
    cur.execute(f"SET LOCAL ROLE {role}")
    try:
        yield cur
    finally:
        _reset_role(conn, cur)


def user_a(conn: psycopg.Connection):
    return as_user(conn, USER_A, [WS_A], {WS_A: "owner"})


def user_a_member(conn: psycopg.Connection):
    return as_user(conn, USER_A2, [WS_A], {WS_A: "member"})


def user_b(conn: psycopg.Connection):
    return as_user(conn, USER_B, [WS_B], {WS_B: "owner"})


@pytest.fixture(scope="session", autouse=True)
def seed(pg: psycopg.Connection) -> None:
    sql = (os.path.join(os.path.dirname(__file__), "seed.sql"))
    with open(sql) as f:
        pg.execute(f.read())
