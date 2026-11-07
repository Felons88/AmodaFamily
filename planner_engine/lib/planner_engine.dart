import 'package:family_circle_safety_engine/safety_engine.dart';

enum FoodUnit { grams, milliliters, pieces }

enum BenefitEligibility { eligible, ineligible, unknown }

enum PlanCode {
  readyForAdultReview,
  noSafeCandidates,
  priceUnknown,
  planInfeasible
}

extension PlanCodeWire on PlanCode {
  String get wireCode => switch (this) {
        PlanCode.readyForAdultReview => 'READY_FOR_ADULT_REVIEW',
        PlanCode.noSafeCandidates => 'NO_SAFE_CANDIDATES',
        PlanCode.priceUnknown => 'PRICE_UNKNOWN',
        PlanCode.planInfeasible => 'PLAN_INFEASIBLE',
      };
}

class FoodQuantity {
  const FoodQuantity(this.amount, this.unit);

  final int amount;
  final FoodUnit unit;
}

class IngredientNeed {
  const IngredientNeed(this.ingredientId, this.quantity);

  final String ingredientId;
  final FoodQuantity quantity;
}

class PantryStock {
  const PantryStock(this.ingredientId, this.quantity,
      {required this.confirmed});

  final String ingredientId;
  final FoodQuantity quantity;
  final bool confirmed;
}

class PriceOffer {
  const PriceOffer({
    required this.ingredientId,
    required this.packSize,
    required this.estimatedCents,
    required this.source,
    required this.observedAt,
    required this.region,
    required this.confidence,
    this.currency = 'USD',
    this.benefitEligibility = BenefitEligibility.unknown,
  });

  final String ingredientId;
  final FoodQuantity packSize;
  final int estimatedCents;
  final String source;
  final DateTime observedAt;
  final String region;
  final double confidence;
  final String currency;
  final BenefitEligibility benefitEligibility;

  bool isUsable(DateTime asOf) =>
      packSize.amount > 0 &&
      estimatedCents >= 0 &&
      source.trim().isNotEmpty &&
      region.trim().isNotEmpty &&
      currency == 'USD' &&
      confidence >= 0 &&
      confidence <= 1 &&
      !observedAt.isAfter(asOf);
}

class BasketLine {
  const BasketLine({
    required this.ingredientId,
    required this.required,
    required this.pantryDeducted,
    required this.packs,
    required this.offer,
    required this.estimatedCents,
  });

  final String ingredientId;
  final FoodQuantity required;
  final FoodQuantity pantryDeducted;
  final int packs;
  final PriceOffer offer;
  final int estimatedCents;
}

class BasketEstimate {
  const BasketEstimate({
    required this.lines,
    required this.unknownPriceIngredientIds,
    required this.totalEstimateCents,
    required this.eligibleBenefitEstimateCents,
    required this.unverifiedBenefitEstimateCents,
  });

  final List<BasketLine> lines;
  final List<String> unknownPriceIngredientIds;
  final int totalEstimateCents;

  /// Only explicitly verified eligible items count toward this subtotal.
  final int eligibleBenefitEstimateCents;
  final int unverifiedBenefitEstimateCents;

  bool get hasCompleteEstimate => unknownPriceIngredientIds.isEmpty;
}

class PlannedRecipe {
  const PlannedRecipe({
    required this.id,
    required this.safetyCandidate,
    required this.ingredientNeeds,
    required this.servings,
    required this.approvedCatalogVersion,
  });

  final String id;
  final RecipeCandidate safetyCandidate;
  final List<IngredientNeed> ingredientNeeds;
  final int servings;
  final bool approvedCatalogVersion;
}

class MealSlot {
  const MealSlot(this.dayIndex, this.slotIndex, this.recipeId);

  final int dayIndex;
  final int slotIndex;
  final String recipeId;
}

class PlanResult {
  const PlanResult(
    this.code, {
    this.slots = const [],
    this.basket,
    this.rejectedRecipeCodes = const {},
  });

  final PlanCode code;
  final List<MealSlot> slots;
  final BasketEstimate? basket;
  final Map<String, EligibilityCode> rejectedRecipeCodes;
}

