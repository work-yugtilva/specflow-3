-- Two-workspace fixture graph: one row per workspace in every relation (RLS denial surface).
-- Fixed UUIDs mirror tests/integration/db/conftest.py.
BEGIN;

TRUNCATE workspaces CASCADE;
DELETE FROM auth.users WHERE id IN (
  '00000000-0000-0000-0001-00000000000a','00000000-0000-0000-0002-00000000000a',
  '00000000-0000-0000-0001-00000000000b','00000000-0000-0000-0003-00000000000f');

INSERT INTO auth.users (id, instance_id, aud, role, email, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
VALUES
  ('00000000-0000-0000-0001-00000000000a','00000000-0000-0000-0000-000000000000','authenticated','authenticated','owner-a@test.local',now(),now(),'{}','{}'),
  ('00000000-0000-0000-0002-00000000000a','00000000-0000-0000-0000-000000000000','authenticated','authenticated','member-a@test.local',now(),now(),'{}','{}'),
  ('00000000-0000-0000-0001-00000000000b','00000000-0000-0000-0000-000000000000','authenticated','authenticated','owner-b@test.local',now(),now(),'{}','{}'),
  ('00000000-0000-0000-0003-00000000000f','00000000-0000-0000-0000-000000000000','authenticated','authenticated','operator@test.local',now(),now(),'{"is_operator": true}','{}');

INSERT INTO workspaces (id, name, company, timezone) VALUES
  ('00000000-0000-0000-0000-00000000000a','WS A','A Co','UTC'),
  ('00000000-0000-0000-0000-00000000000b','WS B','B Co','UTC');

INSERT INTO members (workspace_id, user_id, role) VALUES
  ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0001-00000000000a','owner'),
  ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0002-00000000000a','member'),
  ('00000000-0000-0000-0000-00000000000b','00000000-0000-0000-0001-00000000000b','owner');

INSERT INTO invites (id, workspace_id, email, role, token_hash, expires_at) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','invite-a@test.local','member','\xaa',now()+interval '7 days'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','invite-b@test.local','member','\xbb',now()+interval '7 days');

INSERT INTO identities (id, workspace_id, display_name, primary_email) VALUES
  ('00000000-0000-0001-0001-00000000000a','00000000-0000-0000-0000-00000000000a','Ada','ada@a.test'),
  ('00000000-0000-0001-0002-00000000000a','00000000-0000-0000-0000-00000000000a','Alan','alan@a.test'),
  ('00000000-0000-0001-0003-00000000000a','00000000-0000-0000-0000-00000000000a','Grace','grace@a.test'),
  ('00000000-0000-0001-0001-00000000000b','00000000-0000-0000-0000-00000000000b','Bob','bob@b.test');

INSERT INTO identity_handles (id, workspace_id, identity_id, platform, handle) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0001-0001-00000000000a','slack','U0A'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','00000000-0000-0001-0001-00000000000b','slack','U0B');

INSERT INTO glossary_terms (id, workspace_id, term, definition, created_by) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','batch','group of files','00000000-0000-0000-0001-00000000000a'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','ticket','support item','00000000-0000-0000-0001-00000000000b');

INSERT INTO sources (id, workspace_id, provider, status, config) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','slack','connected','{}'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','slack','connected','{}');

INSERT INTO upload_batches (id, workspace_id, file_count, status, created_by) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a',1,'done','00000000-0000-0000-0001-00000000000a'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b',1,'done','00000000-0000-0000-0001-00000000000b');

INSERT INTO documents (id, workspace_id, kind, title, status) VALUES
  ('00000000-0000-0002-0001-00000000000a','00000000-0000-0000-0000-00000000000a','transcript','Doc A','done'),
  ('00000000-0000-0002-0001-00000000000b','00000000-0000-0000-0000-00000000000b','transcript','Doc B','done');

INSERT INTO chunks (id, workspace_id, document_id, text, char_start, char_end, identity_id, posted_at) VALUES
  ('00000000-0000-0003-0001-00000000000a','00000000-0000-0000-0000-00000000000a','00000000-0000-0002-0001-00000000000a','chunk a',0,7,'00000000-0000-0001-0001-00000000000a',now()),
  ('00000000-0000-0003-0001-00000000000b','00000000-0000-0000-0000-00000000000b','00000000-0000-0002-0001-00000000000b','chunk b',0,7,'00000000-0000-0001-0001-00000000000b',now());

INSERT INTO integration_events (workspace_id, provider, external_id, event_type, payload, dedup_key, received_at) VALUES
  ('00000000-0000-0000-0000-00000000000a','slack','e1','message','{}','seed:a:1',now()),
  ('00000000-0000-0000-0000-00000000000b','slack','e1','message','{}','seed:b:1',now());

INSERT INTO opportunities (id, workspace_id, name, problem_statement, status, cluster_state) VALUES
  ('00000000-0000-0004-0001-00000000000a','00000000-0000-0000-0000-00000000000a','Opp A','problem a','published','approved'),
  ('00000000-0000-0004-0001-00000000000b','00000000-0000-0000-0000-00000000000b','Opp B','problem b','candidate','pending_review');

INSERT INTO opportunity_signals (opportunity_id, chunk_id, stance, similarity, assigned_by) VALUES
  ('00000000-0000-0004-0001-00000000000a','00000000-0000-0003-0001-00000000000a','support',0.9,'auto'),
  ('00000000-0000-0004-0001-00000000000b','00000000-0000-0003-0001-00000000000b','support',0.9,'auto');

