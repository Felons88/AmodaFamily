/// Domain model for Family Circle, aligned with
/// docs/contracts/DOMAIN_MODEL.md. Money is integer USD cents; quantities are
/// typed FoodQuantity from the planner engine. IDs are simple strings in the
/// local backend; the server contract uses UUIDs.
library;

import 'package:family_circle_planner_engine/planner_engine.dart';
import 'package:family_circle_safety_engine/safety_engine.dart';

export 'package:family_circle_planner_engine/planner_engine.dart'
    show
        FoodUnit,
        FoodQuantity,
        PriceOffer,
        BenefitEligibility,
        BasketEstimate,
        BasketLine,
        IngredientNeed,
        PantryStock;
export 'package:family_circle_safety_engine/safety_engine.dart'
    show EligibilityCode, EligibilityResult, IngredientFact, EaterRestrictions;

enum MemberRole { owner, admin, adult, minor }

enum AgeBand { a0to4, a5to8, a9to12, a13to17, adult }

extension AgeBandLabel on AgeBand {
  String get label => switch (this) {
    AgeBand.a0to4 => '0-4',
    AgeBand.a5to8 => '5-8',
    AgeBand.a9to12 => '9-12',
    AgeBand.a13to17 => '13-17',
    AgeBand.adult => '18+',
  };

  bool get isMinor => this != AgeBand.adult;
}

class CircleMember {
  const CircleMember({
    required this.id,
    required this.name,
    required this.role,
    required this.ageBand,
    this.adultVerified = false,
    this.hardAllergens = const {},
    this.active = true,
  });

  final String id;
  final String name;
  final MemberRole role;
  final AgeBand ageBand;
  final bool adultVerified;
  final Set<String> hardAllergens;
  final bool active;

  bool get isMinor => role == MemberRole.minor || ageBand.isMinor;
  bool get isAdult => !isMinor && adultVerified;
  bool get canManage =>
      isAdult &&
      (role == MemberRole.owner ||
          role == MemberRole.admin ||
          role == MemberRole.adult);

  CircleMember copyWith({
    String? name,
    Set<String>? hardAllergens,
    bool? active,
    MemberRole? role,
  }) => CircleMember(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    ageBand: ageBand,
    adultVerified: adultVerified,
    hardAllergens: hardAllergens ?? this.hardAllergens,
    active: active ?? this.active,
  );
}

class Circle {
  const Circle({required this.id, required this.name, required this.members});

  final String id;
  final String name;
  final List<CircleMember> members;

  List<CircleMember> get activeMembers =>
      members.where((m) => m.active).toList();
  List<CircleMember> get minors =>
      activeMembers.where((m) => m.isMinor).toList();
  List<CircleMember> get adults =>
      activeMembers.where((m) => !m.isMinor).toList();
}

// ---------- Catalog ----------

enum MealType { breakfast, lunch, dinner }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch => 'Lunch',
    MealType.dinner => 'Dinner',
  };
}

enum ImageKind { verifiedPhoto, aiIllustration, placeholder }

class RecipeImage {
  const RecipeImage({required this.kind, required this.altText, this.credit});

  final ImageKind kind;
  final String altText;
  final String? credit;

  String get badge => switch (kind) {
    ImageKind.verifiedPhoto => 'Verified photo',
    ImageKind.aiIllustration => 'AI illustration',
    ImageKind.placeholder => 'Photo pending verification',
  };
}

class CatalogIngredient {
  const CatalogIngredient({
    required this.id,
    required this.name,
    required this.stockUnit,
    this.allergens = const {},
    this.compositionVerified = true,
    this.isPackaged = false,
    this.brandLabelChecked = false,
    this.crossContactVerified = false,
    this.crossContactAllergens = const {},
  });

  final String id;
  final String name;
  final FoodUnit stockUnit;
  final Set<String> allergens;
  final bool compositionVerified;
  final bool isPackaged;
  final bool brandLabelChecked;
  final bool crossContactVerified;
  final Set<String> crossContactAllergens;

