-- Tech Stack §5: audit_log + verdicts append-only — REVOKE and trigger, both locks.

-- image default ACLs hand TRUNCATE/TRIGGER/REFERENCES/MAINTAIN to API roles;
-- TRUNCATE bypasses RLS — strip all four everywhere
revoke truncate, trigger, references, maintain on all tables in schema public from anon, authenticated;

revoke update, delete on audit_log from public, anon, authenticated, service_role;
revoke update, delete on verdicts from public, anon, authenticated, service_role;

create function raise_immutable() returns trigger language plpgsql set search_path = '' as $$
begin
  raise exception 'append-only table % — % forbidden', tg_table_name, tg_op;
end $$;

create trigger audit_log_immutable before update or delete on audit_log
  for each statement execute function raise_immutable();
create trigger verdicts_immutable before update or delete on verdicts
  for each statement execute function raise_immutable();

-- TRUNCATE is a third erase path (default ACLs hand it to API roles): close it both ways too
revoke truncate on audit_log, verdicts from public, anon, authenticated, service_role;
create trigger audit_log_no_truncate before truncate on audit_log
  for each statement execute function raise_immutable();
create trigger verdicts_no_truncate before truncate on verdicts
  for each statement execute function raise_immutable();
