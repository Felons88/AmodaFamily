-- Starter migration: require security engineer review and pgTAP tests before deployment.
create extension if not exists pgcrypto;
create table if not exists public.circles (
 id uuid primary key default gen_random_uuid(), name text not null,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.circle_members (
 id uuid primary key default gen_random_uuid(),
 circle_id uuid not null references public.circles(id) on delete cascade,
 auth_user_id uuid references auth.users(id) on delete cascade,
 managed_by_member_id uuid references public.circle_members(id),
 display_name text not null,
 member_kind text not null check (member_kind in ('adult','managed_child')),
 role text not null check (role in ('owner','admin','adult','child')),
 age_band text check (age_band in ('0_4','5_8','9_12','13_17','18_plus')),
 status text not null default 'active' check (status in ('active','invited','removed')),
 created_at timestamptz not null default now(),
 unique(circle_id, auth_user_id),
 check ((member_kind='managed_child' and auth_user_id is null and role='child') or
        (member_kind='adult' and auth_user_id is not null and role in ('owner','admin','adult')))
);
create index if not exists idx_member_user_circle on public.circle_members(auth_user_id, circle_id) where status='active';
create table if not exists public.ingredients (
 id uuid primary key default gen_random_uuid(), canonical_name text not null unique,
 composition_status text not null default 'unknown' check (composition_status in ('verified','unknown','disputed')),
 allergen_tags text[] not null default '{}', composition_source text, verified_at timestamptz
);
create table if not exists public.recipes (
 id uuid primary key default gen_random_uuid(), title text not null,
 version int not null default 1, status text not null default 'draft' check(status in ('draft','review','approved','rejected')),
 fingerprint text unique, description text, cook_minutes int check(cook_minutes>=0),
 servings numeric(7,2) check(servings>0), creator_circle_id uuid references public.circles(id),
 license_status text not null default 'unverified', created_at timestamptz not null default now()
);
create table if not exists public.recipe_ingredients (
 recipe_id uuid not null references public.recipes(id) on delete cascade,
 ingredient_id uuid not null references public.ingredients(id),
 amount numeric(12,3) not null check (amount>0),
 unit text not null, package_brand_verified boolean not null default false,
 primary key (recipe_id,ingredient_id,unit)
);
create table if not exists public.circle_allergies (
 circle_id uuid not null references public.circles(id) on delete cascade,
 member_id uuid not null references public.circle_members(id) on delete cascade,
 allergen_key text not null, severity text not null default 'unspecified',
 created_at timestamptz not null default now(),
 primary key (circle_id,member_id,allergen_key)
);
create table if not exists public.meal_plans (
 id uuid primary key default gen_random_uuid(), circle_id uuid not null references public.circles(id),
 week_start date not null, status text not null default 'draft' check(status in ('draft','approved','archived')),
 budget_estimate_cents bigint, currency char(3) not null default 'USD',
 approved_by uuid references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.plan_slots (
 id uuid primary key default gen_random_uuid(), plan_id uuid not null references public.meal_plans(id) on delete cascade,
 meal_day date not null, meal_kind text not null check(meal_kind in ('breakfast','lunch','dinner','snack')),
 recipe_id uuid not null references public.recipes(id), servings numeric(8,2) not null check(servings>0),
 unique(plan_id,meal_day,meal_kind)
);
create table if not exists public.vote_rounds (
 id uuid primary key default gen_random_uuid(), circle_id uuid not null references public.circles(id),
 created_by uuid not null references auth.users(id), expires_at timestamptz not null,
 status text not null default 'open' check(status in ('open','closed','canceled')),
 created_at timestamptz not null default now()
);
create table if not exists public.vote_options (
 round_id uuid not null references public.vote_rounds(id) on delete cascade,
 recipe_id uuid not null references public.recipes(id),
 primary key(round_id,recipe_id)
);
create table if not exists public.votes (
 round_id uuid not null references public.vote_rounds(id) on delete cascade,
 voter_member_id uuid not null references public.circle_members(id),
 recipe_id uuid not null references public.recipes(id),
 created_at timestamptz not null default now(), primary key(round_id,voter_member_id)
);
create table if not exists public.circle_entitlements (
 circle_id uuid primary key references public.circles(id) on delete cascade,
 plan text not null default 'free' check(plan in ('free','plus','family_pro')),
 status text not null default 'active', provider text, provider_ref text unique,
 expires_at timestamptz, updated_at timestamptz not null default now()
);
-- SECURITY: Postgres direct client writes are denied by default for catalog and sensitive writes;
-- transactional server RPCs verify all invariants. The following helper uses auth.uid().
create or replace function public.is_circle_member(p_circle uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.circle_members m where m.circle_id=p_circle
   and m.auth_user_id=(select auth.uid()) and m.status='active' and m.role in ('owner','admin','adult'));
$$;
revoke all on function public.is_circle_member(uuid) from public;
grant execute on function public.is_circle_member(uuid) to authenticated;
create or replace function public.is_circle_adult(p_circle uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.circle_members m where m.circle_id=p_circle
   and m.auth_user_id=(select auth.uid()) and m.status='active' and m.member_kind='adult');
$$;
revoke all on function public.is_circle_adult(uuid) from public;
grant execute on function public.is_circle_adult(uuid) to authenticated;
alter table public.circles enable row level security;
alter table public.circle_members enable row level security;
alter table public.circle_allergies enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.ingredients enable row level security;
alter table public.meal_plans enable row level security;
alter table public.plan_slots enable row level security;
alter table public.vote_rounds enable row level security;
alter table public.vote_options enable row level security;
alter table public.votes enable row level security;
alter table public.circle_entitlements enable row level security;
-- Must use privileged audited circle creation RPC to atomically create circle and owner membership.
-- This avoids circular 'owner must already be member' policy failure.
create policy circles_select_members on public.circles for select to authenticated
 using (public.is_circle_member(id));
create policy member_list_adults on public.circle_members for select to authenticated
 using (public.is_circle_adult(circle_id));
create policy allergy_read_adults on public.circle_allergies for select to authenticated
 using (public.is_circle_adult(circle_id));
create policy approved_recipe_select on public.recipes for select to authenticated
 using (status='approved' and license_status='verified' and creator_circle_id is null);
create policy approved_ingredient_select on public.ingredients for select to authenticated
 using (composition_status='verified');
create policy approved_recipe_ingredients_select on public.recipe_ingredients for select to authenticated
 using (exists(select 1 from public.recipes r where r.id=recipe_id
 and r.status='approved' and r.license_status='verified' and r.creator_circle_id is null));
create policy plan_read_members on public.meal_plans for select to authenticated
 using(public.is_circle_adult(circle_id));
create policy slot_read_members on public.plan_slots for select to authenticated
 using(exists(select 1 from public.meal_plans p where p.id=plan_id and public.is_circle_adult(p.circle_id)));
create policy vote_round_read_adults on public.vote_rounds for select to authenticated
 using(public.is_circle_adult(circle_id));
create policy vote_option_read_adults on public.vote_options for select to authenticated
 using(exists(select 1 from public.vote_rounds r where r.id=round_id and public.is_circle_adult(r.circle_id)));
create policy vote_read_adults on public.votes for select to authenticated
 using(exists(select 1 from public.vote_rounds r where r.id=round_id and public.is_circle_adult(r.circle_id)));
create policy entitlement_read_adults on public.circle_entitlements for select to authenticated
 using(public.is_circle_adult(circle_id));
-- No client-facing INSERT/UPDATE/DELETE policies: route writes through validated server RPCs.
-- Managed child actions are performed via authenticated adult-controlled sessions/API;
-- do not expose child privileges simply by passing child profile ID from client.
