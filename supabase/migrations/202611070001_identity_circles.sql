-- FC-002: identity and circle boundary. Later migrations must use circle_id and
-- enforce membership on every private table. Apply only to a fresh dev project.
create extension if not exists pgcrypto;

create table public.circles (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 80),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table public.circle_memberships (
  circle_id uuid not null references public.circles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'adult')),
  status text not null default 'active' check (status in ('active', 'invited', 'removed')),
  joined_at timestamptz not null default now(),
  primary key (circle_id, user_id)
);

create unique index circle_one_active_owner
  on public.circle_memberships(circle_id)
  where role = 'owner' and status = 'active';
create index circle_memberships_active_user
  on public.circle_memberships(user_id, circle_id)
  where status = 'active';

-- Children are managed records, never independently authenticated users.
create table public.managed_minors (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles(id) on delete cascade,
  guardian_user_id uuid not null,
  alias text not null check (length(trim(alias)) between 1 and 60),
  age_band text not null check (age_band in ('0_4', '5_8', '9_12', '13_17')),
  created_at timestamptz not null default now(),
  unique (circle_id, id),
  foreign key (circle_id, guardian_user_id)
    references public.circle_memberships(circle_id, user_id)
);
create index managed_minors_guardian
  on public.managed_minors(circle_id, guardian_user_id);

-- SECURITY DEFINER helpers have a fixed search path and no caller-controlled
-- identity argument. They read only the signed auth context.
create function public.is_active_circle_adult(p_circle_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.circle_memberships m
    where m.circle_id = p_circle_id
      and m.user_id = (select auth.uid())
      and m.status = 'active'
      and m.role in ('owner', 'admin', 'adult')
      and exists (
        select 1 from auth.users u
        where u.id = m.user_id
          and u.raw_app_meta_data ->> 'adult_verified' = 'true'
      )
  );
$$;

create function public.create_circle(p_name text)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_circle uuid;
begin
  if v_actor is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if not exists (
    select 1 from auth.users u
    where u.id = v_actor
      and u.raw_app_meta_data ->> 'adult_verified' = 'true'
  ) then
    raise exception 'verified adult authorization required' using errcode = '42501';
  end if;
  if p_name is null or length(btrim(p_name)) not between 1 and 80 then
    raise exception 'invalid circle name' using errcode = '22023';
  end if;

  insert into public.circles (name, created_by)
  values (btrim(p_name), v_actor)
  returning id into v_circle;
  insert into public.circle_memberships (circle_id, user_id, role)
  values (v_circle, v_actor, 'owner');
  return v_circle;
end;
$$;

create function public.create_managed_minor(
  p_circle_id uuid, p_alias text, p_age_band text
)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_minor uuid;
begin
  if v_actor is null or not public.is_active_circle_adult(p_circle_id) then
    raise exception 'active adult membership required' using errcode = '42501';
  end if;
  if p_alias is null or length(btrim(p_alias)) not between 1 and 60
     or p_age_band is null or p_age_band not in ('0_4', '5_8', '9_12', '13_17') then
    raise exception 'invalid managed child profile' using errcode = '22023';
  end if;

  insert into public.managed_minors (circle_id, guardian_user_id, alias, age_band)
  values (p_circle_id, v_actor, btrim(p_alias), p_age_band)
  returning id into v_minor;
  return v_minor;
end;
$$;

revoke all on public.circles, public.circle_memberships,
  public.managed_minors from public, anon, authenticated;
grant select on public.circles, public.circle_memberships,
  public.managed_minors to authenticated;

revoke all on function public.is_active_circle_adult(uuid) from public, anon;
revoke all on function public.create_circle(text) from public, anon;
revoke all on function public.create_managed_minor(uuid, text, text) from public, anon;
grant execute on function public.is_active_circle_adult(uuid),
  public.create_circle(text),
  public.create_managed_minor(uuid, text, text) to authenticated;

alter table public.circles enable row level security;
alter table public.circle_memberships enable row level security;
alter table public.managed_minors enable row level security;

create policy circles_read_active_adult on public.circles
  for select to authenticated
  using (public.is_active_circle_adult(id));
create policy memberships_read_active_adult on public.circle_memberships
  for select to authenticated
  using (public.is_active_circle_adult(circle_id));
create policy managed_minors_read_guardian on public.managed_minors
  for select to authenticated
  using (
    guardian_user_id = (select auth.uid())
    and public.is_active_circle_adult(circle_id)
  );

-- No direct client INSERT, UPDATE or DELETE policies. Invitation, removal,
-- guardian transfer and adult-role changes require separately reviewed RPCs.
