# SpecFlow Launch Checklist

Harvested from next-forge production patterns. Stack adopted: none. Checklist only.

## Security Headers

- [ ] `X-Frame-Options: DENY` set in Next.js response headers
- [ ] `X-Content-Type-Options: nosniff`
- [ ] `Referrer-Policy: strict-origin-when-cross-origin`
- [ ] `Permissions-Policy` restricts camera/mic/geolocation
- [ ] `Content-Security-Policy` — script-src self + nonce, no unsafe-inline
- [ ] `Strict-Transport-Security` with `max-age=31536000; includeSubDomains`
- [ ] All headers verified via [securityheaders.com](https://securityheaders.com) before go-live

## robots.txt / sitemap

- [ ] `robots.txt` at `/` — disallow `/ops`, `/w/`, `/api/`; allow public pages
- [ ] `sitemap.xml` generated and submitted to Google Search Console
- [ ] `next-sitemap` or manual generation — no dynamic routes with sensitive params

## Error Pages

- [ ] `app/not-found.tsx` — branded 404 with nav home link
- [ ] `app/error.tsx` — branded runtime error boundary; Sentry `captureException` called
- [ ] `app/global-error.tsx` — root error boundary for layout crashes
- [ ] Verify all three render correctly on preview before prod deploy

## Performance

- [ ] `next build` output logged; no unexpected large bundles (>500KB)
- [ ] Images via `next/image` with explicit `width`/`height` (no CLS)
- [ ] Fonts: Instrument Serif + DM Sans loaded via `next/font` with `display: swap`

## Observability

- [ ] Sentry DSN set for FE + BE projects; source maps uploaded on build
- [ ] Sentry cron check-ins registered for all five periodic tasks
- [ ] PostHog project key set; `workspace_created`, `upload_*`, `card_*` events wired

## Auth Email

- [ ] Resend custom SMTP (plan §11) is LOGIN-critical, not digest-critical — Supabase's built-in mailer is rate-limited and not production-grade. Live before partner #1's first sign-in.

## Pre-Launch

- [ ] Branch protection active on `main` — all 7 CI contexts required
- [ ] Preview-per-PR verified on a test branch
- [ ] Prod deploy tested from `main`
- [ ] Supabase RLS verified from a non-owner JWT
- [ ] Railway health endpoints 200 for api/worker/mcp
- [ ] Helicone $40/workspace alert tested (fire a synthetic over-spend)

## §2 deploy note (hook registration does not travel with db push)
- [ ] Before §3 auth work on hosted: `supabase db push` (migrations 0101-0108) AND register the
  custom_access_token hook on the hosted project (Management API PATCH or `supabase config push` —
  beware config.toml carries local-dev site_url; prefer surgical API PATCH). Without it, production
  JWTs carry no workspace_ids and every user sees empty data.
