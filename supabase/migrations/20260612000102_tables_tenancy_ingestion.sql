-- Tech Stack §4.1 — Tenancy & identity, Ingestion. Transcribed verbatim.

create table workspaces (
  id uuid primary key default gen_random_uuid(),
  name text,
  company text,
  timezone text default 'UTC',
  created_at timestamptz default now()
);

create table members (
  workspace_id uuid not null references workspaces(id),
  user_id uuid not null references auth.users(id),
  role text check (role in ('owner','member')),
  created_at timestamptz default now(),
  primary key (workspace_id, user_id)
);

create table invites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  email citext,
  role text,
  token_hash bytea,
  expires_at timestamptz,
  accepted_at timestamptz,
  revoked_at timestamptz
);

create table identities (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  display_name text,
  primary_email citext,
  plan_tier text,
  churned_at timestamptz,
  created_at timestamptz default now()
);

create table identity_handles (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  identity_id uuid not null references identities(id),
  platform text check (platform in ('slack','github','discord','email','intercom','zendesk','linear','jira')),
  handle text,
  unique (workspace_id, platform, handle)
);

create table glossary_terms (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  term citext,
  definition text,
  created_by uuid,
  unique (workspace_id, term)
);

create table sources (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  provider text,
  status text check (status in ('connected','paused','error','purging')),
  config jsonb,
  vault_secret_id uuid,
  last_sync_at timestamptz,
  created_at timestamptz default now()
);

create table upload_batches (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  file_count int,
  status text,
  created_by uuid,
  created_at timestamptz default now()
);

create table documents (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  source_id uuid references sources(id),
  batch_id uuid references upload_batches(id),
  kind text check (kind in ('transcript','csv','export','thread','issue','ticket','spec')),
  title text,
  storage_path text,
  parsed_json jsonb,
  metadata jsonb,
  status text check (status in ('queued','parsing','chunking','embedding','done','failed')),
  failure_reason text,
  created_at timestamptz default now()
);

create table chunks (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  document_id uuid not null references documents(id),
  text text,
  char_start int,
  char_end int,
  speaker text,
  author_handle text,
  identity_id uuid references identities(id),
  posted_at timestamptz,
  embedding vector(1536),
  tsv tsvector,
  intent text,
  sentiment text,
  urgency text,
  created_at timestamptz default now()
);

create table integration_events (
  id bigserial primary key,
  workspace_id uuid not null references workspaces(id),
  provider text,
  external_id text,
  event_type text,
  payload jsonb,
  dedup_key text unique,
  received_at timestamptz default now(),
  processed_at timestamptz
);
