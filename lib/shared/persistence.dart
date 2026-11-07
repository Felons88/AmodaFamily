/// JSON codecs for AppStore state snapshots — local (shared_preferences)
/// and remote (Supabase app_snapshots) persistence share this format.
library;

import 'models.dart';

// ---------- primitives ----------

Map<String, dynamic> qtyJson(FoodQuantity q) => {'a': q.amount, 'u': q.unit.name};
FoodQuantity qtyFrom(Map<String, dynamic> j) =>
    FoodQuantity(j['a'] as int, FoodUnit.values.byName(j['u'] as String));

String? dtJson(DateTime? d) => d?.toIso8601String();
DateTime? dtFrom(dynamic s) => s == null ? null : DateTime.parse(s as String);

Map<String, dynamic> offerJson(PriceOffer o) => {
      'i': o.ingredientId,
      'p': qtyJson(o.packSize),
      'c': o.estimatedCents,
      's': o.source,
      'o': o.observedAt.toIso8601String(),
      'r': o.region,
      'f': o.confidence,
      'cur': o.currency,
      'b': o.benefitEligibility.name,
    };
PriceOffer offerFrom(Map<String, dynamic> j) => PriceOffer(
      ingredientId: j['i'] as String,
      packSize: qtyFrom(j['p'] as Map<String, dynamic>),
      estimatedCents: j['c'] as int,
      source: j['s'] as String,
      observedAt: DateTime.parse(j['o'] as String),
      region: j['r'] as String,
      confidence: (j['f'] as num).toDouble(),
      currency: j['cur'] as String? ?? 'USD',
      benefitEligibility: BenefitEligibility.values.byName(j['b'] as String),
    );

Map<String, dynamic> basketJson(BasketEstimate b) => {
      'lines': [
        for (final l in b.lines)
          {
            'i': l.ingredientId,
            'r': qtyJson(l.required),
            'd': qtyJson(l.pantryDeducted),
            'p': l.packs,
            'o': offerJson(l.offer),
            'c': l.estimatedCents,
          }
      ],
      'u': b.unknownPriceIngredientIds,
      't': b.totalEstimateCents,
      'e': b.eligibleBenefitEstimateCents,
      'x': b.unverifiedBenefitEstimateCents,
    };
BasketEstimate basketFrom(Map<String, dynamic> j) => BasketEstimate(
      lines: [
        for (final l in (j['lines'] as List))
          BasketLine(
            ingredientId: l['i'] as String,
            required: qtyFrom(l['r'] as Map<String, dynamic>),
            pantryDeducted: qtyFrom(l['d'] as Map<String, dynamic>),
            packs: l['p'] as int,
            offer: offerFrom(l['o'] as Map<String, dynamic>),
            estimatedCents: l['c'] as int,
          )
      ],
      unknownPriceIngredientIds:
          (j['u'] as List).cast<String>(),
      totalEstimateCents: j['t'] as int,
      eligibleBenefitEstimateCents: j['e'] as int,
      unverifiedBenefitEstimateCents: j['x'] as int,
    );

// ---------- domain models ----------

Map<String, dynamic> memberJson(CircleMember m) => {
      'id': m.id,
      'n': m.name,
      'r': m.role.name,
      'a': m.ageBand.name,
      'v': m.adultVerified,
      'h': m.hardAllergens.toList(),
      'act': m.active,
    };
CircleMember memberFrom(Map<String, dynamic> j) => CircleMember(
      id: j['id'] as String,
      name: j['n'] as String,
      role: MemberRole.values.byName(j['r'] as String),
      ageBand: AgeBand.values.byName(j['a'] as String),
      adultVerified: j['v'] as bool? ?? false,
      hardAllergens: (j['h'] as List?)?.cast<String>().toSet() ?? const {},
      active: j['act'] as bool? ?? true,
    );

Map<String, dynamic> circleJson(Circle c) => {
      'id': c.id,
      'n': c.name,
      'm': [for (final m in c.members) memberJson(m)],
    };
