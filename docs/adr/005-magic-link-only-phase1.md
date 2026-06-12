# ADR-005: Magic Link Only in Phase 1

**Status:** Accepted
**Date:** 2026-06-12

## Context

Section 3 turns the tenancy and RLS boundary into user-facing sessions, invites, members, and onboarding. The original source docs listed Supabase magic links, Google OAuth, and Supabase SAML as Phase 1 sign-in methods. That is too much identity surface for an invite-gated launch with 10 founder-onboarded partners.

Supabase Auth remains the single identity system. The Supabase project stays on the free plan for Phase 1, so the paid SAML add-on is unavailable. Branch databases continue to use the already-approved local fallback pattern.

## Decision

Phase 1 has exactly one sign-in method: Supabase Auth magic link by email.

Google OAuth is deferred, not deleted from the product strategy. It may return in a later ADR when partner demand proves that IdP convenience is worth the added auth surface.

SAML ships only as a stub path in Phase 1. The frontend may render "Continue with SSO" only when a domain-to-IdP map is populated, which is empty by default. The enablement path requires a paid Supabase plan upgrade and a contract that funds it.

## Consequences

- No Google/social auth code path ships in Phase 1.
- The hosted Supabase token hook registration is still required before partner sign-in so JWTs carry `workspace_ids`, `roles`, and `is_operator`.
- SSO contract work is limited to the documented `GET /v1/auth/sso-check?domain=` stub and launch-checklist runbook language.
- Resend custom SMTP is login-critical because all Phase 1 sign-in depends on email deliverability.

## Step Zero Edit Map

The next step amends only sign-in-method references at:

- `docs/plan.md:75` — Section 3 build scope changes from magic link + Google OAuth + SAML add-on to magic link only plus SAML stub.
- `docs/plan.md:77` — Section 3 Supabase configuration step removes Google OAuth and paid SAML add-on setup from Phase 1.
- `docs/plan.md:80` — Section 3 verification changes from SAML config smoke to SAML stub smoke.
- `docs/source/SpecFlow_TechStack_v3.md:43` — Stack map auth row changes Phase 1 auth method.
- `docs/source/SpecFlow_TechStack_v3.md:63` — Frontend auth-pages line changes to magic link only, with SAML stub render conditions.
- `docs/source/SpecFlow_TechStack_v3.md:284` — Auth section changes to magic link as the only Phase 1 sign-in method.
- `docs/source/SpecFlow_TechStack_v3.md:307` — Roles section changes SAML role mapping from active Phase 1 config to the later paid SSO path.
- `docs/source/SpecFlow_TechStack_v3.md:609` — v2-to-v3 SSO correction changes from paid add-on now to stub now, paid add-on later.
- `docs/launch-checklist.md` — Resend custom SMTP is recorded as login-critical before partner #1's first sign-in.

`docs/source/SpecFlow_AppFlow_v1.pdf` is the only App Flow source present in this repository. This ADR amends A3's binding Phase 1 sign-in interpretation from "Magic link (email) + Google OAuth" to "Magic link (email) only" until an editable App Flow source is added or the PDF is regenerated.
