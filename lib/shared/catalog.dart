/// Seeded recipe catalog, ingredient facts and labeled price estimates.
///
/// Every ingredient in this catalog carries a verified composition record per
/// the safety contract — the local backend treats any ingredient not in this
/// map as ALLERGEN_UNCERTAIN, exactly like the server would. Prices are
/// clearly labeled sample estimates (source/observed_at/region/confidence),
/// never represented as live local pricing.
library;

import 'models.dart';

const allergenKeys = [
  'milk',
  'egg',
  'peanut',
  'tree_nut',
  'wheat',
  'soy',
  'fish',
  'shellfish',
  'sesame',
];

final ingredients = <String, CatalogIngredient>{
  for (final i in _ingredientList) i.id: i,
};

final _ingredientList = <CatalogIngredient>[
  const CatalogIngredient(
    id: 'rolled_oats',
    name: 'Rolled oats',
    stockUnit: FoodUnit.grams,
    allergens: {'wheat'},
  ),
  const CatalogIngredient(
    id: 'milk_whole',
    name: 'Whole milk',
    stockUnit: FoodUnit.milliliters,
    allergens: {'milk'},
  ),
  const CatalogIngredient(
    id: 'egg',
    name: 'Eggs',
    stockUnit: FoodUnit.pieces,
    allergens: {'egg'},
  ),
  const CatalogIngredient(
    id: 'banana',
    name: 'Bananas',
    stockUnit: FoodUnit.pieces,
  ),
  const CatalogIngredient(
    id: 'apple',
    name: 'Apples',
    stockUnit: FoodUnit.pieces,
  ),
  const CatalogIngredient(
    id: 'peanut_butter',
    name: 'Peanut butter',
    stockUnit: FoodUnit.grams,
    allergens: {'peanut'},
    isPackaged: true,
    brandLabelChecked: true,
    crossContactVerified: true,
    crossContactAllergens: {'tree_nut'},
  ),
  const CatalogIngredient(
    id: 'bread_whole',
    name: 'Whole grain bread',
    stockUnit: FoodUnit.grams,
    allergens: {'wheat'},
    isPackaged: true,
    brandLabelChecked: true,
    crossContactVerified: true,
    crossContactAllergens: {'sesame'},
  ),
  const CatalogIngredient(
    id: 'chicken_breast',
    name: 'Chicken breast',
    stockUnit: FoodUnit.grams,
  ),
  const CatalogIngredient(
    id: 'rice_white',
    name: 'White rice',
    stockUnit: FoodUnit.grams,
  ),
  const CatalogIngredient(
    id: 'pasta',
    name: 'Pasta',
    stockUnit: FoodUnit.grams,
    allergens: {'wheat'},
  ),
  const CatalogIngredient(
    id: 'tomato_sauce',
    name: 'Tomato sauce',
    stockUnit: FoodUnit.grams,
    isPackaged: true,
    brandLabelChecked: true,
    crossContactVerified: true,
  ),
  const CatalogIngredient(
    id: 'cheese_cheddar',
    name: 'Cheddar cheese',
    stockUnit: FoodUnit.grams,
    allergens: {'milk'},
  ),
  const CatalogIngredient(
    id: 'tortilla',
    name: 'Corn tortillas',
    stockUnit: FoodUnit.pieces,
    isPackaged: true,
    brandLabelChecked: true,
    crossContactVerified: true,
  ),
  const CatalogIngredient(
    id: 'black_beans',
    name: 'Black beans (canned)',
    stockUnit: FoodUnit.grams,
    isPackaged: true,
    brandLabelChecked: true,
    crossContactVerified: true,
  ),
  const CatalogIngredient(
    id: 'ground_beef',
    name: 'Ground beef',
    stockUnit: FoodUnit.grams,
  ),
  const CatalogIngredient(
    id: 'potato',
    name: 'Potatoes',
    stockUnit: FoodUnit.grams,
  ),
  const CatalogIngredient(
    id: 'carrot',
    name: 'Carrots',
    stockUnit: FoodUnit.grams,
  ),
  const CatalogIngredient(
    id: 'onion',
    name: 'Onions',
    stockUnit: FoodUnit.pieces,
  ),
  const CatalogIngredient(
    id: 'frozen_veg',
    name: 'Frozen mixed vegetables',
    stockUnit: FoodUnit.grams,
    isPackaged: true,
    brandLabelChecked: true,
    crossContactVerified: true,
  ),
  const CatalogIngredient(
    id: 'salmon',
    name: 'Salmon fillet',
    stockUnit: FoodUnit.grams,
    allergens: {'fish'},
  ),
  const CatalogIngredient(
    id: 'yogurt_plain',
    name: 'Plain yogurt',
    stockUnit: FoodUnit.grams,
    allergens: {'milk'},
  ),
  const CatalogIngredient(
    id: 'hummus',
    name: 'Hummus',
    stockUnit: FoodUnit.grams,
    allergens: {'sesame'},
    isPackaged: true,
    brandLabelChecked: true,
    crossContactVerified: true,
  ),
  const CatalogIngredient(
    id: 'cucumber',
    name: 'Cucumber',
    stockUnit: FoodUnit.pieces,
  ),
  const CatalogIngredient(
    id: 'lettuce',
    name: 'Romaine lettuce',
    stockUnit: FoodUnit.grams,
  ),
  const CatalogIngredient(
    id: 'olive_oil',
    name: 'Olive oil',
    stockUnit: FoodUnit.milliliters,
  ),
  const CatalogIngredient(
    id: 'flour_tortilla',
    name: 'Flour tortillas',
    stockUnit: FoodUnit.pieces,
    allergens: {'wheat'},
    isPackaged: true,
    brandLabelChecked: true,
    crossContactVerified: true,
  ),
  const CatalogIngredient(
    id: 'lentils',
    name: 'Dry lentils',
    stockUnit: FoodUnit.grams,
  ),
  const CatalogIngredient(
    id: 'bell_pepper',
    name: 'Bell peppers',
    stockUnit: FoodUnit.pieces,
  ),
];

