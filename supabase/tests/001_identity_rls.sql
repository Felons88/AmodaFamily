-- FC-002 adversarial identity tests. Run against a disposable local Supabase DB:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/001_identity_rls.sql
-- The whole fixture is rolled back. Never run against production.
begin;

insert into auth.users (id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, created_at, updated_at)
values
  ('10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
   'fc-test-a@example.invalid', '', now(), '{"adult_verified": true}', now(), now()),
  ('10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
   'fc-test-b@example.invalid', '', now(), '{"adult_verified": true}', now(), now()),
  ('10000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated',
   'fc-test-c@example.invalid', '', now(), '{"adult_verified": true}', now(), now()),
  ('10000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated',
   'fc-test-invited@example.invalid', '', now(), '{}', now(), now());

insert into public.circles (id, name, created_by) values
  ('20000000-0000-4000-8000-000000000001', 'Circle A',
   '10000000-0000-4000-8000-000000000001'),
  ('20000000-0000-4000-8000-000000000002', 'Circle B',
   '10000000-0000-4000-8000-000000000002');
insert into public.circle_memberships (circle_id, user_id, role, status) values
  ('20000000-0000-4000-8000-000000000001',
   '10000000-0000-4000-8000-000000000001', 'owner', 'active'),
  ('20000000-0000-4000-8000-000000000002',
   '10000000-0000-4000-8000-000000000002', 'owner', 'active'),
  ('20000000-0000-4000-8000-000000000001',
   '10000000-0000-4000-8000-000000000003', 'adult', 'active'),
  ('20000000-0000-4000-8000-000000000001',
   '10000000-0000-4000-8000-000000000004', 'adult', 'invited');
insert into public.managed_minors (id, circle_id, guardian_user_id, alias, age_band)
values ('30000000-0000-4000-8000-000000000001',
        '20000000-0000-4000-8000-000000000001',
        '10000000-0000-4000-8000-000000000001', 'Child A', '5_8');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000001', true);
do $$
begin
  if (select count(*) from public.circles) <> 1 then
    raise exception 'A must see only circle A';
  end if;
  if (select count(*) from public.circle_memberships) <> 3 then
    raise exception 'A must see only circle A memberships';
  end if;
  if (select count(*) from public.managed_minors) <> 1 then
    raise exception 'A must see managed child';
  end if;
  if public.is_active_circle_adult('20000000-0000-4000-8000-000000000002') then
    raise exception 'A must not be authorized in B';
  end if;
end $$;

-- Direct client writes fail even when a caller supplies their own circle ID.
do $$
begin
  begin
    insert into public.circles (name, created_by)
    values ('Forged', '10000000-0000-4000-8000-000000000001');
    raise exception 'direct circle insert succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.circle_memberships set role = 'owner'
    where user_id = '10000000-0000-4000-8000-000000000003';
    raise exception 'direct role change succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.managed_minors;
    raise exception 'direct child deletion succeeded';
  exception when insufficient_privilege then null;
  end;
end $$;

do $$
declare v_circle uuid; v_minor uuid;
begin
  v_circle := public.create_circle(' New circle ');
  if not exists (select 1 from public.circle_memberships
                 where circle_id = v_circle and user_id = auth.uid()
                   and role = 'owner' and status = 'active') then
    raise exception 'create_circle did not atomically create owner';
  end if;
  v_minor := public.create_managed_minor(v_circle, ' Junior ', '9_12');
  if not exists (select 1 from public.managed_minors
                 where id = v_minor and alias = 'Junior'
                   and guardian_user_id = auth.uid()) then
    raise exception 'create_managed_minor did not bind guardian';
  end if;
end $$;
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000002', true);
do $$
begin
  if (select count(*) from public.circles) <> 1 then
    raise exception 'B must see only circle B';
  end if;
  if (select count(*) from public.managed_minors) <> 0 then
    raise exception 'B read cross-circle child';
  end if;
  begin
    perform public.create_managed_minor(
      '20000000-0000-4000-8000-000000000001', 'Forged', '5_8');
    raise exception 'B created child in circle A';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000003', true);
do $$
begin
  if (select count(*) from public.circles) <> 1 then
    raise exception 'C should see own circle';
  end if;
  if (select count(*) from public.managed_minors) <> 0 then
    raise exception 'non-guardian adult read child';
  end if;
end $$;
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000004', true);
do $$
begin
  if (select count(*) from public.circles) <> 0 then
    raise exception 'invited member read circle';
  end if;
  if public.is_active_circle_adult('20000000-0000-4000-8000-000000000001') then
    raise exception 'invited member authorized';
  end if;
  begin
    perform public.create_circle('Forged adult');
    raise exception 'unverified account created circle';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

set local role anon;
select set_config('request.jwt.claim.sub', '', true);
do $$
begin
  begin
    perform public.create_circle('Anonymous');
    raise exception 'anon called create_circle';
  exception when insufficient_privilege then null;
  end;
  begin
    perform 1 from public.circles;
    raise exception 'anon queried circles';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

rollback;
