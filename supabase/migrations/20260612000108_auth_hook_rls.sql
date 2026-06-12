-- Tech Stack §5: claims hook, auth_workspaces() helper (verbatim), one policy shape on
-- every workspace table, owner-clause on admin tables, parent-EXISTS on child tables.

-- Custom Access Token Hook: injects {workspace_ids, roles, is_operator} into app_metadata
create function public.custom_access_token(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := (event->>'user_id')::uuid;
  ws uuid[];
  role_map jsonb;
  is_op boolean;
  claims jsonb := coalesce(event->'claims', '{}'::jsonb);
begin
  select coalesce(array_agg(m.workspace_id), '{}'),
         coalesce(jsonb_object_agg(m.workspace_id::text, m.role), '{}'::jsonb)
    into ws, role_map
    from public.members m
   where m.user_id = uid;

  select coalesce((u.raw_app_meta_data->>'is_operator')::boolean, false)
    into is_op
    from auth.users u
   where u.id = uid;

  claims := jsonb_set(
    claims, '{app_metadata}',
    coalesce(claims->'app_metadata', '{}'::jsonb)
      || jsonb_build_object(
           'workspace_ids', to_jsonb(ws),
           'roles', role_map,
           'is_operator', coalesce(is_op, false)));

  return jsonb_set(event, '{claims}', claims);
end $$;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.custom_access_token(jsonb) to supabase_auth_admin;
revoke execute on function public.custom_access_token(jsonb) from public, anon, authenticated;

-- RLS helper — verbatim Tech Stack §5
create function auth_workspaces() returns uuid[] language sql stable as $$
  select coalesce(
    (select array_agg(x::uuid) from jsonb_array_elements_text(
       auth.jwt()->'app_metadata'->'workspace_ids') as x), '{}');
$$;

-- enable RLS everywhere
alter table workspaces enable row level security;
alter table members enable row level security;
alter table invites enable row level security;
alter table identities enable row level security;
alter table identity_handles enable row level security;
alter table glossary_terms enable row level security;
alter table sources enable row level security;
alter table upload_batches enable row level security;
alter table documents enable row level security;
alter table chunks enable row level security;
alter table integration_events enable row level security;
alter table opportunities enable row level security;
alter table opportunity_signals enable row level security;
alter table verdicts enable row level security;
alter table eval_labels enable row level security;
alter table specs enable row level security;
alter table spec_sections enable row level security;
alter table spec_versions enable row level security;
alter table mcp_tokens enable row level security;
alter table ambiguity_flags enable row level security;
alter table engineer_ratings enable row level security;
alter table rating_tokens enable row level security;
alter table exports enable row level security;
alter table pipeline_runs enable row level security;
alter table pipeline_steps enable row level security;
alter table digests enable row level security;
alter table feature_outcomes enable row level security;
alter table audit_log enable row level security;
alter table billing_customers enable row level security;
alter table billing_subscriptions enable row level security;

-- workspaces: tenant key is id itself
create policy ws_isolation on workspaces for all
  using (id = any (auth_workspaces()));

-- one policy shape (Tech Stack §5)
create policy ws_isolation on identities for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on identity_handles for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on glossary_terms for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on sources for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on upload_batches for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on documents for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on chunks for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on integration_events for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on opportunities for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on verdicts for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on eval_labels for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on specs for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on spec_sections for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on ambiguity_flags for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on engineer_ratings for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on exports for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on pipeline_runs for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on digests for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on feature_outcomes for all
  using (workspace_id = any (auth_workspaces()));
create policy ws_isolation on audit_log for all
  using (workspace_id = any (auth_workspaces()));

-- owner-gated admin tables: + owner clause (Tech Stack §5)
create policy ws_isolation on members for all
  using (workspace_id = any (auth_workspaces())
     and (auth.jwt()->'app_metadata'->'roles'->>(workspace_id::text)) = 'owner');
create policy ws_isolation on invites for all
  using (workspace_id = any (auth_workspaces())
     and (auth.jwt()->'app_metadata'->'roles'->>(workspace_id::text)) = 'owner');
create policy ws_isolation on mcp_tokens for all
  using (workspace_id = any (auth_workspaces())
     and (auth.jwt()->'app_metadata'->'roles'->>(workspace_id::text)) = 'owner');
create policy ws_isolation on billing_customers for all
  using (workspace_id = any (auth_workspaces())
     and (auth.jwt()->'app_metadata'->'roles'->>(workspace_id::text)) = 'owner');
create policy ws_isolation on billing_subscriptions for all
  using (workspace_id = any (auth_workspaces())
     and (auth.jwt()->'app_metadata'->'roles'->>(workspace_id::text)) = 'owner');

-- child tables without workspace_id: scope via parent
create policy ws_isolation on opportunity_signals for all
  using (exists (select 1 from opportunities o
                 where o.id = opportunity_id
                   and o.workspace_id = any (auth_workspaces()))
     and exists (select 1 from chunks c
                 where c.id = chunk_id
                   and c.workspace_id = any (auth_workspaces())));
-- chunk-side check closes cross-tenant linkage: own opportunity + foreign chunk
-- would otherwise pollute opportunity_frequency through the definer-semantics view
create policy ws_isolation on spec_versions for all
  using (exists (select 1 from specs s
                 where s.id = spec_id
                   and s.workspace_id = any (auth_workspaces())));
create policy ws_isolation on rating_tokens for all
  using (exists (select 1 from specs s
                 where s.id = spec_id
                   and s.workspace_id = any (auth_workspaces())));
create policy ws_isolation on pipeline_steps for all
  using (exists (select 1 from pipeline_runs r
                 where r.id = run_id
                   and r.workspace_id = any (auth_workspaces())));
