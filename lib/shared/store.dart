/// Local backend implementing the Family Circle server contract.
///
/// Every mutating method enforces the same rules the Supabase RPC layer is
/// specified to enforce: active membership, adult verification for privileged
/// writes, hard-allergen fail-closed filtering via `safety_engine`, basket
/// math via `planner_engine`, per-circle quotas, idempotent awards, consent
/// gating for events, and honest price provenance. Data lives in memory for
/// this demo build; the method surface mirrors the endpoint contracts in
/// docs/contracts/endpoints/.
library;

import 'package:family_circle_planner_engine/planner_engine.dart';
import 'package:family_circle_safety_engine/safety_engine.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart' as catalog;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'errors.dart';
import 'persistence.dart';
import 'models.dart';

/// Actions that are safe to queue while offline (idempotent, low risk).
/// Values are the `action` strings stored on PendingWrite for replay.
abstract final class QueueAction {
  static const groceryCheck = 'grocery_check';
  static const pantryAdd = 'pantry_add';
  static const pantryAdjust = 'pantry_adjust';
}

class AppStore extends ChangeNotifier {
  /// Set by the app shell once the store exists so Supabase auth events can
  /// sync into it without a provider dependency.
  static AppStore? instanceFromAuth;
  // ---------- session ----------
  AppStore() {
    unawaited(_restore());
  }

  String? _userEmail;
  Circle? _circle;
  String? _actorId;
  bool _offline = false;
  ConsentFlags _consent = const ConsentFlags();

  // ---------- data ----------
  WeekPlan? _plan;
  int _planSerial = 0;
  BudgetCycle _budget = const BudgetCycle();
  List<PantryItem> _pantry = [];
  List<GroceryLine> _groceryList = [];
  List<ShoppingTrip> _trips = [];
  List<VoteRound> _voteRounds = [];
  List<GameSession> _gameSessions = [];
  List<Badge> _badges = [];
  Entitlement _entitlement = const Entitlement();
  List<BeverageProfile> _beverages = [];
  Map<String, LearningSignal> _learning = {};
  List<TasteFeedback> _feedback = [];
  List<AppEvent> _events = [];
  NotificationPrefs _notifPrefs = const NotificationPrefs();
  List<PendingWrite> _pending = [];
  List<FavoriteEntry> _favorites = [];
  Map<String, VaultEntry> _vault = {};
  List<QuestObjective> _quest = [];
  int _serial = 0;
  int _shoppingIntervalDays = 7;

  /// Prices learned from confirmed trips (actual spend per pack). These
  /// replace the labeled sample estimates for ingredients the household
  /// has actually bought — real data beats catalog samples over time.
  Map<String, PriceOffer> _priceMemory = {};
  Map<String, PriceOffer> get priceMemory => Map.unmodifiable(_priceMemory);

  /// Junior-chef lesson indexes completed by the household.
  Set<int> _chefDone = {};
  Set<int> get chefLessonsDone => Set.unmodifiable(_chefDone);

  void completeChefLesson(int index) {
    _requireCircle();
    if (_chefDone.contains(index)) return;
    _chefDone = {..._chefDone, index};
    emit('chef_lesson_done', objectType: 'lesson', objectId: '$index');
    notifyListeners();
  }

  /// Offers used for estimates: sample catalog offers except where the
  /// household has a learned actual price for that ingredient.
  List<PriceOffer> get _offers => [
    for (final o in catalog.priceOffers)
      if (!_priceMemory.containsKey(o.ingredientId)) o,
    ..._priceMemory.values,
  ];

  String _nextId(String prefix) => '$prefix-${++_serial}';

  // ---------- getters ----------
  bool get isSignedIn => _userEmail != null;
  bool get isOffline => _offline;
  Circle? get circle => _circle;
  ConsentFlags get consent => _consent;
  WeekPlan? get plan => _plan;
  BudgetCycle get budget => _budget;
  List<PantryItem> get pantry => List.unmodifiable(_pantry);
  List<GroceryLine> get groceryList => List.unmodifiable(_groceryList);
  List<ShoppingTrip> get trips => List.unmodifiable(_trips);
  List<VoteRound> get voteRounds => List.unmodifiable(_voteRounds);
  List<GameSession> get gameSessions => List.unmodifiable(_gameSessions);
  List<Badge> get badges => List.unmodifiable(_badges);
  Entitlement get entitlement => _entitlement;
  List<BeverageProfile> get beverages => List.unmodifiable(_beverages);
  Map<String, LearningSignal> get learning => Map.unmodifiable(_learning);
  List<TasteFeedback> get feedback => List.unmodifiable(_feedback);
  List<AppEvent> get events => List.unmodifiable(_events);
  NotificationPrefs get notifPrefs => _notifPrefs;
  List<PendingWrite> get pending => List.unmodifiable(_pending);
  List<FavoriteEntry> get favorites => List.unmodifiable(_favorites);
  Map<String, VaultEntry> get vault => Map.unmodifiable(_vault);
  List<QuestObjective> get quest => List.unmodifiable(_quest);
  int get shoppingIntervalDays => _shoppingIntervalDays;

  CircleMember? get actor {
    final id = _actorId;
    if (id == null || _circle == null) return null;
    for (final m in _circle!.members) {
      if (m.id == id && m.active) return m;
    }
    return null;
  }

  bool get actorIsMinor => actor?.isMinor ?? false;
  bool get showPrices => !actorIsMinor; // children never see money surfaces

  // ---------- guards (server-side equivalents) ----------

  void _requireAuth() {
    if (!isSignedIn) throw const FcException(FcErrorCode.authRequired);
  }

  Circle _requireCircle() {
    _requireAuth();
    final c = _circle;
    if (c == null) throw const FcException(FcErrorCode.circleForbidden);
    return c;
  }

  void _requireAdult() {
    _requireCircle();
    final a = actor;
    if (a == null || !a.isAdult) throw const FcException(FcErrorCode.adultOnly);
  }

  void _requireOnline() {
    if (_offline) throw const FcException(FcErrorCode.offlineNotSupported);
  }

  void _queue(
    String action,
    String description, [
    Map<String, Object?> params = const {},
  ]) {
    _pending = [
      ..._pending,
      PendingWrite(
        id: _nextId('pw'),
        description: description,
        queuedAt: DateTime.now(),
        action: action,
        params: params,
      ),
    ];
    notifyListeners();
  }

  // ---------- events (privacy-minimized, consent-gated) ----------

  void emit(
    String type, {
    String? objectType,
    String? objectId,
    Map<String, String> meta = const {},
  }) {
    if (!_consent.analytics) return;
    _events = [
      ..._events,
      AppEvent(
        id: _nextId('ev'),
        type: type,
        actorId: _actorId,
        objectType: objectType,
        objectId: objectId,
        at: DateTime.now(),
        meta: meta,
      ),
    ];
  }

  // ---------- auth & session ----------

  String? get displayName => _displayName;
  String? get userEmail => _userEmail;
  String? _displayName;
  bool _googleAuth = false;
  bool get usedGoogleAuth => _googleAuth;

