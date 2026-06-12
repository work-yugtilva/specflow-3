# SpecFlow AI — Claude Code Implementation Plan

**Binds to:** PRD v2 (product scope, acceptance criteria) · Tech Stack v3 (every technical decision) · App Flow v1 (locked copy strings, screen states). Greenfield: zero files exist. Sections are dependency-ordered; each is one Claude Code session. Section N may not start until Section N−1's gate has passed.

---

## 1. Repository Bootstrap + Standing Rules

**Builds:** monorepo skeleton, three environments wired, CI skeleton, and the standing rules every later section obeys. **Depends on:** nothing.

### 1.1 Steps

1. **superpowers:writing-plans** — expand this section into a todo plan; this is the standing first step of *every* section and is not repeated below.
2. **caveman:caveman-help** — index the caveman suite once so every later invocation is deliberate, not exploratory.
3. Scaffold repo: `/web` (Next.js 14.2 App Router, React 18.3, TS strict), `/specflow` (Python 3.12, FastAPI 0.115, Pydantic 2.9), `/supabase` (SQL migrations), `/config` (models.yaml, clustering.yaml, scoring.yaml, prompts/), `/evals`, `/docs`, `/tests`. **vercel:nextjs** for the web scaffold; **vercel:turbopack** to enable turbopack dev and verify a clean build; **context7** to pin `next@14.2` docs before writing config (do not accept Next 15/16 idioms).
4. **vercel:vercel-cli** + **vercel:env-vars** — link the Vercel project, define env var matrix (local/preview/prod). **supabase:supabase** + **Supabase MCP** — create the project (us-east-1), enable pgvector 0.8, pg_trgm, Vault; configure `supabase` CLI for SQL-first migrations. Railway: three services (`api`, `worker`, `mcp`) from one Dockerfile, three start commands per Tech Stack §3.
5. **vercel:vercel-functions** — one decision, recorded: pin Next server functions to `iad1` to co-locate with Supabase/Railway us-east-1; set `maxDuration` defaults. This is the plugin's only product use.
6. **vercel:next-forge** — harvest-only invocation: extract its production checklist (security headers, robots/sitemap, error pages) into `/docs/launch-checklist.md`. Do **not** adopt its stack (Tailwind/shadcn/Clerk are all rejected by Tech Stack §1).
7. **Exclusion ADRs (one invocation each, output = `/docs/adr/`):** **vercel:ai-sdk** (rejected: FE makes zero LLM calls; a client AI path violates the one-API-surface rule and the two-vendor rule, Tech Stack §0.2/§2), **vercel:ai-gateway** (rejected: Helicone is the proxy/cost layer, §8), **vercel:workflow** (rejected: procrastinate on Postgres is the durable job system, §3). Each ADR records the rule the plugin would break, so future sessions don't re-litigate.
8. **gstack** — adopt stacked-PR workflow: every section is a stack of ≤300-line PRs; **caveman:caveman-commit** governs commit messages (compressed, fact-complete). CI skeleton in GitHub Actions: ruff/mypy strict, pytest, tsc/eslint, `next build` — the seven required contexts of Tech Stack §10 land incrementally, named now.
9. **vercel:deployments-cicd** — wire preview-per-PR and prod-on-main; deploy hello-world FE to preview+prod; deploy FastAPI healthcheck to Railway.

### 1.2 Token-Efficiency Standing Rules (bind every section)

- **woz:woz-recall** is the first tool call of every section: recall prior sections' decision log, file map, and interface contracts. If recall returns the contract you need, do **not** reopen PRD/Tech Stack/App Flow — the source docs are read in full exactly once (this plan already encodes them).
- **caveman:compress** before *any* subagent dispatch: compress the section brief plus relevant doc excerpts to ≤1,500 tokens per the caveman validation algorithm (fact-set identical, ≥30% reduction). Never hand a subagent a raw PRD section.
- **context7** before first touch of any external library in a section, resolved to the pinned version (next@14.2, procrastinate@2.x, discord.py@2.4, mcp≥1.2, tiptap@2.6, stripe, supabase-py, pgvector 0.8, webvtt-py, slack_sdk, react-email). One invocation per lib+version for the whole plan; cache the extract in `/docs/lib-notes/`.
- **superpowers:dispatching-parallel-agents** only when units share no files, no migrations, no middleware: parser suite (§5), provider integrations (§10, §16), email templates (§11), eval scorers (§19). Max 4 concurrent; each agent receives a compressed brief and returns a diff + its own test run. Everything touching `/supabase/migrations`, middleware order, or `/config` is sequential. **superpowers:subagent-driven-development** structures those parallel sections; **caveman:cavecrew** governs inter-agent messages (caveman-compressed, no prose chatter).
- **caveman:caveman** mode for high-boilerplate code (DDL, Pydantic models, routers, parser tables): terse code, full tests, no comments that restate code.
- **caveman:caveman-stats** at every gate: log section token spend to `/docs/spend.md`. Any section exceeding 2× the running median starts its successor with a compression audit.

### 1.3 Design-System Standing Rules (bind every UI section)

Canonical tokens live in `web/lib/brand.ts` and are the only styling source (inline styles exclusively; no Tailwind, no CSS-in-JS — Tech Stack §2):

| Token | Value |
|---|---|
| paper / terra / sage / charcoal | `#F8F4EF` / `#E8561B` / `#3D6B5E` / `#0D0D0D` |
| Display / body / metadata type | Instrument Serif / DM Sans / monospace |
| Radius | inputs+buttons 4px · cards 8px · overlays 12px |
| Borders | 1px `rgba(13,13,13,0.12)` |
| Shadow | cards: none (border-defined, editorial) · overlays only: `0 8px 30px rgba(13,13,13,0.12)` |
| Overlay glass | `backdrop-filter: blur(12px)` over `rgba(248,244,239,0.7)` — overlays only, never page chrome |
| Focus ring | 2px terra, always visible |
| States | skeletons in paper tones, never spinners-on-white; destructive failures = inline terra banner, never a toast |

- **figma** — at the end of every UI section, pull the matching frame from the SpecFlow brand file and diff the deployed screen: colors exact-hex, type sizes exact, spacing within 2px. If a frame doesn't exist, push the implemented screenshot to Figma tagged `impl-derived`; it becomes the binding frame for future diffs. Deviations are fixed or recorded as a design ADR — never silent.
- **Playwright MCP** — drive the live preview per UI section: locked App Flow copy strings asserted verbatim, keyboard nav + focus trap on every overlay, Escape closes, PostHog events observed firing, 380px viewport renders board/card read-only (App Flow §12).
- **Passing UI verification =** all locked strings verbatim + Playwright script green + figma diff clean-or-ADR'd + zero toasts on destructive paths + skeleton states render + focus visible everywhere. All six, or the section fails.

### 1.4 V-PROTOCOL (the universal verification block, referenced as "V" below)

