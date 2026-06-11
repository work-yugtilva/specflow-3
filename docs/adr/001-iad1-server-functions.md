# ADR 001 — Next.js Server Functions pinned to iad1

**Status:** Accepted  
**Date:** 2026-06-11

## Decision

All Next.js server functions (`runtime = "nodejs"`) are pinned to Vercel region `iad1` (US East, N. Virginia).

Add to `next.config.js` per-route or via `vercel.json`:
```json
{ "regions": ["iad1"] }
```
Default `maxDuration`: 10s for API routes, 30s for background-eligible routes.

## Rationale

Supabase project and Railway services both run in `us-east-1` (AWS N. Virginia). Pinning the FE compute layer to `iad1` minimises cross-region RTT on every DB/API call. Mismatched regions add 50–100ms per request with no upside.

## Consequences

- All server functions co-located with data layer.
- No edge runtime (`runtime = "edge"`) — disallowed by Tech Stack §1 (no streaming, no edge DB drivers).
