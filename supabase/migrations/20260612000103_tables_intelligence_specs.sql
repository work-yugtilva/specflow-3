-- Tech Stack §4.1 — Intelligence, Specs & MCP. Transcribed verbatim.

create table opportunities (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  name text,
  name_history jsonb default '[]',
  problem_statement text,
  status text check (status in ('candidate','draft','published','archived')),
  cluster_state text check (cluster_state in ('pending_review','approved')),
  centroid vector(1536),
  confidence text check (confidence in ('low','medium','high')),
  confidence_rationale text,
  raise_condition text,
  score numeric,
  score_inputs jsonb,
  counter_checked_n int,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  published_at timestamptz
);

create table opportunity_signals (
  opportunity_id uuid not null references opportunities(id),
  chunk_id uuid not null references chunks(id),
  stance text check (stance in ('support','counter')),
  similarity numeric,
  assigned_by text check (assigned_by in ('auto','operator','synthesis')),
  created_at timestamptz default now(),
  primary key (opportunity_id, chunk_id)
);

create table verdicts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  opportunity_id uuid not null references opportunities(id),
  verdict text check (verdict in ('act','park','reject')),
  reason_code text check (reason_code in ('wrong_cluster','already_knew','not_important','evidence_misread','other')),
  reason_text text,
  linked_url text,
  actor uuid,
  created_at timestamptz default now()
);

create table eval_labels (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  chunk_id uuid not null references chunks(id),
  expected_cluster_key text,
  labeled_by text check (labeled_by in ('operator','seed')),
  created_at timestamptz default now()
);

create table specs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  opportunity_id uuid not null references opportunities(id),
  title text,
  ticket_key text,
  status text check (status in ('draft','in_review','approved')),
  current_version int default 1,
  approved_version int,
  approved_by uuid,
  approved_at timestamptz,
  created_by uuid,
  created_at timestamptz default now()
);

create table spec_sections (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  spec_id uuid not null references specs(id),
  order_idx int,
  block_type text check (block_type in ('story','acceptance_criteria','edge_cases','data_model','api_contract','qa_checklist')),
  content jsonb,
  status text check (status in ('pending','accepted','edited','rejected')),
  evidence_refs jsonb,
  unevidenced bool default false,
  edit_diff jsonb,
  history jsonb default '[]',
  updated_by uuid,
  updated_at timestamptz
);

create table spec_versions (
  id uuid primary key default gen_random_uuid(),
  spec_id uuid not null references specs(id),
  version int,
  snapshot jsonb,
  created_by uuid,
  created_at timestamptz default now(),
  unique (spec_id, version)
);

create table mcp_tokens (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  name text,
  token_hash bytea,
  scopes text[] default '{read,flag}',
  created_by uuid,
  created_at timestamptz default now(),
  last_used_at timestamptz,
  revoked_at timestamptz
);

create table ambiguity_flags (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  spec_id uuid not null references specs(id),
  section_id uuid references spec_sections(id),
  question text,
  asked_via text,
  status text check (status in ('open','answered','escalated')),
  answer text,
  answered_by uuid,
  answered_at timestamptz,
  sla_due_at timestamptz,
  escalated_at timestamptz,
  created_at timestamptz default now()
);

create table engineer_ratings (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  spec_id uuid not null references specs(id),
  rating smallint check (rating between 1 and 5),
  missing_text text,
  rater_handle text,
  source text,
  created_at timestamptz default now()
);

create table rating_tokens (
  id uuid primary key default gen_random_uuid(),
  spec_id uuid not null references specs(id),
  token_hash bytea,
  expires_at timestamptz,
  used_at timestamptz
);

create table exports (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  spec_id uuid not null references specs(id),
  target text check (target in ('linear','jira','markdown')),
  external_key text,
  payload jsonb,
  created_at timestamptz default now()
);
