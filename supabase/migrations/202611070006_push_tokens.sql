-- Device push tokens for Firebase Cloud Messaging.
-- One row per (user, device token); owner-only RLS.
create table if not exists public.push_tokens (
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform text not null default 'android',
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);

alter table public.push_tokens enable row level security;

drop policy if exists push_tokens_owner on public.push_tokens;
create policy push_tokens_owner on public.push_tokens
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