  IngredientFact get fact => IngredientFact(
    id: id,
    compositionVerified: compositionVerified,
    allergens: allergens,
    crossContactVerified: crossContactVerified,
    crossContactAllergens: crossContactAllergens,
  );
}

class RecipeNeed {
  const RecipeNeed(this.ingredientId, this.amount);

  final String ingredientId;
  final int amount; // in the ingredient's stock unit
}

class CatalogRecipe {
  const CatalogRecipe({
    required this.id,
    required this.title,
    required this.meal,
    required this.minutes,
    required this.servings,
    required this.cuisine,
    required this.needs,
    required this.steps,
    required this.image,
    required this.summary,
    this.kidFriendly = false,
    this.substitutions = const {},
  });

  final String id;
  final String title;
  final MealType meal;
  final int minutes;
  final int servings;
  final String cuisine;
  final List<RecipeNeed> needs;
  final List<String> steps;
  final RecipeImage image;
  final String summary;
  final bool kidFriendly;

  /// ingredientId -> alternative ingredientId, all validated as safe swaps.
  final Map<String, String> substitutions;
}

// ---------- Plan ----------

class PlanSlot {
  const PlanSlot({
    required this.day,
    required this.meal,
    required this.recipeId,
  });

  final int day; // 0-6
  final MealType meal;
  final String recipeId;

  PlanSlot copyWith({String? recipeId}) =>
      PlanSlot(day: day, meal: meal, recipeId: recipeId ?? this.recipeId);
}

enum PlanStatus { draft, approved }

class WeekPlan {
  const WeekPlan({
    required this.id,
    required this.revision,
    required this.weekStart,
    required this.slots,
    required this.status,
    this.basket,
    this.rejectedCodes = const {},
  });

  final String id;
  final int revision;
  final DateTime weekStart;
  final List<PlanSlot> slots;
  final PlanStatus status;
  final BasketEstimate? basket;
  final Map<String, EligibilityCode> rejectedCodes;

  WeekPlan copyWith({
    int? revision,
    List<PlanSlot>? slots,
    PlanStatus? status,
    BasketEstimate? basket,
  }) => WeekPlan(
    id: id,
    revision: revision ?? this.revision,
    weekStart: weekStart,
    slots: slots ?? this.slots,
    status: status ?? this.status,
    basket: basket ?? this.basket,
    rejectedCodes: rejectedCodes,
  );
}

// ---------- Pantry / groceries ----------

class PantryItem {
  const PantryItem({
    required this.ingredientId,
    required this.quantity,
    this.confirmed = false,
    this.expiresAt,
    this.addedAt,
  });

  final String ingredientId;
  final FoodQuantity quantity;
  final bool confirmed;
  final DateTime? expiresAt;
  final DateTime? addedAt;

  bool expiringSoon(DateTime now) =>
      expiresAt != null &&
      expiresAt!.isBefore(now.add(const Duration(days: 3)));

  PantryItem copyWith({
    FoodQuantity? quantity,
    bool? confirmed,
    DateTime? expiresAt,
  }) => PantryItem(
    ingredientId: ingredientId,
    quantity: quantity ?? this.quantity,
    confirmed: confirmed ?? this.confirmed,
    expiresAt: expiresAt ?? this.expiresAt,
    addedAt: addedAt,
  );
}

class GroceryLine {
  const GroceryLine({
    required this.ingredientId,
    required this.name,
    required this.requiredQty,
    required this.pantryDeducted,
    required this.packs,
    this.offer,
    this.estimatedCents,
    this.checked = false,
  });

  final String ingredientId;
  final String name;
  final FoodQuantity requiredQty;
  final FoodQuantity pantryDeducted;
  final int packs;
  final PriceOffer? offer;
  final int? estimatedCents;
  final bool checked;

  bool get priced => offer != null && estimatedCents != null;

  GroceryLine copyWith({bool? checked}) => GroceryLine(
    ingredientId: ingredientId,
    name: name,
    requiredQty: requiredQty,
    pantryDeducted: pantryDeducted,
    packs: packs,
    offer: offer,
    estimatedCents: estimatedCents,
    checked: checked ?? this.checked,
  );
}