**superpowers:verification-before-completion**, executed against a *deployed preview*, never against code reading: (1) full test suite green, including this section's new tests; (2) walk every acceptance criterion item-by-item in the running app; (3) UI sections: §1.3 passing definition; (4) **caveman:caveman-review** self-review of the stack, then **superpowers:requesting-code-review**; apply feedback via **superpowers:receiving-code-review**; (5) **superpowers:finishing-a-development-branch** to land the stack; (6) **caveman:caveman-stats** logged. Any red anywhere → **superpowers:systematic-debugging** (hypothesis → instrument → bisect), never patch-and-pray. **superpowers:executing-plans** drives the section's todo list start to finish.

**Acceptance criteria:** repo builds clean on all seven CI contexts (placeholders allowed for eval gate + Playwright until §19/§21); hello-world deployed on Vercel preview/prod and Railway healthcheck 200; ADRs + launch checklist + brand tokens committed.
**Verify:** V.
**GATE:** every criterion green via V on deployed targets, or the section is not done.

---

## 2. Database Schema, RLS, Views, Migrations

**Builds:** the complete Tech Stack §4 schema — every table (tenancy, ingestion, intelligence, specs/MCP, pipeline/ops/billing), indexes, `opportunity_frequency` + `approved_specs` views, append-only enforcement, auth claims hook, pooling config. **Depends on:** §1.

**Steps:** (1) **supabase:supabase-postgres-best-practices** + **context7**(pgvector 0.8) before any DDL. (2) **caveman:caveman** mode: write SQL migrations verbatim from Tech Stack §4.1 — all 28 tables, `vector(1536)` everywhere (the 3072 bug stays dead), HNSW `(m=16, ef_construction=64)`, GIN on `tsv`, partial index on unprocessed `integration_events`, `pg_trgm`. (3) Views: `opportunity_frequency` (DISTINCT `identity_id`, support stance only) and `approved_specs`; create `mcp_reader` role with grants on views only — no grant on `specs`/`spec_sections`. (4) Append-only: `REVOKE UPDATE, DELETE` on `audit_log` + `verdicts` from all roles **and** the `raise_immutable()` trigger — both locks. (5) Custom Access Token Hook injecting `{workspace_ids, roles, is_operator}`; `auth_workspaces()` helper; the one RLS policy shape on every workspace table, owner-clause on admin tables. (6) **superpowers:test-driven-development** — write the cross-tenant denial suite *first* (two seeded workspaces, every table, expect empty/404 — never 403), immutability tests, frequency-math tests (15 messages from one human = frequency 1), `approved_specs` invisibility test (draft spec unreachable as `mcp_reader`). (7) **Supabase MCP** — apply to a branch database, run `supabase db diff` (must be empty), seed fixture workspace. (8) **codex:codex-cli-runtime** + **codex:gpt-5-4-prompting** — second-model adversarial review of the RLS policies and grants specifically; a tenancy hole here invalidates everything downstream; log findings as review comments.

**Acceptance criteria:** frequency = unique humans, never message count (PRD F1 L3); verdict log append-only and immutable (PRD F2); `approved_specs` is the only spec relation `mcp_reader` can see (PRD F3.5 hard rule); RLS denial suite green on every table; `vector(1536)` HNSW index used — `EXPLAIN` shows index scan, not seq scan.
**Verify:** V + pgTAP/pytest integration suite against the branch DB.
**GATE:** all criteria + adversarial review findings resolved, or not done.

---

## 3. Auth, Tenancy, Members

**Builds:** Supabase Auth magic link (sole Phase 1 sign-in method; Google OAuth deferred per ADR-005; SAML stub until a contract funds the upgrade), `@supabase/ssr` HttpOnly sessions, Next middleware, App Flow A3/A4/B1 screens, G1 members settings, invite lifecycle. **Depends on:** §2.

**Steps:** (1) **vercel:auth** — cookie/session/middleware best practices for Supabase-on-Vercel (provider stays Supabase; this plugin informs the Next integration only). (2) **vercel:routing-middleware** — middleware: session refresh, `/w/[ws]` guard against JWT `workspace_ids`, operator-claim guard on `/ops`. (3) **supabase:supabase** — configure magic link (60s resend cooldown) as the sole Phase 1 sign-in method; leave Google OAuth deferred per ADR-005; ship the SAML stub path with an empty domain-to-IdP map until a contract funds the Supabase plan upgrade; register the token hook from §2. (4) Build `/login`, `/auth/callback`, `/invite/[token]`, `/onboarding` with **frontend-design:frontend-design** on brand tokens; the B1 data promise is checkbox-acknowledged and verbatim from App Flow; `workspace_created` PostHog event fires on create — **the TTFI clock starts here**. (5) G1 members page (invite by email + role, revoke, remove with verdicts retained) with **interface-design**. (6) `GET /v1/auth/sso-check?domain=` stub contract documented for §4. (7) **superpowers:test-driven-development** on invite token hashing + expiry/revocation paths.

**Acceptance criteria:** A3 states (link sent, expired-link copy, returning-session redirect) exact; A4 routes owner-with-no-data → `/onboarding`, member → board; B1 data promise verbatim + required; removed member's verdicts remain attributed (App Flow G1); `workspace_created` observed in PostHog debug.
**Verify:** V + **Playwright MCP** drives magic-link flow against local Supabase inbucket, invite accept both roles, SAML stub smoke (empty domain-to-IdP map).
**GATE:** all criteria, or not done.

---

## 4. Backend Core: FastAPI, Queues, Services, Observability Bootstrap

**Builds:** the `/v1` application skeleton, middleware chain, `audited_txn()`, procrastinate wiring (queues `interactive,batch,notify`, concurrency 12, all periodic tasks registered), three Railway services from one image, structlog + redaction, Sentry, Helicone client, PostHog server lib. **Depends on:** §2.

**Steps:** (1) **context7**(fastapi 0.115, procrastinate 2.x, structlog, supabase-py). (2) Middleware in Tech Stack §3 order: request-ID → structlog bind → JWT verify → entitlement check (founding-partner flag short-circuits until §18) → slowapi rate limit keyed on real client IP parsed against Railway proxy hops — **superpowers:test-driven-development** writes the X-Forwarded-For regression test before the parser. (3) `audited_txn()` context manager — TDD: business write + audit row commit atomically or neither; prove with an injected failure. (4) DB access split per Tech Stack §1: supabase-py (caller JWT, RLS) for API paths; SQLAlchemy 2.0 Core async + psycopg3 `prepare_threshold=None`, `pool_size=5`, `pool_pre_ping=True` over Supavisor 6543 for worker; migrations stay on 5432. (5) Procrastinate periodic tasks registered as no-op shells: hourly `digest_dispatch`, nightly `cluster_sweep` 02:00 UTC, 10-min `sla_sweep`, 6-h `purge_monitor`, nightly `outcomes_pull` — bodies arrive in their sections. (6) Webhook receiver pattern: verify → insert `integration_events` → enqueue → 200 <1s; signature verifiers land per-provider later, the harness + 401-no-body-logged behavior lands now. (7) **Sentry MCP** — create FE+BE projects, wire cron check-in slugs for every periodic task. (8) structlog redaction processor strips `text/content/token/session/email` keys — TDD regression test (Tech Stack §8: "a regression test, not a memory"). (9) `LLMClient` (raw Anthropic SDK via Helicone proxy, retries, Pydantic-validated tool-forced JSON), `ModelRouter` reading `config/models.yaml`, `PromptRegistry` pinning `prompt_id@version` into Helicone tags — **caveman:caveman** for the boilerplate. (10) Deploy all three services; `python -m specflow.mcp` is a healthcheck stub until §15.

