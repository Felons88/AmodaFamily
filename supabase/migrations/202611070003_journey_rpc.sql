-- Household mutation RPCs. All use signed auth identity and fixed search path.

create table private.supported_allergens (
  allergen_key text primary key
);
insert into private.supported_allergens (allergen_key) values
  ('milk'), ('egg'), ('peanut'), ('tree_nut'), ('wheat'), ('soy'),
  ('fish'), ('shellfish'), ('sesame'), ('kiwi');
revoke all on private.supported_allergens from public, anon, authenticated;

create function public.set_circle_food_needs(
  p_circle_id uuid, p_allergen_keys text[], p_excluded_ingredient_ids uuid[]
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_keys text[];
begin
  if not public.is_active_circle_adult(p_circle_id) then
    raise exception 'active verified adult membership required' using errcode = '42501';
  end if;
  if p_allergen_keys is null or p_excluded_ingredient_ids is null
     or array_position(p_allergen_keys, null) is not null
     or array_position(p_excluded_ingredient_ids, null) is not null
     or cardinality(p_allergen_keys) > 30
     or cardinality(p_excluded_ingredient_ids) > 100 then
    raise exception 'invalid food needs' using errcode = '22023';
  end if;
  select coalesce(array_agg(distinct lower(btrim(k)) order by lower(btrim(k))), '{}')
    into v_keys from unnest(p_allergen_keys) as k;
  if exists (select 1 from unnest(v_keys) as k
             where not exists (select 1 from private.supported_allergens a
                               where a.allergen_key = k)) then
    raise exception 'unsupported allergen key' using errcode = '22023';
  end if;
  if exists (select 1 from unnest(p_excluded_ingredient_ids) as i
             where not exists (select 1 from public.ingredients x where x.id = i)) then
    raise exception 'unknown excluded ingredient' using errcode = '22023';
  end if;

  insert into public.circle_food_needs
    (circle_id, allergen_keys, updated_by)
  values (p_circle_id, v_keys, auth.uid())
  on conflict (circle_id) do update
    set allergen_keys = excluded.allergen_keys,
        updated_by = excluded.updated_by, updated_at = now();
  delete from public.circle_excluded_ingredients where circle_id = p_circle_id;
  insert into public.circle_excluded_ingredients (circle_id, ingredient_id)
  select p_circle_id, i from (select distinct unnest(p_excluded_ingredient_ids) as i) x;
end;
$$;

create function public.set_budget_cycle(
  p_circle_id uuid, p_cash_cents bigint, p_snap_cents bigint,
  p_deposit_day integer
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not public.is_active_circle_adult(p_circle_id) then
    raise exception 'active verified adult membership required' using errcode = '42501';
  end if;
  if (p_cash_cents is not null and p_cash_cents < 0)
     or (p_snap_cents is not null and p_snap_cents < 0)
     or (p_deposit_day is not null and p_deposit_day not between 1 and 28) then
    raise exception 'invalid budget cycle' using errcode = '22023';
  end if;
  insert into public.budget_cycles
    (circle_id, cash_cents, snap_cents, deposit_day, updated_by)
  values (p_circle_id, p_cash_cents, p_snap_cents, p_deposit_day, auth.uid())
  on conflict (circle_id) do update
    set cash_cents = excluded.cash_cents,
        snap_cents = excluded.snap_cents,
        deposit_day = excluded.deposit_day,
        updated_by = excluded.updated_by, updated_at = now();
end;
$$;

create function public.set_personalization(
  p_circle_id uuid, p_enabled boolean
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not public.is_active_circle_adult(p_circle_id) then
    raise exception 'active verified adult membership required' using errcode = '42501';
  end if;
  if p_enabled is null then
    raise exception 'enabled flag required' using errcode = '22023';
  end if;
  insert into public.circle_privacy_preferences
    (circle_id, personalization_opt_in, updated_by)
  values (p_circle_id, p_enabled, auth.uid())
  on conflict (circle_id) do update
    set personalization_opt_in = excluded.personalization_opt_in,
        updated_by = excluded.updated_by, updated_at = now();
end;
$$;

-- This function is inaccessible directly to API roles. It is called only
-- after adult authorization by the plan RPCs. Unknown composition, uncertain
-- cross-contact, unreviewed photos/recipes, and unchecked packaged ingredients
-- all fail closed. Empty ingredient lists are ineligible.
create function private.recipe_is_safe_for_circle(
  p_circle_id uuid, p_recipe_id uuid
) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.recipes r
    where r.id = p_recipe_id
      and r.review_status = 'approved' and r.license_status = 'verified'
      and exists (select 1 from public.recipe_ingredients ri
                  where ri.recipe_id = r.id)
      and not exists (
        select 1 from public.recipe_ingredients ri
        join public.ingredients i on i.id = ri.ingredient_id
        where ri.recipe_id = r.id
          and (
            i.composition_status <> 'verified'
            or i.cross_contact_status <> 'verified_clear'
            or (ri.is_packaged and not ri.brand_label_checked)
            or exists (
              select 1 from public.circle_excluded_ingredients ex
              where ex.circle_id = p_circle_id
                and ex.ingredient_id = i.id
            )
            or exists (
              select 1 from public.circle_food_needs fn
              where fn.circle_id = p_circle_id
                and fn.allergen_keys && i.allergen_keys
            )
          )
      )
  );
$$;
revoke all on function private.recipe_is_safe_for_circle(uuid, uuid)
  from public, anon, authenticated;

create function public.record_feedback(
  p_circle_id uuid, p_recipe_id uuid, p_value text, p_reason text,
  p_request_id uuid
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_existing public.feedback_events%rowtype;
begin
  if not public.is_active_circle_adult(p_circle_id) then
    raise exception 'active verified adult membership required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.circle_privacy_preferences p
                 where p.circle_id = p_circle_id and p.personalization_opt_in) then
    raise exception 'personalization consent required' using errcode = '42501';
  end if;
  if p_request_id is null or p_value not in ('liked', 'disliked')
     or (p_value = 'disliked' and p_reason is null)
     or (p_reason is not null and p_reason not in
       ('taste', 'time', 'cost', 'texture', 'ingredient', 'other')) then
    raise exception 'invalid feedback' using errcode = '22023';
  end if;
  if not exists (select 1 from public.recipes r where r.id = p_recipe_id
                 and r.review_status = 'approved' and r.license_status = 'verified') then
    raise exception 'recipe not available' using errcode = '22023';
  end if;
  select * into v_existing from public.feedback_events where id = p_request_id;
  if found then
    if v_existing.circle_id <> p_circle_id
       or v_existing.actor_user_id <> auth.uid()
       or v_existing.recipe_id <> p_recipe_id
       or v_existing.value <> p_value
       or v_existing.reason is distinct from p_reason then
      raise exception 'request ID reused with different feedback' using errcode = '23505';
    end if;
    return p_request_id;
  end if;
  insert into public.feedback_events
    (id, circle_id, actor_user_id, recipe_id, value, reason)
  values (p_request_id, p_circle_id, auth.uid(), p_recipe_id, p_value, p_reason);
  return p_request_id;
end;
$$;

create function public.delete_circle_learning(p_circle_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not public.is_active_circle_adult(p_circle_id) then
    raise exception 'active verified adult membership required' using errcode = '42501';
  end if;
  -- Any active adult can clear household learning; no hidden derived state exists
  -- in this MVP migration. Future derived caches must be deleted in this RPC.
  delete from public.feedback_events where circle_id = p_circle_id;
  perform public.set_personalization(p_circle_id, false);
end;
$$;

revoke all on function public.set_circle_food_needs(uuid, text[], uuid[]),
  public.set_budget_cycle(uuid, bigint, bigint, integer),
  public.set_personalization(uuid, boolean),
  public.record_feedback(uuid, uuid, text, text, uuid),
  public.delete_circle_learning(uuid) from public, anon;
grant execute on function public.set_circle_food_needs(uuid, text[], uuid[]),
  public.set_budget_cycle(uuid, bigint, bigint, integer),
  public.set_personalization(uuid, boolean),
  public.record_feedback(uuid, uuid, text, text, uuid),
  public.delete_circle_learning(uuid) to authenticated;
