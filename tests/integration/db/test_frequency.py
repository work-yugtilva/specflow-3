"""Frequency = unique humans, never message count (PRD F1 L3).

15 messages from one human MUST yield frequency 1. View is the only place the math lives.
"""
from .conftest import DOC_A, IDENT_A1, IDENT_A2, IDENT_A3, WS_A

OPP_F = "00000000-0000-0004-00ff-00000000000a"


def _mk_opportunity(db):
    db.execute(
        "INSERT INTO opportunities (id, workspace_id, name, status, cluster_state) "
        "VALUES (%s, %s, 'freq test', 'candidate', 'pending_review')",
        (OPP_F, WS_A),
    )


def _add_signal(db, identity_id, stance="support", n=1):
    for _ in range(n):
        cur = db.execute(
            "INSERT INTO chunks "
            "(id, workspace_id, document_id, text, char_start, char_end, identity_id) "
            "VALUES (gen_random_uuid(), %s, %s, 'm', 0, 1, %s) RETURNING id",
            (WS_A, DOC_A, identity_id),
        )
        chunk_id = cur.fetchone()[0]
        db.execute(
            "INSERT INTO opportunity_signals "
            "(opportunity_id, chunk_id, stance, similarity, assigned_by) "
            "VALUES (%s, %s, %s, 0.9, 'auto')",
            (OPP_F, chunk_id, stance),
        )


def _freq(db):
    cur = db.execute(
        "SELECT unique_humans FROM opportunity_frequency WHERE opportunity_id = %s", (OPP_F,)
    )
    row = cur.fetchone()
    return row[0] if row else 0


def test_fifteen_messages_one_human_is_frequency_one(db):
    _mk_opportunity(db)
    _add_signal(db, IDENT_A1, n=15)
    assert _freq(db) == 1


def test_counter_stance_excluded(db):
    _mk_opportunity(db)
    _add_signal(db, IDENT_A1, n=15)
    _add_signal(db, IDENT_A2, stance="counter")
    assert _freq(db) == 1


def test_null_identity_excluded(db):
    _mk_opportunity(db)
    _add_signal(db, IDENT_A1, n=15)
    _add_signal(db, None)
    assert _freq(db) == 1


def test_three_humans_is_three(db):
    _mk_opportunity(db)
    _add_signal(db, IDENT_A1, n=5)
    _add_signal(db, IDENT_A2, n=5)
    _add_signal(db, IDENT_A3, n=5)
    assert _freq(db) == 3
