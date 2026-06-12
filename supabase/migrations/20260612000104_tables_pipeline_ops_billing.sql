-- Tech Stack §4.1 — Pipeline, ops, billing. Transcribed verbatim.

create table pipeline_runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  trigger text check (trigger in ('upload_batch','sync_delta','nightly','manual')),
  status text check (status in ('running','waiting_review','complete','failed')),
  batch_id uuid references upload_batches(id),
  stats jsonb,
  started_at timestamptz default now(),
  finished_at timestamptz
);

create table pipeline_steps (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references pipeline_runs(id),
  step text check (step in ('parse','chunk','embed','classify','cluster','score','synthesize','publish')),
  status text check (status in ('queued','running','done','failed','skipped')),
  attempt int default 0,
  input_ref jsonb,
  output_ref jsonb,
  error text,
  started_at timestamptz,
  finished_at timestamptz
);

create table digests (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  sent_at timestamptz,
  payload jsonb,
  open_tracked bool
);

create table feature_outcomes (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  spec_id uuid not null references specs(id),
  metric_source text check (metric_source in ('amplitude','mixpanel','manual')),
  metric_key text,
  predicted jsonb,
  observed jsonb,
  window_days int,
  pulled_at timestamptz
);

create table audit_log (
  id bigserial primary key,
  workspace_id uuid not null references workspaces(id),
  actor_type text check (actor_type in ('user','operator','system','agent')),
  actor_id text,
  action text,
  object_type text,
  object_id uuid,
  payload jsonb,
  created_at timestamptz default now()
);

create table billing_customers (
  workspace_id uuid primary key references workspaces(id),
  stripe_customer_id text unique
);

create table billing_subscriptions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id),
  stripe_subscription_id text unique,
  status text,
  founding_partner bool default false,
  current_period_end timestamptz
);