**Acceptance criteria:** `audited_txn` atomicity proven by test; redaction test green; rate-limit IP test green; all five cron check-ins visible in Sentry; Helicone shows a tagged test call with `workspace_id · run_id · prompt_id@version · task`; webhook harness answers <1s and never logs unverified bodies.
**Verify:** V + Railway logs show three healthy services from one image.
**GATE:** all criteria, or not done.

---

## 5. Ingestion Front Door: Storage, Parsers, Chunker, Pipeline State Machine

**Builds:** signed-URL direct upload, batch register transaction, all seven parsers, speaker-turn chunker with char offsets, `pipeline_runs`/`pipeline_steps` + `Orchestrator.advance()`, parse→chunk tasks, IdentityResolver core (email auto-link). **Depends on:** §4.

**Steps:** (1) **woz:woz-recall** for §2 schema + §4 task contracts. (2) Supabase Storage bucket `uploads`, prefix `ws_{id}/`, storage RLS mirroring table RLS, 15-min signed upload URLs, 60-s signed download URLs (**supabase:supabase**). (3) `POST /uploads/sign` → `POST /uploads/register`: one transaction creates `upload_batches`, N `documents(queued)`, `pipeline_runs(upload_batch)`, N `pipeline_steps(parse, queued)`, N parse tasks — TDD the transaction. (4) **superpowers:subagent-driven-development** + **superpowers:dispatching-parallel-agents** (4 agents, **caveman:compress**ed briefs, **caveman:cavecrew** coordination): agent A `.txt/.md`, agent B `.vtt/.srt` via webvtt-py/srt with speaker turns, agent C `.csv` mapper + `.json` Slack/Discord schema autodetect, agent D `.pdf` via pdfplumber text-layer-only with the exact rejection copy ("Scanned PDF — no text layer…"). Each agent: **superpowers:test-driven-development**, fixture files, ≤25MB/≤200-file server enforcement. (5) Sequential: chunker (~300 tokens, 15% overlap, speaker-turn-aware, `char_start/char_end` against original text — these offsets power scroll-to-highlight, TDD them against fixtures byte-exactly). (6) `Orchestrator.advance(run_id)`: join conditions (all docs chunked → schedule embeds), idempotent keyed writes, retry max 4 exponential, every transition writes `pipeline_steps` + audit — TDD the state machine including crash-resume (`advance()` after kill). (7) IdentityResolver v0: exact-email auto-link creates `identities` + `identity_handles`; chunk insert sets `author_handle`, links `identity_id`; L1 near-dup (cosine >0.95 same author+ISO-week) lands with embeddings in §6 — stub the hook now. (8) **graphify** — render the 8-step pipeline DAG + state machine into `/docs/pipeline.md`.

**Acceptance criteria (PRD F1 / §4c-1):** per-file status visible via `GET /uploads/{batch}`; failed files reported with named reason, never silently dropped; one bad file never blocks the batch; speaker turns preserved in transcript chunks; accepted types exactly `.txt .md .vtt .srt .csv .json .pdf`; limits 25MB/200 files server-enforced; 50-doc fixture batch completes parse+chunk on the ≤10-min-p50 trajectory (measured, logged); crash-resume test green.
**Verify:** V + run the 50-fixture batch on preview, inspect `pipeline_steps` rows and timing.
**GATE:** all criteria, or not done.

---

## 6. Embedding, Classification, Hybrid Retrieval

**Builds:** `embed.embed_chunks` (1536-dim), tsv trigger live, `classify.classify_chunks` (Haiku), `HybridRetriever` RRF, L1 dedup, Helicone cost rollup + $40/workspace alert. **Depends on:** §5.

**Steps:** (1) **context7**(openai SDK — the `dimensions: 1536` parameter exactly; anthropic SDK tool-forced JSON). (2) Embed task: batches ≤256, `text-embedding-3-large` with `dimensions: 1536`, write `chunks.embedding`; tsv maintained by trigger from §2 — verify trigger fires on insert. (3) L1 dedup at insert: cosine >0.95 within same author+ISO-week collapses to one signal — **superpowers:test-driven-development** with crafted near-duplicates. (4) Classify task: batches ≤50, `claude-haiku-4-5` temp 0, tool-forced `[{chunk_id, intent, sentiment, urgency}]`, Pydantic-validated, 10 concurrent. (5) `HybridRetriever`: the Tech Stack §6.6 RRF SQL verbatim (dense top-50 + FTS top-50, k=60, workspace-scoped) — TDD as an integration test with seeded corpus asserting fusion order; `SET LOCAL hnsw.ef_search = 100`. (6) Helicone tags on every call; configure the $40/workspace/month alert → Slack `#alerts`; `Helicone-Omit-Request/Response: true` (customer text never persists in a third vendor — Tech Stack §9).

**Acceptance criteria:** `EXPLAIN` on retrieval shows HNSW index scan; classify output schema-valid on a 500-chunk fixture with zero unparsed responses (retry path proven); RRF test green; L1 collapse test green; Helicone dashboard shows tagged spend per workspace; omit headers verified in Helicone (no bodies stored).
**Verify:** V + run embed+classify over the §5 fixture batch on preview; cost for the batch logged (~$1.25 expected — flag if >2×).
**GATE:** all criteria, or not done.

---

## 7. Clustering, Scoring, Synthesis, Counter-Evidence, Publish Path

**Builds:** `ClusterEngine`, incremental assignment bands, Sonnet naming/merge, score SQL, `synthesize.draft_card` + `CounterEvidenceSearcher`, confidence rubric, publish task + `/ops/queue` API, nightly `cluster_sweep` + re-synthesis rule, eval-gated auto-publish (code present, config off), `eval_labels` capture. **Depends on:** §6.

