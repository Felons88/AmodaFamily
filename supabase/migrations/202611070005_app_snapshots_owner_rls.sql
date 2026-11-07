-- Scope app_snapshots to the authenticated user.
-- The app now keys snapshot rows by auth user id, so RLS can enforce
-- owner-only access instead of the interim world-readable policy.

delete from public.app_snapshots;

drop policy if exists app_snapshots_rw on public.app_snapshots;

create policy app_snapshots_owner on public.app_snapshots
  for all
  using (key = auth.uid()::text)
  with check (key = auth.uid()::text);
