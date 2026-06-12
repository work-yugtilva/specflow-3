# SpecFlow AI — Tech Stack v3 (Unified · Definitive)

**Status:** v3.0 · June 11, 2026 · One stack for the entire product described in PRD v2. No phase tags. Every layer decided. Where v2 deferred a call for maturity reasons, the call is made here. **Authority:** PRD v2 for product scope; Tech Stack v2 decisions carried unless explicitly corrected in §12.

---

## 0. Decision Principles

1. **Reuse beats rebuild.** The working FastAPI + Supabase + pgvector system with the citation pipeline, Slack ingest, TipTap diff editing, and RLS multi-tenancy is the foundation. Nothing replaces a working layer without user-visible value.
2. **Two model vendors.** Anthropic (all reasoning) + OpenAI (embeddings only). Quality disputes are settled by the eval harness, never by adding a vendor.
3. **Postgres until it breaks.** Vectors, full-text, job queue, pipeline state, audit log, identity graph, eval labels — one Postgres. New infrastructure must displace a *measured* bottleneck.
4. **Config-driven, never hardcoded.** Prompts, model routing, clustering thresholds, scoring weights are versioned YAML under `config/`, changed only through PRs gated by evals.
5. **Auditable by construction.** Every mutating action — human, operator, pipeline, or agent — writes `audit_log` in the same transaction. The YC bar ("every decision traceable from raw signal to shipped spec") is a schema property, not a feature.
6. **Solo-founder ops budget: near zero.** Nothing that needs a pager, a cluster, or weekly babysitting.

---

## 1. Stack Map (every layer, one line each)

