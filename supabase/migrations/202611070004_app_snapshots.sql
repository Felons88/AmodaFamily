-- Interim whole-state snapshot store for the local backend.
-- Keyed by an unguessable per-install key; normalized per-domain tables
-- replace this once full server auth + RLS land (see TASK_BOARD).
create table if not exists public.app_snapshots (
  key text primary key,
  state jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.app_snapshots enable row level security;

-- Interim policy: snapshot keys are unguessable uuids; tighten to
-- owner-scoped once real auth sessions map to server identities.
create policy app_snapshots_rw on public.app_snapshots
  for all using (true) with check (true);