class PurchasedItem {
  const PurchasedItem({
    required this.ingredientId,
    required this.packs,
    required this.actualCents,
  });

  final String ingredientId;
  final int packs;
  final int actualCents;
}

class ShoppingTrip {
  const ShoppingTrip({
    required this.id,
    required this.date,
    required this.items,
    required this.totalCents,
    required this.snapCents,
    required this.cashCents,
  });

  final String id;
  final DateTime date;
  final List<PurchasedItem> items;
  final int totalCents;
  final int snapCents;
  final int cashCents;
}

class BudgetCycle {
  const BudgetCycle({
    this.cashCents = 0,
    this.snapCents = 0,
    this.depositDay,
    this.spentCashCents = 0,
    this.spentSnapCents = 0,
  });

  final int cashCents;
  final int snapCents;
  final int? depositDay;
  final int spentCashCents;
  final int spentSnapCents;

  int get totalCents => cashCents + snapCents;
  int get spentCents => spentCashCents + spentSnapCents;
  int get remainingCents => totalCents - spentCents;

  BudgetCycle copyWith({
    int? cashCents,
    int? snapCents,
    int? depositDay,
    int? spentCashCents,
    int? spentSnapCents,
  }) => BudgetCycle(
    cashCents: cashCents ?? this.cashCents,
    snapCents: snapCents ?? this.snapCents,
    depositDay: depositDay ?? this.depositDay,
    spentCashCents: spentCashCents ?? this.spentCashCents,
    spentSnapCents: spentSnapCents ?? this.spentSnapCents,
  );
}

// ---------- Beverages ----------

class Beverage {
  const Beverage({
    required this.id,
    required this.name,
    required this.packSize,
    required this.ingredientId,
  });

  final String id;
  final String name;
  final FoodQuantity packSize;
  final String ingredientId;
}

class BeverageProfile {
  const BeverageProfile({
    required this.beverageId,
    this.servingsPerDay = 1,
    this.confirmedIntervals = 0,
    this.dailyRate = 0,
    this.onHand = 0,
  });

  final String beverageId;
  final double servingsPerDay;

  /// Confirmed check-in intervals; forecast stays 'initial estimate' until >=3.
  final int confirmedIntervals;

  /// EWMA of observed daily consumption (packs/day), alpha .25.
  final double dailyRate;
  final double onHand; // packs currently on hand

  bool get confident => confirmedIntervals >= 3;

  BeverageProfile copyWith({
    double? servingsPerDay,
    int? confirmedIntervals,
    double? dailyRate,
    double? onHand,
  }) => BeverageProfile(
    beverageId: beverageId,
    servingsPerDay: servingsPerDay ?? this.servingsPerDay,
    confirmedIntervals: confirmedIntervals ?? this.confirmedIntervals,
    dailyRate: dailyRate ?? this.dailyRate,
    onHand: onHand ?? this.onHand,
  );
}

// ---------- Voting ----------

enum VoteRoundStatus { open, closed }

class VoteRound {
  const VoteRound({
    required this.id,
    required this.title,
    required this.optionIds,
    required this.closesAt,
    required this.createdAt,
    this.status = VoteRoundStatus.open,
    this.votes = const {},
    this.winnerId,
    this.seenBy = const {},
  });

  final String id;
  final String title;
  final List<String> optionIds; // recipe ids, all safety-filtered
  final DateTime closesAt;
  final DateTime createdAt;
  final VoteRoundStatus status;

  /// memberId -> recipeId. One vote per member; changeable until close.
  final Map<String, String> votes;
  final String? winnerId;

  /// Members who opened the ballot. Absence is neutral, never a dislike.
  final Set<String> seenBy;

  bool isExpired(DateTime now) =>
      status == VoteRoundStatus.open && now.isAfter(closesAt);