final recipes = <String, CatalogRecipe>{for (final r in _recipeList) r.id: r};

final _recipeList = <CatalogRecipe>[
  CatalogRecipe(
    id: 'r-oatmeal-banana',
    title: 'Banana Oatmeal',
    meal: MealType.breakfast,
    minutes: 10,
    servings: 4,
    cuisine: 'American',
    kidFriendly: true,
    summary: 'Warm oats with sliced banana. Simple, filling breakfast.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: bowl of oatmeal with banana slices',
    ),
    needs: const [
      RecipeNeed('rolled_oats', 200),
      RecipeNeed('milk_whole', 500),
      RecipeNeed('banana', 3),
    ],
    steps: const [
      'Simmer oats in milk 5-7 minutes.',
      'Slice bananas on top.',
      'Serve warm.',
    ],
    substitutions: const {'milk_whole': 'yogurt_plain'},
  ),
  CatalogRecipe(
    id: 'r-scrambled-eggs',
    title: 'Scrambled Eggs & Toast',
    meal: MealType.breakfast,
    minutes: 12,
    servings: 4,
    cuisine: 'American',
    kidFriendly: true,
    summary: 'Soft scrambled eggs with whole grain toast.',
    image: const RecipeImage(
      kind: ImageKind.aiIllustration,
      altText: 'AI illustration: scrambled eggs with toast on a plate',
    ),
    needs: const [RecipeNeed('egg', 8), RecipeNeed('bread_whole', 200)],
    steps: const [
      'Whisk eggs with a pinch of salt.',
      'Cook low and slow, stirring.',
      'Toast bread and serve.',
    ],
  ),
  CatalogRecipe(
    id: 'r-yogurt-apple',
    title: 'Yogurt & Apple Bowls',
    meal: MealType.breakfast,
    minutes: 5,
    servings: 4,
    cuisine: 'American',
    kidFriendly: true,
    summary: 'Plain yogurt topped with diced apple and a sprinkle of oats.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: yogurt bowl with diced apple',
    ),
    needs: const [
      RecipeNeed('yogurt_plain', 500),
      RecipeNeed('apple', 3),
      RecipeNeed('rolled_oats', 80),
    ],
    steps: const [
      'Dice apples.',
      'Spoon yogurt into bowls.',
      'Top with apple and oats.',
    ],
  ),
  CatalogRecipe(
    id: 'r-pb-toast',
    title: 'Peanut Butter Toast',
    meal: MealType.breakfast,
    minutes: 5,
    servings: 2,
    cuisine: 'American',
    kidFriendly: true,
    summary: 'Whole grain toast with peanut butter and banana.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: toast with peanut butter',
    ),
    needs: const [
      RecipeNeed('bread_whole', 150),
      RecipeNeed('peanut_butter', 60),
      RecipeNeed('banana', 1),
    ],
    steps: const [
      'Toast bread.',
      'Spread peanut butter.',
      'Top with banana slices.',
    ],
  ),
  CatalogRecipe(
    id: 'r-veggie-omelet',
    title: 'Veggie Omelet',
    meal: MealType.breakfast,
    minutes: 15,
    servings: 2,
    cuisine: 'American',
    summary: 'Egg omelet folded with peppers and cheddar.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: folded omelet with peppers',
    ),
    needs: const [
      RecipeNeed('egg', 4),
      RecipeNeed('bell_pepper', 1),
      RecipeNeed('cheese_cheddar', 60),
    ],
    steps: const [
      'Dice pepper and soften in pan.',
      'Add beaten eggs.',
      'Fold with cheese.',
    ],
  ),
  CatalogRecipe(
    id: 'r-chicken-rice',
    title: 'Chicken & Rice Bowls',
    meal: MealType.lunch,
    minutes: 30,
    servings: 4,
    cuisine: 'American',
    kidFriendly: true,
    summary: 'Seasoned chicken over rice with mixed vegetables.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: chicken and rice bowl',
    ),
    needs: const [
      RecipeNeed('chicken_breast', 500),
      RecipeNeed('rice_white', 300),
      RecipeNeed('frozen_veg', 300),
    ],
    steps: const [
      'Cook rice.',
      'Sear chicken until done.',
      'Steam vegetables and combine.',
    ],
  ),
  CatalogRecipe(
    id: 'r-bean-tacos',
    title: 'Black Bean Tacos',
    meal: MealType.lunch,
    minutes: 20,
    servings: 4,
    cuisine: 'Mexican',
    kidFriendly: true,
    summary: 'Corn tortillas with seasoned black beans and lettuce.',
    image: const RecipeImage(
      kind: ImageKind.aiIllustration,
      altText: 'AI illustration: black bean tacos on a plate',
    ),
    needs: const [
      RecipeNeed('tortilla', 8),
      RecipeNeed('black_beans', 400),
      RecipeNeed('lettuce', 100),
      RecipeNeed('cheese_cheddar', 80),
    ],
    steps: const [
      'Warm beans with seasoning.',
      'Warm tortillas.',
      'Assemble with lettuce and cheese.',
    ],
  ),
  CatalogRecipe(
    id: 'r-hummus-veggie',
    title: 'Hummus Veggie Plate',
    meal: MealType.lunch,
    minutes: 10,
    servings: 2,
    cuisine: 'Mediterranean',
    summary: 'Hummus with cucumber, carrots and bread for dipping.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: hummus plate with vegetables',
    ),
    needs: const [
      RecipeNeed('hummus', 200),
      RecipeNeed('cucumber', 1),
      RecipeNeed('carrot', 150),
      RecipeNeed('bread_whole', 150),
    ],
    steps: const [
      'Slice vegetables.',
      'Arrange with hummus.',
      'Serve with bread.',
    ],
  ),
  CatalogRecipe(
    id: 'r-pasta-tomato',
    title: 'Pasta with Tomato Sauce',
    meal: MealType.lunch,
    minutes: 20,
    servings: 4,
    cuisine: 'Italian',
    kidFriendly: true,
    summary: 'Simple pasta in tomato sauce.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: pasta in tomato sauce',
    ),
    needs: const [RecipeNeed('pasta', 400), RecipeNeed('tomato_sauce', 350)],
    steps: const ['Boil pasta.', 'Warm sauce.', 'Combine and serve.'],
  ),
  CatalogRecipe(
    id: 'r-chicken-wrap',
    title: 'Chicken Salad Wraps',
    meal: MealType.lunch,
    minutes: 15,
    servings: 4,
    cuisine: 'American',
    summary: 'Flour tortillas with chicken, lettuce and yogurt dressing.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: chicken wrap cut in half',
    ),
    needs: const [
      RecipeNeed('flour_tortilla', 4),
      RecipeNeed('chicken_breast', 350),
      RecipeNeed('lettuce', 80),
      RecipeNeed('yogurt_plain', 100),
    ],
    steps: const [
      'Cook and slice chicken.',
      'Mix yogurt dressing.',
      'Wrap with lettuce.',
    ],
  ),
  CatalogRecipe(
    id: 'r-lentil-soup',
    title: 'Lentil Vegetable Soup',
    meal: MealType.lunch,
    minutes: 40,
    servings: 6,
    cuisine: 'Mediterranean',
    summary: 'Hearty lentils simmered with carrots and onion.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: lentil soup in a bowl',
    ),
    needs: const [
      RecipeNeed('lentils', 400),
      RecipeNeed('carrot', 200),
      RecipeNeed('onion', 1),
      RecipeNeed('olive_oil', 30),
    ],
    steps: const [
      'Soften onion and carrot in oil.',
      'Add lentils and water.',
      'Simmer 30 minutes.',
    ],
  ),
  CatalogRecipe(
    id: 'r-beef-potato',
    title: 'Beef & Potato Skillet',
    meal: MealType.dinner,
    minutes: 35,
    servings: 4,
    cuisine: 'American',
    kidFriendly: true,
    summary: 'One-pan ground beef with potatoes and carrots.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: beef and potato skillet',
    ),
    needs: const [
      RecipeNeed('ground_beef', 450),
      RecipeNeed('potato', 600),
      RecipeNeed('carrot', 200),
      RecipeNeed('onion', 1),
    ],
    steps: const [
      'Brown beef with onion.',
      'Add diced potato and carrot.',
      'Cover and cook until tender.',
    ],
  ),
  CatalogRecipe(
    id: 'r-salmon-rice',
    title: 'Salmon & Rice',
    meal: MealType.dinner,
    minutes: 25,
    servings: 4,
    cuisine: 'American',
    summary: 'Baked salmon fillets with rice and vegetables.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: salmon with rice',
    ),
    needs: const [
      RecipeNeed('salmon', 500),
      RecipeNeed('rice_white', 300),
      RecipeNeed('frozen_veg', 250),
    ],
    steps: const [
      'Bake salmon at 200C 12-15 min.',
      'Cook rice.',
      'Serve with vegetables.',
    ],
  ),
  CatalogRecipe(
    id: 'r-chicken-enchiladas',
    title: 'Chicken Enchiladas',
    meal: MealType.dinner,
    minutes: 45,
    servings: 6,
    cuisine: 'Mexican',
    kidFriendly: true,
    summary:
        'Corn tortillas rolled with chicken, baked in tomato sauce and cheese.',
    image: const RecipeImage(
      kind: ImageKind.verifiedPhoto,
      altText: 'Chicken enchiladas with tomato sauce and melted cheese in a baking dish',
      credit: 'Curated catalog - license verified',
    ),
    needs: const [
      RecipeNeed('tortilla', 12),
      RecipeNeed('chicken_breast', 500),
      RecipeNeed('tomato_sauce', 400),
      RecipeNeed('cheese_cheddar', 120),
    ],
    steps: const [
      'Cook and shred chicken.',
      'Fill tortillas and roll.',
      'Cover with sauce and cheese, bake 20 min.',
    ],
  ),
  CatalogRecipe(
    id: 'r-veggie-pasta',
    title: 'Veggie Pasta Bake',
    meal: MealType.dinner,
    minutes: 40,
    servings: 6,
    cuisine: 'Italian',
    kidFriendly: true,
    summary: 'Baked pasta with vegetables and cheddar topping.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: pasta bake in a dish',
    ),
    needs: const [
      RecipeNeed('pasta', 400),
      RecipeNeed('frozen_veg', 300),
      RecipeNeed('tomato_sauce', 350),
      RecipeNeed('cheese_cheddar', 100),
    ],
    steps: const [
      'Boil pasta.',
      'Mix with sauce and vegetables.',
      'Top with cheese and bake.',
    ],
  ),
  CatalogRecipe(
    id: 'r-lentil-stew',
    title: 'Lentil & Potato Stew',
    meal: MealType.dinner,
    minutes: 45,
    servings: 6,
    cuisine: 'Mediterranean',
    summary: 'Thick lentil stew with potatoes and carrots.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: lentil stew',
    ),
    needs: const [
      RecipeNeed('lentils', 350),
      RecipeNeed('potato', 500),
      RecipeNeed('carrot', 200),
      RecipeNeed('onion', 1),
    ],
    steps: const [
      'Saute onion.',
      'Add lentils, potato, carrot, water.',
      'Simmer until thick.',
    ],
  ),
  CatalogRecipe(
    id: 'r-beef-tacos',
    title: 'Beef Tacos',
    meal: MealType.dinner,
    minutes: 25,
    servings: 4,
    cuisine: 'Mexican',
    kidFriendly: true,
    summary: 'Seasoned ground beef in corn tortillas with lettuce and cheese.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: beef tacos',
    ),
    needs: const [
      RecipeNeed('tortilla', 8),
      RecipeNeed('ground_beef', 450),
      RecipeNeed('lettuce', 80),
      RecipeNeed('cheese_cheddar', 80),
    ],
    steps: const [
      'Brown beef with seasoning.',
      'Warm tortillas.',
      'Assemble tacos.',
    ],
  ),
  CatalogRecipe(
    id: 'r-baked-chicken',
    title: 'Baked Chicken & Potatoes',
    meal: MealType.dinner,
    minutes: 50,
    servings: 4,
    cuisine: 'American',
    kidFriendly: true,
    summary: 'Sheet-pan chicken with roasted potatoes and carrots.',
    image: const RecipeImage(
      kind: ImageKind.placeholder,
      altText: 'Illustration pending: baked chicken with potatoes',
    ),
    needs: const [
      RecipeNeed('chicken_breast', 500),
      RecipeNeed('potato', 600),
      RecipeNeed('carrot', 200),
      RecipeNeed('olive_oil', 40),
    ],
    steps: const [
      'Toss vegetables in oil.',
      'Arrange with chicken on pan.',
      'Bake at 200C 35-40 min.',
    ],
  ),
];

