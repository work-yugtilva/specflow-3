-- Tech Stack §4.3 indexes (verbatim) + §4.4 tsv trigger.

create index on chunks using hnsw (embedding vector_cosine_ops) with (m=16, ef_construction=64);
-- query-time: SET LOCAL hnsw.ef_search = 100;
create index on chunks using gin (tsv);
create index on chunks (workspace_id, posted_at);
create index on chunks (workspace_id, identity_id);
create index on integration_events (workspace_id, provider, processed_at) where processed_at is null;

create function chunks_tsv_update() returns trigger language plpgsql as $$
begin
  new.tsv := to_tsvector('english', coalesce(new.text, ''));
  return new;
end $$;

create trigger chunks_tsv_trg before insert or update of text on chunks
  for each row execute function chunks_tsv_update();