  VoteRound copyWith({
    VoteRoundStatus? status,
    Map<String, String>? votes,
    String? winnerId,
    Set<String>? seenBy,
  }) => VoteRound(
    id: id,
    title: title,
    optionIds: optionIds,
    closesAt: closesAt,
    createdAt: createdAt,
    status: status ?? this.status,
    votes: votes ?? this.votes,
    winnerId: winnerId ?? this.winnerId,
    seenBy: seenBy ?? this.seenBy,
  );
}

// ---------- Games / rewards ----------

enum GameSessionState {
  available,
  inProgress,
  completed,
  awarded,
  expired,
  blockedSafety,
}

class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.quotaPerWindow,
    required this.window,
    this.minAge = AgeBand.a5to8,
  });

  final String id;
  final String title;
  final String summary;
  final String icon; // semantic icon key, not emoji
  final int quotaPerWindow;
  final Duration window;
  final AgeBand minAge;
}

class GameSession {
  const GameSession({
    required this.id,
    required this.gameId,
    required this.startedAt,
    this.state = GameSessionState.inProgress,
    this.score = 0,
  });

  final String id;
  final String gameId;
  final DateTime startedAt;
  final GameSessionState state;
  final int score; // bounded 0-100

  GameSession copyWith({GameSessionState? state, int? score}) => GameSession(
    id: id,
    gameId: gameId,
    startedAt: startedAt,
    state: state ?? this.state,
    score: score ?? this.score,
  );
}

class Badge {
  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.earnedAt,
    required this.gameId,
  });

  /// (circleId, sessionId, rewardType) derived unique id - award only once.
  final String id;
  final String title;
  final String description;
  final DateTime earnedAt;
  final String gameId;
}

// ---------- Entitlements ----------

enum EntitlementPlan { free, plus, familyPro }

extension EntitlementPlanInfo on EntitlementPlan {
  String get label => switch (this) {
    EntitlementPlan.free => 'Free',
    EntitlementPlan.plus => 'Plus',
    EntitlementPlan.familyPro => 'Family Pro',
  };

  int get monthlyCents => switch (this) {
    EntitlementPlan.free => 0,
    EntitlementPlan.plus => 399,
    EntitlementPlan.familyPro => 699,
  };

  /// Game quota multiplier over free tier.
  int get quotaMultiplier => switch (this) {
    EntitlementPlan.free => 1,
    EntitlementPlan.plus => 3,
    EntitlementPlan.familyPro => 5,
  };
}

class Entitlement {
  const Entitlement({
    this.plan = EntitlementPlan.free,
    this.effectiveAt,
    this.expiresAt,
    this.providerReference,
    this.verified = true,
    this.cancelAtPeriodEnd = false,
  });

  final EntitlementPlan plan;
  final DateTime? effectiveAt;
  final DateTime? expiresAt;
  final String? providerReference;
  final bool verified;
  final bool cancelAtPeriodEnd;

  bool get isPaid => plan != EntitlementPlan.free;
}

// ---------- Feedback / learning ----------

class LearningSignal {
  const LearningSignal({
    required this.recipeId,
    this.score = 0,
    this.evidence = const [],
  });

  final String recipeId;

  /// -1..1 taste estimate; only explicit events move it (see update rules).
  final double score;
  final List<String> evidence; // event type names, most recent last

  LearningSignal copyWith({double? score, List<String>? evidence}) =>
      LearningSignal(
        recipeId: recipeId,
        score: score ?? this.score,
        evidence: evidence ?? this.evidence,
      );
}

class TasteFeedback {
  const TasteFeedback({
    required this.recipeId,
    required this.value,
    this.reason,
    required this.at,
  });

  final String recipeId;
  final String value; // 'like' | 'dislike' | 'cooked'
  final String? reason;
  final DateTime at;
}

// ---------- Events ----------

class AppEvent {
  const AppEvent({
    required this.id,
    required this.type,
    this.actorId,
    this.objectType,
    this.objectId,
    required this.at,
    this.meta = const {},
  });

  final String id;
  final String type;
  final String? actorId;
  final String? objectType;
  final String? objectId;
  final DateTime at;
  final Map<String, String> meta;
}

