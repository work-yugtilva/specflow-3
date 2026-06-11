# ADR 003 — Vercel AI Gateway excluded

**Status:** Accepted  
**Date:** 2026-06-11

## Decision

Vercel AI Gateway is **not used** as a proxy or cost layer. Any future PR routing LLM traffic through it is rejected.

## Rule broken (Tech Stack §8)

Helicone is the designated proxy and cost layer. It provides:
- Per-workspace spend tagging (`workspace_id · run_id · prompt_id@version · task`)
- `Helicone-Omit-Request/Response: true` header (customer text never persists in a third vendor)
- The $40/workspace/month alert wired to Slack `#alerts`

Vercel AI Gateway duplicates this role, splits cost visibility across two dashboards, and creates a second vendor that can store customer text — violating Tech Stack §9.

## Alternative

All LLM traffic: `LLMClient` → Helicone proxy → Anthropic API.