  Future<void> signIn(
    String email,
    String password, {
    bool create = false,
    String? name,
  }) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw const FcException(FcErrorCode.validation, 'Enter a valid email.');
    }
    if (password.length < 8) {
      throw const FcException(
        FcErrorCode.validation,
        'Password needs at least 8 characters.',
      );
    }
    if (create && (name == null || name.trim().isEmpty)) {
      throw const FcException(FcErrorCode.validation, 'Enter your name.');
    }
    if (Supabase.instance.isInitialized) {
      try {
        if (create) {
          final res = await Supabase.instance.client.auth.signUp(
            email: email.trim(),
            password: password,
            data: {
              if (name != null && name.trim().isNotEmpty)
                'full_name': name.trim(),
            },
          );
          var session = res.session;
          session ??= (await Supabase.instance.client.auth.signInWithPassword(
            email: email.trim(),
            password: password,
          )).session;
          if (session == null) {
            throw const FcException(
              FcErrorCode.validation,
              'Account created — check your email to confirm, then sign in.',
            );
          }
          syncSupabaseSession(session);
        } else {
          final res = await Supabase.instance.client.auth.signInWithPassword(
            email: email.trim(),
            password: password,
          );
          syncSupabaseSession(res.session);
        }
        emit(create ? 'account_created' : 'signed_in');
        notifyListeners();
        return;
      } on FcException {
        rethrow;
      } catch (_) {
        throw const FcException(
          FcErrorCode.authRequired,
          'Could not sign in. Check your details and connection.',
        );
      }
    }
    // Local-only fallback: Supabase not configured (tests, unconfigured builds).
    _userEmail = email.trim();
    _displayName = name?.trim();
    _googleAuth = false;
    emit(create ? 'account_created' : 'signed_in');
    notifyListeners();
  }

  /// Google sign-in via Supabase OAuth. The session arrives through the
  /// deep-link redirect -> onAuthStateChange -> syncSupabaseSession; the
  /// router then sends the user into onboarding automatically.
  Future<void> signInWithGoogle({String? name}) async {
    if (!Supabase.instance.isInitialized) {
      throw const FcException(
        FcErrorCode.validation,
        'Google sign-in needs a connection right now.',
      );
    }
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.amoda.kinplora://login-callback',
      );
    } catch (_) {
      throw const FcException(
        FcErrorCode.authRequired,
        'Google sign-in could not start. Check your connection.',
      );
    }
  }

  /// Called once when the store is created — picks up any session that
  /// already exists (e.g. app reopened after sign-in).
  void restoreSupabaseSession() {
    try {
      syncSupabaseSession(Supabase.instance.client.auth.currentSession);
    } catch (_) {}
  }

  /// Supabase user id used to scope cloud snapshots; null for local-only
  /// sessions (demo, unconfigured builds) which never touch remote state.
  String? _supabaseUserId;

  void syncSupabaseSession(Session? session) {
    final email = session?.user.email;
    if (session == null || email == null || email.isEmpty) {
      // Real sign-out / expired session: only act if we had a Supabase
      // identity — never wipe a local-only account on a null session.
      if (_supabaseUserId != null) signOut();
      return;
    }
    final accountChanged = _userEmail != null && _userEmail != email;
    if (accountChanged) _clearLocalState();
    final wasSignedOut = _userEmail == null;
    _supabaseUserId = session.user.id;
    _userEmail = email;
    _displayName ??=
        session.user.userMetadata?['full_name'] as String? ??
        session.user.userMetadata?['name'] as String?;
    _googleAuth = session.user.appMetadata['provider'] == 'google';
    if (wasSignedOut || accountChanged) {
      _remoteReady = false;
      unawaited(_restoreRemote());
    }
    if (wasSignedOut) emit('signed_in', meta: {'provider': 'supabase'});
    notifyListeners();
  }

  void signInDemo() {
    _supabaseUserId = null;
    _userEmail = 'demo@familycircle.local';
    _seedDemoHousehold();
    emit('signed_in', meta: {'mode': 'demo'});
    notifyListeners();
  }

  /// Whether the current session is the seeded demo household.
  bool get isDemoMode => _userEmail == 'demo@familycircle.local';

  void signOut() {
    _supabaseUserId = null;
    try {
      if (Supabase.instance.isInitialized) {
        unawaited(Supabase.instance.client.auth.signOut());
      }
    } catch (_) {}
    _clearLocalState();
    notifyListeners();
  }

  void _clearLocalState() {
    _userEmail = null;
    _displayName = null;
    _googleAuth = false;
    _circle = null;
    _actorId = null;
    _plan = null;
    _pantry = [];
    _groceryList = [];
    _trips = [];
    _voteRounds = [];
    _gameSessions = [];
    _badges = [];
    _entitlement = const Entitlement();
    _beverages = [];
    _learning = {};
    _feedback = [];
    _events = [];
    _pending = [];
    _favorites = [];
    _vault = {};
    _quest = [];
    _chefDone = {};
    _priceMemory = {};
    _budget = const BudgetCycle();
    _consent = const ConsentFlags();
    _notifPrefs = const NotificationPrefs();
    _offline = false;
    _lastSavedAt = null;
  }

  /// Updates the signed-in adult's display name (account settings).
  void updateDisplayName(String name) {
    _requireAuth();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const FcException(FcErrorCode.validation, 'Enter your name.');
    }
    _displayName = trimmed;
    notifyListeners();
  }

  void switchActor(String memberId) {
    final c = _requireCircle();
    final m = c.members.where((m) => m.id == memberId && m.active).firstOrNull;
    if (m == null) throw const FcException(FcErrorCode.circleForbidden);
    _actorId = memberId;
    emit('profile_switched');
    notifyListeners();
  }

  void setOffline(bool value) {
    _offline = value;
    if (!value && _pending.isNotEmpty) {
      _replayPending();
    }
    notifyListeners();
  }

  /// Re-applies queued safe writes on reconnect. Writes that still fail
  /// (validation, missing catalog entry) stay queued so nothing is lost
  /// silently; the rest are applied through the normal code paths.
  void _replayPending() {
    final queued = List<PendingWrite>.of(_pending);
    final failed = <PendingWrite>[];
    var applied = 0;
    for (final p in queued) {
      try {
        switch (p.action) {
          case QueueAction.groceryCheck:
            toggleGrocery(p.params['ingredientId'] as String);
          case QueueAction.pantryAdd:
            addPantryItem(
              p.params['ingredientId'] as String,
              p.params['amount'] as int,
              confirmed: p.params['confirmed'] as bool? ?? true,
              expiresAt: DateTime.tryParse(
                p.params['expiresAt'] as String? ?? '',
              ),
            );
          case QueueAction.pantryAdjust:
            adjustPantry(
              p.params['ingredientId'] as String,
              p.params['amount'] as int,
            );
          default:
            failed.add(p);
            continue;
        }
        applied++;
      } catch (_) {
        failed.add(p);
      }
    }
    _pending = failed;
    emit('offline_queue_replayed', meta: {'count': '$applied'});
  }

  // ---------- circle / members ----------

  void createCircle(String name) {
    _requireAuth();
    if (name.trim().isEmpty) {
      throw const FcException(
        FcErrorCode.validation,
        'Give your household a name.',
      );
    }
    final owner = CircleMember(
      id: _nextId('m'),
      name: _displayName ?? _userEmail!.split('@').first,
      role: MemberRole.owner,
      ageBand: AgeBand.adult,
      adultVerified: true,
    );
    _circle = Circle(
      id: _nextId('circle'),
      name: name.trim(),
      members: [owner],
    );
    _actorId = owner.id;
    emit('circle_created', objectType: 'circle', objectId: _circle!.id);
    notifyListeners();
  }

  void addMember(
    String name, {
    required bool minor,
    AgeBand band = AgeBand.a9to12,
  }) {
    _requireAdult();
    if (name.trim().isEmpty) {
      throw const FcException(FcErrorCode.validation, 'Enter a name.');
    }
    final c = _circle!;
    if (c.activeMembers.length >= 12) {
      throw const FcException(
        FcErrorCode.validation,
        'Households support up to 12 members.',
      );
    }
    final member = CircleMember(
      id: _nextId('m'),
      name: name.trim(),
      role: minor ? MemberRole.minor : MemberRole.adult,
      ageBand: minor ? band : AgeBand.adult,
      adultVerified: !minor,
    );
    _circle = Circle(id: c.id, name: c.name, members: [...c.members, member]);
    emit(
      minor ? 'managed_minor_added' : 'member_added',
      objectType: 'member',
      objectId: member.id,
    );
    notifyListeners();
  }

  void removeMember(String memberId) {
    _requireAdult();
    final c = _circle!;
    final target = c.members.where((m) => m.id == memberId).firstOrNull;
    if (target == null) throw const FcException(FcErrorCode.circleForbidden);
    if (target.role == MemberRole.owner) {
      throw const FcException(
        FcErrorCode.validation,
        'The household owner cannot be removed.',
      );
    }
    _circle = Circle(
      id: c.id,
      name: c.name,
      members: [
        for (final m in c.members)
          m.id == memberId ? m.copyWith(active: false) : m,
      ],
    );
    emit('member_removed', objectType: 'member', objectId: memberId);
    notifyListeners();
  }

  void setMemberAllergens(String memberId, Set<String> allergens) {
    _requireAdult();
    final c = _circle!;
    _circle = Circle(
      id: c.id,
      name: c.name,
      members: [
        for (final m in c.members)
          m.id == memberId ? m.copyWith(hardAllergens: allergens) : m,
      ],
    );
    emit('food_needs_saved', objectType: 'member', objectId: memberId);
    notifyListeners();
  }

  // ---------- budget ----------

  void setBudget({int cashCents = 0, int snapCents = 0, int? depositDay}) {
    _requireAdult();
    if (cashCents < 0 || snapCents < 0) {
      throw const FcException(
        FcErrorCode.validation,
        'Amounts cannot be negative.',
      );
    }
    if (depositDay != null && (depositDay < 1 || depositDay > 31)) {
      throw const FcException(
        FcErrorCode.validation,
        'Deposit day must be 1-31.',
      );
    }
    _budget = _budget.copyWith(
      cashCents: cashCents,
      snapCents: snapCents,
      depositDay: depositDay,
    );
    emit('budget_saved', objectType: 'budget');
    notifyListeners();
  }

  // ---------- safety / eligibility ----------

  List<EaterRestrictions> _eaters() => [
    for (final m in _requireCircle().activeMembers)
      EaterRestrictions(hardAllergens: m.hardAllergens),
  ];

  Map<String, IngredientFact> get _facts => {
    for (final e in catalog.ingredients.entries) e.key: e.value.fact,
  };

  /// Server-side equivalent: run the deterministic filter before a recipe is
  /// ever rendered as an option. Returns eligibility per recipe id.
  Map<String, EligibilityResult> eligibilityFor(
    Iterable<CatalogRecipe> pool, {
    int maxPrepMinutes = 90,
  }) {
    final eaters = _eaters();
    final facts = _facts;
    final result = <String, EligibilityResult>{};
    for (final recipe in pool) {
      result[recipe.id] = evaluateRecipe(
        recipe: RecipeCandidate(
          ingredients: [
            for (final n in recipe.needs)
              RecipeIngredient(
                ingredientId: n.ingredientId,
                isPackaged:
                    catalog.ingredients[n.ingredientId]?.isPackaged ?? false,
                brandLabelChecked:
                    catalog.ingredients[n.ingredientId]?.brandLabelChecked ??
                    false,
              ),
          ],
          timeMinutes: recipe.minutes,
        ),
        eaters: eaters,
        facts: facts,
        maxPrepMinutes: maxPrepMinutes,
      );
    }
    return result;
  }

  /// Recipes safe to *display* to this household right now. Blocked and
  /// uncertain recipes are excluded entirely (fail closed).
  List<CatalogRecipe> eligibleRecipes({MealType? meal}) {
    final pool = catalog.recipes.values.where(
      (r) => meal == null || r.meal == meal,
    );
    final checks = eligibilityFor(pool);
    return [
      for (final r in pool)
        if (checks[r.id]?.isEligible ?? false) r,
    ];
  }

  List<IngredientNeed> _needsFor(CatalogRecipe r) => [
    for (final n in r.needs)
      IngredientNeed(
        n.ingredientId,
        FoodQuantity(n.amount, catalog.ingredients[n.ingredientId]!.stockUnit),
      ),
  ];

  List<PantryStock> _pantryStock() => [
    for (final p in _pantry)
      PantryStock(p.ingredientId, p.quantity, confirmed: p.confirmed),
  ];

  // ---------- planning ----------

  /// Assembles a deterministic 7-day x 3-meal plan. Only eligible recipes are
  /// candidates; each pick must keep the cumulative basket inside budget with
  /// a complete price estimate, mirroring buildSevenDayPlan semantics while
  /// staying meal-type aware.
  WeekPlan generatePlan({int maxPrepMinutes = 60}) {
    _requireAdult();
    _requireOnline();
    final c = _requireCircle();
    final budgetCents = _budget.totalCents > 0 ? _budget.totalCents : 1000000;
    final byMeal = {
      for (final t in MealType.values)
        t:
            eligibleRecipes(meal: t)
                .where(
                  (r) =>
                      r.minutes <= maxPrepMinutes &&
                      r.servings >= c.activeMembers.length.clamp(1, 12),
                )
                .toList()
              ..sort((a, b) => a.id.compareTo(b.id)),
    };
    final rejected = <String, EligibilityCode>{};
    for (final t in MealType.values) {
      final checks = eligibilityFor(
        catalog.recipes.values.where((r) => r.meal == t),
      );
      for (final e in checks.entries) {
        if (!e.value.isEligible) rejected[e.key] = e.value.code;
      }
    }
    if (byMeal.values.any((l) => l.isEmpty)) {
      throw const FcException(
        FcErrorCode.planInfeasible,
        'Not enough verified safe recipes for every meal type.',
      );
    }
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final useCount = <String, int>{};
    final slots = <PlanSlot>[];
    var needs = <IngredientNeed>[];
    BasketEstimate? basket;
    var sawUnknownPrice = false;
    for (var day = 0; day < 7; day++) {
      for (final meal in MealType.values) {
        CatalogRecipe? chosen;
        BasketEstimate? chosenBasket;
        for (final option in byMeal[meal]!) {
          if ((useCount[option.id] ?? 0) >= 4) continue;
          final candidate = estimateBasket(
            needs: [...needs, ..._needsFor(option)],
            pantry: _pantryStock(),
            offers: _offers,
            asOf: now,
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
          throw FcException(
            sawUnknownPrice
                ? FcErrorCode.budgetEstimateUnavailable
                : FcErrorCode.planInfeasible,
          );
        }
        slots.add(PlanSlot(day: day, meal: meal, recipeId: chosen.id));
        needs.addAll(_needsFor(chosen));
        useCount[chosen.id] = (useCount[chosen.id] ?? 0) + 1;
        basket = chosenBasket;
      }
    }
    _plan = WeekPlan(
      id: _nextId('plan'),
      revision: ++_planSerial,
      weekStart: weekStart,
      slots: slots,
      status: PlanStatus.draft,
      basket: basket,
      rejectedCodes: rejected,
    );
    _buildGroceryList();
    emit('plan_generated', objectType: 'plan', objectId: _plan!.id);
    notifyListeners();
    return _plan!;
  }

  void approvePlan(int expectedRevision) {
    _requireAdult();
    final p = _plan;
    if (p == null) throw const FcException(FcErrorCode.planInfeasible);
    if (p.revision != expectedRevision) {
      throw const FcException(FcErrorCode.conflictRevision);
    }
    _plan = p.copyWith(status: PlanStatus.approved);
    emit('plan_approved', objectType: 'plan', objectId: p.id);
    notifyListeners();
  }

  /// Replace one slot with another safe recipe; bumps revision. The
  /// replacement is re-checked against the same hard filter.
  void swapSlot(int day, MealType meal, String newRecipeId) {
    _requireAdult();
    _requireOnline();
    final p = _plan;
    if (p == null) throw const FcException(FcErrorCode.planInfeasible);
    final recipe = catalog.recipes[newRecipeId];
    if (recipe == null || recipe.meal != meal) {
      throw const FcException(FcErrorCode.recipeUnverified);
    }
    final checks = eligibilityFor([recipe]);
    if (!(checks[newRecipeId]?.isEligible ?? false)) {
      throw FcException(
        checks[newRecipeId]?.code == EligibilityCode.allergenUncertain
            ? FcErrorCode.allergenUncertain
            : FcErrorCode.recipeUnverified,
      );
    }
    _plan = p.copyWith(
      revision: ++_planSerial,
      status: PlanStatus.draft,
      slots: [
        for (final s in p.slots)
          (s.day == day && s.meal == meal)
              ? s.copyWith(recipeId: newRecipeId)
              : s,
      ],
    );
    _repricePlan();
    _buildGroceryList();
    emit('plan_regenerated', objectType: 'plan', objectId: p.id);
    notifyListeners();
  }

  void _repricePlan() {
    final p = _plan;
    if (p == null) return;
    final needs = <IngredientNeed>[
      for (final s in p.slots) ..._needsFor(catalog.recipes[s.recipeId]!),
    ];
    _plan = p.copyWith(
      basket: estimateBasket(
        needs: needs,
        pantry: _pantryStock(),
        offers: _offers,
        asOf: DateTime.now(),
      ),
    );
  }

  void _buildGroceryList() {
    final p = _plan;
    if (p == null || p.basket == null) {
      _groceryList = [];
      return;
    }
    _groceryList = [
      for (final line in p.basket!.lines)
        GroceryLine(
          ingredientId: line.ingredientId,
          name:
              catalog.ingredients[line.ingredientId]?.name ?? line.ingredientId,
          requiredQty: line.required,
          pantryDeducted: line.pantryDeducted,
          packs: line.packs,
          offer: line.offer,
          estimatedCents: line.estimatedCents,
        ),
      for (final id in p.basket!.unknownPriceIngredientIds)
        GroceryLine(
          ingredientId: id,
          name: catalog.ingredients[id]?.name ?? id,
          requiredQty: const FoodQuantity(0, FoodUnit.grams),
          pantryDeducted: const FoodQuantity(0, FoodUnit.grams),
          packs: 0,
        ),
    ];
  }

  // ---------- grocery / trips ----------

  void toggleGrocery(String ingredientId) {
    _requireCircle();
    if (_offline) {
      _queue(QueueAction.groceryCheck, 'Check off $ingredientId', {
        'ingredientId': ingredientId,
      });
      return;
    }
    _groceryList = [
      for (final g in _groceryList)
        g.ingredientId == ingredientId ? g.copyWith(checked: !g.checked) : g,
    ];
    emit('grocery_checked', objectType: 'ingredient', objectId: ingredientId);
    notifyListeners();
  }

  /// Confirm a shopping trip. SNAP estimate applies only to items with
  /// verified benefit eligibility — unknown items are never claimed covered.
  ShoppingTrip confirmTrip(Map<String, int> actualCentsByIngredient) {
    _requireAdult();
    _requireOnline();
    var total = 0;
    var snap = 0;
    final items = <PurchasedItem>[];
    for (final line in _groceryList.where((g) => g.checked && g.priced)) {
      final actual =
          actualCentsByIngredient[line.ingredientId] ?? line.estimatedCents!;
      items.add(
        PurchasedItem(
          ingredientId: line.ingredientId,
          packs: line.packs,
          actualCents: actual,
        ),
      );
      total += actual;
      if (line.offer!.benefitEligibility == BenefitEligibility.eligible) {
        snap += actual;
      }
    }
    snap = snap > _budget.snapCents - _budget.spentSnapCents
        ? (_budget.snapCents - _budget.spentSnapCents).clamp(0, 1 << 31)
        : snap;
    final cash = total - snap;
    final trip = ShoppingTrip(
      id: _nextId('trip'),
      date: DateTime.now(),
      items: items,
      totalCents: total,
      snapCents: snap,
      cashCents: cash,
    );
    _trips = [..._trips, trip];
    _budget = _budget.copyWith(
      spentSnapCents: _budget.spentSnapCents + snap,
      spentCashCents: _budget.spentCashCents + cash,
    );
    // Purchased items move into confirmed pantry stock, and their actual
    // prices are learned so future estimates use real household data.
    for (final line in _groceryList.where((g) => g.checked && g.priced)) {
      final ing = catalog.ingredients[line.ingredientId];
      if (ing == null) continue;
      final packAmount = line.offer!.packSize.amount * line.packs;
      _upsertPantry(
        line.ingredientId,
        FoodQuantity(packAmount, ing.stockUnit),
        confirmed: true,
      );
      final actual =
          actualCentsByIngredient[line.ingredientId] ?? line.estimatedCents!;
      if (line.packs > 0) {
        _priceMemory = {
          ..._priceMemory,
          line.ingredientId: PriceOffer(
            ingredientId: line.ingredientId,
            packSize: line.offer!.packSize,
            estimatedCents: (actual / line.packs).round(),
            source: 'household_actual',
            observedAt: DateTime.now(),
            region: line.offer!.region,
            confidence: 0.85,
            benefitEligibility: line.offer!.benefitEligibility,
          ),
        };
      }
    }
    _groceryList = [for (final g in _groceryList) g.copyWith(checked: false)];
    emit('purchase_confirmed', objectType: 'trip', objectId: trip.id);
    notifyListeners();
    return trip;
  }

  void setShoppingInterval(int days) {
    _requireAdult();
    _shoppingIntervalDays = days.clamp(1, 30);
    notifyListeners();
  }

  // ---------- pantry ----------

  void addPantryItem(
    String ingredientId,
    int amount, {
    bool confirmed = true,
    DateTime? expiresAt,
  }) {
    _requireCircle();
    if (amount <= 0) {
      throw const FcException(
        FcErrorCode.validation,
        'Amount must be above zero.',
      );
    }
    if (catalog.ingredients[ingredientId] == null) {
      throw const FcException(
        FcErrorCode.allergenUncertain,
        'Unknown ingredients cannot be marked safe.',
      );
    }
    if (_offline) {
      _queue(QueueAction.pantryAdd, 'Add pantry $ingredientId', {
        'ingredientId': ingredientId,
        'amount': amount,
        'confirmed': confirmed,
        'expiresAt': expiresAt?.toIso8601String(),
      });
      return;
    }
    final ing = catalog.ingredients[ingredientId]!;
    _upsertPantry(
      ingredientId,
      FoodQuantity(amount, ing.stockUnit),
      confirmed: confirmed,
      expiresAt: expiresAt,
    );
    emit(
      'ingredient_depleted',
      objectType: 'ingredient',
      objectId: ingredientId,
    );
    notifyListeners();
  }

  void _upsertPantry(
    String ingredientId,
    FoodQuantity qty, {
    bool confirmed = true,
    DateTime? expiresAt,
  }) {
    final existing = _pantry
        .where((p) => p.ingredientId == ingredientId)
        .firstOrNull;
    if (existing == null) {
      _pantry = [
        ..._pantry,
        PantryItem(
          ingredientId: ingredientId,
          quantity: qty,
          confirmed: confirmed,
          expiresAt: expiresAt,
          addedAt: DateTime.now(),
        ),
      ];
    } else {
      _pantry = [
        for (final p in _pantry)
          p.ingredientId == ingredientId
              ? p.copyWith(
                  quantity: FoodQuantity(
                    existing.quantity.amount + qty.amount,
                    qty.unit,
                  ),
                  confirmed: confirmed,
                  expiresAt: expiresAt ?? p.expiresAt,
                )
              : p,
      ];
    }
    _repricePlan();
    _buildGroceryList();
  }

  void adjustPantry(String ingredientId, int newAmount) {
    _requireCircle();
    if (newAmount < 0) {
      throw const FcException(
        FcErrorCode.validation,
        'Amount cannot be negative.',
      );
    }
    if (_offline) {
      _queue(QueueAction.pantryAdjust, 'Adjust pantry $ingredientId', {
        'ingredientId': ingredientId,
        'amount': newAmount,
      });
      return;
    }
    _pantry = [
      for (final p in _pantry)
        p.ingredientId == ingredientId
            ? p.copyWith(quantity: FoodQuantity(newAmount, p.quantity.unit))
            : p,
    ]..removeWhere((p) => p.ingredientId == ingredientId && newAmount == 0);
    _repricePlan();
    _buildGroceryList();
    emit(
      'quantity_corrected',
      objectType: 'ingredient',
      objectId: ingredientId,
    );
    notifyListeners();
  }

  // ---------- beverages ----------

  void setBeverageProfile(
    String beverageId, {
    double? servingsPerDay,
    double? onHand,
  }) {
    _requireAdult();
    final existing =
        _beverages.where((b) => b.beverageId == beverageId).firstOrNull ??
        BeverageProfile(beverageId: beverageId);
    _beverages = [
      ..._beverages.where((b) => b.beverageId != beverageId),
      existing.copyWith(servingsPerDay: servingsPerDay, onHand: onHand),
    ];
    emit(
      'beverage_profile_saved',
      objectType: 'beverage',
      objectId: beverageId,
    );
    notifyListeners();
  }

  /// Record a confirmed consumption check-in; EWMA alpha .25 per the
  /// consumption engine contract. Never required of children.
  void confirmBeverageInterval(String beverageId, double observedDailyPacks) {
    _requireAdult();
    const alpha = 0.25;
    _beverages = [
      for (final b in _beverages)
        b.beverageId == beverageId
            ? b.copyWith(
                confirmedIntervals: b.confirmedIntervals + 1,
                dailyRate: b.confirmedIntervals == 0
                    ? observedDailyPacks
                    : alpha * observedDailyPacks +
                          (1 - alpha) *
                              (b.dailyRate == 0
                                  ? observedDailyPacks
                                  : b.dailyRate),
              )
            : b,
    ];
    emit('beverage_checkin', objectType: 'beverage', objectId: beverageId);
    notifyListeners();
  }

  /// Forecast packs needed before the next trip; 'initial estimate' until 3
  /// confirmed intervals per contract.
  ({double packsNeeded, bool confident}) beverageForecast(String beverageId) {
    final profile =
        _beverages.where((b) => b.beverageId == beverageId).firstOrNull ??
        const BeverageProfile(beverageId: '');
    final rate = profile.confident ? profile.dailyRate : profile.servingsPerDay;
    final needed = (rate * _shoppingIntervalDays - profile.onHand).clamp(
      0.0,
      1e9,
    );
    return (packsNeeded: needed.ceilToDouble(), confident: profile.confident);
  }

  // ---------- voting ----------

  int _countInWindow(Iterable<DateTime> times, Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return times.where((t) => t.isAfter(cutoff)).length;
  }

  VoteRound openVoteRound(
    String title,
    List<String> optionIds, {
    Duration openFor = const Duration(hours: 24),
  }) {
    _requireAdult();
    _requireOnline();
    final limit = 3 * _entitlement.plan.quotaMultiplier;
    if (_countInWindow(
          _voteRounds.map((r) => r.createdAt),
          const Duration(days: 7),
        ) >=
        limit) {
      throw const FcException(
        FcErrorCode.rateLimited,
        'Vote rounds are used up for this week.',
      );
    }
    // Ballots may only offer safety-verified options.
    final eligibleIds = eligibleRecipes().map((r) => r.id).toSet();
    final options = optionIds.where(eligibleIds.contains).toList();
    if (options.length < 2) {
      throw const FcException(
        FcErrorCode.validation,
        'Pick at least two safe meal options.',
      );
    }
    final round = VoteRound(
      id: _nextId('vote'),
      title: title.trim().isEmpty ? 'Family vote' : title.trim(),
      optionIds: options,
      closesAt: DateTime.now().add(openFor),
      createdAt: DateTime.now(),
    );
    _voteRounds = [..._voteRounds, round];
    emit('ballot_opened', objectType: 'vote_round', objectId: round.id);
    notifyListeners();
    return round;
  }

  void markBallotSeen(String roundId) {
    _requireCircle();
    final id = _actorId;
    if (id == null) return;
    final round = _voteRounds.where((v) => v.id == roundId).firstOrNull;
    if (round == null || round.seenBy.contains(id)) return; // already recorded
    _voteRounds = [
      for (final v in _voteRounds)
        v.id == roundId ? v.copyWith(seenBy: {...v.seenBy, id}) : v,
    ];
    emit('ballot_viewed', objectType: 'vote_round', objectId: roundId);
    notifyListeners();
  }

  /// Cast or change a vote. Reversible until close; one member one vote;
  /// expired ballots reject with BALLOT_EXPIRED.
  void castVote(String roundId, String recipeId) {
    _requireCircle();
    _requireOnline();
    final actorId = _actorId;
    if (actorId == null) throw const FcException(FcErrorCode.authRequired);
    final idx = _voteRounds.indexWhere((v) => v.id == roundId);
    if (idx < 0) throw const FcException(FcErrorCode.circleForbidden);
    final round = _voteRounds[idx];
    if (round.status == VoteRoundStatus.closed ||
        round.isExpired(DateTime.now())) {
      throw const FcException(FcErrorCode.ballotExpired);
    }
    if (!round.optionIds.contains(recipeId)) {
      throw const FcException(FcErrorCode.recipeUnverified);
    }
    _voteRounds = [
      for (final v in _voteRounds)
        v.id == roundId
            ? v.copyWith(
                votes: {...v.votes, actorId: recipeId},
                seenBy: {...v.seenBy, actorId},
              )
            : v,
    ];
    // Vote cast is a weak explicit signal; never counted for absence.
    _applyLearning(recipeId, 'meal_vote_cast');
    emit('meal_vote_submitted', objectType: 'vote_round', objectId: roundId);
    notifyListeners();
  }

  /// Explicit skip: neutral, recorded as a skip event only.
  void skipVote(String roundId) {
    _requireCircle();
    emit(
      'meal_vote_skipped_explicit',
      objectType: 'vote_round',
      objectId: roundId,
    );
    notifyListeners();
  }

  VoteRound closeVoteRound(String roundId, {String? adultPickTie}) {
    _requireAdult();
    _requireOnline();
    final idx = _voteRounds.indexWhere((v) => v.id == roundId);
    if (idx < 0) throw const FcException(FcErrorCode.circleForbidden);
    final round = _voteRounds[idx];
    final tally = <String, int>{};
    for (final recipeId in round.votes.values) {
      tally[recipeId] = (tally[recipeId] ?? 0) + 1;
    }
    String? winner;
    if (tally.isNotEmpty) {
      final ranked = tally.entries.toList()
        ..sort(
          (a, b) => b.value != a.value
              ? b.value.compareTo(a.value)
              : a.key.compareTo(b.key),
        );
      if (ranked.length > 1 && ranked[0].value == ranked[1].value) {
        // Tie resolved by adult pick or deterministic lowest-id rule.
        winner = adultPickTie != null && round.optionIds.contains(adultPickTie)
            ? adultPickTie
            : ranked[0].key;
      } else {
        winner = ranked.first.key;
      }
    }
    _voteRounds = [
      for (final v in _voteRounds)
        v.id == roundId
            ? v.copyWith(status: VoteRoundStatus.closed, winnerId: winner)
            : v,
    ];
    emit('ballot_closed', objectType: 'vote_round', objectId: roundId);
    notifyListeners();
    return _voteRounds[idx];
  }

  // ---------- games & rewards ----------

  int gamePlaysRemaining(String gameId) {
    final def = catalog.gameById(gameId);
    final limit = def.quotaPerWindow * _entitlement.plan.quotaMultiplier;
    final used = _countInWindow(
      _gameSessions.where((s) => s.gameId == gameId).map((s) => s.startedAt),
      def.window,
    );
    return (limit - used).clamp(0, limit);
  }

  GameSession startGame(String gameId) {
    _requireCircle();
    _requireOnline();
    if (gamePlaysRemaining(gameId) <= 0) {
      throw const FcException(
        FcErrorCode.rateLimited,
        'This game is used up for now.',
      );
    }
    final session = GameSession(
      id: _nextId('gs'),
      gameId: gameId,
      startedAt: DateTime.now(),
    );
    _gameSessions = [..._gameSessions, session];
    emit('game_started', objectType: 'game', objectId: gameId);
    notifyListeners();
    return session;
  }

  /// Finish a session and award the participation badge exactly once
  /// ((circle, session, reward) unique). Score is clamped to 0-100.
  Badge finishGame(
    GameSession session, {
    int score = 50,
    String rewardTitle = 'Player',
    String rewardDescription = 'Played a family game.',
  }) {
    _requireCircle();
    final c = _circle!;
    final badgeId = '${c.id}:${session.id}:participation';
    _gameSessions = [
      for (final s in _gameSessions)
        s.id == session.id
            ? s.copyWith(
                state: GameSessionState.awarded,
                score: score.clamp(0, 100),
              )
            : s,
    ];
    final existing = _badges.where((b) => b.id == badgeId).firstOrNull;
    if (existing != null) return existing;
    final badge = Badge(
      id: badgeId,
      title: rewardTitle,
      description: rewardDescription,
      earnedAt: DateTime.now(),
      gameId: session.gameId,
    );
    _badges = [..._badges, badge];
    emit('game_completed', objectType: 'game', objectId: session.gameId);
    notifyListeners();
    return badge;
  }

  // ---------- quest ----------

  void ensureQuest() {
    if (_quest.isNotEmpty) return;
    _quest = const [
      QuestObjective(id: 'q-vote', title: 'Vote in a family meal round'),
      QuestObjective(id: 'q-list', title: 'Help check one grocery item'),
      QuestObjective(
        id: 'q-skill',
        title: 'Practice one kitchen skill with an adult',
      ),
      QuestObjective(
        id: 'q-passport',
        title: 'Visit a cuisine in Food Passport',
      ),
    ];
  }

  void completeQuestObjective(String id) {
    _requireCircle();
    _quest = [for (final q in _quest) q.id == id ? q.copyWith(done: true) : q];
    emit('quest_objective_done', objectType: 'quest', objectId: id);
    notifyListeners();
  }

  void approveQuestObjective(String id) {
    _requireAdult();
    _quest = [
      for (final q in _quest)
        q.id == id ? q.copyWith(done: true, adultApproved: true) : q,
    ];
    notifyListeners();
  }

  // ---------- feedback / learning ----------

  void _applyLearning(String recipeId, String eventType) {
    if (!_consent.personalization) return;
    const weights = {
      'recipe_cooked_liked': 0.24,
      'recipe_rated_positive': 0.20,
      'meal_vote_cast': 0.08,
      'recipe_disliked_explicit': -0.27,
      'recipe_cooked_disliked': -0.26,
    };
    final w = weights[eventType];
    if (w == null) return; // neutral events never update taste
    final current = _learning[recipeId] ?? LearningSignal(recipeId: recipeId);
    final next = (current.score + w * (1 - current.score.abs())).clamp(
      -1.0,
      1.0,
    );
    _learning = {
      ..._learning,
      recipeId: current.copyWith(
        score: next,
        evidence: [...current.evidence, eventType],
      ),
    };
  }

  void submitFeedback(String recipeId, String value, {String? reason}) {
    _requireCircle();
    _requireOnline();
    _feedback = [
      ..._feedback,
      TasteFeedback(
        recipeId: recipeId,
        value: value,
        reason: reason,
        at: DateTime.now(),
      ),
    ];
    switch (value) {
      case 'like':
        _applyLearning(recipeId, 'recipe_rated_positive');
      case 'dislike':
        _applyLearning(recipeId, 'recipe_disliked_explicit');
      case 'cooked':
        _applyLearning(recipeId, 'recipe_cooked_liked');
        final v = _vault[recipeId] ?? VaultEntry(recipeId: recipeId);
        _vault = {
          ..._vault,
          recipeId: v.copyWith(
            cookedCount: v.cookedCount + 1,
            lastCooked: DateTime.now(),
          ),
        };
    }
    emit(
      'recipe_rated',
      objectType: 'recipe',
      objectId: recipeId,
      meta: {'value': value},
    );
    notifyListeners();
  }

  void correctLearning(String recipeId) {
    _requireAdult();
    _learning = {..._learning}..remove(recipeId);
    emit('learning_corrected', objectType: 'recipe', objectId: recipeId);
    notifyListeners();
  }

  // ---------- favorites / vault ----------

  void toggleFavorite(String recipeId) {
    _requireCircle();
    if (_favorites.any((f) => f.recipeId == recipeId)) {
      _favorites = _favorites.where((f) => f.recipeId != recipeId).toList();
    } else {
      _favorites = [
        ..._favorites,
        FavoriteEntry(recipeId: recipeId, addedAt: DateTime.now()),
      ];
      emit('recipe_saved', objectType: 'recipe', objectId: recipeId);
    }
    notifyListeners();
  }

  /// Opt-in catalog sharing goes to moderation; private notes and child data
  /// never migrate with a shared recipe.
  void shareToCatalog(String recipeId) {
    _requireAdult();
    final v = _vault[recipeId] ?? VaultEntry(recipeId: recipeId);
    _vault = {
      ..._vault,
      recipeId: v.copyWith(shareStatus: ShareStatus.pendingReview),
    };
    emit('catalog_share_requested', objectType: 'recipe', objectId: recipeId);
    notifyListeners();
  }

  // ---------- entitlements (adult-only commerce) ----------

  void checkout(EntitlementPlan plan) {
    _requireAdult();
    _requireOnline();
    if (actorIsMinor) throw const FcException(FcErrorCode.minorCommerceBlocked);
    // Mock provider: clearly labeled, replaceable by store billing.
    _entitlement = Entitlement(
      plan: plan,
      effectiveAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      providerReference: 'mock-${_nextId('rcpt')}',
    );
    emit(
      'offer_viewed_adult',
      objectType: 'entitlement',
      meta: {'plan': plan.name},
    );
    notifyListeners();
  }

  void cancelSubscription() {
    _requireAdult();
    _entitlement = Entitlement(
      plan: _entitlement.plan,
      effectiveAt: _entitlement.effectiveAt,
      expiresAt: _entitlement.expiresAt,
      providerReference: _entitlement.providerReference,
      cancelAtPeriodEnd: true,
    );
    notifyListeners();
  }

  void restorePurchase() {
    _requireAdult();
    if (_entitlement.providerReference == null) {
      throw const FcException(FcErrorCode.subscriptionNotVerified);
    }
    emit('purchase_restored', objectType: 'entitlement');
    notifyListeners();
  }

  // ---------- privacy / consent / notifications ----------

  void setConsent({
    bool? analytics,
    bool? personalization,
    bool? aiProcessing,
  }) {
    _requireCircle();
    _consent = _consent.copyWith(
      analytics: analytics,
      personalization: personalization,
      aiProcessing: aiProcessing,
    );
    notifyListeners();
  }

  void setNotifPrefs(NotificationPrefs prefs) {
    _requireCircle();
    _notifPrefs = prefs;
    emit('notification_opt_in', meta: {'push': prefs.pushEnabled.toString()});
    notifyListeners();
  }

  Map<String, Object?> exportData() {
    _requireAdult();
    return {
      'circle': _circle?.name,
      'members': [
        for (final m in _circle?.members ?? [])
          {'name': m.name, 'role': m.role.name, 'ageBand': m.ageBand.label},
      ],
      'events': _events.length,
      'learning': _learning.map((k, v) => MapEntry(k, v.score)),
      'feedback': _feedback.length,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  void deleteLearningData() {
    _requireAdult();
    _learning = {};
    _events = [];
    _feedback = [];
    emit('learning_deleted');
    notifyListeners();
  }

  void deleteHousehold() {
    _requireAdult();
    _requireOnline();
    final uid = _supabaseUserId;
    if (Supabase.instance.isInitialized && uid != null) {
      unawaited(
        Supabase.instance.client
            .from('app_snapshots')
            .delete()
            .eq('key', uid)
            .then((_) {})
            .catchError((_) {}),
      );
    }
    signOut();
  }

  // ---------- demo seed ----------

  /// Full demo household: 2 adults + 2 managed minors, generated plan, pantry,
  /// open ballot and beverages. Demo data is honest sample data, labeled in UI.
  void _seedDemoHousehold() {
    final owner = CircleMember(
      id: 'm-alex',
      name: 'Alex',
      role: MemberRole.owner,
      ageBand: AgeBand.adult,
      adultVerified: true,
      hardAllergens: {},
    );
    final partner = CircleMember(
      id: 'm-sam',
      name: 'Sam',
      role: MemberRole.admin,
      ageBand: AgeBand.adult,
      adultVerified: true,
      hardAllergens: {'peanut'},
    );
    final kid1 = CircleMember(
      id: 'm-riley',
      name: 'Riley',
      role: MemberRole.minor,
      ageBand: AgeBand.a9to12,
      hardAllergens: {},
    );
    final kid2 = CircleMember(
      id: 'm-maya',
      name: 'Maya',
      role: MemberRole.minor,
      ageBand: AgeBand.a5to8,
      hardAllergens: {'tree_nut'},
    );
    _circle = Circle(
      id: 'circle-demo',
      name: 'The Rivera Family',
      members: [owner, partner, kid1, kid2],
    );
    _actorId = owner.id;
    _budget = const BudgetCycle(
      cashCents: 12000,
      snapCents: 15000,
      depositDay: 5,
      spentCashCents: 2300,
      spentSnapCents: 4100,
    );
    _pantry = [
      PantryItem(
        ingredientId: 'rolled_oats',
        quantity: const FoodQuantity(400, FoodUnit.grams),
        confirmed: true,
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      ),
      PantryItem(
        ingredientId: 'rice_white',
        quantity: const FoodQuantity(800, FoodUnit.grams),
        confirmed: true,
      ),
      PantryItem(
        ingredientId: 'milk_whole',
        quantity: const FoodQuantity(500, FoodUnit.milliliters),
        confirmed: true,
        expiresAt: DateTime.now().add(const Duration(days: 2)),
      ),
      PantryItem(
        ingredientId: 'onion',
        quantity: const FoodQuantity(2, FoodUnit.pieces),
        confirmed: false,
      ),
      PantryItem(
        ingredientId: 'black_beans',
        quantity: const FoodQuantity(425, FoodUnit.grams),
        confirmed: true,
        expiresAt: DateTime.now().add(const Duration(days: 400)),
      ),
    ];
    _beverages = const [
      BeverageProfile(
        beverageId: 'water',
        servingsPerDay: 8,
        confirmedIntervals: 4,
        dailyRate: 1.6,
        onHand: 2,
      ),
      BeverageProfile(
        beverageId: 'milk_whole',
        servingsPerDay: 2,
        confirmedIntervals: 3,
        dailyRate: 0.5,
        onHand: 0.5,
      ),
      BeverageProfile(beverageId: 'juice', servingsPerDay: 1),
    ];
    generatePlan();
    approvePlan(_plan!.revision);
    openVoteRound('Friday dinner pick', const [
      'r-beef-tacos',
      'r-chicken-enchiladas',
      'r-veggie-pasta',
    ], openFor: const Duration(hours: 48));
    ensureQuest();
  }

  // ---------- persistence ----------

  Timer? _persistTimer;
  static const _prefsKey = 'kinplora_state_v1';

  /// Remote snapshots are keyed by the Supabase user id so RLS can scope
  /// rows to `auth.uid()`. Local-only sessions (demo, unconfigured builds)
  /// never touch the remote table.
  bool _remoteReady = false;

  /// Every mutation notifies -> schedule a debounced snapshot write.
  @override
  void notifyListeners() {
    super.notifyListeners();
    _schedulePersist();
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 800), _persist);
  }

  /// Restores local snapshot, then remote if newer. Fire-and-forget.
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        importState(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      }
      unawaited(_restoreRemote());
    } catch (_) {}
  }

  Future<void> _restoreRemote() async {
    final uid = _supabaseUserId;
    if (uid == null || !Supabase.instance.isInitialized) return;
    try {
      final res = await Supabase.instance.client
          .from('app_snapshots')
          .select('state, updated_at')
          .eq('key', uid)
          .maybeSingle();
      if (res == null) return;
      final remoteSaved = DateTime.tryParse(res['updated_at'] as String? ?? '');
      final localSaved = _lastSavedAt;
      // A local state with no household never blocks a remote restore —
      // this is what makes sign-in on a new device (or after sign-out)
      // recover the cloud snapshot regardless of local write timestamps.
      final localEmpty = _circle == null;
      if (remoteSaved != null &&
          (localEmpty ||
              localSaved == null ||
              remoteSaved.isAfter(localSaved))) {
        importState((res['state'] as Map).cast<String, dynamic>());
        notifyListeners();
      }
    } catch (_) {
    } finally {
      _remoteReady = true;
    }
  }

  DateTime? _lastSavedAt;

  Future<void> _persist() async {
    try {
      final state = exportState();
      state['_savedAt'] = DateTime.now().toIso8601String();
      final json = jsonEncode(state);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, json);
      _lastSavedAt = DateTime.now();
      // Remote sync — only for Supabase-authenticated users, and only after
      // the first remote fetch so a stale local state can't clobber newer
      // cloud data on sign-in.
      final uid = _supabaseUserId;
      if (Supabase.instance.isInitialized &&
          uid != null &&
          _remoteReady &&
          isSignedIn) {
        unawaited(
          Supabase.instance.client
              .from('app_snapshots')
              .upsert({
                'key': uid,
                'state': state,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .then((_) {})
              .catchError((_) {}),
        );
      }
    } catch (_) {}
  }

  /// Serializes all user-owned state (catalog stays static).
  Map<String, dynamic> exportState() => {
    'v': 1,
    'email': _userEmail,
    'name': _displayName,
    'google': _googleAuth,
    'actor': _actorId,
    'consent': {
      'a': _consent.analytics,
      'p': _consent.personalization,
      'ai': _consent.aiProcessing,
    },
    'circle': _circle == null ? null : circleJson(_circle!),
    'plan': _plan == null ? null : planJson(_plan!),
    'planSerial': _planSerial,
    'serial': _serial,
    'shopInterval': _shoppingIntervalDays,
    'budget': budgetJson(_budget),
    'pantry': [for (final p in _pantry) pantryJson(p)],
    'grocery': [for (final g in _groceryList) groceryJson(g)],
    'trips': [for (final t in _trips) tripJson(t)],
    'votes': [for (final v in _voteRounds) voteJson(v)],
    'sessions': [for (final g in _gameSessions) sessionJson(g)],
    'badges': [for (final b in _badges) badgeJson(b)],
    'entitlement': entitlementJson(_entitlement),
    'beverages': [for (final b in _beverages) beverageJson(b)],
    'learning': {
      for (final e in _learning.entries) e.key: learningJson(e.value),
    },
    'feedback': [for (final f in _feedback) feedbackJson(f)],
    'notif': notifJson(_notifPrefs),
    'pending': [for (final p in _pending) pendingJson(p)],
    'favorites': [for (final f in _favorites) favJson(f)],
    'vault': {for (final e in _vault.entries) e.key: vaultJson(e.value)},
    'quest': [for (final q in _quest) questJson(q)],
    'priceMemory': {
      for (final e in _priceMemory.entries) e.key: offerJson(e.value),
    },
    'chefDone': _chefDone.toList()..sort(),
  };

  /// Restores state from a snapshot map. Does not notify — caller does.
  void importState(Map<String, dynamic> j) {
    if ((j['v'] as int? ?? 0) != 1) return;
    _userEmail = j['email'] as String?;
    _displayName = j['name'] as String?;
    _googleAuth = j['google'] as bool? ?? false;
    _actorId = j['actor'] as String?;
    final c = j['consent'] as Map?;
    if (c != null) {
      _consent = ConsentFlags(
        analytics: c['a'] as bool? ?? true,
        personalization: c['p'] as bool? ?? true,
        aiProcessing: c['ai'] as bool? ?? false,
      );
    }
    _circle = j['circle'] == null
        ? null
        : circleFrom(j['circle'] as Map<String, dynamic>);
    _plan = j['plan'] == null
        ? null
        : planFrom(j['plan'] as Map<String, dynamic>);
    _planSerial = j['planSerial'] as int? ?? 0;
    _serial = j['serial'] as int? ?? 0;
    _shoppingIntervalDays = j['shopInterval'] as int? ?? 7;
    _budget = budgetFrom(j['budget'] as Map<String, dynamic>? ?? {});
    _pantry = [
      for (final p in (j['pantry'] as List? ?? []))
        pantryFrom(p as Map<String, dynamic>),
    ];
    _groceryList = [
      for (final g in (j['grocery'] as List? ?? []))
        groceryFrom(g as Map<String, dynamic>),
    ];
    _trips = [
      for (final t in (j['trips'] as List? ?? []))
        tripFrom(t as Map<String, dynamic>),
    ];
    _voteRounds = [
      for (final v in (j['votes'] as List? ?? []))
        voteFrom(v as Map<String, dynamic>),
    ];
    _gameSessions = [
      for (final g in (j['sessions'] as List? ?? []))
        sessionFrom(g as Map<String, dynamic>),
    ];
    _badges = [
      for (final b in (j['badges'] as List? ?? []))
        badgeFrom(b as Map<String, dynamic>),
    ];
    _entitlement = entitlementFrom(
      j['entitlement'] as Map<String, dynamic>? ?? {},
    );
    _beverages = [
      for (final b in (j['beverages'] as List? ?? []))
        beverageFrom(b as Map<String, dynamic>),
    ];
    _learning = {
      for (final e in ((j['learning'] as Map?) ?? {}).entries)
        e.key as String: learningFrom(e.value as Map<String, dynamic>),
    };
    _feedback = [
      for (final f in (j['feedback'] as List? ?? []))
        feedbackFrom(f as Map<String, dynamic>),
    ];
    _notifPrefs = notifFrom(j['notif'] as Map<String, dynamic>? ?? {});
    _pending = [
      for (final p in (j['pending'] as List? ?? []))
        pendingFrom(p as Map<String, dynamic>),
    ];
    _favorites = [
      for (final f in (j['favorites'] as List? ?? []))
        favFrom(f as Map<String, dynamic>),
    ];
    _vault = {
      for (final e in ((j['vault'] as Map?) ?? {}).entries)
        e.key as String: vaultFrom(e.value as Map<String, dynamic>),
    };
    _quest = [
      for (final q in (j['quest'] as List? ?? []))
        questFrom(q as Map<String, dynamic>),
    ];
    _priceMemory = {
      for (final e in ((j['priceMemory'] as Map?) ?? {}).entries)
        e.key as String: offerFrom(e.value as Map<String, dynamic>),
    };
    _chefDone = {
      for (final i in (j['chefDone'] as List? ?? [])) (i as num).toInt(),
    };
    _lastSavedAt = DateTime.tryParse(j['_savedAt'] as String? ?? '');
  }
}