// ---------- Consent / notifications / privacy ----------

class ConsentFlags {
  const ConsentFlags({
    this.analytics = true,
    this.personalization = true,
    this.aiProcessing = false,
  });

  final bool analytics;
  final bool personalization;
  final bool aiProcessing;

  ConsentFlags copyWith({
    bool? analytics,
    bool? personalization,
    bool? aiProcessing,
  }) => ConsentFlags(
    analytics: analytics ?? this.analytics,
    personalization: personalization ?? this.personalization,
    aiProcessing: aiProcessing ?? this.aiProcessing,
  );
}

class NotificationPrefs {
  const NotificationPrefs({
    this.pushEnabled = false,
    this.emailEnabled = false,
    this.tripReminders = true,
    this.voteReminders = true,
    this.pantryExpiry = true,
    this.mealPrep = false,
    this.quietStartHour = 21,
    this.quietEndHour = 8,
    this.minorOptIn = false,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final bool tripReminders;
  final bool voteReminders;
  final bool pantryExpiry;
  final bool mealPrep;
  final int quietStartHour;
  final int quietEndHour;

  /// Parent-controlled; minors get at most 1/week and only quest reminders.
  final bool minorOptIn;

  NotificationPrefs copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? tripReminders,
    bool? voteReminders,
    bool? pantryExpiry,
    bool? mealPrep,
    int? quietStartHour,
    int? quietEndHour,
    bool? minorOptIn,
  }) => NotificationPrefs(
    pushEnabled: pushEnabled ?? this.pushEnabled,
    emailEnabled: emailEnabled ?? this.emailEnabled,
    tripReminders: tripReminders ?? this.tripReminders,
    voteReminders: voteReminders ?? this.voteReminders,
    pantryExpiry: pantryExpiry ?? this.pantryExpiry,
    mealPrep: mealPrep ?? this.mealPrep,
    quietStartHour: quietStartHour ?? this.quietStartHour,
    quietEndHour: quietEndHour ?? this.quietEndHour,
    minorOptIn: minorOptIn ?? this.minorOptIn,
  );
}

class PendingWrite {
  const PendingWrite({
    required this.id,
    required this.description,
    required this.queuedAt,
    this.action,
    this.params = const {},
  });

  final String id;
  final String description;
  final DateTime queuedAt;

  /// Machine-readable action replayed on reconnect, e.g. 'grocery_check'.
  final String? action;

  /// JSON-serializable arguments for [action].
  final Map<String, Object?> params;
}

class FavoriteEntry {
  const FavoriteEntry({
    required this.recipeId,
    required this.addedAt,
    this.privateNote,
  });

  final String recipeId;
  final DateTime addedAt;
  final String? privateNote;
}

enum ShareStatus { privateOnly, pendingReview, published }

class VaultEntry {
  const VaultEntry({
    required this.recipeId,
    this.cookedCount = 0,
    this.lastCooked,
    this.shareStatus = ShareStatus.privateOnly,
  });

  final String recipeId;
  final int cookedCount;
  final DateTime? lastCooked;
  final ShareStatus shareStatus;

  VaultEntry copyWith({
    int? cookedCount,
    DateTime? lastCooked,
    ShareStatus? shareStatus,
  }) => VaultEntry(
    recipeId: recipeId,
    cookedCount: cookedCount ?? this.cookedCount,
    lastCooked: lastCooked ?? this.lastCooked,
    shareStatus: shareStatus ?? this.shareStatus,
  );
}

class QuestObjective {
  const QuestObjective({
    required this.id,
    required this.title,
    this.done = false,
    this.adultApproved = false,
  });

  final String id;
  final String title;
  final bool done;

  /// Minors' completions need adult approval per family-food-quest contract.
  final bool adultApproved;

  QuestObjective copyWith({bool? done, bool? adultApproved}) => QuestObjective(
    id: id,
    title: title,
    done: done ?? this.done,
    adultApproved: adultApproved ?? this.adultApproved,
  );
}
