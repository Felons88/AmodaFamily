-- FC-003/004/007 first adult journey. No catalog data is bundled: a plan
-- cannot be generated until reviewed recipes, ingredients and dated prices exist.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.circle_food_needs (
  circle_id uuid primary key references public.circles(id) on delete cascade,
  allergen_keys text[] not null default '{}',
  updated_by uuid not null references auth.users(id),
  updated_at timestamptz not null default now(),
  check (array_position(allergen_keys, null) is null)
);
create table public.circle_excluded_ingredients (
  circle_id uuid not null references public.circles(id) on delete cascade,
  ingredient_id uuid not null,
  primary key (circle_id, ingredient_id)
);

create table public.budget_cycles (
  circle_id uuid primary key references public.circles(id) on delete cascade,
  cash_cents bigint check (cash_cents is null or cash_cents >= 0),
  snap_cents bigint check (snap_cents is null or snap_cents >= 0),
  deposit_day smallint check (deposit_day between 1 and 28),
  currency char(3) not null default 'USD' check (currency = 'USD'),
  source text not null default 'manual' check (source = 'manual'),
  updated_by uuid not null references auth.users(id),
  updated_at timestamptz not null default now()
);

create table public.ingredients (
  id uuid primary key default gen_random_uuid(),
  canonical_name text not null unique,
  composition_status text not null default 'unknown'
    check (composition_status in ('unknown', 'verified', 'disputed')),
  allergen_keys text[] not null default '{}',
  cross_contact_status text not null default 'unknown'
    check (cross_contact_status in ('unknown', 'verified_clear', 'known_risk')),
  source_provenance text,
  verified_at timestamptz,
  check (array_position(allergen_keys, null) is null),
  check (composition_status <> 'verified' or
         (source_provenance is not null and verified_at is not null))
);
alter table public.circle_excluded_ingredients
  add constraint circle_excluded_ingredient_fk
  foreign key (ingredient_id) references public.ingredients(id);

create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(trim(title)) between 1 and 160),
  servings smallint not null check (servings between 1 and 24),
  prep_minutes smallint not null check (prep_minutes between 0 and 480),
  review_status text not null default 'draft'
    check (review_status in ('draft', 'review', 'approved', 'rejected')),
  license_status text not null default 'unverified'
    check (license_status in ('unverified', 'verified')),
  image_status text not null default 'placeholder'
    check (image_status in ('placeholder', 'verified')),
  source_provenance text,
  created_at timestamptz not null default now(),
  check (review_status <> 'approved' or source_provenance is not null)
);
create table public.recipe_ingredients (
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id),
  amount numeric(12,3) not null check (amount > 0),
  unit text not null check (unit in ('g', 'ml', 'piece')),
  is_packaged boolean not null default false,
  brand_label_checked boolean not null default false,
  primary key (recipe_id, ingredient_id, unit)
);

create table public.ingredient_price_estimates (
  id uuid primary key default gen_random_uuid(),
  ingredient_id uuid not null references public.ingredients(id),
  pack_quantity numeric(12,3) not null check (pack_quantity > 0),
  unit text not null check (unit in ('g', 'ml', 'piece')),
  pack_price_cents bigint not null check (pack_price_cents >= 0),
  currency char(3) not null default 'USD' check (currency = 'USD'),
  source text not null check (length(trim(source)) > 0),
  region text not null check (length(trim(region)) > 0),
  observed_at timestamptz not null,
  confidence text not null check (confidence in ('low', 'medium', 'high')),
  snap_eligibility text not null default 'unverified'
    check (snap_eligibility in ('unverified', 'verified_yes', 'verified_no')),
  created_at timestamptz not null default now()
);
create index ingredient_price_recent on public.ingredient_price_estimates
  (ingredient_id, unit, observed_at desc);

create table public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles(id) on delete cascade,
  week_start date not null,
  status text not null default 'draft'
    check (status in ('draft', 'approved', 'archived')),
  revision integer not null default 1 check (revision > 0),
  estimated_total_cents bigint not null check (estimated_total_cents >= 0),
  currency char(3) not null default 'USD' check (currency = 'USD'),
  estimate_source text not null,
  estimate_observed_at timestamptz not null,
  estimate_confidence text not null
    check (estimate_confidence in ('low', 'medium', 'high')),
  budget_status text not null
    check (budget_status in ('not_set', 'within_cash', 'snap_unverified')),
  created_by uuid not null references auth.users(id),
  approved_by uuid references auth.users(id),
  approved_at timestamptz,
  created_at timestamptz not null default now()
);
create index meal_plans_circle_week on public.meal_plans(circle_id, week_start);
create table public.plan_slots (
  plan_id uuid not null references public.meal_plans(id) on delete cascade,
  meal_day date not null,
  meal_slot text not null default 'dinner' check (meal_slot = 'dinner'),
  recipe_id uuid not null references public.recipes(id),
  servings smallint not null check (servings between 1 and 24),
  primary key (plan_id, meal_day, meal_slot)
);
create table public.plan_grocery_items (
  plan_id uuid not null references public.meal_plans(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id),
  unit text not null check (unit in ('g', 'ml', 'piece')),
  required_quantity numeric(12,3) not null check (required_quantity > 0),
  pack_quantity numeric(12,3) not null check (pack_quantity > 0),
  pack_count integer not null check (pack_count > 0),
  estimated_cents bigint not null check (estimated_cents >= 0),
  currency char(3) not null default 'USD' check (currency = 'USD'),
  pricing_source text not null,
  price_observed_at timestamptz not null,
  region text not null,
  confidence text not null check (confidence in ('low', 'medium', 'high')),
  snap_eligibility text not null
    check (snap_eligibility in ('unverified', 'verified_yes', 'verified_no')),
  primary key (plan_id, ingredient_id, unit)
);

