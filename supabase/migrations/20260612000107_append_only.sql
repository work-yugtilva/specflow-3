-- Tech Stack §5: audit_log + verdicts append-only — REVOKE and trigger, both locks.

revoke update, delete on audit_log from public, anon, authenticated, service_role;
revoke update, delete on verdicts from public, anon, authenticated, service_role;

create function raise_immutable() returns trigger language plpgsql as $$
begin
  raise exception 'append-only table % — % forbidden', tg_table_name, tg_op;
end $$;

create trigger audit_log_immutable before update or delete on audit_log
  for each statement execute function raise_immutable();
create trigger verdicts_immutable before update or delete on verdicts
  for each statement execute function raise_immutable();
