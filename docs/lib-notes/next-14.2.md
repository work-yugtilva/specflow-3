# next@14.2 — context7 extract (pinned: v14.3.0-canary.87)

## Key idioms (App Router, turbopack)

- `next dev --turbo` enables turbopack (package.json `dev` script)
- tsconfig: `strict: true`, `moduleResolution: bundler`, `jsx: react-jsx`
- App Router: pages live in `app/` directory
- Import alias: `@/*` maps to `./*`
- No Tailwind — inline styles only (project rule)

## package.json scripts
```json
{ "dev": "next dev --turbo", "build": "next build", "start": "next start", "lint": "next lint" }
```

## tsconfig.json (canonical)
- target: ES2017, lib: dom+esnext, strict, noEmit, isolatedModules, incremental
- plugins: [{ name: "next" }]

## Rejected Next 15/16 idioms
- `use cache` directive (15+)
- `after()` API (15+)
- `connection()` (15+)
- Partial Prerendering GA (15+)
