import 'dart:io';

import 'package:family_circle_safety_engine/safety_engine.dart';

void expectCode(EligibilityResult result, EligibilityCode expected) {
  if (result.code != expected) {
    throw StateError('Expected $expected, got ${result.code}');
  }
}

void main() {
  const kiwiAllergy = EaterRestrictions(hardAllergens: {'kiwi'});
  const noAllergies = EaterRestrictions(hardAllergens: {});

  const kiwi = IngredientFact(
    id: 'kiwi',
    compositionVerified: true,
    allergens: {'kiwi'},
  );
  const banana = IngredientFact(
    id: 'banana',
    compositionVerified: true,
    allergens: {},
  );
  const mysteryMix = IngredientFact(
    id: 'mystery_mix',
    compositionVerified: false,
    allergens: {},
  );
  const labeledMix = IngredientFact(
    id: 'labeled_mix',
    compositionVerified: true,
    allergens: {},
    crossContactVerified: true,
  );
  const traceKiwi = IngredientFact(
    id: 'trace_kiwi',
    compositionVerified: true,
    allergens: {},
    crossContactVerified: true,
    crossContactAllergens: {'kiwi'},
  );
  final facts = {
    kiwi.id: kiwi,
    banana.id: banana,
    mysteryMix.id: mysteryMix,
    labeledMix.id: labeledMix,
    traceKiwi.id: traceKiwi,
  };

  EligibilityResult check(
    String ingredientId, {
    bool packaged = false,
    bool labelChecked = false,
    List<EaterRestrictions> eaters = const [kiwiAllergy],
    int timeMinutes = 10,
    int maxPrepMinutes = 30,
  }) =>
      evaluateRecipe(
        recipe: RecipeCandidate(
          ingredients: [
            RecipeIngredient(
              ingredientId: ingredientId,
              isPackaged: packaged,
              brandLabelChecked: labelChecked,
            ),
          ],
          timeMinutes: timeMinutes,
        ),
        eaters: eaters,
        facts: facts,
        maxPrepMinutes: maxPrepMinutes,
      );

  // The two documented golden allergen fixtures.
  expectCode(check('kiwi'), EligibilityCode.allergenBlocked);
  if (check('kiwi').code.wireCode != 'ALLERGEN_BLOCKED') {
    throw StateError('Wrong wire error code');
  }
  expectCode(check('mystery_mix'), EligibilityCode.allergenUncertain);

  expectCode(check('banana'), EligibilityCode.eligible);
  expectCode(check('missing'), EligibilityCode.allergenUncertain);
  expectCode(
    check('trace_kiwi', packaged: true, labelChecked: true),
    EligibilityCode.allergenBlocked,
  );
  expectCode(
    check('labeled_mix', packaged: true),
    EligibilityCode.packagedFoodUnverified,
  );
  expectCode(
    check('banana', packaged: true, labelChecked: true),
    EligibilityCode.packagedFoodUnverified,
  );
  expectCode(
    check('labeled_mix', packaged: true, labelChecked: true),
    EligibilityCode.eligible,
  );
  expectCode(check('kiwi', eaters: [noAllergies]), EligibilityCode.eligible);
  expectCode(
    check('kiwi', eaters: [noAllergies, kiwiAllergy]),
    EligibilityCode.allergenBlocked,
  );
  expectCode(
    check(
      'kiwi',
      eaters: const [
        EaterRestrictions(hardAllergens: {' KIWI '}),
      ],
    ),
    EligibilityCode.allergenBlocked,
  );
  expectCode(check('banana', timeMinutes: 45), EligibilityCode.timeConstraint);

  // A substitution changes the ingredient ID; it must be checked anew.
  expectCode(check('kiwi'), EligibilityCode.allergenBlocked);
  expectCode(check('banana'), EligibilityCode.eligible);
  expectCode(check('mystery_mix'), EligibilityCode.allergenUncertain);
  expectCode(check('banana', eaters: []), EligibilityCode.allergenUncertain);
  expectCode(
    evaluateRecipe(
      recipe: const RecipeCandidate(ingredients: [], timeMinutes: 10),
      eaters: const [kiwiAllergy],
      facts: facts,
      maxPrepMinutes: 30,
    ),
    EligibilityCode.allergenUncertain,
  );
  stdout.writeln('Safety cases passed');
}
