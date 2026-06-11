# ADR 004 — Vercel Workflow excluded

**Status:** Accepted  
**Date:** 2026-06-11

## Decision

Vercel Workflow (durable execution) is **not used** for job orchestration. Any future PR adopting it is rejected.

## Rule broken (Tech Stack §3)

`procrastinate` on Postgres is the durable job system. It provides:
- Queues `interactive`, `batch`, `notify` with concurrency 12
- Periodic tasks (`digest_dispatch`, `cluster_sweep`, `sla_sweep`, `purge_monitor`, `outcomes_pull`)
- Postgres-native persistence — no additional vendor, no extra egress cost, transactional task enqueue via `audited_txn()`

Vercel Workflow adds a second vendor for durability, breaks the Postgres-only data layer rule, and cannot participate in `audited_txn()` atomicity guarantees.

## Alternative

`procrastinate` + `audited_txn()`. Worker service runs on Railway from the same Docker image as `api`.
