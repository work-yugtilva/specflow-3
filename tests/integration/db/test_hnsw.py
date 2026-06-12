"""HNSW index is USED — EXPLAIN must show an index scan, not a seq scan.

vector(1536) only: the 3072 column couldn't even build this index (Tech Stack §4.2).
"""
from .conftest import DOC_A, WS_A, ZVEC


def test_hnsw_index_scan_on_vector_query(db):
    # 1k rows with distinct random embeddings; i*0 correlates the subquery per row
    db.execute(
        "INSERT INTO chunks (id, workspace_id, document_id, text, char_start, char_end, embedding) "
        "SELECT gen_random_uuid(), %s, %s, 'v' || i, 0, 1, v.vec "
        "FROM generate_series(1, 1000) AS i, "
        "LATERAL (SELECT ('[' || string_agg(random()::text, ',') || ']')::vector(1536) AS vec "
        "         FROM generate_series(1, 1536 + (i - i))) v",  # (i-i) correlates: fresh vector per row
        (WS_A, DOC_A),
    )
    db.execute("ANALYZE chunks")
    db.execute("SET LOCAL hnsw.ef_search = 100")
    # cost model prefers seq scan at toy row counts; assertion is "index exists and is used
    # when scanning is viable", so pin the choice deterministically
    db.execute("SET LOCAL enable_seqscan = off")
    cur = db.execute(
        f"EXPLAIN SELECT id FROM chunks ORDER BY embedding <=> '{ZVEC}'::vector(1536) LIMIT 10"
    )
    plan = "\n".join(r[0] for r in cur.fetchall())
    assert "Index Scan" in plan, plan
    assert "hnsw" in plan.lower() or "embedding" in plan, plan


def test_embedding_dimension_is_1536(db):
    cur = db.execute(
        "SELECT atttypmod FROM pg_attribute "
        "WHERE attrelid = 'chunks'::regclass AND attname = 'embedding'"
    )
    assert cur.fetchone()[0] == 1536