/// Labeled sample price estimates. Source/observedAt/region/confidence are
/// always displayed next to any dollar figure in adult surfaces.
final priceOffers = <PriceOffer>[
  for (final e in _offerRows)
    PriceOffer(
      ingredientId: e.$1,
      packSize: FoodQuantity(e.$2, e.$3),
      estimatedCents: e.$4,
      source: 'sample_estimate',
      observedAt: DateTime.utc(2026, 10, 15),
      region: 'US-DEMO',
      confidence: 0.55,
      benefitEligibility: e.$5,
    ),
];

// (ingredientId, packAmount, packUnit, estCents, benefitEligibility)
const _offerRows = <(String, int, FoodUnit, int, BenefitEligibility)>[
  ('rolled_oats', 500, FoodUnit.grams, 329, BenefitEligibility.eligible),
  ('milk_whole', 1000, FoodUnit.milliliters, 189, BenefitEligibility.eligible),
  ('egg', 12, FoodUnit.pieces, 349, BenefitEligibility.eligible),
  ('banana', 6, FoodUnit.pieces, 149, BenefitEligibility.eligible),
  ('apple', 6, FoodUnit.pieces, 399, BenefitEligibility.eligible),
  ('peanut_butter', 450, FoodUnit.grams, 299, BenefitEligibility.eligible),
  ('bread_whole', 600, FoodUnit.grams, 279, BenefitEligibility.eligible),
  ('chicken_breast', 1000, FoodUnit.grams, 799, BenefitEligibility.eligible),
  ('rice_white', 900, FoodUnit.grams, 219, BenefitEligibility.eligible),
  ('pasta', 500, FoodUnit.grams, 149, BenefitEligibility.eligible),
  ('tomato_sauce', 400, FoodUnit.grams, 129, BenefitEligibility.eligible),
  ('cheese_cheddar', 400, FoodUnit.grams, 429, BenefitEligibility.eligible),
  ('tortilla', 12, FoodUnit.pieces, 229, BenefitEligibility.eligible),
  ('black_beans', 425, FoodUnit.grams, 119, BenefitEligibility.eligible),
  ('ground_beef', 1000, FoodUnit.grams, 899, BenefitEligibility.eligible),
  ('potato', 2000, FoodUnit.grams, 349, BenefitEligibility.eligible),
  ('carrot', 1000, FoodUnit.grams, 169, BenefitEligibility.eligible),
  ('onion', 3, FoodUnit.pieces, 149, BenefitEligibility.eligible),
  ('frozen_veg', 500, FoodUnit.grams, 199, BenefitEligibility.eligible),
  ('salmon', 500, FoodUnit.grams, 799, BenefitEligibility.eligible),
  ('yogurt_plain', 900, FoodUnit.grams, 379, BenefitEligibility.eligible),
  ('hummus', 300, FoodUnit.grams, 349, BenefitEligibility.eligible),
  ('cucumber', 1, FoodUnit.pieces, 99, BenefitEligibility.eligible),
  ('lettuce', 300, FoodUnit.grams, 219, BenefitEligibility.eligible),
  ('olive_oil', 500, FoodUnit.milliliters, 649, BenefitEligibility.unknown),
  ('flour_tortilla', 8, FoodUnit.pieces, 269, BenefitEligibility.eligible),
  ('lentils', 900, FoodUnit.grams, 279, BenefitEligibility.eligible),
  ('bell_pepper', 3, FoodUnit.pieces, 299, BenefitEligibility.eligible),
];