Circle circleFrom(Map<String, dynamic> j) => Circle(
      id: j['id'] as String,
      name: j['n'] as String,
      members: [for (final m in (j['m'] as List)) memberFrom(m as Map<String, dynamic>)],
    );

Map<String, dynamic> planJson(WeekPlan p) => {
      'id': p.id,
      'rev': p.revision,
      'ws': p.weekStart.toIso8601String(),
      'slots': [
        for (final s in p.slots) {'d': s.day, 'm': s.meal.name, 'r': s.recipeId}
      ],
      'st': p.status.name,
      if (p.basket != null) 'b': basketJson(p.basket!),
      'rej': {for (final e in p.rejectedCodes.entries) e.key: e.value.name},
    };
WeekPlan planFrom(Map<String, dynamic> j) => WeekPlan(
      id: j['id'] as String,
      revision: j['rev'] as int,
      weekStart: DateTime.parse(j['ws'] as String),
      slots: [
        for (final s in (j['slots'] as List))
          PlanSlot(
            day: s['d'] as int,
            meal: MealType.values.byName(s['m'] as String),
            recipeId: s['r'] as String,
          )
      ],
      status: PlanStatus.values.byName(j['st'] as String),
      basket: j['b'] == null ? null : basketFrom(j['b'] as Map<String, dynamic>),
      rejectedCodes: {
        for (final e in ((j['rej'] as Map?) ?? {}).entries)
          e.key as String: EligibilityCode.values.byName(e.value as String)
      },
    );

Map<String, dynamic> pantryJson(PantryItem p) => {
      'i': p.ingredientId,
      'q': qtyJson(p.quantity),
      'c': p.confirmed,
      'e': dtJson(p.expiresAt),
      'a': dtJson(p.addedAt),
    };
PantryItem pantryFrom(Map<String, dynamic> j) => PantryItem(
      ingredientId: j['i'] as String,
      quantity: qtyFrom(j['q'] as Map<String, dynamic>),
      confirmed: j['c'] as bool? ?? false,
      expiresAt: dtFrom(j['e']),
      addedAt: dtFrom(j['a']),
    );

Map<String, dynamic> groceryJson(GroceryLine g) => {
      'i': g.ingredientId,
      'n': g.name,
      'rq': qtyJson(g.requiredQty),
      'pd': qtyJson(g.pantryDeducted),
      'p': g.packs,
      if (g.offer != null) 'o': offerJson(g.offer!),
      'c': g.estimatedCents,
      'ck': g.checked,
    };
GroceryLine groceryFrom(Map<String, dynamic> j) => GroceryLine(
      ingredientId: j['i'] as String,
      name: j['n'] as String,
      requiredQty: qtyFrom(j['rq'] as Map<String, dynamic>),
      pantryDeducted: qtyFrom(j['pd'] as Map<String, dynamic>),
      packs: j['p'] as int,
      offer: j['o'] == null ? null : offerFrom(j['o'] as Map<String, dynamic>),
      estimatedCents: j['c'] as int?,
      checked: j['ck'] as bool? ?? false,
    );

Map<String, dynamic> tripJson(ShoppingTrip t) => {
      'id': t.id,
      'd': t.date.toIso8601String(),
      'items': [
        for (final i in t.items)
          {'i': i.ingredientId, 'p': i.packs, 'c': i.actualCents}
      ],
      't': t.totalCents,
      's': t.snapCents,
      'ca': t.cashCents,
    };
ShoppingTrip tripFrom(Map<String, dynamic> j) => ShoppingTrip(
      id: j['id'] as String,
      date: DateTime.parse(j['d'] as String),
      items: [
        for (final i in (j['items'] as List))
          PurchasedItem(
            ingredientId: i['i'] as String,
            packs: i['p'] as int,
            actualCents: i['c'] as int,
          )
      ],
      totalCents: j['t'] as int,
      snapCents: j['s'] as int,
      cashCents: j['ca'] as int,
    );

