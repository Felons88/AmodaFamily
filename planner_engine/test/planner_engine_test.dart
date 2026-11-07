import 'dart:io';

import 'package:family_circle_planner_engine/planner_engine.dart';
import 'package:family_circle_safety_engine/safety_engine.dart';

void check(bool condition, String description) {
  if (!condition) throw StateError(description);
}

void main() {
  final now = DateTime.utc(2026, 11, 7);
  const kiwiAllergy = EaterRestrictions(hardAllergens: {'kiwi'});
  const facts = <String, IngredientFact>{
    'kiwi': IngredientFact(
        id: 'kiwi', compositionVerified: true, allergens: {'kiwi'}),
    'banana':
        IngredientFact(id: 'banana', compositionVerified: true, allergens: {}),
    'unknown_fruit': IngredientFact(
        id: 'unknown_fruit', compositionVerified: false, allergens: {}),
  };
  PlannedRecipe recipe(String id, String ingredientId,
          {bool approved = true}) =>
      PlannedRecipe(
        id: id,
        safetyCandidate: RecipeCandidate(
          ingredients: [RecipeIngredient(ingredientId: ingredientId)],
          timeMinutes: 10,
        ),
        ingredientNeeds: [
          IngredientNeed(ingredientId, const FoodQuantity(1, FoodUnit.pieces))
        ],
        servings: 1,
        approvedCatalogVersion: approved,
      );
  PriceOffer offer(String id, int cents,
          {BenefitEligibility benefit = BenefitEligibility.unknown,
          DateTime? observedAt}) =>
      PriceOffer(
        ingredientId: id,
        packSize: const FoodQuantity(1, FoodUnit.pieces),
        estimatedCents: cents,
        source: 'synthetic-fixture',
        observedAt: observedAt ?? now.subtract(const Duration(days: 1)),
        region: 'US-test',
        confidence: 0.5,
        benefitEligibility: benefit,
      );

  PlanResult plan({
    required List<PlannedRecipe> recipes,
    required List<PriceOffer> offers,
    int budget = 1000,
  }) =>
      buildSevenDayPlan(
        recipes: recipes,
        eaters: const [kiwiAllergy],
        ingredientFacts: facts,
        pantry: const [],
        offers: offers,
        budgetCents: budget,
        maxPrepMinutes: 30,
        asOf: now,
        slotsPerDay: 1,
      );

  final safePlan = plan(
    recipes: [
      recipe('kiwi-smoothie', 'kiwi'),
      recipe('unknown-mix', 'unknown_fruit'),
      recipe('banana-snack', 'banana'),
    ],
    offers: [offer('banana', 50)],
    budget: 350,
  );
  check(safePlan.code == PlanCode.readyForAdultReview, 'safe plan status');
  check(safePlan.slots.length == 7, 'seven day plan');
  check(safePlan.slots.every((slot) => slot.recipeId == 'banana-snack'),
      'unsafe recipe never selected');
  check(safePlan.basket?.totalEstimateCents == 350, 'dated basket total');
  check(
      safePlan.rejectedRecipeCodes['kiwi-smoothie'] ==
          EligibilityCode.allergenBlocked,
      'kiwi blocked');
  check(
      safePlan.rejectedRecipeCodes['unknown-mix'] ==
          EligibilityCode.allergenUncertain,
      'unknown mix blocked');
  check(
      plan(recipes: [recipe('kiwi', 'kiwi')], offers: []).code ==
          PlanCode.noSafeCandidates,
      'zero safe candidates');
  check(
      plan(
                  recipes: [recipe('banana', 'banana')],
                  offers: [offer('banana', 50)],
                  budget: 349)
              .code ==
          PlanCode.planInfeasible,
      'hard budget infeasible');
  check(
      plan(recipes: [recipe('banana', 'banana')], offers: []).code ==
          PlanCode.priceUnknown,
      'unknown price does not become a fabricated estimate');
  check(
      plan(
              recipes: [recipe('banana', 'banana', approved: false)],
              offers: [offer('banana', 50)]).code ==
          PlanCode.noSafeCandidates,
      'unapproved catalog recipe excluded');
  check(
      plan(recipes: [
            recipe('banana', 'banana')
          ], offers: [
            offer('banana', 50, observedAt: now.add(const Duration(days: 1)))
          ]).code ==
          PlanCode.priceUnknown,
      'future price observation rejected');

  // The documented pantry-stock fixture: 2 gallons needed, 1 on hand.
  const gallonMl = 3785;
  final milkBasket = estimateBasket(
    needs: const [
      IngredientNeed('milk', FoodQuantity(2 * gallonMl, FoodUnit.milliliters))
    ],
    pantry: const [
      PantryStock('milk', FoodQuantity(gallonMl, FoodUnit.milliliters),
          confirmed: true)
    ],
    offers: [
      PriceOffer(
        ingredientId: 'milk',
        packSize: const FoodQuantity(gallonMl, FoodUnit.milliliters),
        estimatedCents: 400,
        source: 'synthetic-fixture',
        observedAt: now,
        region: 'US-test',
        confidence: 0.5,
      )
    ],
    asOf: now,
  );
  check(milkBasket.lines.single.packs == 1, 'one gallon purchase');
  check(milkBasket.lines.single.pantryDeducted.amount == gallonMl,
      'confirmed stock deducted');
  check(milkBasket.totalEstimateCents == 400, 'one pack estimated cost');
  check(milkBasket.eligibleBenefitEstimateCents == 0,
      'unknown SNAP eligibility not counted');
  check(milkBasket.unverifiedBenefitEstimateCents == 400,
      'unknown SNAP subtotal flagged');

  final unconfirmedBasket = estimateBasket(
    needs: const [
      IngredientNeed('milk', FoodQuantity(2 * gallonMl, FoodUnit.milliliters))
    ],
    pantry: const [
      PantryStock('milk', FoodQuantity(gallonMl, FoodUnit.milliliters),
          confirmed: false)
    ],
    offers: [milkBasket.lines.single.offer],
    asOf: now,
  );
  check(unconfirmedBasket.lines.single.packs == 2,
      'unconfirmed pantry stock not deducted');
  final mixedUnits = estimateBasket(
    needs: const [
      IngredientNeed('milk', FoodQuantity(100, FoodUnit.milliliters)),
      IngredientNeed('milk', FoodQuantity(100, FoodUnit.grams)),
    ],
    pantry: const [],
    offers: [milkBasket.lines.single.offer],
    asOf: now,
  );
  check(mixedUnits.unknownPriceIngredientIds.contains('milk'),
      'ambiguous unit conversion not invented');
  check(PlanCode.planInfeasible.wireCode == 'PLAN_INFEASIBLE',
      'typed API error code');
  stdout.writeln('Planner safety, budget, and basket cases passed');
}
