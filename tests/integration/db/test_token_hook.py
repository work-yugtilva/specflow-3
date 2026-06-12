"""Custom Access Token Hook injects {workspace_ids, roles, is_operator} (Tech Stack §5)."""
import json

from .conftest import USER_A, USER_A2, USER_B, USER_OP, WS_A, WS_B


def _run_hook(db, user_id):
    event = {"user_id": user_id, "claims": {"role": "authenticated", "aud": "authenticated"}}
    cur = db.execute("SELECT public.custom_access_token(%s::jsonb)", (json.dumps(event),))
    return cur.fetchone()[0]["claims"]


def test_owner_claims(db):
    claims = _run_hook(db, USER_A)
    am = claims["app_metadata"]
    assert am["workspace_ids"] == [WS_A]
    assert am["roles"] == {WS_A: "owner"}
    assert am["is_operator"] is False


def test_member_claims(db):
    claims = _run_hook(db, USER_A2)
    am = claims["app_metadata"]
    assert am["workspace_ids"] == [WS_A]
    assert am["roles"] == {WS_A: "member"}


def test_operator_flag_from_app_metadata(db):
    claims = _run_hook(db, USER_OP)
    am = claims["app_metadata"]
    assert am["is_operator"] is True
    assert am["workspace_ids"] == []


def test_existing_claims_preserved(db):
    claims = _run_hook(db, USER_B)
    assert claims["role"] == "authenticated"
    assert claims["aud"] == "authenticated"
    assert claims["app_metadata"]["workspace_ids"] == [WS_B]