Map<String, dynamic> budgetJson(BudgetCycle b) => {
      'c': b.cashCents,
      's': b.snapCents,
      'dd': b.depositDay,
      'sc': b.spentCashCents,
      'ss': b.spentSnapCents,
    };
BudgetCycle budgetFrom(Map<String, dynamic> j) => BudgetCycle(
      cashCents: j['c'] as int? ?? 0,
      snapCents: j['s'] as int? ?? 0,
      depositDay: j['dd'] as int?,
      spentCashCents: j['sc'] as int? ?? 0,
      spentSnapCents: j['ss'] as int? ?? 0,
    );

Map<String, dynamic> beverageJson(BeverageProfile b) => {
      'b': b.beverageId,
      's': b.servingsPerDay,
      'ci': b.confirmedIntervals,
      'dr': b.dailyRate,
      'oh': b.onHand,
    };
BeverageProfile beverageFrom(Map<String, dynamic> j) => BeverageProfile(
      beverageId: j['b'] as String,
      servingsPerDay: (j['s'] as num?)?.toDouble() ?? 1,
      confirmedIntervals: j['ci'] as int? ?? 0,
      dailyRate: (j['dr'] as num?)?.toDouble() ?? 0,
      onHand: (j['oh'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> voteJson(VoteRound v) => {
      'id': v.id,
      't': v.title,
      'o': v.optionIds,
      'cl': v.closesAt.toIso8601String(),
      'cr': v.createdAt.toIso8601String(),
      'st': v.status.name,
      'v': v.votes,
      'w': v.winnerId,
      'seen': v.seenBy.toList(),
    };
VoteRound voteFrom(Map<String, dynamic> j) => VoteRound(
      id: j['id'] as String,
      title: j['t'] as String,
      optionIds: (j['o'] as List).cast<String>(),
      closesAt: DateTime.parse(j['cl'] as String),
      createdAt: DateTime.parse(j['cr'] as String),
      status: VoteRoundStatus.values.byName(j['st'] as String),
      votes: (j['v'] as Map?)?.cast<String, String>() ?? const {},
      winnerId: j['w'] as String?,
      seenBy: (j['seen'] as List?)?.cast<String>().toSet() ?? const {},
    );

Map<String, dynamic> sessionJson(GameSession g) => {
      'id': g.id,
      'g': g.gameId,
      'st': g.startedAt.toIso8601String(),
      's': g.state.name,
      'sc': g.score,
    };
GameSession sessionFrom(Map<String, dynamic> j) => GameSession(
      id: j['id'] as String,
      gameId: j['g'] as String,
      startedAt: DateTime.parse(j['st'] as String),
      state: GameSessionState.values.byName(j['s'] as String),
      score: j['sc'] as int? ?? 0,
    );

Map<String, dynamic> badgeJson(Badge b) => {
      'id': b.id,
      't': b.title,
      'd': b.description,
      'e': b.earnedAt.toIso8601String(),
      'g': b.gameId,
    };
Badge badgeFrom(Map<String, dynamic> j) => Badge(
      id: j['id'] as String,
      title: j['t'] as String,
      description: j['d'] as String,
      earnedAt: DateTime.parse(j['e'] as String),
      gameId: j['g'] as String,
    );

Map<String, dynamic> entitlementJson(Entitlement e) => {
      'p': e.plan.name,
      'ea': dtJson(e.effectiveAt),
      'ex': dtJson(e.expiresAt),
      'pr': e.providerReference,
      'v': e.verified,
      'c': e.cancelAtPeriodEnd,
    };
Entitlement entitlementFrom(Map<String, dynamic> j) => Entitlement(
      plan: EntitlementPlan.values.byName(j['p'] as String? ?? 'free'),
      effectiveAt: dtFrom(j['ea']),
      expiresAt: dtFrom(j['ex']),
      providerReference: j['pr'] as String?,
      verified: j['v'] as bool? ?? true,
      cancelAtPeriodEnd: j['c'] as bool? ?? false,
    );

Map<String, dynamic> learningJson(LearningSignal l) => {
      'r': l.recipeId,
      's': l.score,
      'e': l.evidence,
    };
LearningSignal learningFrom(Map<String, dynamic> j) => LearningSignal(
      recipeId: j['r'] as String,
      score: (j['s'] as num?)?.toDouble() ?? 0,
      evidence: (j['e'] as List?)?.cast<String>() ?? const [],
    );

Map<String, dynamic> feedbackJson(TasteFeedback f) => {
      'r': f.recipeId,
      'v': f.value,
      're': f.reason,
      'at': f.at.toIso8601String(),
    };
TasteFeedback feedbackFrom(Map<String, dynamic> j) => TasteFeedback(
      recipeId: j['r'] as String,
      value: j['v'] as String,
      reason: j['re'] as String?,
      at: DateTime.parse(j['at'] as String),
    );

Map<String, dynamic> notifJson(NotificationPrefs n) => {
      'pe': n.pushEnabled,
      'ee': n.emailEnabled,
      'tr': n.tripReminders,
      'vr': n.voteReminders,
      'px': n.pantryExpiry,
      'mp': n.mealPrep,
      'qs': n.quietStartHour,
      'qe': n.quietEndHour,
      'mo': n.minorOptIn,
    };
NotificationPrefs notifFrom(Map<String, dynamic> j) => NotificationPrefs(
      pushEnabled: j['pe'] as bool? ?? false,
      emailEnabled: j['ee'] as bool? ?? false,
      tripReminders: j['tr'] as bool? ?? true,
      voteReminders: j['vr'] as bool? ?? true,
      pantryExpiry: j['px'] as bool? ?? true,
      mealPrep: j['mp'] as bool? ?? false,
      quietStartHour: j['qs'] as int? ?? 21,
      quietEndHour: j['qe'] as int? ?? 8,
      minorOptIn: j['mo'] as bool? ?? false,
    );

Map<String, dynamic> pendingJson(PendingWrite p) => {
      'id': p.id,
      'd': p.description,
      'q': p.queuedAt.toIso8601String(),
    };
PendingWrite pendingFrom(Map<String, dynamic> j) => PendingWrite(
      id: j['id'] as String,
      description: j['d'] as String,
      queuedAt: DateTime.parse(j['q'] as String),
    );

Map<String, dynamic> favJson(FavoriteEntry f) => {
      'r': f.recipeId,
      'a': f.addedAt.toIso8601String(),
      'n': f.privateNote,
    };
FavoriteEntry favFrom(Map<String, dynamic> j) => FavoriteEntry(
      recipeId: j['r'] as String,
      addedAt: DateTime.parse(j['a'] as String),
      privateNote: j['n'] as String?,
    );

Map<String, dynamic> vaultJson(VaultEntry v) => {
      'r': v.recipeId,
      'c': v.cookedCount,
      'l': dtJson(v.lastCooked),
      's': v.shareStatus.name,
    };
VaultEntry vaultFrom(Map<String, dynamic> j) => VaultEntry(
      recipeId: j['r'] as String,
      cookedCount: j['c'] as int? ?? 0,
      lastCooked: dtFrom(j['l']),
      shareStatus: ShareStatus.values.byName(j['s'] as String? ?? 'privateOnly'),
    );

Map<String, dynamic> questJson(QuestObjective q) => {
      'id': q.id,
      't': q.title,
      'd': q.done,
      'ap': q.adultApproved,
    };
QuestObjective questFrom(Map<String, dynamic> j) => QuestObjective(
      id: j['id'] as String,
      title: j['t'] as String,
      done: j['d'] as bool? ?? false,
      adultApproved: j['ap'] as bool? ?? false,
    );