**Steps:** (1) **superpowers:brainstorming** — one bounded session: the three counter-evidence query templates (satisfaction language, explicit negation, churn markers) per Tech Stack §6.3; output frozen into `config/prompts/`. (2) `ClusterEngine`: one SELECT of unassigned signal-chunk embeddings → sklearn `AgglomerativeClustering(metric='cosine', linkage='average', distance_threshold=0.30)` from `config/clustering.yaml`; candidates require ≥3 unique humans via `identity_id`; write `opportunities(candidate, pending_review, centroid=mean)` + `opportunity_signals(support, auto)` — **superpowers:test-driven-development** on band math: ≥0.78 auto-assign, 0.65–0.78 → operator queue, ≥3 co-clustering unassigned humans → new candidate. (3) Sonnet 4.6 naming calls (12 sampled chunks each, temp 0.2): name, customer-framed problem statement, merge proposals — through `PromptRegistry`. (4) Score: single SQL pass `0.5·log(1+unique_humans) + 0.3·severity + 0.2·recency`; severity = mean urgency {.33,.66,1.0}; recency `exp(−ln2·days/45)`; `score_inputs` persisted so every rank is explainable — TDD the math to fixed decimals. (5) `synthesize.draft_card`: HybridRetriever quote candidates diversified by identity; CounterEvidenceSearcher runs the three templates; `counter_checked_n` = chunks covered, persisted (the "N chunks checked" claim must be a checked claim); one Sonnet call temp 0.2 returns Pydantic card JSON: summary, ≥3 quote chunk_ids, counter chunk_ids-or-empty, confidence + rationale + raise-condition; confidence rubric-bounded in config (High = ≥6 humans across ≥2 sources AND counter reviewed). (6) Publish: `/ops/queue` API endpoints (operator-claim gated) — approve/rename/split/merge/discard, every correction appends `eval_labels`; `publish_card` flips status, audit-logs, fires `cards_published`; eval-gated auto-publish branch implemented behind `config/clustering.yaml` thresholds shipped **disabled** — enabling is a config PR that §19's baselines must justify. (7) Nightly `cluster_sweep` body + re-synthesis rule (≥3 new humans or any new counter → re-draft; rejected cards resurface in digest only). (8) **graphify** — confidence/state diagrams appended to `/docs/pipeline.md`.

**Acceptance criteria (PRD F2 / §4c-3):** every drafted card carries ≥3 quotes with source chunk links; counter-evidence block always present or the explicit checked claim with real N; frequency reads only from `opportunity_frequency`; no card reaches `published` without an operator action while auto-publish config is off (proven by test); band assignments audit `assigned_by` correctly; the 50-fixture batch yields named, scored, drafted cards end-to-end ≤11 min system time, <$2.50 LLM spend (Helicone-verified).
**Verify:** V + full pipeline run on preview from upload to `/ops/queue` rows; inspect one card's `score_inputs` and recompute by hand.
**GATE:** all criteria, or not done.

---

## 8. Onboarding + Upload UI (the TTFI path, B1–B5)

**Builds:** empty-workspace drop zone, preview/mapping modal, processing status page, first-cards render, the instrumented TTFI funnel start-to-stop. **Depends on:** §3, §5, §7.

**Steps:** (1) **vercel:nextjs** + **vercel:react-best-practices** — App Router pages `/w/[ws]` first-use state, `/w/[ws]/uploads/[batch]`; TanStack Query v5 keyed by route params; 2-s polling against `GET /v1/uploads/{batch}` (no SSE — Tech Stack §1). (2) **frontend-design:frontend-design** on brand tokens: full-width drop zone with the verbatim copy "Drop your interviews, exports, or feedback files.", quieter live-source card, drag-over lift with terra border, per-file inline rejection list that never blocks the batch. (3) **vercel:shadcn** — harvest-only: extract dialog focus-trap and file-input keyboard semantics for the mapping modal; implement in our inline-style system; install nothing. (4) Mapping modal (B3): speaker counts, CSV three-column mapper with auto-guess + required confirm, schema badges, scanned-PDF rejection copy verbatim. (5) Status page (B4): per-file `queued→parsing→chunking→embedding→done|failed:<reason>`, overall bar, elapsed, the "You can leave this page" line; partial-failure retry; total-failure banner + Sentry. (6) B5: board swaps in on first publish; one-time callout "Every claim links to your customers' words — click any quote."; empty-but-processing state with live counts. (7) PostHog events wired exactly: `upload_started`, `upload_completed`, `cards_published`, `card_opened`, `source_viewed` — TTFI stop requires card ≥3 quotes enforced in the funnel definition. (8) **humanizer~** — pass over *non-locked* microcopy only (helper lines, reassurance text); locked App Flow strings are listed in the PR description and asserted untouched.

**Acceptance criteria (PRD §4a, F1; App Flow B):** TTFI clock = `workspace_created` → `card_opened` + `source_viewed`, both required, visible in PostHog funnel; all B2–B4 locked strings verbatim; rejected files listed with reasons while valid files proceed; status page survives a mid-run deploy (polling, stateless).
**Verify:** V + **Playwright MCP** drives drag-drop with mixed valid/invalid fixtures, asserts strings, watches events fire, kills/redeploys preview mid-batch and confirms status resumes; **figma** diff per §1.3.
**GATE:** §1.3 passing definition + all criteria, or not done.

---

## 9. Trust Surface: Board, Card Detail, Source Viewer, Verdicts, Archive, Identities

**Builds:** Flows D1–D4 and E1–E3 complete — the product's daily surface. **Depends on:** §7, §8.

**Steps:** (1) **frontend-design:frontend-design** — board: track-record panel in the exact grammar "14 surfaced · 6 acted on · 3 parked · 5 rejected" (renders "0 surfaced" honestly), filters, ranked compact cards (Instrument Serif names). **vercel:next-cache-components** — board/card are dynamic, refetch on focus + after mutation; optimistic update on verdicts only. (2) Card detail (D2): the PRD F2 structure top-to-bottom, nothing collapsed — name inline-rename (`card_renamed`, history on hover), problem statement, evidence strip, ≥3 attributed quotes with monospace metadata, counter-evidence block always rendered (or the verbatim checked claim), confidence chip + raise condition, verdict bar. (3) D3 evidence list panel; D4 source viewer scroll-to-highlight via char offsets, terra span, breadcrumb, "also cited in" markers, purged-source state. The drill-down contract: quote→viewer = 1 click; strip→list→viewer = 2 clicks; nothing needs a third — encode as a Playwright assertion. (4) Verdicts (E1): Act modal with link field (nudged), Park one-click, Reject modal with the five reasons single-select required, 10-s undo, append-only writes, track-record refresh ≤1 min. (5) **interface-design** — Archive (E2) with disagreement sentences ("You rejected **Bulk import** on June 18 — reason: already knew."), restore logged; Identities (E3): suggested merges with match basis, merge recomputes frequency, split always available, first-use explainer. (6) Cross-cutting states (App Flow §12): 401 → re-auth modal returning to route with state; offline banner, verdict submission blocked offline with explanation; concurrent verdicts append with both actors. (7) **superpowers:test-driven-development** on verdict immutability at the API layer and identity merge/split frequency recompute.

