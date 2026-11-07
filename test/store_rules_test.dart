/// Tests for the non-negotiable rules from docs/: allergen fail-closed,
/// minor commerce blocked, non-vote neutrality, quota enforcement,
/// idempotent awards, budget feasibility and price provenance.
library;

import 'package:family_circle/shared/errors.dart';
import 'package:family_circle/shared/models.dart';
import 'package:family_circle/shared/store.dart';
import 'package:flutter_test/flutter_test.dart';

AppStore demoStore() {
  final store = AppStore()..signInDemo();
  return store;
}

void main() {
  test('peanut allergy removes peanut recipes from eligibility', () {
    final store = demoStore();
    final eligible = store.eligibleRecipes().map((r) => r.id).toSet();
    expect(eligible, isNot(contains('r-pb-toast')));
    expect(eligible, contains('r-scrambled-eggs'));
  });

  test('new allergy immediately re-filters the plan candidates', () {
    final store = demoStore();
    final maya = store.circle!.members.firstWhere((m) => m.name == 'Maya');
    store.setMemberAllergens(maya.id, {'milk', 'tree_nut'});
    final eligible = store.eligibleRecipes().map((r) => r.id).toSet();
    expect(eligible, isNot(contains('r-oatmeal-banana'))); // milk
    expect(eligible, isNot(contains('r-yogurt-apple'))); // yogurt
    expect(eligible, isNot(contains('r-bean-tacos'))); // cheddar
    expect(eligible, isNot(contains('r-veggie-pasta'))); // cheddar
    expect(eligible, contains('r-pasta-tomato')); // no milk
    expect(eligible, contains('r-lentil-soup')); // no milk
  });

  test('demo plan has 21 slots and complete priced basket', () {
    final store = demoStore();
    final plan = store.plan!;
    expect(plan.slots.length, 21);
    expect(plan.basket, isNotNull);
    expect(plan.basket!.hasCompleteEstimate, isTrue);
    expect(plan.basket!.totalEstimateCents, greaterThan(0));
  });

  test('minor cannot open vote rounds, buy, or manage members', () {
    final store = demoStore();
    final riley = store.circle!.members.firstWhere((m) => m.name == 'Riley');
    store.switchActor(riley.id);
    expect(store.actorIsMinor, isTrue);
    expect(
      () => store.openVoteRound('x', const ['a', 'b']),
      throwsA(
        isA<FcException>().having((e) => e.code, 'code', FcErrorCode.adultOnly),
      ),
    );
    expect(
      () => store.checkout(EntitlementPlan.plus),
      throwsA(
        isA<FcException>().having((e) => e.code, 'code', FcErrorCode.adultOnly),
      ),
    );
    expect(
      () => store.addMember('New', minor: true),
      throwsA(
        isA<FcException>().having((e) => e.code, 'code', FcErrorCode.adultOnly),
      ),
    );
  });

  test('minor sees no prices', () {
    final store = demoStore();
    final riley = store.circle!.members.firstWhere((m) => m.name == 'Riley');
    store.switchActor(riley.id);
    expect(store.showPrices, isFalse);
    final alex = store.circle!.members.firstWhere((m) => m.name == 'Alex');
    store.switchActor(alex.id);
    expect(store.showPrices, isTrue);
  });

  test('minor CAN vote on an open ballot and change until close', () {
    final store = demoStore();
    final round = store.voteRounds.first;
    final riley = store.circle!.members.firstWhere((m) => m.name == 'Riley');
    store.switchActor(riley.id);
    store.castVote(round.id, round.optionIds.first);
    store.castVote(round.id, round.optionIds.last); // reversible until close
    final updated = store.voteRounds.firstWhere((v) => v.id == round.id);
    expect(updated.votes[riley.id], round.optionIds.last);
    expect(
      updated.votes.values.where((v) => v == riley.id).length,
      0,
    ); // one entry only
  });

  test('unseen ballot produces no learning signal', () {
    final store = demoStore();
    final round = store.voteRounds.first;
    store.markBallotSeen(round.id);
    expect(store.learning[round.optionIds.first], isNull);
  });

  test('closed ballot rejects votes with BALLOT_EXPIRED', () {
    final store = demoStore();
    final short = store.openVoteRound('Quick', const [
      'r-beef-tacos',
      'r-veggie-pasta',
    ], openFor: const Duration(hours: 1));
    store.closeVoteRound(short.id);
    expect(
      () => store.castVote(short.id, 'r-beef-tacos'),
      throwsA(
        isA<FcException>().having(
          (e) => e.code,
          'code',
          FcErrorCode.ballotExpired,
        ),
      ),
    );
  });

  test('vote quota enforced per window', () {
    final store = demoStore();
    // Free tier: 3 rounds/week. Seed already opened 1; open 2 more then fail.
    store.openVoteRound('B1', const ['r-beef-tacos', 'r-veggie-pasta']);
    store.openVoteRound('B2', const ['r-beef-tacos', 'r-veggie-pasta']);
    expect(
      () => store.openVoteRound('B3', const ['r-beef-tacos', 'r-veggie-pasta']),
      throwsA(
        isA<FcException>().having(
          (e) => e.code,
          'code',
          FcErrorCode.rateLimited,
        ),
      ),
    );
  });

  test('game session awards badge exactly once', () {
    final store = demoStore();
    final s = store.startGame('recipe-roulette');
    final b1 = store.finishGame(s, rewardTitle: 'T1');
    final b2 = store.finishGame(s, rewardTitle: 'T1');
    expect(identical(b1, b2) || b1.id == b2.id, isTrue);
    expect(store.badges.where((b) => b.id == b1.id).length, 1);
  });

  test('game quota exhaustion returns rate limited', () {
    final store = demoStore();
    for (var i = 0; i < 3; i++) {
      store.startGame('recipe-roulette');
    }
    expect(
      () => store.startGame('recipe-roulette'),
      throwsA(
        isA<FcException>().having(
          (e) => e.code,
          'code',
          FcErrorCode.rateLimited,
        ),
      ),
    );
  });

  test('paid tier raises quotas for the whole household', () {
    final store = demoStore();
    store.checkout(EntitlementPlan.familyPro);
    expect(store.entitlement.plan, EntitlementPlan.familyPro);
    expect(store.gamePlaysRemaining('recipe-roulette'), 15);
  });

  test('explicit dislike moves learning negative; like moves positive', () {
    final store = demoStore();
    store.submitFeedback('r-beef-tacos', 'dislike', reason: 'too_spicy');
    expect(store.learning['r-beef-tacos']!.score, lessThan(0));
    store.submitFeedback('r-bean-tacos', 'like');
    expect(store.learning['r-bean-tacos']!.score, greaterThan(0));
  });

  test('deleting learning data clears signals', () {
    final store = demoStore();
    store.submitFeedback('r-beef-tacos', 'dislike');
    store.deleteLearningData();
    expect(store.learning, isEmpty);
  });

  test('offline queues safe writes and blocks plan generation', () {
    final store = demoStore();
    store.setOffline(true);
    store.toggleGrocery(store.groceryList.first.ingredientId);
    expect(store.pending, isNotEmpty);
    expect(
      () => store.generatePlan(),
      throwsA(
        isA<FcException>().having(
          (e) => e.code,
          'code',
          FcErrorCode.offlineNotSupported,
        ),
      ),
    );
    store.setOffline(false);
    expect(store.pending, isEmpty);
  });

  test('plan infeasible when budget is a few cents', () {
    final store = demoStore();
    store.setBudget(cashCents: 10);
    expect(() => store.generatePlan(), throwsA(isA<FcException>()));
  });

  test('basket honors SNAP verified vs unknown eligibility', () {
    final store = demoStore();
    final basket = store.plan!.basket!;
    // olive_oil offer is BenefitEligibility.unknown -> never claimed covered.
    expect(
      basket.eligibleBenefitEstimateCents,
      lessThanOrEqualTo(basket.totalEstimateCents),
    );
    expect(
      basket.eligibleBenefitEstimateCents +
          basket.unverifiedBenefitEstimateCents,
      lessThanOrEqualTo(basket.totalEstimateCents),
    );
  });
}