create table public.circle_privacy_preferences (
  circle_id uuid primary key references public.circles(id) on delete cascade,
  personalization_opt_in boolean not null default false,
  updated_by uuid not null references auth.users(id),
  updated_at timestamptz not null default now()
);
create table public.feedback_events (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles(id) on delete cascade,
  actor_user_id uuid not null references auth.users(id),
  recipe_id uuid not null references public.recipes(id),
  value text not null check (value in ('liked', 'disliked')),
  reason text check (reason in ('taste', 'time', 'cost', 'texture', 'ingredient', 'other')),
  created_at timestamptz not null default now(),
  check (value <> 'disliked' or reason is not null)
);
create index feedback_circle_actor on public.feedback_events(circle_id, actor_user_id);

revoke all on public.circle_food_needs, public.circle_excluded_ingredients,
  public.budget_cycles, public.ingredients, public.recipes,
  public.recipe_ingredients, public.ingredient_price_estimates,
  public.meal_plans, public.plan_slots, public.plan_grocery_items,
  public.circle_privacy_preferences,
  public.feedback_events from public, anon, authenticated;
grant select on public.circle_food_needs, public.circle_excluded_ingredients,
  public.budget_cycles, public.ingredients, public.recipes,
  public.recipe_ingredients, public.ingredient_price_estimates,
  public.meal_plans, public.plan_slots, public.plan_grocery_items,
  public.circle_privacy_preferences,
  public.feedback_events to authenticated;

alter table public.circle_food_needs enable row level security;
alter table public.circle_excluded_ingredients enable row level security;
alter table public.budget_cycles enable row level security;
alter table public.ingredients enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.ingredient_price_estimates enable row level security;
alter table public.meal_plans enable row level security;
alter table public.plan_slots enable row level security;
alter table public.plan_grocery_items enable row level security;
alter table public.circle_privacy_preferences enable row level security;
alter table public.feedback_events enable row level security;

create policy food_needs_read_adult on public.circle_food_needs
  for select to authenticated using (public.is_active_circle_adult(circle_id));
create policy excluded_read_adult on public.circle_excluded_ingredients
  for select to authenticated using (public.is_active_circle_adult(circle_id));
create policy budgets_read_adult on public.budget_cycles
  for select to authenticated using (public.is_active_circle_adult(circle_id));
create policy ingredient_read_verified on public.ingredients
  for select to authenticated using (composition_status = 'verified');
create policy recipe_read_approved on public.recipes
  for select to authenticated using
    (review_status = 'approved' and license_status = 'verified');
create policy recipe_lines_read_approved on public.recipe_ingredients
  for select to authenticated using (
    exists (select 1 from public.recipes r where r.id = recipe_id
      and r.review_status = 'approved' and r.license_status = 'verified')
  );
-- Retailer estimates may be shown only in adult contexts; API must label them.
create policy prices_read_adult on public.ingredient_price_estimates
  for select to authenticated using (
    exists (select 1 from public.circle_memberships m
      where m.user_id = (select auth.uid()) and m.status = 'active'
        and public.is_active_circle_adult(m.circle_id))
  );
create policy plans_read_adult on public.meal_plans
  for select to authenticated using (public.is_active_circle_adult(circle_id));
create policy slots_read_adult on public.plan_slots
  for select to authenticated using (
    exists (select 1 from public.meal_plans p where p.id = plan_id
      and public.is_active_circle_adult(p.circle_id))
  );
create policy grocery_read_adult on public.plan_grocery_items
  for select to authenticated using (
    exists (select 1 from public.meal_plans p where p.id = plan_id
      and public.is_active_circle_adult(p.circle_id))
  );
create policy privacy_read_adult on public.circle_privacy_preferences
  for select to authenticated using (public.is_active_circle_adult(circle_id));
create policy feedback_read_own on public.feedback_events
  for select to authenticated using
    (actor_user_id = (select auth.uid()) and
     public.is_active_circle_adult(circle_id));

-- No direct client mutations. Catalog review and price ingestion remain trusted
-- server operations, separate from household user RPCs below.
