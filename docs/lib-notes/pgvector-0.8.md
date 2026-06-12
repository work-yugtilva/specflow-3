# pgvector 0.8 — §2 extract (context7 /pgvector/pgvector)

- HNSW cosine: `CREATE INDEX ON t USING hnsw (col vector_cosine_ops) WITH (m=16, ef_construction=64);` — matches Tech Stack §4.3 verbatim.
- Query knob: `SET LOCAL hnsw.ef_search = 100;` (per-txn).
- `vector` type HNSW max 2000 dims → vector(1536) OK, vector(3072) would FAIL at index build (the dead v2 bug).
- Operator for cosine distance ordering: `embedding <=> $1` (must ORDER BY ... LIMIT k for index use).
- Planner is cost-based: tiny tables → seq scan wins legitimately. For index-usage tests: seed real rows; `SET LOCAL enable_seqscan = off` acceptable in test to assert index *exists and is usable*.
- pg_trgm 1.6 + GIN tsv unchanged from training-data knowledge; no 0.8-specific deltas relevant to §2 DDL.
