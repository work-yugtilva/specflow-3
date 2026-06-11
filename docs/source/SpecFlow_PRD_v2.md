# SpecFlow AI — PRD v2

**Status:** Draft v2.0 · June 10, 2026. **Author:** Founder. **Supersedes:** v1.0 entirely. Not a patch. Ground-up rewrite.
**Compression note:** Caveman style. Short sentences. All facts preserved. Tags: [VALIDATED — source] = known. [HYPOTHESIS] = believed, unconfirmed.

---

## 1. PRODUCT POSITIONING STATEMENT

> **"SpecFlow turns scattered customer feedback into evidence-backed specs that AI coding agents execute directly — every line traceable to the customers who asked."**

Pain solved: founder-PMs decide features from memory. Signal sits unread in Slack, GitHub, Discord, interview recordings. Evidence dies before reaching the spec.

Behavior change enabled: PM ranks roadmap by cited evidence, not recall. Agent builds from a spec that knows which customers asked, and why.

---

## 2. THE PROBLEM (HONEST VERSION)

**Validated:**

- [VALIDATED — founder experience] I build with Claude Code daily. Vague spec → agent builds wrong thing fluently. Agent never asks clarifying questions. Silence is not quality. I deleted and rebuilt my own frontend after spec drift. Cost: weeks.
- [VALIDATED — founder experience] Spec quality is measurable, not vibes. Built multi-pass critic loop for my own specs. Score moved 58/100 → 84/100 only after structured evaluation. Unstructured review caught nothing.
- [VALIDATED — none, customer side] **Zero customer interviews completed. Every customer claim below is hypothesis.** No retention statistics exist. None will be cited.

**Hypotheses:**

- [HYPOTHESIS] H1 — Seed-stage signal volume: AI-native startups (2–20 engineers) generate 50–500 signals/month across Slack, GitHub, Discord, interviews. Enough to lose. Enough to cluster. *Kill condition: median partner volume <100/month AND clusters repeat weekly.*
- [HYPOTHESIS] H2 — Evidence loss: founder-PMs decide from recall. Cannot answer "which customers asked for the last shipped feature?" without 20+ minutes of search. *Kill condition: ≥12/20 interviewees answer instantly.*
- [HYPOTHESIS] H3 — Agent consumers raise the bar: spec consumer is now an agent. Agents execute ambiguity instead of asking about it. Spec clarity matters more than 2 years ago. *Kill condition: interviewees report agents handle vague tickets fine.*
- [HYPOTHESIS] H4 — Trust is winnable: PMs act on machine-ranked evidence when sources are 2 clicks away and counter-evidence is shown. *Kill condition: Phase 1 partners use cards as search, never as decisions.*

**Validation plan:** 20 problem interviews. Founder-PMs at agent-native seed startups. Source: YC network, X DMs, build-in-public communities. Script: last 3 feature decisions — how decided, where evidence lived, what process cost. All recorded. Transcripts become first dogfood corpus. **Deadline: June 24, 2026.** This section gets rewritten with real quotes on June 25.

---

## 3. WHO WE SERVE (REVISED BEACHHEAD)

**Primary: Founder-PM.** AI-native seed company. 2–20 engineers. Cursor or Claude Code daily. No support team. No Zendesk. Signal lives in Slack #feedback, GitHub issues, Discord community, call recordings, DMs.

*Day-in-the-life before SpecFlow:* Morning: 40 Discord messages, 12 GitHub issues, 3 Slack threads from a design partner. Reads some. Stars two. Forgets one. Afternoon: writes Linear ticket from memory — "users want better onboarding." Agent executes the ticket. Builds an onboarding tour. Users wanted faster imports. Evening: investor asks "what's the evidence for this quarter's roadmap?" Answer: vibes, confidently delivered.