INSERT INTO verdicts (id, workspace_id, opportunity_id, verdict, actor) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0004-0001-00000000000a','act','00000000-0000-0000-0001-00000000000a'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','00000000-0000-0004-0001-00000000000b','park','00000000-0000-0000-0001-00000000000b');

INSERT INTO eval_labels (id, workspace_id, chunk_id, expected_cluster_key, labeled_by) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0003-0001-00000000000a','k1','seed'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','00000000-0000-0003-0001-00000000000b','k1','seed');

INSERT INTO specs (id, workspace_id, opportunity_id, title, ticket_key, status, current_version, approved_version, approved_by, approved_at, created_by) VALUES
  ('00000000-0000-0005-0001-00000000000a','00000000-0000-0000-0000-00000000000a','00000000-0000-0004-0001-00000000000a','Draft Spec A','SPF-1','draft',1,NULL,NULL,NULL,'00000000-0000-0000-0001-00000000000a'),
  ('00000000-0000-0005-0002-00000000000a','00000000-0000-0000-0000-00000000000a','00000000-0000-0004-0001-00000000000a','Approved Spec A','SPF-2','approved',1,1,'00000000-0000-0000-0001-00000000000a',now(),'00000000-0000-0000-0001-00000000000a'),
  ('00000000-0000-0005-0001-00000000000b','00000000-0000-0000-0000-00000000000b','00000000-0000-0004-0001-00000000000b','Draft Spec B','SPF-3','draft',1,NULL,NULL,NULL,'00000000-0000-0000-0001-00000000000b');

INSERT INTO spec_sections (id, workspace_id, spec_id, order_idx, block_type, content, status) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0005-0001-00000000000a',0,'story','{"text":"story a"}','pending'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','00000000-0000-0005-0001-00000000000b',0,'story','{"text":"story b"}','pending');

INSERT INTO spec_versions (id, spec_id, version, snapshot, created_by) VALUES
  (gen_random_uuid(),'00000000-0000-0005-0002-00000000000a',1,'[{"block_type":"story","content":{"text":"approved story"}}]','00000000-0000-0000-0001-00000000000a'),
  (gen_random_uuid(),'00000000-0000-0005-0001-00000000000b',1,'[{"block_type":"story","content":{"text":"b v1"}}]','00000000-0000-0000-0001-00000000000b');

INSERT INTO mcp_tokens (id, workspace_id, name, token_hash, created_by) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','tok-a','\xa1','00000000-0000-0000-0001-00000000000a'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','tok-b','\xb1','00000000-0000-0000-0001-00000000000b');

INSERT INTO ambiguity_flags (id, workspace_id, spec_id, question, asked_via, status) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0005-0002-00000000000a','what is x?','cursor','open'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','00000000-0000-0005-0001-00000000000b','what is y?','cursor','open');

INSERT INTO engineer_ratings (id, workspace_id, spec_id, rating, rater_handle, source) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0005-0002-00000000000a',5,'eng-a','linear'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','00000000-0000-0005-0001-00000000000b',4,'eng-b','linear');

INSERT INTO rating_tokens (id, spec_id, token_hash, expires_at) VALUES
  (gen_random_uuid(),'00000000-0000-0005-0002-00000000000a','\xa2',now()+interval '7 days'),
  (gen_random_uuid(),'00000000-0000-0005-0001-00000000000b','\xb2',now()+interval '7 days');

INSERT INTO exports (id, workspace_id, spec_id, target, external_key) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0005-0002-00000000000a','markdown','exp-a'),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','00000000-0000-0005-0001-00000000000b','markdown','exp-b');

INSERT INTO pipeline_runs (id, workspace_id, trigger, status) VALUES
  ('00000000-0000-0006-0001-00000000000a','00000000-0000-0000-0000-00000000000a','upload_batch','complete'),
  ('00000000-0000-0006-0001-00000000000b','00000000-0000-0000-0000-00000000000b','upload_batch','complete');

INSERT INTO pipeline_steps (id, run_id, step, status) VALUES
  (gen_random_uuid(),'00000000-0000-0006-0001-00000000000a','parse','done'),
  (gen_random_uuid(),'00000000-0000-0006-0001-00000000000b','parse','done');

INSERT INTO digests (id, workspace_id, sent_at, payload, open_tracked) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a',now(),'{}',false),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b',now(),'{}',false);

INSERT INTO feature_outcomes (id, workspace_id, spec_id, metric_source, metric_key, predicted, observed, window_days) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0005-0002-00000000000a','manual','m1','{}','{}',30),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','00000000-0000-0005-0001-00000000000b','manual','m1','{}','{}',30);

INSERT INTO audit_log (workspace_id, actor_type, actor_id, action, object_type, object_id, payload) VALUES
  ('00000000-0000-0000-0000-00000000000a','user','00000000-0000-0000-0001-00000000000a','seed','workspace','00000000-0000-0000-0000-00000000000a','{}'),
  ('00000000-0000-0000-0000-00000000000b','user','00000000-0000-0000-0001-00000000000b','seed','workspace','00000000-0000-0000-0000-00000000000b','{}');

INSERT INTO billing_customers (workspace_id, stripe_customer_id) VALUES
  ('00000000-0000-0000-0000-00000000000a','cus_a'),
  ('00000000-0000-0000-0000-00000000000b','cus_b');

INSERT INTO billing_subscriptions (id, workspace_id, stripe_subscription_id, status, founding_partner) VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','sub_a','active',true),
  (gen_random_uuid(),'00000000-0000-0000-0000-00000000000b','sub_b','active',false);

COMMIT;
