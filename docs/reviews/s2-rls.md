# §2 RLS Adversarial Review Log

Scope: `supabase/migrations/20260612000106..0108` — views, mcp_reader grants, append-only locks, claims hook, all RLS policies.

## Review 1 — fresh-context verifier subagent (caveman:cavecrew-reviewer)

Brief: Tech Stack §4.3/§5 verbatim excerpts + 3 migration files, blind to implementation reasoning.

| # | Finding | Severity | Resolution |
|---|---------|----------|------------|
| V1 | `opportunity_frequency` lacks SECURITY DEFINER → mcp_reader SELECT would fail | critical (claimed) | **False positive — disproven empirically.** PG views run with owner privileges by default (`security_invoker=false`); `SECURITY DEFINER` is not view syntax. Live check: `reloptions=NULL` on both views; `SET ROLE mcp_reader; SELECT ticket_key FROM approved_specs` → `SPF-2`; `SELECT count(*) FROM opportunity_frequency` → 2. Test suite `test_mcp_reader.py` (6 tests) green as `mcp_reader`. |
| V2 | `approved_specs` same claim | critical (claimed) | Same disproof as V1. |
| V3 | 30/30 ENABLE RLS present | pass | — |
| V4 | 30/30 policies present, shapes match spec exactly (flat / owner-gated / parent-EXISTS) | pass | — |
| V5 | auth_workspaces() verbatim, hook claims shape + security definer + pinned search_path + execute revokes correct | pass | — |
| V6 | Both append-only locks present on both tables; grant(0106)→revoke(0107) ordering correct, no re-grant | pass | — |
| V7 | mcp_reader grants: two views only; no anon grants; WITH CHECK defaults correct for FOR ALL | pass | — |

Verifier verdict: HOLES (V1/V2). Post-disproof verdict: **SOUND** — zero real findings.

## Review 2 — codex (GPT) cross-vendor adversarial review

Run 1: hung after first-pass read (21m+ no progress, canceled at 12h42m elapsed wall clock). Run 2 (`--effort medium`): completed. Findings — **zero critical, three major**:

| # | Finding | Severity | Resolution |
|---|---------|----------|------------|
| C1 | Flat workspace tables check own `workspace_id` but not that FK parents share the workspace — cross-tenant linkage + FK existence oracle (specs→opportunities, verdicts→opportunities, chunks→documents/identities, documents→sources, exports→specs, feature_outcomes→specs) | major | **Partially fixed, remainder deferred with rationale.** The one instance that corrupts tenant data (`opportunity_signals` → foreign chunk polluting `opportunity_frequency` through the definer view) was found independently in self-review and fixed: chunk-side EXISTS added, denial test green. Full fix = composite FKs `(workspace_id, id)` on every child — a schema deviation from verbatim Tech Stack §4.1, requires unique(workspace_id,id) on parents. Logged as §20 security-hardening follow-up + ADR candidate. Exploit preconditions: attacker must hold a valid foreign-row UUID (gen_random_uuid, unguessable) and the API layer (§4, supabase-py w/ caller JWT) constructs FK references server-side. |
| C2 | JWT claims are stale until token expiry — removed/downgraded member retains access ≤1h (jwt_expiry 3600) | major | **Accepted by design, documented.** Claims-hook architecture is Tech Stack §5's explicit choice. Mitigations already specced elsewhere: §3 session refresh on membership mutation, G1 member-removal flow revokes sessions (plan §20 verifies). Window bounded by jwt_expiry. |
| C3 | TRUNCATE not covered by append-only locks; default ACLs hand TRUNCATE to API roles → delete-all bypass on audit_log/verdicts | major | **Fixed.** `revoke truncate` from all API roles + `BEFORE TRUNCATE` statement trigger on both tables (third lock). 4 new tests green (denied for authenticated, trigger raises for superuser). Seed fixture uses `session_replication_role=replica` escape. |

## Outcome

- Critical findings: **0 open** (none raised).
- Major: 1 fixed fully (C3), 1 fixed at the exploitable instance + follow-up logged (C1), 1 accepted-by-design with §3/§20 hooks (C2).
- Suite after fixes: **139/139 green** on real Postgres (local supabase stack).

## Review 3 — V-PROTOCOL code-reviewer subagent (fresh context, post-codex)

Found the one true critical of the section: broad DML grant covered the two definer views →
any authenticated JWT could read every tenant's `approved_specs`/`opportunity_frequency` via
PostgREST (live-proven by reviewer). **Fixed**: views revoked from anon/authenticated
(mcp_reader + service_role only) + denial test. Also fixed from same review: schema-wide revoke
of default-ACL TRUNCATE/TRIGGER/REFERENCES/MAINTAIN from API roles; search_path pinned on
trigger functions; ws_b visibility tests guard against vacuous denial passes. Noted for later
sections: §7/§9 need an invoker view or service-role path for board frequency; §15 must scope
opportunity_frequency app-side; hook registration must be repeated on hosted at deploy.

## Final state
Suite: **160/160 green** on real Postgres after all fixes. Open criticals: **0**.