/// Sums needs in canonical units only. An ambiguous conversion leaves the
/// ingredient unpriced; it is never silently inferred from a different unit.
BasketEstimate estimateBasket({
  required List<IngredientNeed> needs,
  required List<PantryStock> pantry,
  required List<PriceOffer> offers,
  required DateTime asOf,
}) {
  final required = <String, FoodQuantity>{};
  final unknown = <String>{};
  for (final need in needs) {
    if (need.ingredientId.isEmpty || need.quantity.amount <= 0) {
      unknown.add(need.ingredientId);
      continue;
    }
    final previous = required[need.ingredientId];
    if (previous != null && previous.unit != need.quantity.unit) {
      unknown.add(need.ingredientId);
      continue;
    }
    required[need.ingredientId] = FoodQuantity(
      (previous?.amount ?? 0) + need.quantity.amount,
      need.quantity.unit,
    );
  }

  final lines = <BasketLine>[];
  var total = 0;
  var benefitEligible = 0;
  var benefitUnknown = 0;
  for (final id in required.keys.toList()..sort()) {
    if (unknown.contains(id)) continue;
    final demand = required[id]!;
    final confirmedPantry = pantry
        .where((stock) =>
            stock.confirmed &&
            stock.ingredientId == id &&
            stock.quantity.unit == demand.unit &&
            stock.quantity.amount > 0)
        .fold<int>(0, (sum, stock) => sum + stock.quantity.amount);
    final deduction =
        confirmedPantry < demand.amount ? confirmedPantry : demand.amount;
    final net = demand.amount - deduction;
    if (net == 0) continue;

    final matching = offers.where((offer) =>
        offer.ingredientId == id &&
        offer.packSize.unit == demand.unit &&
        offer.isUsable(asOf));
    if (matching.isEmpty) {
      unknown.add(id);
      continue;
    }
    PriceOffer? chosen;
    var chosenPacks = 0;
    var chosenCost = 0;
    for (final offer in matching) {
      final packs = (net + offer.packSize.amount - 1) ~/ offer.packSize.amount;
      final cost = packs * offer.estimatedCents;
      if (chosen == null ||
          cost < chosenCost ||
          (cost == chosenCost &&
              offer.packSize.amount < chosen.packSize.amount)) {
        chosen = offer;
        chosenPacks = packs;
        chosenCost = cost;
      }
    }
    lines.add(BasketLine(
      ingredientId: id,
      required: demand,
      pantryDeducted: FoodQuantity(deduction, demand.unit),
      packs: chosenPacks,
      offer: chosen!,
      estimatedCents: chosenCost,
    ));
    total += chosenCost;
    switch (chosen.benefitEligibility) {
      case BenefitEligibility.eligible:
        benefitEligible += chosenCost;
      case BenefitEligibility.unknown:
        benefitUnknown += chosenCost;
      case BenefitEligibility.ineligible:
        break;
    }
  }
  return BasketEstimate(
    lines: lines,
    unknownPriceIngredientIds: (unknown.toList()..sort()),
    totalEstimateCents: total,
    eligibleBenefitEstimateCents: benefitEligible,
    unverifiedBenefitEstimateCents: benefitUnknown,
  );
}

/// Deterministic, bounded MVP planner. Every slot is chosen from catalog
/// approved recipes that pass the independent hard-allergen filter. A complete
/// dated price estimate and hard budget fit are required before returning a
/// reviewable plan; no plan is automatically approved or purchased.
PlanResult buildSevenDayPlan({
  required List<PlannedRecipe> recipes,
  required List<EaterRestrictions> eaters,
  required Map<String, IngredientFact> ingredientFacts,
  required List<PantryStock> pantry,
  required List<PriceOffer> offers,
  required int budgetCents,
  required int maxPrepMinutes,
  required DateTime asOf,
  int slotsPerDay = 3,
  int maxUsesPerRecipe = 7,
}) {
  if (budgetCents < 0 ||
      slotsPerDay <= 0 ||
      maxUsesPerRecipe <= 0 ||
      eaters.isEmpty) {
    return const PlanResult(PlanCode.planInfeasible);
  }
  final rejected = <String, EligibilityCode>{};
  final safe = <PlannedRecipe>[];
  for (final recipe in recipes) {
    final result = evaluateRecipe(
      recipe: recipe.safetyCandidate,
      eaters: eaters,
      facts: ingredientFacts,
      maxPrepMinutes: maxPrepMinutes,
    );
    if (!recipe.approvedCatalogVersion ||
        recipe.id.isEmpty ||
        recipe.servings < eaters.length ||
        recipe.ingredientNeeds.isEmpty ||
        !result.isEligible) {
      rejected[recipe.id] =
          result.isEligible ? EligibilityCode.allergenUncertain : result.code;
      continue;
    }
    final componentIds = recipe.safetyCandidate.ingredients
        .map((ingredient) => ingredient.ingredientId)
        .toSet();
    if (recipe.ingredientNeeds.any((need) =>
        !componentIds.contains(need.ingredientId) ||
        need.quantity.amount <= 0)) {
      rejected[recipe.id] = EligibilityCode.allergenUncertain;
      continue;
    }
    safe.add(recipe);
  }
  if (safe.isEmpty) {
    return PlanResult(PlanCode.noSafeCandidates, rejectedRecipeCodes: rejected);
  }
  safe.sort((a, b) => a.id.compareTo(b.id));
  final useCounts = <String, int>{};
  final slots = <MealSlot>[];
  final needs = <IngredientNeed>[];
  BasketEstimate? basket;
  var sawUnknownPrice = false;
  for (var day = 0; day < 7; day++) {
    for (var slot = 0; slot < slotsPerDay; slot++) {
      final options = [...safe]..sort((a, b) {
          final byUses = (useCounts[a.id] ?? 0).compareTo(useCounts[b.id] ?? 0);
          return byUses != 0 ? byUses : a.id.compareTo(b.id);
        });
      PlannedRecipe? chosen;
      BasketEstimate? chosenBasket;
      for (final option in options) {
        if ((useCounts[option.id] ?? 0) >= maxUsesPerRecipe) continue;
        final candidate = estimateBasket(
          needs: [...needs, ...option.ingredientNeeds],
          pantry: pantry,
          offers: offers,
          asOf: asOf,
        );
        if (!candidate.hasCompleteEstimate) {
          sawUnknownPrice = true;
          continue;
        }
        if (candidate.totalEstimateCents > budgetCents) continue;
        chosen = option;
        chosenBasket = candidate;
        break;
      }
      if (chosen == null) {
        return PlanResult(
          sawUnknownPrice ? PlanCode.priceUnknown : PlanCode.planInfeasible,
          rejectedRecipeCodes: rejected,
        );
      }
      slots.add(MealSlot(day, slot, chosen.id));
      needs.addAll(chosen.ingredientNeeds);
      useCounts[chosen.id] = (useCounts[chosen.id] ?? 0) + 1;
      basket = chosenBasket;
    }
  }
  return PlanResult(PlanCode.readyForAdultReview,
      slots: slots, basket: basket, rejectedRecipeCodes: rejected);
}
