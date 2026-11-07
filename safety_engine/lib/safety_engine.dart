/// Deterministic eligibility checks. An eligible result is permission to consider
/// a recipe in a meal plan, never a medical or cross-contact safety guarantee.
library;

enum EligibilityCode {
  eligible,
  allergenBlocked,
  allergenUncertain,
  packagedFoodUnverified,
  timeConstraint,
}

extension EligibilityCodeWire on EligibilityCode {
  String get wireCode => switch (this) {
        EligibilityCode.eligible => 'ELIGIBLE',
        EligibilityCode.allergenBlocked => 'ALLERGEN_BLOCKED',
        EligibilityCode.allergenUncertain => 'ALLERGEN_UNCERTAIN',
        EligibilityCode.packagedFoodUnverified => 'PACKAGED_FOOD_UNVERIFIED',
        EligibilityCode.timeConstraint => 'TIME_CONSTRAINT',
      };
}

Set<String> _normalized(Set<String> values) =>
    values.map((value) => value.trim().toLowerCase()).toSet();

/// An ingredient fact must come from a trusted, reviewed source. The caller is
/// responsible for enforcing that provenance before setting [compositionVerified].
class IngredientFact {
  const IngredientFact({
    required this.id,
    required this.compositionVerified,
    required this.allergens,
    this.crossContactVerified = false,
    this.crossContactAllergens = const {},
  });

  final String id;
  final bool compositionVerified;
  final Set<String> allergens;
  final bool crossContactVerified;
  final Set<String> crossContactAllergens;
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.ingredientId,
    this.isPackaged = false,
    this.brandLabelChecked = false,
  });

  /// Canonical ID of the actual ingredient, including a chosen substitution.
  final String ingredientId;
  final bool isPackaged;
  final bool brandLabelChecked;
}

class RecipeCandidate {
  const RecipeCandidate({required this.ingredients, required this.timeMinutes});

  final List<RecipeIngredient> ingredients;
  final int timeMinutes;
}

class EaterRestrictions {
  const EaterRestrictions({required this.hardAllergens});

  final Set<String> hardAllergens;
}

class EligibilityResult {
  const EligibilityResult(this.code, {this.ingredientId});

  final EligibilityCode code;
  final String? ingredientId;

  bool get isEligible => code == EligibilityCode.eligible;
}

/// Checks the *actual selected ingredient IDs*, including substitutions.
/// Unknown facts, unverified composition, and missing packaged-food label or
/// cross-contact verification are never silently treated as safe.
EligibilityResult evaluateRecipe({
  required RecipeCandidate recipe,
  required List<EaterRestrictions> eaters,
  required Map<String, IngredientFact> facts,
  required int maxPrepMinutes,
}) {
  if (eaters.isEmpty ||
      recipe.ingredients.isEmpty ||
      recipe.timeMinutes < 0 ||
      maxPrepMinutes < 0) {
    return const EligibilityResult(EligibilityCode.allergenUncertain);
  }

  for (final component in recipe.ingredients) {
    final fact = facts[component.ingredientId];
    if (fact == null ||
        fact.id != component.ingredientId ||
        !fact.compositionVerified) {
      return EligibilityResult(
        EligibilityCode.allergenUncertain,
        ingredientId: component.ingredientId,
      );
    }

    for (final eater in eaters) {
      final hardAllergens = _normalized(eater.hardAllergens);
      if (_normalized(fact.allergens).intersection(hardAllergens).isNotEmpty ||
          _normalized(fact.crossContactAllergens)
              .intersection(hardAllergens)
              .isNotEmpty) {
        return EligibilityResult(
          EligibilityCode.allergenBlocked,
          ingredientId: component.ingredientId,
        );
      }
    }

    if (component.isPackaged &&
        (!component.brandLabelChecked || !fact.crossContactVerified)) {
      return EligibilityResult(
        EligibilityCode.packagedFoodUnverified,
        ingredientId: component.ingredientId,
      );
    }
  }

  if (recipe.timeMinutes > maxPrepMinutes) {
    return const EligibilityResult(EligibilityCode.timeConstraint);
  }
  return const EligibilityResult(EligibilityCode.eligible);
}
