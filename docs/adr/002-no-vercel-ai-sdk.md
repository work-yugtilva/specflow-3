# ADR 002 — Vercel AI SDK excluded

**Status:** Accepted  
**Date:** 2026-06-11

## Decision

`ai` (Vercel AI SDK) is **not installed** in this codebase. Any future PR adding it is rejected.

## Rules broken (Tech Stack §0.2 / §2)

1. **One-API-surface rule**: all LLM calls are made server-side via the raw Anthropic SDK through the Helicone proxy. The FE makes zero LLM calls. Vercel AI SDK's primary value is streaming LLM responses to the browser — a pattern this product explicitly rejects.
2. **Two-vendor rule**: introducing Vercel AI SDK adds Vercel as a second AI vendor surface alongside Anthropic. Cost attribution, retry logic, and prompt versioning all live in `LLMClient`/`ModelRouter`/`PromptRegistry` — not in a Vercel abstraction.

## Alternative

`LLMClient` wraps the raw `anthropic` SDK, routes through Helicone (`HELICONE_API_KEY`), and returns Pydantic-validated JSON. No streaming to FE.