// ---------- Beverages ----------

final beverages = <String, Beverage>{
  'water': const Beverage(
    id: 'water',
    name: 'Water',
    packSize: FoodQuantity(4000, FoodUnit.milliliters),
    ingredientId: 'water',
  ),
  'milk_whole': const Beverage(
    id: 'milk_whole',
    name: 'Milk',
    packSize: FoodQuantity(1000, FoodUnit.milliliters),
    ingredientId: 'milk_whole',
  ),
  'juice': const Beverage(
    id: 'juice',
    name: 'Juice',
    packSize: FoodQuantity(1500, FoodUnit.milliliters),
    ingredientId: 'juice',
  ),
  'coffee': const Beverage(
    id: 'coffee',
    name: 'Coffee',
    packSize: FoodQuantity(340, FoodUnit.grams),
    ingredientId: 'coffee',
  ),
};

// ---------- Games ----------

final gameDefinitions = <GameDefinition>[
  const GameDefinition(
    id: 'dinner-showdown',
    title: 'Dinner Showdown',
    summary: 'Bracket vote: pick tonight\'s champion meal.',
    icon: 'trophy',
    quotaPerWindow: 3,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'pantry-bingo',
    title: 'Pantry Bingo',
    summary: 'Complete a 3x3 board using real pantry items.',
    icon: 'grid',
    quotaPerWindow: 1,
    window: Duration(days: 30),
  ),
  const GameDefinition(
    id: 'recipe-roulette',
    title: 'Recipe Roulette',
    summary: 'Spin for a safe surprise dinner idea.',
    icon: 'shuffle',
    quotaPerWindow: 3,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'price-guess',
    title: 'Guess the Price',
    summary: 'Estimate a sample basket cost, then compare.',
    icon: 'tag',
    quotaPerWindow: 1,
    window: Duration(days: 7),
    minAge: AgeBand.a9to12,
  ),
  const GameDefinition(
    id: 'fridge-rescue',
    title: 'Fridge Rescue',
    summary: 'Pick pantry items and rescue them into a meal.',
    icon: 'rescue',
    quotaPerWindow: 1,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'build-a-meal',
    title: 'Build a Meal',
    summary: 'Combine safe components into a balanced plate.',
    icon: 'stack',
    quotaPerWindow: 5,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'mystery-recipe',
    title: 'Mystery Recipe',
    summary: 'Guess the dish from up to five clues.',
    icon: 'mystery',
    quotaPerWindow: 3,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'world-food',
    title: 'World Food',
    summary: 'Explore a cuisine and earn a passport stamp.',
    icon: 'globe',
    quotaPerWindow: 3,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'family-restaurant',
    title: 'Family Restaurant',
    summary: 'Draft a dream menu and vote on the lineup.',
    icon: 'menu_book',
    quotaPerWindow: 2,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'budget-hero',
    title: 'Budget Hero',
    summary: 'Plan a meal that fits a chosen spending limit.',
    icon: 'shield',
    quotaPerWindow: 2,
    window: Duration(days: 7),
    minAge: AgeBand.a13to17,
  ),
  const GameDefinition(
    id: 'food-trivia',
    title: 'Food Trivia',
    summary: 'Short food science and kitchen safety quiz.',
    icon: 'quiz',
    quotaPerWindow: 1,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'junior-chef',
    title: 'Junior Chef',
    summary: 'Safety-first kitchen lessons with an adult.',
    icon: 'chef',
    quotaPerWindow: 7,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'cooking-together',
    title: 'Cooking Together',
    summary: 'Shared cooking checklist with roles.',
    icon: 'people',
    quotaPerWindow: 4,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'grocery-detective',
    title: 'Grocery Detective',
    summary: 'Identify and check pantry items like a pro.',
    icon: 'search',
    quotaPerWindow: 4,
    window: Duration(days: 7),
  ),
  const GameDefinition(
    id: 'leftover-legends',
    title: 'Leftover Legends',
    summary: 'Learn safe leftover storage and reuse.',
    icon: 'fridge',
    quotaPerWindow: 3,
    window: Duration(days: 7),
    minAge: AgeBand.a9to12,
  ),
];

