-- Tech Stack §4.3 views (verbatim SQL) + mcp_reader role: grants on views ONLY.
-- Draft/in-review specs unreachable by construction — no grant on specs/spec_sections.

create view opportunity_frequency as
select os.opportunity_id, count(distinct c.identity_id) as unique_humans
from opportunity_signals os join chunks c on c.id = os.chunk_id
where os.stance = 'support' and c.identity_id is not null
group by os.opportunity_id;

create view approved_specs as
select s.id, s.workspace_id, s.ticket_key, s.title, v.snapshot, s.approved_at, s.approved_by
from specs s join spec_versions v on v.spec_id = s.id and v.version = s.approved_version
where s.status = 'approved';

do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'mcp_reader') then
    create role mcp_reader nologin;
  end if;
end $$;

grant usage on schema public to mcp_reader;
grant mcp_reader to postgres;  -- lets admin/test sessions assume the role (parity with authenticated)
grant select on opportunity_frequency, approved_specs to mcp_reader;

-- Hardened supabase images grant API roles no DML by default — explicit grants here;
-- RLS (0108) constrains rows, 0107 revokes append-only tables AFTER these grants.
grant select, insert, update, delete on all tables in schema public to authenticated, service_role;
grant usage, select on all sequences in schema public to authenticated, service_role;