*Trigger event:* Engineer (or agent) ships the wrong thing from a vague ticket. PM spends 25 minutes searching Slack for the original customer request. Finds fragments. Decision was verbal. Three days of build wasted. [HYPOTHESIS — frequency unknown; interview question #4 measures it.]

*What "good" looks like:*
- **Day 7:** Uploaded transcripts + connected Slack/GitHub. Sees 5 named opportunity cards built from own customers' words. Says: "Card #2 — I suspected this, never had the evidence in one place."
- **Day 30:** Weekly digest is a habit. 2+ roadmap items this month chose themselves from cards. PM pasted a cited quote into an investor update.
- **Day 90:** Every Linear ticket links to evidence. Engineer asks "why this?" PM sends a card link, not a paragraph. New signal auto-clusters into existing opportunities.

**Secondary: Engineering lead / agent operator.** Runs Cursor or Claude Code against tickets. *Before:* reverse-engineers customer intent from two-line tickets. *Trigger:* agent builds wrong thing twice in a month. *Good at day 30 (Phase 2):* agent pulls acceptance criteria + customer evidence via MCP without leaving the editor. Flags ambiguity. Gets PM answer same day.

**Org admin (condensed).** Same person as founder-PM at this stage, usually. Needs: invite 3–10 members, owner/member roles, delete-my-data button, DPA on request. Nothing more in Phase 1.

---

## 4. WHAT WE ARE BUILDING (SCOPE)

### 4a. The North Star

**Time-to-First-Insight (TTFI) < 10 minutes.**

Precise definition: clock starts at workspace creation. Clock stops when PM (a) opens first opportunity card containing ≥3 quotes from their own data, and (b) clicks through to ≥1 raw source. Both required — viewing without drill-down is not insight. Measured as median across new workspaces. Instrumented via PostHog events: `workspace_created` → `card_opened` → `source_viewed`. Baseline today: no workspaces. Zero.

### 4b. The Validated Aha Moment

[HYPOTHESIS — not yet validated. Experiment below.]

Believed sequence:
1. PM drags 10–20 interview transcripts (or Slack/Discord export) onto the empty workspace.
2. Progress view shows: parsed → chunked → clustered. Under 10 minutes for 50 documents.
3. Screen shows 5 named opportunity cards. Each card: their customers' names. Their customers' words. Frequency by unique humans. Counter-evidence where it exists.
4. PM clicks one quote. Lands inside the original transcript, scrolled to the highlight.
5. PM says the sentence we are hunting: *"I suspected this. I never had the evidence in one place."*

Experiment: first 5 design-partner onboardings run live on a call. Screen-recorded with consent. At step 3, one question: *"Would you act on card #1? Why or why not?"* Success bar: ≥3/5 answer yes AND name one card that surprised them. Failure bar: ≥3/5 say "all stuff I knew" → Bet 1 is wounded; see kill criteria §8. **Deadline: Week 3 (July 1, 2026).**

### 4c. What We Are Building (Phase 1 — 8 Weeks)

Rule: every item maps to a strategic bet (B1 = seed signal suffices; B2 = engineers adopt MCP; B3 = PMs let evidence change decisions). No bet, no build. B2 is tested in Phase 2 by design — Phase 1 carries zero MCP work.

**1. Upload-First Ingestion** — *Bet B1*
Drag-and-drop transcripts, CSVs, Slack/Discord exports. Front door, not fallback.
*Acceptance criteria:* 50 mixed documents process in ≤10 min p50; per-file status visible; failed files reported with reason, never silently dropped; speaker turns preserved in transcripts.
*Day-30 working behavior:* partners upload new interviews unprompted, same day as the call happens.

**2. Live Source Connect: Slack, GitHub, Discord** — *Bet B1*
Slack channel read (OAuth), GitHub issues (app install), Discord channels (bot invite). Continuous background sync.
*Acceptance criteria:* connect flow ≤3 min per source; new messages ingested ≤15 min after posting; PM selects channels explicitly — no full-workspace scraping; disconnect purges source data ≤24 h.
*Day-30 working behavior:* ≥2 live sources connected per active workspace; signal arrives without anyone uploading anything.

**3. Opportunity Cards + Evidence Panel** — *Bets B1 + B3*
Clustered, ranked opportunities. Evidence panel is the primary surface — supporting quotes, counter-evidence, confidence with visible track record, ≤2-click drill-down. Full spec in §6 F2.
*Acceptance criteria:* every card cites ≥3 quotes with source links; counter-evidence block present on every card (or explicit "none found — N chunks checked"); drill-down to raw source ≤2 clicks; frequency counts unique humans, never message count.
*Day-30 working behavior:* PMs open the drill-down without being told it exists. They quote cards in their own team discussions.

**4. Verdict + Disagreement Log** — *Bet B3*
PM marks each card: Act on it / Park / Reject (reason required).
*Acceptance criteria:* reject requires a structured reason (wrong cluster / already knew / not important / evidence misread / other+text); verdicts append to an immutable log; track-record panel reflects verdicts within 1 min.
*Day-30 working behavior:* ≥70% of surfaced cards carry a verdict. Rejections cluster into learnable patterns the founder reviews weekly.

**5. Weekly Evidence Digest** — *Bet B1*
Monday email + Slack DM: top 5 cards, what changed, new counter-evidence.
*Acceptance criteria:* sends automatically; renders quotes with attribution; one-click from digest to card.
*Day-30 working behavior:* digest open rate ≥60%; at least one partner forwards a digest internally.

**6. TTFI Instrumentation + Eval Harness v0** — *Bet B3 (trust requires measured quality)*
PostHog funnel for TTFI. Braintrust golden set v0 for clustering quality: 50 hand-labeled signals → expected clusters.
*Acceptance criteria:* TTFI dashboard live before first partner onboards; every prompt change runs the golden set before deploy; regression = blocked deploy.
*Day-30 working behavior:* prompt iterations cite eval deltas, not anecdotes.

### 4d. What We Are Not Building (Phase 1)

| Cut from v1 | Why deferred |
|---|---|
| Spec generation (F3) | Not the Phase 1 question. Trust in synthesis comes first. Phase 2. |
| Human review canvas (F3.5) | Reviews specs. No specs in Phase 1. Phase 2. |
| MCP server (F4) | Tests Bet B2. Sequenced after Bet B3 evidence. Phase 2. |
| Intercom + Zendesk OAuth | Wrong segment. Beachhead has no support desk. Phase 2, on paying demand. |
| Linear/Jira push | Export exists in old codebase; polishing it serves Phase 2 spec flow, not Phase 1 trust. |
| Custom scoring weights | Configurability before calibration = noise. Defaults unknown. Phase 3. |
| 10-node LangGraph orchestration | Nodes run as scripts until outputs deserve orchestration. §5. |
| F5 self-improving scoring | Insufficient data at beachhead scale. Phase 3. §6 F5. |
| Roles beyond owner/member | Admin UI premature. RLS schema + audit-log tables ship now — retrofitting those is hell. UI later. |
| Amplitude / Mixpanel | Outcome tracking needs shipped specs first. Phase 3. |
| SSO / SAML, SOC2 audit | No enterprise buyer in Phase 1. Architecture stays audit-ready; paperwork starts Phase 3. |
| Audio file upload (.mp3) | Open question §10-Q2. Text transcripts only for now. |
| Real-time collaborative editing | v1 already deferred it. Still deferred. |
| 4-vendor model sprawl | v1 used OpenAI + Google + Anthropic + Cohere. Phase 1 uses two vendors: Anthropic (reasoning) + OpenAI (embeddings). Fewer bills. Fewer failure modes. |

---

## 5. THE EVIDENCE-TO-SPEC PIPELINE (REVISED)

Phase 1 truth: pipeline is scripts plus a human gate. Not a graph. Existing assets get reused — FastAPI ingest service, pgvector embedding + hybrid retrieval, citation pipeline with source IDs and confidence scores. Greenfield is steps 5–7 only.

| # | Step | What happens (Phase 1) | Human-in-the-loop role (first 60 days) |
|---|---|---|---|
| 1 | Ingest | Upload parser + Slack/GitHub/Discord sync. Existing FastAPI service, extended. | Founder spot-checks parse failures daily. |
| 2 | Chunk | Semantic chunking. Speaker turns preserved. Metadata: author, source, date, plan tier if known. | None. Deterministic. |
| 3 | Embed | OpenAI text-embedding-3-large → pgvector. BM25 index in parallel. Existing service. | None. |
| 4 | Classify | Haiku tags intent, sentiment, urgency. Batch script. | Founder reviews 20-sample accuracy weekly. |
| 5 | Cluster | Script: embedding clusters → Sonnet names + merges. Dedup by unique-human count. | **Founder reviews every cluster before it becomes a card.** Renames bad names. Splits bad merges. Logs every correction. |
| 6 | Score | Fixed default formula: frequency (unique humans) × severity × recency. Weights hardcoded. | Founder sanity-checks ranking vs. own read of the data. Mismatches logged. |
| 7 | Synthesize | Sonnet drafts card: summary, quotes, counter-evidence search, confidence rationale. | **Concierge gate: founder approves/edits every card before partner sees it.** 24 h max latency. |
| 8 | Publish | Card lands in workspace + weekly digest. | Founder watches first-open behavior in PostHog. |

Corrections from steps 5–7 feed the Braintrust golden set. The concierge gate is the eval-set factory.

**Orchestrated version (Phase 2 onward):** durable background jobs with retries, per-step audit events, automatic publish gated on eval scores above threshold, human gate narrowing to low-confidence cards only. Deferred on purpose: orchestration multiplies throughput. Multiplying bad outputs makes things worse faster. Quality first. Plumbing second.

---

## 6. FEATURE SPECIFICATIONS (REVISED)

### F1 — Signal Ingestion (Phase 1)

Priority order: **transcript/CSV upload → Slack → GitHub → Discord.** Upload is the front door.

*Exact upload flow:* (1) Empty workspace shows one element: a drop zone. Copy: "Drop your interviews, exports, or feedback files." (2) Drag files → instant client-side validation (type, size). (3) Preview screen: detected file types, detected speakers per transcript, detected columns per CSV with a mapping confirm (author / date / text). (4) Confirm → processing screen with per-file status. (5) Completion → first cards render. TTFI clock is running this whole time.

*Accepted types:* `.txt`, `.md`, `.vtt`, `.srt`, `.csv`, `.json` (Slack + Discord export schemas auto-detected), `.pdf` (text layer only — scanned PDFs rejected with message).
*Limits:* ≤25 MB per file. ≤200 files per batch.
*Processing targets:* 50 documents ≤10 min p50, ≤20 min p95. Status visible per file. Failures named, never silent.

*Deduplication across the four sources:*
- Layer 1 — exact/near-duplicate: cosine similarity >0.95 within same author+week → collapse to one signal.
- Layer 2 — identity resolution: one human across platforms. Phase 1 mechanism: identity map table (email ↔ Slack handle ↔ Discord username ↔ GitHub login). Auto-matched on email where available; PM can merge identities manually. No magic claimed.
- Layer 3 — same-request clustering: same ask from different humans stays separate signals, counts as frequency. **Frequency = unique humans. Never message count.** One loud user posting 15 times = frequency 1.

### F2 — Synthesis & Opportunity Scoring (Trust-First)

Evidence panel is the primary UI surface. Not a tooltip. Not an accordion.

*Card structure (top to bottom):*
1. Opportunity name (PM-renamable; renames logged — feeds §10-Q6).
2. One-sentence problem statement in customers' framing.
3. Evidence strip: unique-human count, sources breakdown (Slack 4 · GitHub 3 · interviews 2), recency.
4. Supporting quotes: ≥3, attributed (name, company, date, source icon), each click-through to source.
5. **Counter-evidence block — always rendered:** contradicting signal, satisfied-user signal, or churned-requester flags. If empty: "No counter-evidence found — 1,240 chunks checked." Absence is a checked claim, not an omission.
6. Confidence: Low / Medium / High, plus one sentence stating what would raise it ("two more independent requesters → High").
7. Verdict bar: Act / Park / Reject.

*Confidence display — visible track record:* workspace-level panel: "Recommendations so far: 14 surfaced · 6 acted on · 3 parked · 5 rejected." Starts at zero. Populated only by PM verdicts. No invented priors. A confidence number with no track record is decoration; the track record is the trust mechanism.

*Drill-down path (≤2 clicks):* Click any quote → source viewer opens the full transcript/thread, scrolled to the highlighted span (1 click). Click evidence strip → full signal list for the card (1 click) → click any item → source viewer (2nd click). Nothing requires a third click.

*PM disagreement recording:* Reject → structured reason required: wrong cluster / already knew / not important / evidence misread / other (free text). Effects: card archived (recoverable); reason appended to immutable disagreement log; track record updates; weekly founder review of all rejections. **No automatic model adjustment in Phase 1** — honesty over theater. The system shows the rejection back: "You rejected 'Bulk import' on June 18 — reason: already knew." Memory of disagreement is itself a trust feature.

### F3 — Spec Generation (Phase 2)

**Quality bar: an engineer acts on the spec correctly.** Not "agent asks no questions." Agents never ask. They build the wrong thing fluently. Silence proves nothing.

*Spec linter — structural checks before PM ever sees a draft:*
- Every user story has ≥1 acceptance criterion.
- Every criterion contains an observable outcome (testable verb + measurable state). "Works well" fails lint.
- Every noun resolves to the workspace glossary or the data-model section. Unresolved nouns flagged.
- No ambiguous pronoun references across sentences.
- Edge-case section non-empty or explicitly "none identified — reviewed."
- Data-model changes enumerated or explicitly "none."
- Every section carries ≥1 evidence citation or an inline flag: `[UNEVIDENCED — PM assumption]`. Assumptions are allowed. Hidden assumptions are not.

*Braintrust eval harness:* Golden set = 20 reference specs. Source: 10 built from design partners' real opportunities + 10 synthetic edge cases. Ground truth: partner engineers rate each 1–5; founder adjudicates conflicts. Cadence: regression run on **every** prompt or model change before deploy, plus weekly scheduled run. Regression below baseline = blocked deploy. No exceptions.

*Engineer rating flow (post-merge):* One question, posted automatically as a Linear ticket comment + Slack DM after the linked PR merges: **"Did this spec describe what you actually built? 1–5. What was missing?"** Score + comment surface on the spec page and in the PM's weekly digest. Aggregate metric: **% of executed specs rated ≥4** — this is the real spec-quality number. Target set in Phase 2 exit criteria.

### F3.5 — Human Review Gate (Designed, Not Named)

Section-by-section diff canvas. The PM's daily surface. Reuses existing TipTap inline-diff editing with accept/reject controls.

*What the PM sees per spec section:* left column — generated content as discrete blocks (story, criteria, edge cases, data model). Right rail, pinned and scroll-synced — the evidence that drove this block: quotes, citation confidence, source links. Generated text never appears without its evidence beside it.

*Interaction states per block:* **Accept** (block locks, green) · **Edit inline** (TipTap; edits diff-tracked; edited block = accepted-with-changes) · **Reject + Regenerate** (block regenerates; old version retained in history) · **Add instruction** (one-line steer, e.g. "make criteria measurable in Amplitude" → targeted regeneration of that block only).

*State flow into MCP:* a spec reaches **Approved** only when every block is Accepted or Edited. Draft and In-Review specs are never served via MCP — hard rule. Approval writes reviewer identity + timestamp to the audit log. Any post-approval edit reverts status to In-Review and bumps the version. Diff and rollback across versions.

### F4 — MCP Server (Adoption-First, Phase 2)

**Risk severity: High.** Corrected from v1's "Low." Two-sided adoption: buyer (PM) ≠ user (engineer). Engineer never asked for this.

*Rollout strategy — install lives in the path of work:*
- Every Linear/Jira export and every spec markdown export embeds the MCP config block automatically: server URL, workspace-scoped token, suggested first query. Plus a one-click Cursor deeplink. Connecting SpecFlow is part of picking up the ticket, never a separate initiative.
- *First query an agent makes:* `specflow.get_spec(ticket_id)` → returns structured JSON: user stories, acceptance criteria, edge cases, data-model notes, top evidence quotes with attribution, open `[UNEVIDENCED]` assumptions. The agent starts with the why, not just the what.
- *Write-back:* `specflow.flag_ambiguity(spec_id, section, question)` → lands in the PM review queue + immediate Slack DM to the spec owner. **Response SLA: <4 business hours.** Unanswered at 24 h → escalates to workspace owner. Rationale: one ignored question and engineers stop asking permanently.
- *Adoption metric + gate:* weekly MCP queries per org; org counts as adopted at ≥1 query/week. **60-day gate: <60% of active orgs adopted → all feature work stops. Adoption gets fixed first.** Written here so future-me cannot negotiate with it.

### F5 — Feedback Loop (Deferred — Honest Scope)

Self-improving scoring from shipped outcomes: **Phase 3.** Math: a beachhead org ships 10–20 specced features per quarter. Learning scoring weights needs hundreds of outcome pairs, confound-controlled. n=15 per quarter = noise dressed as learning. Claiming otherwise is the same fabrication v1 committed with churn statistics.

Manual analog, Phases 1–2: engineer ratings (F3), PM disagreement log (F2), and a weekly founder-maintained spreadsheet correlating opportunity verdicts → spec ratings → shipped outcomes. When that spreadsheet shows a pattern worth automating, F5 earns its build. Not before.

---

## 7. INTEGRATION ROADMAP (REVISED)

| Integration | Phase | Rationale | Beachhead fit |
|---|---|---|---|
| Transcript / CSV / export upload | 1 | Front door. Zero-OAuth value in minutes. TTFI depends on it. | Every target team has files today. |
| Slack | 1 | #feedback channels + founder DMs = primary qualitative stream. Webhook ingest partially built. | Universal at target stage. |
| GitHub Issues | 1 | Technical users file structured requests here. High signal density. | Universal for dev-tool startups. |
| Discord | 1 | Where AI-native startups' communities actually live. v1 omitted it entirely — the single clearest segment error. | High for devtool/AI products. |
| Linear | 2 | Export target + engineer-rating surface, not a signal source. Needed when specs ship. | High. |
| Jira | 2 | Same role as Linear; larger orgs. | Medium. |
| Intercom | 2 | Real signal once a support function exists. Deferred: beachhead lacks support desks. Pulled forward the day a paying partner demands it. | Low now, grows with customers. |
| Zendesk | 2 | Same logic as Intercom. v1 had both in Phase 1 — built for a Series B stack the beachhead does not run. | Low now. |
| Amplitude / Mixpanel | 3 | Outcome tracking presupposes shipped specs + volume. Premature before Phase 2 exits. | Medium. |
| Salesforce / HubSpot | 3 | Revenue-weighted scoring is an upmarket feature. Wrong persona today. | Low. |
| Gong / Chorus | 3 | Sales-call signal arrives when customers have sales teams. | Low. |

---

## 8. PHASED LAUNCH PLAN (LEARNING-FIRST)

### Phase 1 — Prove Trust (Weeks 1–8)

One question: **can 10 PMs trust the machine's reading of their own customers?**

*Ships (the minimum):* §4c items 1–6. Two model vendors. Scripts + concierge gate per §5. Ten design partners at **$250/month per workspace, founding-partner rate, 12-month lock. Paid from day one — free pilots produce polite lies.** No per-seat pricing ever in this phase: engineer seats taxed = MCP queries lost later.

*Concierge model:* founder reviews every cluster and every card before any partner sees it. Cadence: ≤24 h from pipeline run to publish. Weekly 30-minute call per partner, three fixed questions: *Which card surprised you? Which card is wrong? Would you let this rank your roadmap?* Learning targets: cluster failure modes, naming quality, counter-evidence misses, verdict patterns. Every correction enters the golden set.

*Week 2 design-partner experience, day by day:*
- **Day 1 (Mon):** 25-min onboarding call. Partner uploads last quarter's transcripts, connects Slack #feedback + GitHub. First cards same day, concierge-reviewed.
- **Day 3 (Wed):** first digest: 5 named opportunities, unique-human counts, ≥3 quotes each, counter-evidence rendered.
- **Day 5 (Fri):** verdict nudge. Partner marks Act / Park / Reject on ≥3 cards.
- **Day 8 (Mon):** digest #2 shows movement: new signal absorbed into existing cards, track record now non-zero.
- **Day 10 (Wed):** 30-min call. The three questions. Hunting for: *"Card #2 — I suspected it, never had the evidence."* Dreading, and needing to hear early if true: *"This is all stuff I already knew."*

*Exit criteria (all required before Phase 2):*
- 10 active paying partners.
- TTFI median <10 min across all onboardings.
- ≥6/10 partners report a "didn't know that" insight in ≥2 separate weekly calls.
- ≥30% of accepted cards marked **Act** with a linked roadmap/sprint item.
- "Already knew" share of rejections <40%.

*Kill criteria (any one → stop, rethink Bet 1):*
- ≥6/10 partners at "all stuff I knew" after 4 weeks of full data.
- Median partner signal volume <100/month AND weekly cards repeat without movement.
- Digest open rate <30% by Week 6 — attention is the first thing churn kills.
- Pivot direction if killed: upmarket (50–500-person orgs — Intercom/Zendesk/SOC2 jump to Phase 1) or narrow to interview-synthesis wedge.

### Phase 2 — Prove Spec Quality + MCP (Weeks 9–16)

Conditioned on every Phase 1 exit criterion. Ships: F3 spec generation + linter, F3.5 review canvas, F4 MCP server, Linear export with embedded MCP config, Braintrust spec golden set live, engineer post-merge rating flow.

*MCP measurement + intervention:* weekly adopted-org %; time-to-first-MCP-query per org (target <7 days from first spec export); write-back response time. Trigger: adoption <60% at the 60-day gate → feature freeze, adoption sprint. Secondary trigger: any write-back unanswered >24 h twice in one org → founder intervenes directly with that PM.

*Exit criteria:* ≥60% adopted orgs · ≥70% of executed specs rated ≥4 by engineers · ≥80% of generated specs reach Approved within 2 review sessions (heavy editing is engagement, not failure — speed-to-approved is the bar, not zero-edit rate) · ≥1 write-back question asked and answered per org.

### Phase 3 — Enterprise Readiness + Revenue (Weeks 17–24, directional)

Intercom + Zendesk live. SOC2 Type I engagement starts. Pricing tiers beyond founding rate (workspace + connected-sources value metric; usage-based evaluated against real Helicone cost curves). Amplitude/Mixpanel outcome tracking groundwork → F5 prerequisites. EU residency if §10-Q5 demands it. **This section gets rewritten after Phase 1 exit. Anything more specific today is fiction.**

---

## 9. RISKS (HONEST VERSION)

| Risk | Severity | Likelihood | Early warning signal | Mitigation (specific) |
|---|---|---|---|---|
| PMs don't trust synthesis | High | High | "Already knew" >40% of rejections in Weeks 2–4; drill-down click-through <30% of card opens | Counter-evidence on every card; visible track record from zero; concierge gate; weekly 3-question calls; golden-set evals on every prompt change |
| **MCP adoption stalls** | **High** (v1 said Low — wrong) | Medium-High | Time-to-first-query >7 days; write-back unanswered >24 h; queries from <3 orgs by Week 12 | Config embedded in every ticket export; Cursor deeplink; 4-hour PM response SLA; 60-day feature-freeze gate written in advance |
| Beachhead signal volume insufficient (Bet 1 fails) | High | Medium | Median <100 signals/month; cards static week over week; digest opens decay | 20 interviews quantify volume before Week 3; upload path captures historical corpus on day 1; pre-committed pivot directions in §8 kill criteria |
| Concierge doesn't scale with founder time | Medium | High | Founder card-review >10 h/week; publish latency >24 h | Eval harness graduates high-confidence cards to auto-publish; concierge narrows to low-confidence only; partner cap stays at 10 until then |
| Solo-founder capacity / bus factor | High | — (structural) | Any Phase 1 week slipping >5 days; review backlog >48 h | Scope discipline in §4d; weekly cut ritual (something gets deferred every Friday); no net-new infrastructure while existing services suffice |
| Partner data trust (we hold their customers' words) | Medium | Medium | Partners redact uploads; security questions stall onboarding | DPA template ready before partner #1; no training on customer data — stated in writing; source disconnect purges ≤24 h; delete-workspace = hard delete |
| Linear/Jira ship native synthesis | Medium | Medium | Linear AI announcements; partners say "Linear does this now" in calls | Moat = cross-channel identity resolution + provenance data model they can't retrofit; deepen Slack/Discord/GitHub fusion fast; provenance graph from day 1 |
| LLM cost per workspace | Low (Phase 1 scale) | Low | Cost >$40/workspace/month at current volumes | Haiku for classification; Sonnet only for cluster/synthesize; two-vendor cap; Helicone per-request tracking from Week 1 |

---

## 10. WHAT WE DO NOT KNOW

First-class section. Each unknown changes the product if answered differently.

**Q1 — Pricing model.** Flat $250/workspace is a hypothesis, not a validated price. *Why it matters:* per-seat kills MCP adoption; underpricing locks wrong expectations for 12 months. *How answered:* 10 partners signed at $250 by **July 8** = validated for Phase 1; ≥3 balk specifically at price → test $150 vs. $400 anchoring in the next 5 conversations. Usage-based revisited Phase 3 with real cost data.

**Q2 — Audio-native discovery.** Direct .mp3/recording upload: high value, heavy processing. *Why it matters:* if partners' richest signal is locked in recordings, text-only ingestion misses the core corpus. *How answered:* count unprompted partner requests to upload audio; ≥4/10 by **July 22** → pulls Whisper ingestion into Phase 2; otherwise Phase 3.

**Q3 — Scoring transparency.** Show the formula or hide it? Transparency invites gaming; opacity erodes trust. *How answered:* concierge A/B — show full weights to 5 partners, summary-only to 5; compare trust language in weekly calls + verdict rates. Decision by **August 5**.

**Q4 — Write-back UX.** Agent ambiguity: block the agent, or async-notify the PM? *Why it matters:* blocking kills agent velocity; async risks ignored questions. *How answered:* shadow 3 partner engineers during first MCP sessions, Weeks 10–11; decide by **September 2** before F4 GA.

**Q5 — Data residency.** EU partners may require in-region storage. *How answered:* asked directly in all 20 interviews by **June 24**; ≥2 EU design partners → EU Supabase project lands in Phase 2; zero → Phase 3 backlog.

**Q6 — Opportunity naming.** AI names will sometimes be wrong or awkward. Rename burden vs. disambiguation layer. *How answered:* instrument rename rate from day 1; >50% of cards renamed by **July 22** → add a naming-confirmation step before publish; otherwise PM rename suffices.

**Q7 — Counter-evidence effect.** Does showing contradicting signal build trust or just lower conviction? *How answered:* weekly-call probe + verdict-rate comparison on cards with vs. without counter-evidence, reviewed **August 5**. If conviction drops without trust gains, redesign the block's framing — never remove it.

---

## 11. SUCCESS METRICS (PHASE 1 ONLY)

No cohort statistics. No retention multiples. Product has zero cohorts today; every baseline below is zero and says so.

| Metric | Definition (precise) | Maps to bet | Baseline | Week-8 target | Instrument |
|---|---|---|---|---|---|
| TTFI (median) | `workspace_created` → first `card_opened` + `source_viewed`, per §4a | B1 | 0 workspaces | <10 min | PostHog funnel, live before partner #1 |
| Weekly Insight Rate | % of partners reporting ≥1 "didn't know that" in the structured weekly call | B1 + B3 | 0 | ≥60% | Founder call log, 3 fixed questions, written same day |
| Evidence-Influenced Decision Rate | % of accepted cards marked **Act** with a linked roadmap/sprint item | B3 | 0 | ≥30% | Verdict log + link field; verified verbally in calls |
| "Already Knew" Rejection Share | Rejections citing *already knew* ÷ all rejections | B1 | 0 (no verdicts) | <40% | Disagreement log, immutable |
| Active Partner Retention (W8) | Partners with ≥1 ingestion event AND ≥1 digest open in Week 8 ÷ partners onboarded | B1 | 0 | ≥8/10 | Ingestion events + digest-open tracking |

Bet B2 carries no Phase 1 metric by design — MCP is unbuilt until Phase 2. Pretending to measure it would repeat v1's fabrication pattern.

---

## 12. YC APPLICATION ANSWERS

**"Describe your product in 3 sentences or less."** *(written for the moment 10 partners are active — not claimable before)*

> SpecFlow turns the customer feedback scattered across Slack, GitHub, Discord, and interview transcripts into ranked product opportunities and specs that AI coding agents execute directly — every recommendation cites the exact customers who asked. Ten design partners pay $250/month and use it weekly; the median team sees its first evidence-backed opportunity map within 10 minutes of uploading their own data. Coding agents made building fast; SpecFlow is the system of record for deciding what to build.

**"Why now?"**

> AI coding agents collapsed implementation time, which moved the bottleneck upstream: the constraint is no longer writing code, it's deciding what to build — and that decision is still a founder manually skimming Slack, GitHub, and Discord, then writing tickets from memory. Two things changed in the last eighteen months: the consumer of a spec is now an agent that executes ambiguity instead of asking about it, and MCP became the standard that lets a product-context layer feed those agents live while they build. The teams adopting agents fastest are hitting this wall today, and nobody owns it yet.

**"What have you built so far?"** *(honest, technical, specific — true today)*

> I'm a solo technical founder. The working system: a FastAPI + Supabase backend with pgvector hybrid retrieval (dense + BM25), a citation pipeline that carries source IDs and confidence scores from raw signal through generated output, Slack webhook ingestion, a multi-agent research synthesis pipeline for bulk transcripts and URLs, a TipTap review surface with inline diff and accept/reject per section, Linear sync, and multi-tenant row-level security. I also built a multi-pass spec critic that moved my own spec quality from 58 to 84 out of 100 — which taught me spec quality is measurable, and that agents executing vague specs fail silently. What's not built yet: the clustering-and-scoring layer that turns signal into ranked opportunities, and the MCP server — that's the current 8-week plan, with 10 paying design partners as the test. Twenty problem interviews are scheduled over the next two weeks; the problem section of this PRD gets rewritten with their words on June 25.