GameDefinition gameById(String id) =>
    gameDefinitions.firstWhere((g) => g.id == id);

// ---------- Passport / trivia / lessons content ----------

class CuisineInfo {
  const CuisineInfo({
    required this.name,
    required this.fact,
    required this.recipeId,
    required this.challenge,
  });

  final String name;
  final String fact;
  final String recipeId;
  final String challenge;
}

const passportStops = <CuisineInfo>[
  CuisineInfo(
    name: 'Mexico',
    fact: 'Corn has been grown in Mexico for thousands of years and is the base of tortillas.',
    recipeId: 'r-bean-tacos',
    challenge: 'Help fill a taco with beans and lettuce.',
  ),
  CuisineInfo(
    name: 'Italy',
    fact: 'Dried pasta keeps for a long time, which is why it became a pantry staple.',
    recipeId: 'r-pasta-tomato',
    challenge: 'Stir the pasta pot with an adult watching.',
  ),
  CuisineInfo(
    name: 'Mediterranean',
    fact: 'Lentils and chickpeas have fed families around the Mediterranean for centuries.',
    recipeId: 'r-lentil-soup',
    challenge: 'Rinse the lentils before they go in the pot.',
  ),
];

class TriviaQuestion {
  const TriviaQuestion({
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });

  final String question;
  final List<String> choices;
  final int answerIndex;
  final String explanation;
}