**Acceptance criteria (PRD F2 / §4c-3, §4c-4):** ≤2-click drill-down proven by script; counter block on every card; reject requires structured reason; verdicts append-only (changing appends, never overwrites); track record updates within 1 min; rename logged with prior name; merge/split reversibility test green; 380px read-only board+card render.
**Verify:** V + **Playwright MCP** full E1 verdict cycle including undo + archive restore; **figma** diff on board, card, viewer, archive, identities.
**GATE:** §1.3 + all criteria, or not done.

---

## 10. Live Sources: Slack, GitHub, Discord + Sources Hub + Purge

**Builds:** three direct integrations end-to-end (OAuth/app/bot, webhooks, backfill, normalization, incremental cluster assignment), sources hub UI (C1–C5), disconnect purge cascade + monitor. **Depends on:** §6, §7, §9.

**Steps:** (1) **superpowers:dispatching-parallel-agents** — three provider agents, **caveman:compress**ed briefs, **caveman:cavecrew**: *Slack* — OAuth v2 with the exact scope set (`channels:read, channels:history, groups:read, groups:history, chat:write, users:read`), explicit channel picker, Events API verifier (v0 HMAC, 5-min tolerance, ack <3s via `integration_events` insert), paged backfill `Retry-After`-aware, `dedup_key slack:{channel}:{ts}`; *GitHub* — GitHub App per-repo install, `issues:read, metadata:read`, `X-Hub-Signature-256` webhooks, ETag backfill, issue+comments → one `documents(issue)` thread; *Discord* — discord.py 2.4 gateway inside `worker`, intents `guilds, guild_messages, message_content`, PM-selected channels only, session-resume reconnect, 5-min Sentry heartbeat, **file the privileged-intent verification application now** (Tech Stack §7.4 — the 100-server wall must never block the beachhead's primary channel). Each agent: **superpowers:test-driven-development** on its signature verifier and dedup key. (2) **context7**(slack_sdk, discord.py 2.4) per agent. (3) Sequential: `normalize.py` mapping all providers → documents+chunks with author_handle/posted_at/offsets → IdentityResolver → incremental band assignment from §7; pg_trgm >0.6 display-name *suggestions* feed the §9 identities screen. (4) **interface-design** — sources hub: four cards, sage status dots, scope summaries, last-sync, per-source terra error banners ("Slack token revoked — reconnect to resume sync"), Discord live "listening" indicator flipping on heartbeat loss >5 min; pickers get the §8 shadcn-harvested combobox keyboard semantics. (5) Disconnect (C5): typed-confirmation modal with real counts, `purge_source` cascade (signals → orphan-archive cards → chunks/documents/storage → rescore → audit with counts), `purge_monitor` Sentry-alerts pending >20h. (6) **composio-cli** — test-fixture generation only: fire sandbox Slack messages/GitHub issues at a dev workspace to exercise the webhook→ingest→assign path end-to-end without manual clicking.

**Acceptance criteria (PRD §4c-2; App Flow C):** connect flow ≤3 min per source (timed); webhook→chunk-visible ≤15 min path proven; channel/repo selection explicit, never workspace-wide; disconnect purges ≤24h SLA with monitor armed; heartbeat-loss warning visible in hub (kill the gateway, watch the card flip); all three signature verifiers reject tampered payloads with 401 and no body logged.
**Verify:** V + composio-generated live events traced from `integration_events` to a card's evidence list on preview; **figma** diff on the hub.
**GATE:** all criteria, or not done.

---

## 11. Digest + Notify

**Builds:** Monday digest (email + Slack DM mirror), Resend SMTP for auth mail, React Email templates, timezone dispatch, open tracking, zero-activity digest, rejected-card resurfacing. **Depends on:** §7, §9, §10.

**Steps:** (1) **context7**(resend, react-email). (2) Resend domain `mail.specflow.ai` with DKIM/SPF/DMARC *before* the first send; Supabase Auth SMTP relayed through Resend. (3) `digest_dispatch` hourly body: fires for workspaces at Monday 09:00 local via `workspaces.timezone` — **superpowers:test-driven-development** on the timezone math (DST fixtures included). (4) React Email templates on brand: top-5 cards with one representative attributed quote each, "What changed", "New counter-evidence" explicit, previously-rejected-resurfaced block (≥3 new humans), every block one-click to its card; zero-activity copy: "Quiet week — no new signal. Connected sources are healthy."; footer prefs — unsubscribe pauses email, never silently kills Slack DM. (5) Slack DM mirror via the workspace bot through queue `notify`. (6) `/webhooks/resend` Svix-verified → `digests.open_tracked` + PostHog `digest_opened`. (7) **humanizer~** — digest intro/transition copy (non-locked) reads like a person wrote it; locked strings asserted.

**Acceptance criteria (PRD §4c-5; App Flow F):** digest sends automatically with no human trigger; quotes rendered with attribution; one click from any block to its card; `digest_opened` fires via webhook; zero-activity week still sends the honest short version; counter-evidence surfaces in email, not just in-app.
**Verify:** V + force-dispatch to a test workspace across three timezones; open the email, confirm the PostHog event and `open_tracked` row.
**GATE:** all criteria, or not done.

---

## 12. Operator Console + PostHog Funnel + Event Parity

**Builds:** `/ops/queue` and `/ops/partners` UIs (Flow H), the TTFI dashboard, SLA timers, golden-set counter, event-name parity CI check. **Depends on:** §7, §8, §9, §10, §11.

**Steps:** (1) **interface-design** — operator console (internal density over flourish, still on brand tokens): *Clusters pending* tab with sampled chunks, cohesion, the 0.65–0.78 borderline queue, rename/split/merge/approve/discard, golden-set footer counter ("golden set: N labels") fed by `eval_labels`; *Cards pending* tab rendering the draft with the **same D2 component** §9 built, inline edit, 24-h SLA countdown from `pipeline_runs.finished_at`, >18h floats to top with terra timers. (2) `/ops/partners`: per-workspace TTFI (the only place the clock is visible — never PM-facing), last ingestion, digest open streak, verdict coverage %, "already-knew" rejection share live (the PRD §8 kill-criterion number), weekly-call notes field for the three fixed questions, classification 20-sample spot-check tool. (3) PostHog: build the TTFI funnel dashboard (`workspace_created → upload_started → upload_completed → cards_published → card_opened → source_viewed`) — **PRD §4c-6: this dashboard exists before partner #1; it exists now.** (4) Event parity: one constants module is the single source of event names for FE+BE; a CI test diffs it against `/docs/events.md` (the Tech Stack §8 map) — drift fails the build. (5) Operator routes gated by `is_operator` claim at middleware *and* API; every operator action audit-logged with identity — **superpowers:test-driven-development** on the gate (member with no claim → 404).

**Acceptance criteria (PRD §4c-6; App Flow H):** TTFI dashboard live and correct against a scripted run; SLA timers count from pipeline completion; every queue correction appends `eval_labels`; operator console invisible to non-operators (404, not 403); already-knew share computes from the disagreement log.
**Verify:** V + **Playwright MCP** as operator: approve a card, watch `cards_published` fire and the golden-set counter increment; as member: assert `/ops` is a 404.
**GATE:** all criteria, or not done.

---

## 13. Spec Generation + Linter + Glossary

**Builds:** `specs.generate` (Opus 4.8), the deterministic linter + Haiku ambiguity pass, auto-regeneration on lint failure, glossary CRUD, generation entry from Act-verdicted cards. **Depends on:** §7, §9.

**Steps:** (1) **woz:woz-recall** for card/evidence contracts. (2) `POST /opportunities/{id}/spec` guarded: requires an Act verdict (specs grow from decisions — App Flow I1). (3) Context pack assembly: opportunity + support/counter chunks + glossary + related prior approved specs via HybridRetriever (the §14 memory loop's read side, wired now). (4) `specs.generate` on `claude-opus-4-8` temp 0.2 → structured sections (story, acceptance_criteria, edge_cases, data_model, api_contract, qa_checklist), each with `evidence_refs` or `unevidenced=true` — never a hidden assumption. (5) Linter — **superpowers:test-driven-development**, every rule a named test before implementation, the PRD F3 list verbatim: every story ≥1 criterion; every criterion contains an observable outcome (testable verb + measurable state — "works well" fails); every noun resolves to glossary or data-model section; no ambiguous cross-sentence pronouns (Haiku 4.5 pass augments deterministic checks); edge-case section non-empty or explicitly "none identified — reviewed"; data-model changes enumerated or "none"; every section cited or flagged `[UNEVIDENCED — PM assumption]`. (6) Lint failure → one auto-regeneration with the lint report appended; a draft failing lint **never** reaches the PM (route to regeneration, then to operator attention). (7) Glossary CRUD endpoints + minimal settings UI (**interface-design**). (8) **caveman:caveman** for the Pydantic section models.

**Acceptance criteria (PRD F3):** all seven lint rules independently tested with passing and failing fixtures; failing draft provably unreachable by PM (API returns generation-in-progress, never the failed draft); every generated section carries citations or the UNEVIDENCED flag; Opus routing visible in Helicone with cost per spec logged.
**Verify:** V + generate from a fixture Act card; hand-check one spec's citations resolve to real chunks.
**GATE:** all criteria, or not done.

---

## 14. Review Canvas + Versions + Approval + Memory Re-ingest

**Builds:** the F3.5 diff canvas (Flow I2), block + spec state machines, version snapshot/diff/rollback, approval guard, export precondition, approved-spec re-ingestion into the corpus. **Depends on:** §13.

**Steps:** (1) **context7**(tiptap 2.6, diff-match-patch). (2) **frontend-design:frontend-design** — canvas: left column of discrete blocks with state chips; right rail scroll-synced evidence (quotes, citation confidence, source links) driven by `spec_sections.evidence_refs`; UNEVIDENCED flags as labeled amber blocks, never hidden; lock-icon note on non-approved specs: "Not visible to coding agents until approved." (3) Block machine `pending → accepted | edited | rejected` via `PATCH /v1/specs/{id}/sections/{sid}` `{action: accept|edit|reject_regenerate|instruct}` — TipTap inline diff for `edit` (stores `edit_diff`, lands `edited`), `reject_regenerate` pushes history + enqueues block regen on Opus with pinned original context, `instruct` adds the one-line steer — **superpowers:test-driven-development** on every transition + audit row. (4) Spec machine `draft → in_review → approved`: approve guarded server-side — every section `accepted|edited` else 409; approval snapshots the full section array into `spec_versions`, sets `approved_version`, records reviewer+timestamp; **any post-approval PATCH reverts to `in_review` and bumps `current_version`** — trigger on the transition function, proven by test. (5) Version diff = diff-match-patch over snapshot text + structural array diff; rollback copies an old snapshot forward as a new version. (6) On approval: re-ingest as `documents(kind='spec')` → chunk → embed into the same corpus — search now surfaces past decisions (Tech Stack §6.10); TDD: approved spec retrievable via HybridRetriever within one pipeline cycle. (7) **graphify** — both state machines rendered into `/docs/spec-states.md`.

**Acceptance criteria (PRD F3.5):** approve with any pending/rejected block → 409; post-approval edit reverts + bumps version (test); reviewer identity + timestamp in audit log; evidence rail scroll-syncs to the active block; generated text never renders without its evidence beside it; rollback produces a new version, history never rewritten; approved spec appears in evidence search.
**Verify:** V + **Playwright MCP**: accept/edit/instruct/approve full cycle, then edit post-approval and watch status revert; **figma** diff on the canvas.
**GATE:** §1.3 + all criteria, or not done.

---

## 15. MCP Server + Tokens + Ambiguity Loop + Ratings

**Builds:** the `mcp` service for real (FastMCP, Streamable HTTP, stateless, `mcp.specflow.ai`), token mint/revoke, four tools, rate limit, per-call audit, write-back loop with SLA + inbox + escalation, rating flow. **Depends on:** §14.

**Steps:** (1) **context7**(mcp SDK ≥1.2 — Streamable HTTP server specifics). (2) Service connects as `mcp_reader` (§2 grants: `approved_specs`, published-opportunities view, `chunks`, `opportunity_frequency`; INSERT `ambiguity_flags`; nothing else); workspace scope injected from the token row into every query. (3) Auth: bearer tokens minted/revoked by owners (settings UI + API), SHA-256 at rest, constant-time compare, `last_used_at`, scopes `{read, flag}` — **superpowers:test-driven-development**: timing-safe compare, revoked-token 401, scope enforcement, and the structural test that a `draft` spec is *unreachable* through this service. (4) Tools with exact Pydantic signatures (Tech Stack §6.8): `get_spec(ticket_key)` returning stories/criteria/edges/data-model/api-contract/qa/evidence-with-attribution/unevidenced/ambiguities{open,resolved}; `search_evidence(query, k=8)` over HybridRetriever with stance; `list_priorities()`; `flag_ambiguity(ticket_key, section, question)`. (5) Rate limit: token bucket 60 req/min per token, 429 + `Retry-After`; every call writes `audit_log(actor_type='agent')`. (6) Ambiguity loop (§6.9): Haiku dedup triage → flag with `sla_due_at = +4 business hours` workspace-local Mon–Fri 09:00–18:00 (TDD the business-hours calc, holidays excluded by design, DST fixtures) → same-transaction Slack DM (email fallback) → inbox `/w/[ws]/inbox` with live countdown (**interface-design**) → `sla_sweep` escalates at 24h (status, owner banner + email, audit) → answer pins to section and ships inside `get_spec().ambiguities.resolved`. (7) Ratings: `rating_tokens` single-use hashed, `/rate/[token]` page with the verbatim question "Did this spec describe what you actually built? 1–5. What was missing?" — two fields, ten seconds; score lands on the spec page + operator aggregate (% rated ≥4); expired-token dead-end with regenerate request. (8) `config_block.py`: renders the Cursor deeplink + `claude mcp add --transport http …` line + suggested first query into every export (consumed by §16); `/connect/cursor` landing with manual fallback; first authenticated call stops `time_to_first_mcp_query` and fires `mcp_first_query`.

**Acceptance criteria (PRD F4, F3.5):** draft/in-review specs structurally invisible via MCP (role-grant test, not an if-statement); flag → DM → inbox → answer → resolved-in-get_spec roundtrip proven; SLA countdown correct across timezone fixtures; escalation fires at 24h exactly once with audit row; 61st request in a minute → 429; every tool call audited; rating roundtrip updates the ≥4 aggregate.
**Verify:** V + connect a real Claude Code session to the preview MCP URL: `get_spec`, `flag_ambiguity`, answer in the inbox, re-query and read the resolved answer.
**GATE:** all criteria, or not done.

---

## 16. Exports + Nango Class: Linear, Jira, Intercom, Zendesk

**Builds:** Nango Cloud wiring, Linear/Jira export with embedded MCP config, post-merge rating trigger, Intercom/Zendesk ingestion, markdown export, `exports` table. **Depends on:** §10 (normalize), §15 (config block).

**Steps:** (1) **context7**(nango). Nango owns OAuth/refresh/webhooks; single Svix-style signed `/webhooks/nango`; tokens live in Nango, connection IDs in `sources.config`, our Vault holds only the Nango secret. (2) **superpowers:dispatching-parallel-agents** — four provider agents on **caveman:compress**ed briefs, **caveman:cavecrew** coordination: *Linear* — GraphQL `issueCreate` with description = spec markdown **+ §15 config block + deeplink**, `commentCreate` rating ask, done-with-PR webhook → mint rating token + Slack DM, `exports.external_key` resolves `ticket_key`; *Jira* — REST v3 OAuth 3LO, ADF description, same contract; *Intercom* — conversation webhooks + Conversations API backfill → `documents(ticket)` threads, parts=chunks, contact email → identity auto-link, `dedup_key intercom:{conversation}:{part}`; *Zendesk* — incremental cursor export + ticket webhooks, requester email → identity, `dedup_key zendesk:{ticket}:{comment}`. Each agent TDDs its dedup key + normalization. (3) Sequential: `POST /specs/{id}/export` (linear|jira|markdown), export history UI row (**interface-design**), markdown download embeds the same config block — no export path exists without the MCP install in it.

**Acceptance criteria (PRD F4 rollout; Tech Stack §7.5):** every export of every type embeds the MCP config block + Cursor deeplink + suggested first query; Linear done-webhook provably mints a rating token and DMs; Intercom/Zendesk events land as documents/chunks with identities linked by email; replaying a webhook is idempotent via `dedup_key`.
**Verify:** V + export a fixture spec to a Linear sandbox, click the embedded deeplink config against the preview MCP, complete one rating via the webhook-minted link.
**GATE:** all criteria, or not done.

---

## 17. Outcomes: Amplitude + Mixpanel Pulls + Predicted-vs-Actual

**Builds:** nightly `outcomes_pull`, metric binding at approval, `feature_outcomes`, the predicted-vs-actual panel. **Depends on:** §14.

**Steps:** (1) **context7**(amplitude export API, mixpanel raw export). (2) Approval flow gains metric binding: PM names the metric key to watch ("this ships → watch `import_completed`") + predicted direction/window, stored on the spec. (3) `outcomes_pull` nightly: batch read-only pulls (keys in Vault), filtered to bound keys, rows into `feature_outcomes(predicted, observed, window_days)` — **superpowers:test-driven-development** on window math + idempotent re-pulls. (4) Spec page panel renders predicted vs observed (**interface-design**). (5) Hard rule asserted in review: outcomes are **evidence for the human, never gradients for a model** — no code path adjusts weights/prompts from outcomes; scoring changes remain config PRs through the §19 gate (Tech Stack §6.6, permanent).

**Acceptance criteria:** bound metric pulls land nightly with correct windows; panel renders both series; grep-level + review-level assertion that no automatic weight adjustment exists; keys never appear in logs (redaction test extended).
**Verify:** V + seed a fake Amplitude export fixture, run the pull, read the panel.
**GATE:** all criteria, or not done.

---

## 18. Billing + Entitlements

**Builds:** Stripe Billing live, entitlement middleware enforced, founding-partner flag path, G3 billing settings. **Depends on:** §4 (middleware), §3 (settings shell).

**Steps:** (1) **context7**(stripe python + webhooks). (2) One product, one price: flat workspace subscription **$249/month**; founding partners are `billing_subscriptions.founding_partner=true` — entitled without a Stripe sub, a flag, not a code path. (3) Stripe-hosted checkout; customer portal via `POST /v1/billing/portal` — zero billing UI built beyond G3's read-only state ("Founding partner — $250/month, 12-month term" for the cohort; invoice list with status links) (**interface-design**). (4) Webhooks `checkout.session.completed`, `customer.subscription.updated/.deleted`, `invoice.payment_failed` → `billing_subscriptions`; **superpowers:test-driven-development** on webhook idempotency + signature rejection; Stripe is source of truth, our row is the cache. (5) Flip the §4 entitlement middleware from short-circuit to live: active subscription or founding flag, else 402 with a portal pointer. (6) Schema assertion stays true: nothing in `members` meters seats — **no per-seat pricing exists, structurally** (a taxed engineer seat is a lost MCP query).

**Acceptance criteria (Tech Stack §11):** founding workspace passes entitlement with no Stripe object; canceled subscription → 402 within one webhook delivery; replayed webhook is a no-op; portal session opens from G3; no seat counter anywhere in schema or code (review-asserted).
**Verify:** V + Stripe test-mode: checkout, cancel, dunning event — watch entitlement flip both ways on preview.
**GATE:** all criteria, or not done.

---

## 19. Evals: Golden Sets, Scorers, Baselines, the CI Merge Gate

**Builds:** the three Braintrust datasets, scorers, `evals/baselines.json`, the path-filtered GitHub Action, branch protection — the mechanism that makes a prompt regression undeployable. **Depends on:** §7, §13 (the generators it scores), §12 (`eval_labels` flowing).

**Steps:** (1) **atomic-agents** — offline fixture tooling *only*, never product runtime (Tech Stack §6.0 stands): a small agent chain generates the synthetic half of the corpora — 10 synthetic edge-case specs and the 10-planted-contradiction corpus for counter-evidence recall; output is reviewed, frozen files in `/evals/fixtures/`. (2) Datasets: `clustering-golden` (operator `eval_labels` + 50 seed-labeled signals; metric ARI + naming-quality LLM rubric + counter-evidence recall on the planted set), `card-synthesis-golden`, `spec-golden` (10 partner-real once partners exist + 10 synthetic; engineer-rated 1–5, founder-adjudicated). (3) Scorers in `evals/scorers/` — judges run Sonnet 4.6 *offline*, a different call than the generator, rubric pinned; **superpowers:dispatching-parallel-agents** to author the three scorer suites in parallel, **superpowers:test-driven-development** on scorer determinism (same input → same score at temp 0). (4) **codex:codex-cli-runtime** + **codex:gpt-5-4-prompting** — second-model red-team of the judge rubrics: have Codex draft cards that *should* fail and verify the judges fail them; bias in a judge silently corrupts every future "green." (5) `evals/baselines.json` seeded from the first honest run — baselines ratchet up via their own PR with the Braintrust run linked, never drift down. (6) GitHub Action: path filter `config/prompts/**`, `config/*.yaml`, `specflow/pipeline/**` → run bound datasets → any metric below baseline = red check; wire into branch protection as a required context. (7) Prove the gate: open a PR that deliberately degrades the synthesis prompt; CI must block the merge; close it. (8) Auto-publish enablement criteria documented: sustained ARI + rubric above `config/clustering.yaml` thresholds for N runs → a config PR may flip §7's switch for High-confidence cards only; Medium/Low stay operator-gated forever.

**Acceptance criteria (PRD §4c-6; Tech Stack §6.5/§8):** the deliberately-bad PR is unmergeable; every prompt YAML carries a bound dataset; judges fail the red-team fixtures; baselines file exists with linked runs; `eval_labels` from the ops queue flow into `clustering-golden` automatically.
**Verify:** V + the blocked-PR screenshot in the section log is the verification artifact.
**GATE:** the gate provably blocks a regression, or the section is not done.

---

## 20. Security Hardening + Compliance + Landing/Access

**Builds:** full webhook-verifier coverage audit, Vault wiring complete, deletion guarantees end-to-end, workspace export job, G2 data & privacy, DPA artifacts, Vanta, Vercel firewall, security headers, landing (A1) + request access (A2). **Depends on:** everything prior except §21.

**Steps:** (1) Verifier audit: all five receivers (slack/github/nango/stripe/resend) per the Tech Stack §9 table — tamper tests already exist per-section; this section asserts coverage and the 401-no-body-logged invariant globally. (2) Vault sweep: every credential-we-present (Nango secret, Amplitude/Mixpanel keys, per-tenant app secrets) is in Supabase Vault, decryptable only by service role — grep + test that no token-shaped value exists in app tables; credentials-others-present remain SHA-256 only. (3) Deletion end-to-end: source-disconnect purge cascade integration test with storage-object count verification; workspace delete (typed confirm, 60-s grace) → sessions/tokens/invites revoked immediately, Stripe canceled, hard delete ≤30 days, PITR age-out ≤37 — the numbers that go in the DPA; right-to-access export job (JSON + originals → emailed signed link). G2 page ships these controls + DPA download (**interface-design**). (4) **vercel:vercel-firewall** — bot protection + challenge on `/request-access` and `/login`; rate rules on the FE domain (the `/v1` surface is Railway — slowapi from §4 covers it, restated). (5) Security headers from the §1 next-forge harvest applied and tested. (6) **frontend-design:frontend-design** — landing A1: the positioning sentence verbatim as hero, one real card screenshot with counter-evidence visible, two CTAs; A2 request-access form with the feedback-location checkboxes (a research instrument), confirmation copy verbatim, `access_requested` event. **humanizer~** on supporting marketing copy only. (7) **vercel:runtime-cache** + **vercel:next-cache-components** — landing/static marketing cached; app routes stay dynamic. (8) Vanta agent across Supabase/Railway/Vercel/GitHub; SOC2 Type I engagement opens; evidence is already structural (RLS, audit log, access reviews). (9) **codex:codex-cli-runtime** — final second-model security review across auth, MCP, webhooks, purge; findings triaged to zero criticals. (10) **Sentry MCP** — confirm every cron check-in green for 7 consecutive days of preview operation.

**Acceptance criteria (App Flow A1/A2; Tech Stack §9):** locked landing/access copy verbatim; `access_requested` fires; purge SLA monitor alerts on an artificially-stalled purge; export job delivers a complete archive; cross-tenant suite still green post-everything; zero critical findings open; firewall challenge observed on scripted bot traffic.
**Verify:** V + **Playwright MCP** on landing/access; full deletion drill on a sacrificial workspace, verified down to storage object counts.
**GATE:** all criteria, or not done.

---

## 21. CI/CD Completion + Deployment Verification + Launch Gate

**Builds:** all seven required CI contexts live, migration discipline enforced, TTFI smoke in CI, deployment verification, the launch checklist closed. **Depends on:** all.

**Steps:** (1) Finish the seven contexts (Tech Stack §10): ruff/mypy → pytest unit+integration (supabase/postgres service container: RLS, state machines, RRF, dedup, purge, immutability) → httpx API contracts + webhook-signature rejection → tsc/eslint/`next build` (**vercel:turbopack** verified build) → Playwright smoke **signup → workspace → 3-file upload → cards → evidence → verdict** (the TTFI path is a required check — if it breaks, nothing else matters) → eval gate (§19) → `supabase db diff` empty against the branch DB. Branch protection requires all seven. (2) Deploy order on main: migrations first over 5432 (`supabase migration up`), Railway three-service deploy, Vercel promote; forward-only migrations, destructive changes as two PRs (stop-writing, then drop) so a one-click Railway rollback never meets a missing column — encode as a PR-template checklist. (3) **vercel:deployments-cicd** + **vercel:verification** — deployment protection on previews with a bypass token for the Playwright job; **vercel:vercel-agent** — automated post-deploy checks on every preview (routes 200, headers present, no console errors). (4) **vercel:next-upgrade** — readiness report only: codemod dry-run archived to `/docs/`, **no upgrade executed** (Tech Stack §1: upgrades are chores, never milestones). (5) **woz:woz-recall** sweep: the decision log is complete and queryable for the next contributor. (6) **caveman:caveman-stats** — final plan-wide token accounting appended to `/docs/spend.md`. (7) **superpowers:finishing-a-development-branch** — last stack lands; tag `v1.0.0`. (8) Launch checklist from §1 closed line-by-line; auto-publish remains **off** until §19's enablement criteria are met by real-workspace runs — flipping it is a config PR, not a launch task.

**Acceptance criteria (Tech Stack §10):** a PR missing any of the seven contexts cannot merge (proven); TTFI smoke green against a production-shaped preview; rollback drill executed (deploy, roll back one image, app healthy); migration-drift check catches an injected un-checked-in schema change; tag pushed; every plugin in this plan has at least one logged invocation in `/docs/spend.md`.
**Verify:** V — and this section's V runs against **production**, not preview, for the smoke path.
**GATE:** all seven contexts required and green, rollback drill passed, launch checklist closed — or the product is not launched.