| Layer | Decision | Rejected alternative | Why |
|---|---|---|---|
| FE framework | Next.js 14.2 App Router · React 18.3 · TS 5.x strict | Next 15/16 upgrade-as-project | Upgrade is a maintenance chore, never a milestone |
| FE styling | Existing inline-styles brand system (paper/terra/sage/charcoal; Instrument Serif + DM Sans + mono) | Tailwind 4 + shadcn | Restyle rewrite = negative-value work |
| FE server state | TanStack Query v5, keyed by route params | Redux/Zustand stores | Kills the triplicated-session-state bug class |
| FE realtime | Polling: 2 s (active jobs), 30 s (inbox/queue badges) | SSE, WebSockets, Supabase Realtime | Stateless across deploys; nothing in the product is sub-second collaborative |
| Rich text / diff | TipTap 2.6 (block editor, inline diff, accept/reject — already built) + `diff-match-patch` for version compare | ProseMirror raw, Lexical | The review canvas exists; rebuilding it is theater |
| FE hosting | Vercel (preview deploy per PR) | — | Carried |
| BE framework | FastAPI 0.115 · Python 3.12 · Pydantic v2.9 | Node/TS backend | AI tooling is Python-first; system already exists |
| API style | REST, versioned `/v1`, OpenAPI free | GraphQL | One consumer (our FE) + MCP; GraphQL buys nothing |
| DB access | supabase-py (PostgREST, caller-JWT, RLS-enforced) for API reads/writes · SQLAlchemy 2.0 Core async (psycopg3) for pipeline batch SQL | Drizzle (TS — cannot exist in a Python backend), Django ORM | Split matches trust boundary: user paths go through RLS, worker is service-role with explicit scoping |
| Queue | Procrastinate 2.x (Postgres-backed, psycopg3) | Inngest, BullMQ+Redis, Celery+Redis | Transactional with the rows it processes; queryable for progress UI; zero new infra |
| Pipeline orchestration | Homegrown Postgres state machine: `pipeline_runs` + `pipeline_steps`, advanced by `Orchestrator` | LangGraph — **permanently rejected** (§6.0) | The pipeline is a static DAG with two human gates already modeled in the DB; a graph framework duplicates state outside the audit-aligned schema |
| Agent framework | None. Direct Anthropic SDK + Pydantic-validated structured outputs | LangChain, LlamaIndex, CrewAI | Every abstraction layer between us and the model is a debugging layer; structured-output + retries is ~200 lines we own |
| Reasoning models | Claude Opus 4.8 (spec gen) · Sonnet 4.6 (synthesis/naming/judges) · Haiku 4.5 (classify/lint/triage) | Gemini, Cohere | Two-vendor rule; routing table §6.4 |
| Embeddings | OpenAI `text-embedding-3-large` at **`dimensions: 1536`** | 3072-dim (v2's spec — see §12, it cannot be HNSW-indexed), Voyage | Matryoshka truncation, ~99% retrieval quality, half the storage, under pgvector's 2000-dim HNSW ceiling |
| Vector store | pgvector 0.8 (HNSW, cosine) in the primary Postgres | Pinecone | Stays killed; one database |
| Full-text | Postgres FTS (`tsvector`, `ts_rank_cd`, `websearch_to_tsquery`) | Elasticsearch, true BM25 service | FTS is BM25-approximate; corpus per workspace is 10⁴–10⁵ chunks |
| Retrieval fusion | RRF (k=60) over dense top-50 + FTS top-50, workspace-scoped | Cross-encoder rerank — **permanently out** | Adds a vendor (violates rule 2) or self-hosted infra (violates rule 6); Sonnet does in-context selection at synthesis time anyway |
| Integrations, community class | Direct: Slack OAuth v2, GitHub App, Discord gateway bot | Nango for these | Discord *requires* a gateway (no middleware does it); Slack/GitHub are built and event semantics matter |
| Integrations, ticket/support class | **Nango Cloud**: Linear, Jira, Intercom, Zendesk (OAuth + webhook normalization + sync) | Four hand-rolled OAuth flows | At 7+ providers total, unified middleware pays for itself — the threshold v2 set is met by the full product |
| Outcome analytics | Amplitude Export API + Mixpanel Raw Export, direct scheduled pulls | Nango (no good fit), event SDK embedding | Batch read-only pulls; keys in Vault |
| MCP server | Official `mcp` Python SDK ≥1.2, Streamable HTTP, separate Railway service at `mcp.specflow.ai` | stdio transport, REST-pretending-to-be-MCP | Remote multi-tenant server ⇒ HTTP; stdio is local-only |
| Auth | Supabase Auth: magic link (sole Phase 1 method; Google OAuth deferred per ADR-005; SAML stub until a contract funds the upgrade) | Clerk (stays killed), WorkOS | One Supabase identity system keeps sessions/RLS unchanged; WorkOS means bridging two identity systems |
| Roles | `owner` · `member`, plus `is_operator` JWT claim (founder only) | YC brief's owner/PM/engineer/reviewer matrix | Permissions only fork at admin actions; reviewer/engineer are *attributions* (recorded everywhere), not permissions. Role theater rejected |
| File storage | Supabase Storage, per-workspace prefix, signed direct uploads | Cloudflare R2 | One fewer vendor; egress is rounding error |
| Email | Resend: SMTP for Supabase Auth mail, API + React Email for digests, open webhooks → PostHog | SES, Postmark | Carried |
| Payments | **Stripe Billing**: workspace-level subscription, customer portal, webhook-driven entitlements. **No per-seat pricing — schema cannot express seats** | Manual invoicing (v2's choice — fine at 10, not a product) | The full product self-serves; per-seat is banned because every taxed engineer seat is a lost MCP query |
| Product analytics | PostHog (full event map §8) | Amplitude for ourselves | TTFI funnel is the contract |
| LLM observability | Helicone proxy on Anthropic + OpenAI; per-workspace cost rollup; $40/workspace/mo alert | Langfuse, homegrown | Carried; tagging schema §8 |
| Evals | Braintrust: `clustering-golden`, `card-synthesis-golden`, `spec-golden` datasets; CI merge gate | Promptfoo, vibes | The harness v1 named, v2 specced, v3 wires into branch protection |
| Errors/logs | Sentry (FE + BE + cron check-ins) · structlog JSON with redaction processor | Datadog | Free tier; no pager — alerts go to Slack `#alerts` |
| BE hosting | Railway: `api`, `worker`, `mcp` — three services, **one Docker image**, three start commands | Fly, ECS | Carried; blast-radius isolation per service |
| Secrets | Platform env vars for app config · **Supabase Vault** for tenant integration tokens | Tokens in app tables | Encrypted at rest, never queryable by app role |
| Compliance | Vanta (monitors Supabase/Railway/Vercel/GitHub) → SOC2 Type I, then II | Manual evidence collection | The architecture is already audit-shaped; Vanta makes the paperwork a subscription |
| Data residency | Single region, AWS us-east-1 (Supabase + Railway co-located) | EU project | Not offered. One region until a signed contract requires otherwise |

---

## 2. Frontend

**Next.js 14.2 App Router, React 18.3, TypeScript strict.** Server components fetch initial board/card payloads from the FastAPI `/v1` surface (never PostgREST directly — one API surface, one auth path); client interactivity hydrates through TanStack Query v5 with query keys derived from route params. Mutations invalidate by key; optimistic updates only on verdicts (the one interaction where latency is felt).

**Session:** `@supabase/ssr` manages the HttpOnly Secure cookie; the JWT never touches `localStorage` or client state. Auth pages are custom (`/login`, `/auth/callback`, `/invite/[token]`) — magic link with 60 s resend cooldown is the sole Phase 1 sign-in method; Google OAuth is deferred per ADR-005; SAML remains a stub until a contract funds the upgrade. The FE only renders "Continue with SSO" when the email domain maps to a registered IdP via `GET /v1/auth/sso-check?domain=`, and that map is empty by default.

**Styling:** the established brand system only — paper `#F8F4EF`, terra `#E8561B`, sage `#3D6B5E`, charcoal `#0D0D0D`; Instrument Serif (display), DM Sans (body), monospace (quote metadata); editorial glassmorphism on overlays; **inline styles exclusively**. No Tailwind, no CSS-in-JS library, no new framework. Skeletons in paper tones, never spinners-on-white; destructive failures are inline banners, never toasts.

**Realtime behavior — polling, deliberately:**
- Upload processing (`/w/[ws]/uploads/[batch]`): 2 s poll against `GET /v1/uploads/{batch}` (reads `pipeline_steps` + per-document status). Survives deploys because state is rows, not connections.
- Ambiguity inbox + operator queue badges: 30 s poll. SLA countdowns render client-side from `sla_due_at`.
- Board: refetch on focus + after any mutation. No live push anywhere. Real-time collaborative editing is **out of the product** (PRD §4d) — single-reviewer spec canvas with append-only verdict logs makes last-write-wins a display question.

**Review canvas:** TipTap 2.6 block editor (already built) with custom marks for inline diff and per-block accept/reject controls; the evidence rail is a sibling scroll-synced column driven by `spec_sections.evidence_refs`. Version compare runs `diff-match-patch` over `spec_versions.snapshot` section text, structural add/remove computed on the section array.

**Mobile:** board + card detail render read-only-comfortable to 380 px. Upload, identities, canvas, ops are desktop surfaces — stated in the UI, not pretended otherwise.

---

## 3. Backend & Service Architecture

**One FastAPI app, one Docker image, three Railway services:**

| Service | Start command | Responsibility |
|---|---|---|
| `api` | `uvicorn specflow.api.main:app` | All `/v1` HTTP + all inbound webhooks |
| `worker` | `procrastinate worker --concurrency 12 --queues interactive,batch,notify` + Discord gateway listener (same process, supervised task) | Pipeline tasks, scheduled jobs, Discord ingest |
| `mcp` | `python -m specflow.mcp` | MCP Streamable HTTP server, isolated auth surface |

The Discord gateway is the one always-on connection in the system; it lives in `worker` so a Discord outage can never touch `api`. The `mcp` service is separate so agent traffic load, agent-facing auth, and the restricted DB role (§6.8) never share a process with the human API.

**Queues:** `interactive` (upload parse/chunk/embed/classify, spec generate/lint/regenerate, notifications — latency-sensitive), `batch` (nightly clustering, digests, purges, outcome pulls), `notify` (Slack DMs, escalations). Procrastinate periodic tasks: hourly `digest_dispatch` (fires for workspaces at Monday 09:00 local — `workspaces.timezone`), nightly `cluster_sweep` 02:00 UTC, 10-min `sla_sweep`, 6-h `purge_monitor`, nightly `outcomes_pull`.

**`/v1` API surface (complete):**

| Group | Endpoints |
|---|---|
| Auth/session | Supabase-managed login; `GET /me`, `POST /invites/accept`, `GET /auth/sso-check` |
| Workspaces | CRUD, members CRUD (owner-gated), invites |
| Uploads | `POST /uploads/sign` → `POST /uploads/register` (batch manifest, starts pipeline run) → `GET /uploads/{batch}` |
| Sources | list · `GET /sources/connect/{slack\|github\|discord\|linear\|jira\|intercom\|zendesk}` · provider callbacks · channel/repo/inbox selection · `DELETE /sources/{id}` (schedules purge) |
| Opportunities | list (rank order, filters) · detail · rename · evidence list · `GET /documents/{id}?highlight={chunk_id}` |
| Verdicts | `POST /opportunities/{id}/verdict` (act+link / park / reject+reason) |
| Identities | list · suggested merges · merge · split |
| Track record | workspace aggregate view |
| Specs | `POST /opportunities/{id}/spec` (requires Act verdict) · `GET /specs`, `GET /specs/{id}` · `PATCH /specs/{id}/sections/{sid}` (accept/edit/reject/instruct) · `POST /specs/{id}/approve` · versions list/diff · `POST /specs/{id}/export` (linear/jira/markdown) |
| Inbox | `GET /inbox` (ambiguity flags) · `POST /inbox/{flag_id}/answer` |
| MCP tokens | mint · list · revoke (owner-gated) |
| Ratings | `GET/POST /ratings/{token}` (signed single-use) |
| Glossary | CRUD (`glossary_terms` — the lint resolver's dictionary) |
| Billing | `GET /billing` · `POST /billing/portal` (Stripe portal session) |
| Webhooks | `/webhooks/slack` · `/webhooks/github` · `/webhooks/nango` · `/webhooks/stripe` · `/webhooks/resend` — verify, insert `integration_events`, enqueue, 200 in <1 s |
| Operator (`is_operator` claim) | `/ops/queue` (clusters + cards, approve/edit/discard) · `/ops/partners` (TTFI, kill-criterion numbers, call notes) · classification spot-check |

**Middleware order:** request ID → structlog binding → auth (Supabase JWT verify) → entitlement check (active subscription or founding-partner flag) → rate limit (slowapi, keyed on real client IP — `X-Forwarded-For` parsed against Railway's proxy hops, regression-tested) → route. Every mutating handler uses the `audited_txn()` context manager: business write + `audit_log` insert commit together or not at all.

---

## 4. Database

**Supabase Postgres 16 · pgvector 0.8 · single project, single region.** Every table carries `workspace_id uuid not null` with RLS (§5). The worker connects with the service role but every query is explicitly workspace-scoped from the task payload — belt and suspenders.

### 4.1 Schema catalog (every core table)

**Tenancy & identity**
```
workspaces(id uuid pk default gen_random_uuid(), name text, company text,
           timezone text default 'UTC', created_at timestamptz default now())
members(workspace_id uuid fk, user_id uuid fk auth.users, role text check (role in ('owner','member')),
        created_at timestamptz, pk(workspace_id, user_id))
invites(id uuid pk, workspace_id fk, email citext, role text, token_hash bytea,
        expires_at timestamptz, accepted_at timestamptz, revoked_at timestamptz)
identities(id uuid pk, workspace_id fk, display_name text, primary_email citext,
           plan_tier text, churned_at timestamptz, created_at timestamptz)
identity_handles(id uuid pk, workspace_id fk, identity_id fk, platform text
                 check (platform in ('slack','github','discord','email','intercom','zendesk','linear','jira')),
                 handle text, unique(workspace_id, platform, handle))
glossary_terms(id uuid pk, workspace_id fk, term citext, definition text,
               created_by uuid, unique(workspace_id, term))
```

**Ingestion**
```
sources(id uuid pk, workspace_id fk, provider text, status text check (status in
        ('connected','paused','error','purging')), config jsonb,        -- channel/repo/inbox selections
        vault_secret_id uuid,                                            -- token lives in Vault, referenced only
        last_sync_at timestamptz, created_at timestamptz)
upload_batches(id uuid pk, workspace_id fk, file_count int, status text, created_by uuid, created_at)
documents(id uuid pk, workspace_id fk, source_id fk null, batch_id fk null,
          kind text check (kind in ('transcript','csv','export','thread','issue','ticket','spec')),
          title text, storage_path text, parsed_json jsonb, metadata jsonb,
          status text check (status in ('queued','parsing','chunking','embedding','done','failed')),
          failure_reason text, created_at timestamptz)
chunks(id uuid pk, workspace_id fk, document_id fk, text text,
       char_start int, char_end int,                                     -- load-bearing: powers scroll-to-highlight
       speaker text, author_handle text, identity_id uuid fk null,
       posted_at timestamptz, embedding vector(1536), tsv tsvector,
       intent text, sentiment text, urgency text, created_at timestamptz)
integration_events(id bigserial pk, workspace_id fk, provider text, external_id text,
                   event_type text, payload jsonb, dedup_key text unique,
                   received_at timestamptz, processed_at timestamptz)    -- raw landing zone, append-only
```

**Intelligence**
```
opportunities(id uuid pk, workspace_id fk, name text, name_history jsonb default '[]',
              problem_statement text,
              status text check (status in ('candidate','draft','published','archived')),
              cluster_state text check (cluster_state in ('pending_review','approved')),
              centroid vector(1536),                                     -- incremental assignment target
              confidence text check (confidence in ('low','medium','high')),
              confidence_rationale text, raise_condition text,
              score numeric, score_inputs jsonb,
              counter_checked_n int,                                     -- "No counter-evidence found — N chunks checked"
              created_at, updated_at, published_at timestamptz)
opportunity_signals(opportunity_id fk, chunk_id fk, stance text check (stance in ('support','counter')),
                    similarity numeric, assigned_by text check (assigned_by in ('auto','operator','synthesis')),
                    created_at, pk(opportunity_id, chunk_id))
verdicts(id uuid pk, workspace_id fk, opportunity_id fk,
         verdict text check (verdict in ('act','park','reject')),
         reason_code text check (reason_code in ('wrong_cluster','already_knew','not_important','evidence_misread','other')),
         reason_text text, linked_url text, actor uuid, created_at)      -- APPEND-ONLY
eval_labels(id uuid pk, workspace_id fk, chunk_id fk, expected_cluster_key text,
            labeled_by text check (labeled_by in ('operator','seed')), created_at)
```

**Specs & MCP**
```
specs(id uuid pk, workspace_id fk, opportunity_id fk, title text, ticket_key text,
      status text check (status in ('draft','in_review','approved')),
      current_version int default 1, approved_version int,
      approved_by uuid, approved_at timestamptz, created_by uuid, created_at)
spec_sections(id uuid pk, workspace_id fk, spec_id fk, order_idx int,
              block_type text check (block_type in ('story','acceptance_criteria','edge_cases',
                                                    'data_model','api_contract','qa_checklist')),
              content jsonb,
              status text check (status in ('pending','accepted','edited','rejected')),
              evidence_refs jsonb,            -- [{chunk_id, confidence}]
              unevidenced bool default false, -- the [UNEVIDENCED — PM assumption] flag
              edit_diff jsonb, history jsonb default '[]', updated_by uuid, updated_at)
spec_versions(id uuid pk, spec_id fk, version int, snapshot jsonb,       -- full section array at approval
              created_by uuid, created_at, unique(spec_id, version))
mcp_tokens(id uuid pk, workspace_id fk, name text, token_hash bytea,     -- sha256, constant-time compare
           scopes text[] default '{read,flag}', created_by uuid,
           created_at, last_used_at, revoked_at timestamptz)
ambiguity_flags(id uuid pk, workspace_id fk, spec_id fk, section_id fk, question text,
                asked_via text,                                          -- 'cursor' | 'claude-code' | client string
                status text check (status in ('open','answered','escalated')),
                answer text, answered_by uuid, answered_at timestamptz,
                sla_due_at timestamptz, escalated_at timestamptz, created_at)
engineer_ratings(id uuid pk, workspace_id fk, spec_id fk, rating smallint check (rating between 1 and 5),
                 missing_text text, rater_handle text, source text, created_at)
rating_tokens(id uuid pk, spec_id fk, token_hash bytea, expires_at, used_at timestamptz)
exports(id uuid pk, workspace_id fk, spec_id fk, target text check (target in ('linear','jira','markdown')),
        external_key text, payload jsonb, created_at)
```

**Pipeline, ops, billing**
```
pipeline_runs(id uuid pk, workspace_id fk,
              trigger text check (trigger in ('upload_batch','sync_delta','nightly','manual')),
              status text check (status in ('running','waiting_review','complete','failed')),
              batch_id fk null, stats jsonb, started_at, finished_at timestamptz)
pipeline_steps(id uuid pk, run_id fk, step text check (step in
               ('parse','chunk','embed','classify','cluster','score','synthesize','publish')),
               status text check (status in ('queued','running','done','failed','skipped')),
               attempt int default 0, input_ref jsonb, output_ref jsonb, error text,
               started_at, finished_at timestamptz)
digests(id uuid pk, workspace_id fk, sent_at timestamptz, payload jsonb, open_tracked bool)
feature_outcomes(id uuid pk, workspace_id fk, spec_id fk, metric_source text
                 check (metric_source in ('amplitude','mixpanel','manual')),
                 metric_key text, predicted jsonb, observed jsonb, window_days int, pulled_at timestamptz)
audit_log(id bigserial pk, workspace_id fk, actor_type text check (actor_type in
          ('user','operator','system','agent')), actor_id text, action text,
          object_type text, object_id uuid, payload jsonb, created_at timestamptz default now())
billing_customers(workspace_id pk fk, stripe_customer_id text unique)
billing_subscriptions(id uuid pk, workspace_id fk, stripe_subscription_id text unique,
                      status text, founding_partner bool default false, current_period_end timestamptz)
-- procrastinate manages its own tables (procrastinate_jobs etc.) in-schema
```

### 4.2 The dimension correction (v2 bug, fixed here)

v2 specced `embedding vector(3072)` with an HNSW index. **pgvector cannot build an HNSW index above 2000 dimensions on the `vector` type.** That column as written would either fail at index creation or silently fall back to sequential scan — at exactly the moment retrieval latency sits inside the TTFI window. Fix: request `dimensions: 1536` from `text-embedding-3-large` (native Matryoshka truncation, ~99% of retrieval quality on MTEB-style benchmarks), store `vector(1536)`, index HNSW. `halfvec(3072)` was the alternative (HNSW to 4000 dims on pgvector ≥0.7); rejected because 1536 full-precision benchmarks comparably, halves row size and index IO, and keeps centroid math trivial. Same class of error as v1's Drizzle-on-Python — caught the same way: by an engineering read before build.

### 4.3 Indexes & views

```sql
CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops) WITH (m=16, ef_construction=64);
-- query-time: SET LOCAL hnsw.ef_search = 100;
CREATE INDEX ON chunks USING gin (tsv);
CREATE INDEX ON chunks (workspace_id, posted_at);
CREATE INDEX ON chunks (workspace_id, identity_id);
CREATE INDEX ON integration_events (workspace_id, provider, processed_at) WHERE processed_at IS NULL;
CREATE EXTENSION pg_trgm;  -- fuzzy identity-name suggestions
```

**`opportunity_frequency`** — the one place frequency math exists, so no caller can get it wrong:
```sql
CREATE VIEW opportunity_frequency AS
SELECT os.opportunity_id, count(DISTINCT c.identity_id) AS unique_humans
FROM opportunity_signals os JOIN chunks c ON c.id = os.chunk_id
WHERE os.stance = 'support' AND c.identity_id IS NOT NULL
GROUP BY os.opportunity_id;
```

**`approved_specs`** — the only relation the MCP service can read specs from (§6.8):
```sql
CREATE VIEW approved_specs AS
SELECT s.id, s.workspace_id, s.ticket_key, s.title, v.snapshot, s.approved_at, s.approved_by
FROM specs s JOIN spec_versions v ON v.spec_id = s.id AND v.version = s.approved_version
WHERE s.status = 'approved';
```
Draft and In-Review specs are unreachable from the MCP service *by construction* — the `mcp_reader` role has no grant on `specs` or `spec_sections`, only on this view.

### 4.4 Connection pooling & migrations

- **API + worker → Supavisor transaction mode (port 6543).** psycopg3 with `prepare_threshold=None` (named prepared statements break under transaction pooling); SQLAlchemy 2.0 async engine, `pool_size=5` per service, `pool_pre_ping=True`.
- **Migrations → direct connection (5432)**, plain SQL files via `supabase` CLI, applied by CI before deploy. SQL-first (not Alembic) because RLS policies, triggers, views, and `REVOKE` statements are first-class in this schema and belong in reviewable SQL, not ORM autogen. Branch databases back preview environments.
- FTS `tsv` maintained by trigger on `chunks` insert/update.

---

## 5. Auth & Multi-Tenancy

**Supabase Auth** issues every session. In Phase 1, magic link is the only sign-in method; Google OAuth is deferred per ADR-005; SAML stays a stub until a contract funds the Supabase plan upgrade. One identity system keeps RLS, cookies, and JWT claims identical when additional methods are enabled later. Sessions live in HttpOnly Secure cookies via `@supabase/ssr`; no token ever reaches `localStorage`.

**Claims** are injected by a Custom Access Token Hook (Postgres function registered with GoTrue):
```json
{ "app_metadata": { "workspace_ids": ["..."], "roles": {"<ws_id>": "owner"}, "is_operator": false } }
```

**RLS pattern** — one helper, one policy shape, applied to every workspace table:
```sql
CREATE FUNCTION auth_workspaces() RETURNS uuid[] LANGUAGE sql STABLE AS $$
  SELECT coalesce(
    (SELECT array_agg(x::uuid) FROM jsonb_array_elements_text(
       auth.jwt()->'app_metadata'->'workspace_ids') AS x), '{}');
$$;
CREATE POLICY ws_isolation ON chunks FOR ALL
  USING (workspace_id = ANY (auth_workspaces()));
-- owner-gated tables (members, invites, mcp_tokens, billing_*) add:
--   AND (auth.jwt()->'app_metadata'->'roles'->>workspace_id::text) = 'owner'
```
API user paths execute through PostgREST with the caller's JWT, so the database enforces tenancy — application code cannot forget a `WHERE`. The worker's service-role queries always take `workspace_id` from the task payload and bind it explicitly.

**Append-only enforcement** on `verdicts` and `audit_log`: `REVOKE UPDATE, DELETE FROM ALL` + a `BEFORE UPDATE OR DELETE` trigger that raises — two locks, because history rewriting must be impossible, not discouraged.

**Roles:** `owner` and `member`. Verdicts are open to any member with actor attribution rendered ("Rejected by Maya"); spec approval records `approved_by`; engineer-ness is expressed through MCP tokens and rating links, not membership tier. SAML group → role mapping is reserved for the later paid SSO path; Phase 1 ships only the empty-map stub. The operator console is gated by `is_operator` — set only on founder account(s), never grantable through workspace membership, every action audit-logged with operator identity.

**MCP auth is a separate plane** (§6.8): workspace-scoped bearer tokens in `mcp_tokens`, hashed at rest, owner-mintable/revocable — agents never hold user sessions.

---

## 6. AI Agent Architecture

### 6.0 Framework decision

**There is no agent framework. There is a pipeline.** Orchestration is a homegrown Postgres state machine (`pipeline_runs`/`pipeline_steps`) advanced by procrastinate tasks; model calls go through the raw Anthropic SDK with tool-schema-forced JSON validated by Pydantic.

Why not LangGraph — final, not deferred: the product's flow is a static DAG with exactly two human gates (concierge publish, spec approval), and both gates are *already* database state machines that the UI, the audit log, and the MCP visibility rule hang off. LangGraph's value is dynamic control flow and checkpointed agent loops; its cost here is a second source of state truth (its checkpointer) living outside the schema that the YC audit bar requires, plus a framework's debugging indirection on a solo-founder ops budget. Conditional routing — the thing v2 said would justify orchestration — is one column: high-confidence cards (`eval-gated`, §6.6) set `pipeline_steps.publish.input_ref->>'auto' = true` and skip the operator queue. That is an `if`, not a graph library. Why not LangChain/LlamaIndex/CrewAI for the model layer: every call in this system is single-shot structured generation with retrieval prepared by our own code; abstraction over that is surface area without behavior.

### 6.1 Module tree (what the engineer opens tomorrow)

```
specflow/
  api/                      # FastAPI routers per §3
  pipeline/
    orchestrator.py         # Orchestrator.advance(run_id) — the DAG walker
    tasks/
      ingest.py             # parse_document, chunk_document
      embed.py              # embed_chunks
      classify.py           # classify_chunks
      cluster.py            # run_clustering, assign_incremental
      score.py              # score_opportunities
      synthesize.py         # draft_card
      publish.py            # publish_card, enqueue_review
    retrieval.py            # HybridRetriever (dense + FTS + RRF)
    counter.py              # CounterEvidenceSearcher
    identity.py             # IdentityResolver
    chunking.py             # turn/paragraph chunker, 300-tok target, 15% overlap
  llm/
    client.py               # LLMClient — Anthropic SDK via Helicone, retries, Pydantic validation
    router.py               # ModelRouter — reads config/models.yaml
    prompts.py              # PromptRegistry — loads config/prompts/*.yaml, pins versions
  specs/
    generate.py lint.py state.py
  mcp_server/
    server.py tools.py auth.py config_block.py
  integrations/
    slack.py github.py discord_gw.py nango.py normalize.py outcomes.py
  notify/  digest.py slack_dm.py sla.py
config/
  models.yaml  clustering.yaml  scoring.yaml  prompts/*.yaml
evals/
  baselines.json  scorers/
```

### 6.2 The pipeline as tasks (node-by-node)

| # | Step | Task fn (procrastinate) | Input | Output | Model | Reads | Writes |
|---|---|---|---|---|---|---|---|
| 1 | Parse | `ingest.parse_document(document_id)` | storage object | `parsed_json` (turns/rows/messages) | — | `documents`, Storage | `documents` |
| 2 | Chunk | `ingest.chunk_document(document_id)` | parsed_json | chunk rows w/ char offsets, speaker, author | — | `documents` | `chunks` |
| 3 | Embed | `embed.embed_chunks(chunk_ids[≤256])` | chunk text | 1536-dim vectors | text-embedding-3-large | `chunks` | `chunks.embedding` (tsv via trigger) |
| 4 | Classify | `classify.classify_chunks(chunk_ids[≤50])` | chunk text batch | intent/sentiment/urgency | Haiku 4.5 | `chunks` | `chunks` tag cols |
| 5 | Cluster | `cluster.run_clustering(workspace_id, run_id)` | unassigned embeddings | candidate opportunities + signal links; borderline → operator | Sonnet 4.6 (naming/merge) | `chunks`, `opportunities.centroid` | `opportunities(candidate)`, `opportunity_signals` |
| 6 | Score | `score.score_opportunities(workspace_id)` | signals + tags + recency | `score`, `score_inputs` | — (SQL) | `opportunity_frequency`, `chunks` | `opportunities` |
| 7 | Synthesize | `synthesize.draft_card(opportunity_id)` | top quotes + counter-search results | card draft (summary, quotes, counter, confidence) | Sonnet 4.6 | `chunks` via `HybridRetriever`/`CounterEvidenceSearcher` | `opportunities(draft)`, `opportunity_signals(counter)` |
| 8 | Publish | `publish.publish_card(opportunity_id)` | operator approval (or eval-gated auto) | published card, digest inclusion | — | — | `opportunities(published)`, `audit_log`, PostHog `cards_published` |

Spec-side tasks: `specs.generate(spec_id)` (Opus 4.8) → `specs.lint(spec_id)` (deterministic checks + one Haiku pass) → on lint failure, one auto-regeneration with the lint report appended → PM review (§6.7) → `specs.export(spec_id, target)`. `specs.regenerate_block(section_id, instruction)` re-runs a single block with the steering line, Opus 4.8, original context pack pinned.

Every task is idempotent (keyed writes, `ON CONFLICT` upserts), retried with exponential backoff (max 4), and emits an `audit_log` row + `pipeline_steps` transition. `Orchestrator.advance(run_id)` runs after every step completion: it checks the DAG's join conditions (all documents chunked → schedule embeds; all classified → schedule cluster) and enqueues the next layer. State is rows; resume after any crash is `advance()`.

### 6.3 The exact sequence: 50 transcripts in, 5 ranked cards out

PM drags 50 `.vtt` files onto the empty workspace at **t=0**. (~2,800 chunks; timings are p50 on the stated batch sizes.)

1. **t+0 s** — FE: `POST /v1/uploads/sign` → 50 signed Storage URLs; direct client uploads; `POST /v1/uploads/register` with the manifest. API (one transaction): `upload_batches` row, 50 `documents(status=queued)` rows, `pipeline_runs(trigger=upload_batch, status=running)`, 50 `pipeline_steps(parse, queued)` rows, 50 `ingest.parse_document` tasks on `interactive`. PostHog `upload_started`.
2. **t+0–90 s** — 12 worker slots chew parse tasks: `webvtt-py` extracts cues + speakers, `documents.parsed_json` written, each completion enqueues `chunk_document`. CSVs would route through the confirmed column mapping; text-layer-less PDFs fail here with the App Flow copy, `documents.status=failed`, batch never blocked.
3. **t+90–150 s** — `chunking.py`: speaker-turn-aware windows, ~300 tokens, 15 % overlap, `char_start/char_end` recorded against the original text (these offsets are the 1-click scroll-to-highlight). ~2,800 `chunks` rows. `Orchestrator.advance`: all docs chunked → 11 `embed.embed_chunks` tasks (256/batch).
4. **t+150–270 s** — embeddings: 11 OpenAI calls through Helicone (`dimensions=1536`), ~1 M tokens ≈ **$0.13**. `advance` → 56 `classify.classify_chunks` tasks (50/batch).
5. **t+270–450 s** — Haiku 4.5, temp 0, tool-forced JSON `[{chunk_id, intent, sentiment, urgency}]`, 10 concurrent; ~0.9 M input tokens ≈ **$1.10**. `advance` → `cluster.run_clustering`.
6. **t+450–540 s** — `ClusterEngine`: one `SELECT` of unassigned signal-chunk embeddings; `sklearn.AgglomerativeClustering(metric='cosine', linkage='average', distance_threshold=0.30)` (from `config/clustering.yaml`); candidates require **≥3 unique humans** (via `identity_id`, the only frequency that exists). ~8 candidates → 8 parallel Sonnet naming calls (12 sampled chunks each): name, one-sentence problem statement in the customers' framing, merge proposals. Writes `opportunities(status=candidate, cluster_state=pending_review, centroid=mean(members))` + `opportunity_signals(stance=support, assigned_by=auto)`. Incremental path for later sync deltas: cosine-to-centroid ≥0.78 auto-assigns, 0.65–0.78 routes to the operator queue, ≥3 unique humans co-clustering in the unassigned pool spawns a new candidate.
7. **t+540 s** — `score.score_opportunities`: single SQL pass — `score = 0.5·log(1+unique_humans) + 0.3·severity + 0.2·recency`; severity = mean urgency mapped {low .33, med .66, high 1.0} over supporting chunks; recency = `exp(−ln2 · days_since_last_signal / 45)`. Weights from `config/scoring.yaml` — config, PR-reviewed, eval-gated, never user-exposed. `score_inputs` persisted so every rank is explainable.
8. **t+540–660 s** — `synthesize.draft_card` for the top candidates, 4 concurrent. Per card: `HybridRetriever` pulls quote candidates diversified by `identity_id`; `CounterEvidenceSearcher` runs three templated hybrid queries against the cluster topic — (a) satisfaction language, (b) explicit negation of the ask, (c) churn markers (`identities.churned_at` + textual signals); `counter_checked_n` = workspace chunk count covered by the index scan, persisted, because "No counter-evidence found — 1,240 chunks checked" must be a checked claim. One Sonnet call (temp 0.2, ~8 k in / 1.2 k out) returns Pydantic-validated JSON: summary, ≥3 selected quote `chunk_id`s, counter `chunk_id`s or empty, confidence + rationale + raise-condition. Confidence is rubric-bounded in config (High requires ≥6 unique humans across ≥2 sources *and* counter-evidence reviewed); the model fills rationale inside those rails. Counter chunks get `opportunity_signals(stance=counter, assigned_by=synthesis)`. LLM spend for the whole batch so far: **< $2.50**.
9. **t+~11 min** — `pipeline_runs.status=waiting_review`; cards sit in `/ops/queue` with the 24 h SLA timers. During an onboarding call the founder is live: rename, split, re-pick quotes, approve — every correction auto-appends to `eval_labels`/Braintrust (the queue is the eval-set factory). `publish.publish_card` flips `status=published`, fires `cards_published`, queues digest inclusion.
10. **t+~15–30 min** — PM's board poll renders 5 ranked cards; first `card_opened`; first quote click → `GET /v1/documents/{id}?highlight={chunk_id}` → source viewer scrolls to the char-offset span → `source_viewed` — **TTFI clock stops** (funnel enforces the ≥3-quote rule). System time ≈ 9–11 min; the remainder is the human gate, which is the product working as designed.

### 6.4 Model routing table (`config/models.yaml`)

| Task | Model (string) | Params | Cost basis | Why this model |
|---|---|---|---|---|
| Chunk classification | `claude-haiku-4-5` | temp 0, batch 50, tool-forced JSON | $1/$5 per MTok → ~$0.0004/chunk | Highest-volume call in the system; a label task, not a judgment task |
| Cluster naming + merge proposals | `claude-sonnet-4-6` | temp 0.2 | $3/$15 per MTok; ~10 calls/run | Naming quality is a trust surface; volume is low |
| Card synthesis + counter-evidence filtering | `claude-sonnet-4-6` | temp 0.2, 2 k max out | < $0.10/card | The core daily artifact; Sonnet's selection quality at this context size is the calibrated workhorse |
| Spec generation + block regeneration | `claude-opus-4-8` | temp 0.2, 8 k max out | Premium tier; at ≤ a few hundred specs/quarter, absolute spend < $50/mo | The single highest-stakes generation — engineer-rated post-merge, executed by agents. Quality ceiling matters; volume makes cost irrelevant. Same model for block regen keeps voice consistent |
| Spec lint ambiguity pass (pronouns, unresolved nouns vs glossary) | `claude-haiku-4-5` | temp 0 | pennies | Augments deterministic checks; not a reasoning task |
| Ambiguity-flag dedup/triage | `claude-haiku-4-5` | temp 0 | pennies | Keeps the inbox from doubling on rephrased questions |
| Embeddings | `text-embedding-3-large`, `dimensions: 1536` | — | $0.13/MTok | §4.2 |
| Eval LLM-judge scorers (naming rubric, spec rubric) | `claude-sonnet-4-6` | offline, Braintrust | offline budget | Judges must be a different *call* than the generator, same vendor is acceptable; rubric pinned in `evals/scorers/` |

Two vendors, total. Helicone tags every request with `workspace_id`, `run_id`, `prompt_id@version`, `task` — the $40/workspace/month alert and per-card cost curves fall out of the tags.

### 6.5 Prompt management

Every prompt is one YAML in `config/prompts/`:
```yaml
id: synthesize_card
version: 7
model: anthropic/claude-sonnet-4-6
temperature: 0.2
max_tokens: 2000
braintrust_dataset: card-synthesis-golden
schema: schemas/card_draft.json      # Pydantic-mirrored; output force-validated
template: |
  <system>You are drafting an opportunity card...</system>
  ...
```
`PromptRegistry` loads by `id`, pins `version`, and stamps `prompt_id@version` into Helicone properties and the `pipeline_steps.output_ref` — every artifact in the database knows which prompt produced it. **Change protocol:** edit YAML → PR → GitHub Action path filter (`config/prompts/**`, `config/clustering.yaml`, `config/scoring.yaml`, `specflow/pipeline/**`) triggers the bound Braintrust dataset → score compared to `evals/baselines.json` → regression = red check = unmergeable (branch protection, not willpower). Green merge updates the baseline in the same PR. There is no runtime prompt mutation, no prompt admin UI, no exceptions path.

### 6.6 Clustering, scoring, synthesis — the quality internals

**Hybrid retrieval (`HybridRetriever`)** — the primitive under synthesis, counter-evidence, MCP `search_evidence`, and spec-memory recall:
```sql
WITH dense AS (
  SELECT id, row_number() OVER (ORDER BY embedding <=> :qvec) AS r
  FROM chunks WHERE workspace_id = :ws ORDER BY embedding <=> :qvec LIMIT 50),
fts AS (
  SELECT id, row_number() OVER (ORDER BY ts_rank_cd(tsv, websearch_to_tsquery(:qtext)) DESC) AS r
  FROM chunks WHERE workspace_id = :ws AND tsv @@ websearch_to_tsquery(:qtext) LIMIT 50)
SELECT id, sum(1.0/(60+r)) AS rrf FROM (TABLE dense UNION ALL TABLE fts) u
GROUP BY id ORDER BY rrf DESC LIMIT :k;
```

**Re-synthesis rule:** a published card re-enters `synthesize.draft_card` when it gains ≥3 new unique humans or any new counter-evidence since last synthesis (`config/clustering.yaml: resynth_min_new_humans: 3`). Re-synthesized cards show "what changed" in the digest. Previously rejected cards that accrue ≥3 new unique humans surface in the digest as "previously rejected — new signal," never silently resurrected.

**Learning loop — human-mediated, permanently:** verdicts, rejection reasons, operator corrections, and engineer ratings feed the golden sets and the founder's weekly review; they never adjust weights or prompts automatically. The PRD's statistical argument (n≈15 outcomes/quarter at this segment) is not a maturity gate, it's arithmetic. Scoring-weight changes are config PRs that must beat the eval baseline. `feature_outcomes` (Amplitude/Mixpanel pulls keyed to shipped specs, §7.6) powers the predicted-vs-actual panel — evidence for the human, not gradients for a model.

**Eval-gated auto-publish:** when `clustering-golden` ARI and the naming rubric hold above thresholds in `config/clustering.yaml` for a workspace's last N runs *and* a card's confidence is High, `publish` skips the operator queue (`assigned_by=auto` audit-logged). The concierge gate narrows; it never disappears for Medium/Low confidence.

### 6.7 The human review gate — actual state machine, data model, API

Two gates exist. **Gate 1 (cards):** `opportunities.status: candidate → draft → published | archived`, transitions owned by `/ops/queue` endpoints, every transition audit-logged with operator identity, 24 h SLA timer = `now() − pipeline_runs.finished_at` rendered in the queue.

**Gate 2 (specs)** — the F3.5 canvas, technically:

- **Block machine:** `spec_sections.status: pending → accepted | edited | rejected`. `PATCH /v1/specs/{id}/sections/{sid}` with `{action: accept | edit | reject_regenerate | instruct, content?, instruction?}`. `edit` stores TipTap content + `edit_diff` and lands in `edited` (accepted-with-changes); `reject_regenerate` pushes the old content onto `history` and enqueues `specs.regenerate_block`; `instruct` does the same with the steering line in the prompt context. Every transition: audit row.
- **Spec machine:** `draft → in_review → approved`. `in_review` is entered when lint passes and the PM first opens the canvas. `POST /v1/specs/{id}/approve` is guarded server-side: *every* section must be `accepted` or `edited`, else 409. Approval writes `approved_by`, `approved_at`, snapshots the full section array into `spec_versions(version = current_version)`, sets `approved_version`, audit-logs. **Any post-approval `PATCH` reverts status to `in_review` and increments `current_version`** — the trigger is on the transition function, not on UI goodwill. Diff between versions = `diff-match-patch` over snapshot section text + structural array diff; rollback = copy an old snapshot forward as a new version (history is never rewritten).
- **MCP visibility is the view, not an if-statement:** agents read `approved_specs` (§4.3) under a role that cannot see `specs`. A reverted spec disappears from the view the same transaction its status flips.

### 6.8 The MCP server

- **Framework/transport:** official `mcp` Python SDK (≥1.2), `FastMCP` server, **Streamable HTTP**, stateless mode, served at `https://mcp.specflow.ai/mcp` from the dedicated `mcp` Railway service. stdio is rejected (local-only); SSE-legacy transport is rejected (deprecated in the spec; Streamable HTTP is what current Cursor and Claude Code speak).
- **Auth:** `Authorization: Bearer <token>`. Tokens are workspace-scoped, minted/revoked by owners in settings, stored as SHA-256 in `mcp_tokens.token_hash`, compared constant-time, `last_used_at` maintained. Full OAuth 2.1 dynamic registration is rejected for now-and-decided reasons: header-token auth is universally supported by both target clients, revocation is per-workspace and instant, and there is no third-party app ecosystem to authorize. Scopes: `read` (get_spec, search_evidence, list_priorities), `flag` (flag_ambiguity).
- **DB isolation:** the service connects as `mcp_reader` — grants: SELECT on `approved_specs`, `opportunities` (published only, via a second view), `chunks`, `opportunity_frequency`; INSERT on `ambiguity_flags`; nothing else. Workspace scoping is injected from the token row into every query.
- **Tools exposed** (Pydantic schemas, exact signatures):
  - `get_spec(ticket_key: str) → SpecPayload` — stories, acceptance_criteria[], edge_cases[], data_model_notes, api_contract, qa_checklist, evidence[{quote, author, company, date, source_ref}], unevidenced_assumptions[], ambiguities{open[], resolved[{question, answer, answered_at}]}. The agent starts with the *why*.
  - `search_evidence(query: str, k: int = 8) → EvidenceHit[]` — `HybridRetriever`, workspace-scoped, each hit carries chunk text, attribution, source_ref, stance.
  - `list_priorities() → PriorityCard[]` — published opportunities in score order with verdict state and unique-human counts.
  - `flag_ambiguity(ticket_key: str, section: str, question: str) → FlagReceipt` — §6.9.
- **Rate limit:** token bucket per token, 60 req/min, 429 with `Retry-After`. **Every call** writes `audit_log(actor_type='agent', actor_id=token_id, action=tool_name, payload=args_hash)`.
- **Client connection — install lives in the path of work:** `config_block.py` renders into every Linear/Jira/markdown export: the one-click Cursor deeplink (`cursor://anysphere.cursor-deeplink/mcp/install?name=specflow&config=<base64{"url":"https://mcp.specflow.ai/mcp","headers":{"Authorization":"Bearer …"}}>`), the Claude Code line (`claude mcp add --transport http specflow https://mcp.specflow.ai/mcp --header "Authorization: Bearer …"`), and the suggested first query (`get_spec("SPEC-123")`). `/connect/cursor` is the deeplink landing with manual fallback; first authenticated tool call stops the operator-visible `time_to_first_mcp_query` clock and fires `mcp_first_query`.

### 6.9 Write-back: the ambiguity loop

`flag_ambiguity` → Haiku triage (duplicate of an open flag? merge) → `ambiguity_flags(status=open, sla_due_at = +4 business hours, workspace-local Mon–Fri 09:00–18:00, computed in notify/sla.py)` → same transaction enqueues `notify.slack_dm` to the spec owner (via the workspace's connected Slack bot; email fallback) and the flag appears in `/w/[ws]/inbox` with a live countdown. `sla_sweep` (10-min periodic) escalates: unanswered at 24 h → `status=escalated`, banner + email to the workspace owner, audit row — the SLA is a product promise, so it is a monitored job, not a hope. `POST /v1/inbox/{flag}/answer` → `status=answered`, answer pinned to the spec section, included in `get_spec().ambiguities.resolved` — the agent picks it up on its next query (HTTP MCP has no durable server-push session to an ephemeral agent; the answer travels with the spec, which is where the agent looks anyway). One ignored question kills engineer adoption permanently; this loop is built so ignoring one is structurally loud.

### 6.10 Memory persistence (the YC bar: decisions citable six months later)

On approval, every spec is re-ingested as `documents(kind='spec')` → chunked → embedded into the same retrieval corpus. Consequences, for free: `search_evidence` surfaces past *decisions* alongside raw signal; spec generation's context pack retrieves related prior approved specs ("we decided X in March — cite or contradict explicitly"); the source viewer renders old specs like any other document. The verdict log and `name_history` make disagreement and renaming citable too. Memory compounds because everything flows back into one indexed corpus — no separate "memory" subsystem to build or drift.

---

## 7. Integrations

All inbound events land append-only in `integration_events` (uniqueness on `dedup_key = provider:external_id:event_type`) before normalization — replayable, idempotent, audit-friendly. `normalize.py` maps every provider into the same shape: `documents(kind=thread|issue|ticket)` + `chunks` with `author_handle`, `posted_at`, char offsets → `IdentityResolver` → incremental cluster assignment (§6.3 step 6 bands).

**Deduplication, three layers (mechanics):** L1 near-duplicate — cosine >0.95 within same author+ISO-week collapses to one signal at chunk insert. L2 identity — exact-email auto-link across platforms; `pg_trgm` display-name similarity >0.6 creates *suggestions only*, PM-confirmed in `/identities`, merges reversible (a wrong merge corrupts frequency, and frequency is the product's credibility). L3 — same ask from different humans stays separate; frequency = `DISTINCT identity_id`, enforced by the one view.

### 7.1 Upload (the front door)
Signed-URL direct upload → batch register → per-file pipeline (§6.3). Parsers: `.txt/.md` plain; `.vtt/.srt` cue-aware via `webvtt-py`/`srt` with speaker turns; `.csv` with confirmed author/date/text mapping; `.json` auto-detected Slack/Discord export schemas; `.pdf` text-layer only via `pdfplumber` — scanned PDFs rejected with the exact App Flow copy. Server-enforced: ≤25 MB/file, ≤200 files/batch. Audio (`.mp3`) is **not in the product** — PRD scope, not a deferral.

### 7.2 Slack (direct)
OAuth v2; scopes `channels:read, channels:history, groups:read, groups:history, chat:write, users:read` — private channels work only where the bot is explicitly invited (consent by mechanics), `chat:write` powers digest mirrors + ambiguity DMs. Explicit channel picker; selected channel IDs only, never workspace-wide. Events API receiver verifies `X-Slack-Signature` (v0 HMAC over `v0:timestamp:body`, 5-min tolerance), acks <3 s by inserting `integration_events` and enqueueing. Backfill: paged `conversations.history` per selected channel, `Retry-After`-aware. `dedup_key = slack:{channel}:{ts}`.

### 7.3 GitHub (direct)
GitHub App (not OAuth app): per-repo install, permissions `issues:read, metadata:read`. Webhooks `issues`, `issue_comment` verified via `X-Hub-Signature-256` HMAC. Backfill: REST with conditional requests (ETags). `dedup_key = github:{repo}:{issue}:{comment_id|body}`. Issue + comments normalize to one `documents(kind=issue)` thread.

### 7.4 Discord (direct — the integration middleware cannot do)
discord.py 2.4 gateway client inside `worker`: bot invited per server, intents `guilds, guild_messages, message_content` — **message-content is a privileged intent; Discord app verification is required at 100 servers and is filed early, because this is the beachhead's primary channel and an approval queue must never block ingestion**. Reads only PM-selected channel IDs; auto-reconnect with session resume; 5-min Sentry cron heartbeat — heartbeat loss flips the sources card to a visible warning, so a dead connection is never discovered through missing data. `dedup_key = discord:{channel}:{message_id}`.

### 7.5 Linear · Jira · Intercom · Zendesk (via Nango Cloud)
Nango owns OAuth, token refresh, webhook ingestion (single signed `/webhooks/nango` endpoint, signature verified), and sync scripts; tokens live in Nango, connection IDs in `sources.config` — our Vault holds only the Nango secret.
- **Linear** (export target + rating surface): GraphQL through the Nango proxy — `issueCreate` with description = spec markdown **+ embedded MCP config block + Cursor deeplink**; `commentCreate` posts the post-merge rating ask; webhook on issue state → `done` with a linked PR triggers `rating_tokens` mint + Slack DM ("Did this spec describe what you actually built? 1–5"). `exports.external_key` stores the Linear identifier the MCP `ticket_key` resolves through.
- **Jira**: REST v3 (OAuth 3LO), same create/comment/webhook contract, ADF-rendered description with the same embedded config block.
- **Intercom** (signal source): `conversation.user.created/replied` webhooks + backfill via Conversations API; conversation = one `documents(kind=ticket)` thread, parts = chunks, author = contact (email → identity auto-link). `dedup_key = intercom:{conversation}:{part}`.
- **Zendesk** (signal source): incremental cursor export API for backfill + ticket webhooks; comments = chunks; requester email → identity. `dedup_key = zendesk:{ticket}:{comment}`.

### 7.6 Outcomes (Amplitude · Mixpanel)
Read-only, batch, direct: Amplitude Export API + Mixpanel Raw Export, nightly `outcomes_pull` (keys in Vault), filtered to the metric keys a PM binds to a spec at approval ("this ships → watch `import_completed`"). Rows land in `feature_outcomes(predicted, observed, window_days)` → the predicted-vs-actual panel on the spec page. No event SDK, no write access, no automatic weight learning (§6.6).

---

## 8. Observability

| Tool | Instruments | Alert / gate it enforces |
|---|---|---|
| **Helicone** (proxy on both vendors) | Every LLM call, tagged `workspace_id · run_id · prompt_id@version · task` | **$40/workspace/month alert** (PRD risk threshold) to Slack `#alerts`; per-card and per-spec cost curves for pricing work |
| **Braintrust** | `clustering-golden` (ARI vs `eval_labels`, naming-quality LLM rubric, counter-evidence recall on 10 planted contradictions) · `card-synthesis-golden` · `spec-golden` (20 specs: 10 partner-real, 10 synthetic; engineer-rated 1–5, founder-adjudicated) | **CI merge gate**: any PR touching prompts/thresholds/pipeline runs the bound dataset; below `evals/baselines.json` = red = unmergeable (branch protection) |
| **PostHog** | Full event map: `workspace_created → upload_started → upload_completed → cards_published → card_opened → source_viewed` (TTFI funnel, **dashboard exists before partner #1**), `verdict_submitted`, `card_renamed`, `identity_merged`, `source_connected/disconnected`, `digest_opened`, `access_requested`, `mcp_first_query`, `ambiguity_flagged/answered`, `spec_approved`, `spec_rated` | TTFI median <10 min is the north star; event-name parity with this doc is checked in CI (single source of truth) |
| **Sentry** (FE + BE) | Exceptions + **cron check-ins**: Discord gateway heartbeat (5 min), Monday digest job, purge SLA, `sla_sweep`, `outcomes_pull` | Missed check-in → Slack `#alerts`. No PagerDuty — solo founder, no pager, by principle |
| **structlog** | JSON logs, request-ID-bound; redaction processor strips tokens, session IDs, emails | The session-ID-leak bug class has a **regression test**, not a memory |

Operator-facing numbers (`/ops/partners`): TTFI per workspace, digest open streak, verdict coverage %, "already-knew" rejection share (the kill-criterion number, live), time-to-first-MCP-query, write-back response times, % executed specs rated ≥4.

---

## 9. Security

**Encryption.** TLS 1.2+ on every hop (Vercel, Railway, Supabase all terminate TLS; service-to-DB over TLS). At rest: Supabase AES-256 volume encryption. Secrets that are *credentials we present* (Nango secret, Amplitude/Mixpanel keys, Slack/GitHub app secrets per tenant where applicable) live in **Supabase Vault** (authenticated encryption via pgsodium; decryptable only by the service role, never by `authenticated` or `mcp_reader`). Secrets that are *credentials others present* (MCP tokens, invite tokens, rating tokens) are stored only as SHA-256 hashes, compared constant-time — a DB read can never mint access.

**RLS.** Default-deny on every workspace table; the `auth_workspaces()` pattern (§5) is the only tenancy filter. PostgREST paths run as the caller; the worker's service-role queries are explicitly workspace-scoped from task payloads. **Cross-tenant denial is a permanent integration test** (two seeded workspaces, every endpoint, expect 404/empty — not 403, which leaks existence).

**Webhook verification (every receiver, no exceptions):**

| Receiver | Method | Window |
|---|---|---|
| `/webhooks/slack` | `X-Slack-Signature` v0 HMAC-SHA256 over `v0:ts:body` | 5 min ts tolerance |
| `/webhooks/github` | `X-Hub-Signature-256` HMAC-SHA256 | n/a |
| `/webhooks/nango` | Nango signature header (HMAC, per-account secret) | n/a |
| `/webhooks/stripe` | `stripe.Webhook.construct_event` (sig + ts) | 5 min |
| `/webhooks/resend` | Svix signature scheme | 5 min |

Failed verification → 401, Sentry event, **no body logged**. Raw payloads land in `integration_events` only after verification.

**Audit log immutability** — schema, not policy:
```sql
REVOKE UPDATE, DELETE ON audit_log, verdicts FROM PUBLIC, authenticated, service_role;
CREATE TRIGGER audit_log_immutable BEFORE UPDATE OR DELETE ON audit_log
  FOR EACH ROW EXECUTE FUNCTION raise_immutable();  -- RAISE EXCEPTION, belt for the REVOKE's suspenders
```
Every mutating API handler runs inside `audited_txn()` (§3): the business write and its audit row commit atomically or neither lands.

**LLM data path.** Anthropic and OpenAI under zero-data-retention / no-training API terms (DPAs executed; both listed on the subprocessor page). Helicone proxies with `Helicone-Omit-Request: true` and `Helicone-Omit-Response: true` — we keep cost/latency/tag metadata, customer text never persists in a third vendor. Prompts never log to structlog either; the redaction processor strips `text`, `content`, token, session, and email fields by key.

**Deletion guarantees (product promises, monitored):**
- **Source disconnect** → `sources.status='purging'` → `ingest.purge_source`: delete `opportunity_signals` → orphan-check `opportunities` (zero-support cards auto-archive with reason) → delete `chunks`, `documents`, storage objects under the source prefix → rescore affected cards → audit row with counts. **24 h SLA**; `purge_monitor` (6-h periodic) Sentry-alerts any purge pending >20 h.
- **Workspace deletion** (owner, typed confirmation): immediate — revoke all sessions, MCP tokens, invites; cancel Stripe subscription. Hard delete of all rows + storage within 30 days (grace window for accidental deletion, stated in-product). Backups age out with Supabase PITR (7-day window), so full disappearance ≤37 days — the number written in the DPA, not a vibe.
- **Right-to-access**: workspace export (JSON + original files) is an owner-triggered job, not a support ticket.

**Rate limiting.** slowapi on `/v1` (per-user and per-IP, real client IP parsed against Railway proxy hops — regression-tested); MCP token bucket 60/min (§6.8); upload caps server-enforced (≤25 MB/file, ≤200 files/batch); webhook receivers are verify-then-enqueue with <1 s handlers, so floods hit the queue, not the DB.

**Compliance.** Vanta agent monitors Supabase, Railway, Vercel, GitHub; policies and evidence collection run from day one → **SOC2 Type I** engagement immediately, Type II after the 3–6 month observation window. The architecture already produces the evidence (RLS, audit log, access reviews via `members`, encrypted secrets); Vanta turns it into auditor-shaped paperwork. **Single region: AWS us-east-1** (Supabase + Railway co-located). EU residency is not offered — it becomes a project when a signed contract pays for it, and the answer until then is "no," not "soon."

---

## 10. CI/CD & Deployment

**Environments:**

| Env | FE | BE | DB | Purpose |
|---|---|---|---|---|
| local | `next dev` | `uvicorn --reload` + `procrastinate worker` | `supabase start` (local stack, pgvector + Vault enabled) | Everything runs offline except LLM calls |
| staging | Vercel preview (per PR) | Railway `staging` environment (api/worker/mcp) | **Supabase branch database** per PR (CLI-created, seeded fixture workspace) | Real OAuth apps in dev mode; Stripe test mode |
| prod | Vercel `main` | Railway `production` | Supabase project (us-east-1) | — |

**Pipeline (GitHub Actions), on every PR:**
1. `ruff check` + `ruff format --check` + `mypy --strict specflow/`
2. `pytest tests/unit tests/integration` — integration jobs run against a `supabase/postgres` service container (pgvector + pg_trgm preinstalled); **the RLS cross-tenant suite, state-machine transition suite, RRF SQL, and dedup logic run here**
3. `pytest tests/api` — httpx against the app wired to the test DB
4. `tsc --noEmit` + `eslint` + `next build`
5. Playwright smoke: signup → create workspace → upload 3-file fixture batch → cards visible → open evidence → verdict. **This is the TTFI path; if it breaks, nothing else matters**
6. **Eval gate** (path-filtered): changes under `config/prompts/**`, `config/*.yaml`, or `specflow/pipeline/**` trigger Braintrust runs of the bound datasets; any metric below `evals/baselines.json` fails the check
7. Migration check: `supabase db diff` against the branch DB must be empty after applying `supabase/migrations/**` (catches drift and un-checked-in schema)

Branch protection on `main` requires all seven contexts. **The eval gate is a required status check — a prompt regression is unmergeable, therefore undeployable. That is the whole mechanism; there is no second one.**

**Deploy (merge to `main`):** migrations apply first (`supabase migration up` over the direct 5432 connection), then Railway deploys `api`/`worker`/`mcp` from the single image, then Vercel promotes. Migrations are forward-only and additive; destructive changes ship as two PRs (stop-writing, then drop) so a Railway rollback (one-click previous image) never meets a missing column. Raising `evals/baselines.json` is its own PR with the Braintrust run linked — baselines ratchet up, never drift down.

**Test suite layout:**
```
tests/unit/          # parsers, chunker, scoring math, SLA business-hours calc, lint rules, redaction processor
tests/integration/   # RLS denial, gate state machines, RRF, dedup layers, purge cascade, audit immutability
tests/api/           # contract tests per /v1 group, webhook signature rejection
tests/e2e/           # Playwright: TTFI smoke, canvas accept/edit/approve, MCP token mint → get_spec roundtrip
evals/               # Braintrust harness + baselines.json (the only file that defines "good enough")
```

---

## 11. Supporting Services

**Email — Resend.** Custom domain (`mail.specflow.ai`) with DKIM/SPF/DMARC at setup, not after the first spam-foldered magic link. Supabase Auth SMTP relays through Resend (auth mail inherits deliverability). Product mail — Monday digest, ambiguity DM email fallback, escalations, rating asks, purge/export confirmations — via Resend API with **React Email** templates (same component stack as the app; digests render the brand system). Open-tracking webhook → `/webhooks/resend` → `digests.open_tracked` + PostHog `digest_opened` — the digest open streak is an operator retention metric, so opens are first-class data.

**File storage — Supabase Storage.** Bucket `uploads`, prefix `ws_{workspace_id}/...`, storage RLS mirrors table RLS. Upload: 15-min signed upload URLs (client → storage direct; bytes never transit the API). Read: 60-s signed download URLs for original-file access in the source viewer. Purge deletes objects by prefix and verifies count against `documents` rows.

**Payments — Stripe Billing.** One product, one price: **flat workspace subscription, $249/month** (founding partners: `billing_subscriptions.founding_partner=true`, entitled without a Stripe sub — the concierge cohort is a flag, not a special code path). Checkout via Stripe-hosted page; card management, invoices, and cancellation via the **customer portal** (`POST /v1/billing/portal`) — we build zero billing UI. Webhooks (`checkout.session.completed`, `customer.subscription.updated/.deleted`, `invoice.payment_failed`) update `billing_subscriptions`; the entitlement middleware (§3) reads only that table — Stripe is the source of truth, our row is the cache. Dunning is Stripe Smart Retries + their emails. **No per-seat pricing — restated as a schema fact: nothing in `members` meters seats, by design, because a priced engineer seat is a lost MCP query.** No metered/usage billing at launch; Helicone's per-workspace cost curves are the dataset that prices v2 of pricing.

---

## 12. Deltas from Tech Stack v2 (every correction and newly-forced call)

| # | Area | v2 said | v3 says | Why |
|---|---|---|---|---|
| 1 | **Embeddings** | `text-embedding-3-large`, `vector(3072)`, HNSW | `dimensions: 1536`, `vector(1536)`, HNSW (m=16, ef_construction=64) | **v2 bug**: pgvector cannot HNSW-index >2000 dims on `vector`; 3072 fails at index build or silently seq-scans. Matryoshka truncation keeps ~99% quality at half the storage |
| 2 | Orchestration | "Revisit a graph framework when the pipeline needs interrupts" | Postgres state machine (`pipeline_runs`/`pipeline_steps` + `Orchestrator`); **LangGraph permanently rejected** | Both human gates are already DB state machines; a checkpointer duplicates state outside the audit-aligned schema. The interrupt case arrived and the answer is rows |
| 3 | Spec generation model | Undecided (Sonnet implied) | **Claude Opus 4.8** for `specs.generate` + `regenerate_block` | Highest-stakes artifact, lowest volume; <$50/mo at projected volume; engineer-rated quality is the moat metric |
| 4 | Ticket-class integrations | "Hand-roll until ~7 providers, then reconsider middleware" | **Nango Cloud** for Linear/Jira/Intercom/Zendesk now | The full product crosses v2's own threshold on day one; four hand-rolled OAuth+refresh+webhook stacks is pure undifferentiated liability |
| 5 | SSO | Deferred | **SAML stub in Phase 1; Supabase Auth SAML 2.0 add-on only after a paid-plan contract funds it**; WorkOS rejected | SAML stays inside the existing IdP when enabled later: sessions, JWT claims, RLS all unchanged. WorkOS = bridging two identity systems forever |
| 6 | Payments | Manual invoicing for founding partners | **Stripe Billing**, flat workspace sub + portal + webhook entitlements | Self-serve product needs self-serve billing; manual invoicing doesn't survive partner #11 |
| 7 | Compliance | Unaddressed | **Vanta → SOC2 Type I now, Type II after observation window** | Mid-market support/CRM data won't connect without it; the architecture already emits the evidence |
| 8 | Reranker | "Maybe a cross-encoder later" | **Permanently out** | Violates two-vendor rule or zero-ops rule; RRF + Sonnet in-context selection holds at 10⁴–10⁵ chunks/workspace |
| 9 | Auto-publish | Operator gate on everything, always | **Eval-gated auto-publish for High-confidence cards only**; Medium/Low stay gated | The concierge gate narrows on evidence (sustained ARI + rubric scores), never on optimism — and never disappears |
| 10 | Roles | (carried) YC brief implies owner/PM/engineer/reviewer | `owner` · `member` + `is_operator` claim, **final** | Permissions only fork at admin actions; reviewer/engineer are attributions on rows, not grants. Role theater rejected with prejudice |
| 11 | Realtime | Polling "for now" | Polling, **permanently** (2 s / 30 s) | Nothing in the product is sub-second collaborative; PRD excludes realtime co-editing; stateless-across-deploys wins |
| 12 | Audio ingestion | Open question in v1 era | **Not in the product** — PRD scope, not a deferral | Transcripts are the input; transcription is the customer's tool choice |
| 13 | EU residency | Open question | **Not offered**; single region us-east-1 | Becomes a funded project when a contract requires it; until then the honest answer is no |
| 14 | Data deletion | "Purge on disconnect" (mechanism unspecified) | Purge cascade with **24 h SLA, Sentry-monitored**, workspace hard-delete ≤30 d, backup age-out ≤37 d, numbers in the DPA | A deletion guarantee without a monitor and a number is marketing copy |