const triviaQuestions = <TriviaQuestion>[
  TriviaQuestion(
    question: 'Why do we wash hands before cooking?',
    choices: [
      'It makes food taste better',
      'To keep germs away from food',
      'It is just a rule',
    ],
    answerIndex: 1,
    explanation: 'Clean hands help keep germs out of the food we eat.',
  ),
  TriviaQuestion(
    question: 'Which food needs a grown-up to cook with heat?',
    choices: ['Washing lettuce', 'Frying eggs', 'Peeling a banana'],
    answerIndex: 1,
    explanation: 'Heat and pans are adult jobs. Kids can wash and peel.',
  ),
  TriviaQuestion(
    question: 'What does "use by" on food mean?',
    choices: [
      'Eat it before that date for safety',
      'It is the day it was made',
      'Nothing important',
    ],
    answerIndex: 0,
    explanation: 'The use-by date tells us when food may stop being safe.',
  ),
];

class ChefLesson {
  const ChefLesson({
    required this.title,
    required this.steps,
    required this.needsAdult,
  });

  final String title;
  final List<String> steps;

  /// True when the step involves heat, knives or other adult-supervised tasks.
  final bool needsAdult;
}

const chefLessons = <ChefLesson>[
  ChefLesson(
    title: 'Clean hands station',
    needsAdult: false,
    steps: [
      'Wet hands with warm water.',
      'Soap for 20 seconds - sing the ABCs.',
      'Rinse and dry with a clean towel.',
    ],
  ),
  ChefLesson(
    title: 'Measuring like a chef',
    needsAdult: false,
    steps: [
      'Scoop oats into a measuring cup.',
      'Level the top with a butter knife (adult helps).',
      'Pour into the bowl.',
    ],
  ),
  ChefLesson(
    title: 'Safe stovetop with an adult',
    needsAdult: true,
    steps: [
      'Adult turns on the burner.',
      'Watch the pot together.',
      'Adult turns it off - kids never touch knobs alone.',
    ],
  ),
];

class MysteryClue {
  const MysteryClue({required this.recipeId, required this.clues});

  final String recipeId;
  final List<String> clues;
}

const mysteryRecipes = <MysteryClue>[
  MysteryClue(
    recipeId: 'r-chicken-enchiladas',
    clues: [
      'This dinner comes from Mexican cooking.',
      'It is rolled up before it goes in the oven.',
      'It uses a flat bread made from corn.',
      'It has shredded chicken inside.',
      'Melted cheese goes on top.',
    ],
  ),
  MysteryClue(
    recipeId: 'r-lentil-soup',
    clues: [
      'This meal is warm and eaten with a spoon.',
      'Its main ingredient is a tiny round legume.',
      'Carrots and onions help flavor it.',
      'It simmers for about thirty minutes.',
      'It is popular around the Mediterranean.',
    ],
  ),
];

/// Adult-approved ballot options for the shared catalog demo.
const adultOnlyNote =
    'Only adults can see prices, billing and household settings.';
