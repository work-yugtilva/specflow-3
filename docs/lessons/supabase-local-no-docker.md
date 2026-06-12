No Docker on dev Mac: colima + docker CLI via brew is enough for `supabase start`; exclude `vector,logflare` (docker.sock mount fails under colima) and `studio,imgproxy,edge-runtime,realtime` (unneeded, edge-runtime healthcheck 502s).

- `brew install colima docker && colima start --cpu 4 --memory 8`
- `supabase start -x vector,logflare,studio,imgproxy,edge-runtime,realtime`
- `~/bin/supabase` is a broken shim (missing supabase-go); real CLI: `npm i -g supabase`, binary at `$(npm prefix -g)/bin/supabase`.
- config.toml: `project_id = "..."` top-level; `[project] id=` fails parse (§1 wrote it wrong, never booted locally).
