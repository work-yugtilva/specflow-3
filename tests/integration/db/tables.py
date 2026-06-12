"""Table registry for RLS test parametrization. Source: Tech Stack v3 §4.1 (30 relations)."""

# tables with a workspace_id column; policy: ws_isolation
WS_TABLES = [
    "members", "invites", "identities", "identity_handles", "glossary_terms",
    "sources", "upload_batches", "documents", "chunks", "integration_events",
    "opportunities", "verdicts", "eval_labels",
    "specs", "spec_sections", "mcp_tokens", "ambiguity_flags", "engineer_ratings", "exports",
    "pipeline_runs", "digests", "feature_outcomes", "audit_log",
    "billing_customers", "billing_subscriptions",
]

# tenant key is id itself
WORKSPACES = "workspaces"

# no workspace_id column; scoped via parent EXISTS policy
PARENT_TABLES = {
    "opportunity_signals": ("opportunity_id", "opportunities"),
    "spec_versions": ("spec_id", "specs"),
    "rating_tokens": ("spec_id", "specs"),
    "pipeline_steps": ("run_id", "pipeline_runs"),
}

# owner-clause tables (Tech Stack §5): member role sees/touches nothing
OWNER_GATED = {"members", "invites", "mcp_tokens", "billing_customers", "billing_subscriptions"}

# append-only: no UPDATE/DELETE denial tests (immutability suite covers them)
IMMUTABLE = {"verdicts", "audit_log"}

ALL_RELATIONS = [WORKSPACES, *WS_TABLES, *PARENT_TABLES.keys()]
