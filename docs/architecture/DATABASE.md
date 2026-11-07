# Database contracts (Postgres/Supabase)

## Domain entities
- `profiles(id uuid auth.users pk, display_name nullable, age_band enum adult|minor, locale, created_at)` — avoid birth date unless legally necessary.
- `circles(id uuid, owner_id uuid, plan_tier, created_at)`; `memberships(circle_id, user_id, role enum owner|adult|minor, status enum active|invited, invited_by)`; unique active membership rules defined per allowed multiple-circle policy; children may be parent-managed profile rows without Auth credentials.
- `managed_minors(id uuid, circle_id, guardian_member_id, alias, age_band, avatar_ref)` — no direct email/credentials.
- `member_food_profiles(id, circle_id, member_ref, allergies jsonb, dietary_restrictions jsonb, dislikes jsonb, likes jsonb, consent_flags jsonb)` — restrict child record access to guardians.
- `budgets(circle_id, cycle_start_day, snap_amount_estimate, cash_amount_estimate, current_manual_snap_balance nullable, currency)`; `shopping_schedules(circle_id, cadence, next_date, preferred_stores jsonb)`.
- `ingredients(id, canonical_name, units, allergens jsonb, source_provenance, verification_status)`; `recipes(id, canonical_key, slug, title, visibility, version, review_status, provenance, license, image_status, created_at)`; `recipe_ingredients(recipe_id, ingredient_id, qty, unit, optional, substitution_rules)`; `recipe_steps(recipe_id, step_order, text, safety_notes)`; `recipe_images(recipe_id, storage_path, license_info, generated_label, confidence, reviewer_id)`.
- `meal_plans(id, circle_id, week_start, status, revision)`; `planned_meals(id, plan_id, date, meal_slot, recipe_id, servings, chosen_by)`.
- `pantry_items(id, circle_id, ingredient_id, qty, unit, expires_on, confidence, revision)`; `beverage_preferences(id, circle_id, member_ref, ingredient_id, qty_per_week, unit)`; `shopping_trips(id, circle_id, planned_date, status, budget_estimate, actual_spend nullable)`; `shopping_items(id, trip_id, ingredient_id, qty, unit, estimated_price, pricing_source, purchased)`.
- `votes(id, circle_id, round_id, member_ref, recipe_id, value, created_at)`; `vote_rounds(id, circle_id, closes_at, status, created_by)`; `game_progress(circle_id, member_ref, game_id, points, progress)`.
- `interaction_events(id, circle_id, actor_ref, event_type, object_type, object_id, reason_code nullable, created_at, policy_version)`; `preference_signals(circle_id, member_ref, feature, confidence, score, source, updated_at)`; `recommendation_explanations(id, circle_id, candidate_recipes, feature_contributions, policy_version)`.
- `subscriptions(circle_id, billing_provider, customer_ref, active_entitlement, renewal_at, provider_event_id)`; `notification_preferences(member_ref, opt_in, quiet_start, quiet_end, category_flags)`; `audit_log(actor_id, circle_id, action, object_type, timestamp, outcome)`.

## Integrity / access
Use `circle_id` on every private table, composite FKs where relevant, unique vote per member per round, constraints for nonnegative quantities/prices, restricted enum states, no raw bank/EBT credentials. Enforce RLS with `auth.uid()` and SECURITY DEFINER functions only after reviewed auth checks and fixed search_path. Separate global read-only approved recipe views from internal draft/review tables. Prevent arbitrary clients from updating `subscriptions`, recipe-review states or others' profiles. Cascade deletion deliberately with GDPR/US privacy and record-retention requirements.

## Migration sequence
001 identity + circles; 002 preferences + allergies; 003 recipes + ingredients; 004 plans + budgets; 005 pantry + shopping + beverages; 006 votes + games; 007 events + recommendation cache; 008 billing + notifications + audit; 009 indices and server functions. Each migration has a rollback plan and tests.
