import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/drinks/drinks_page.dart';
import '../features/feedback/feedback_page.dart';
import '../features/games/game_pages.dart';
import '../features/games/games_lobby.dart';
import '../features/home/home_page.dart';
import '../features/home/more_page.dart';
import '../features/insights/insights_page.dart';
import '../features/kids/kids_pages.dart';
import '../features/members/family_page.dart';
import '../features/members/members_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/offline/offline_page.dart';
import '../features/onboarding/onboarding_pages.dart';
import '../features/pantry/pantry_page.dart';
import '../features/plan/recipe_detail_page.dart';
import '../features/plan/week_plan_page.dart';
import '../features/privacy/privacy_page.dart';
import '../features/shopping/shopping_pages.dart';
import '../features/subscriptions/subscriptions_page.dart';
import '../features/vault/vault_page.dart';
import '../features/votes/votes_page.dart';
import '../shared/widgets.dart';

/// Typed route names; paths mirror the storyboard screen index.
enum AppRoute {
  welcome('/welcome'),
  preview('/preview'),
  account('/onboarding/account'),
  household('/onboarding/household'),
  foodNeeds('/onboarding/food-needs'),
  budget('/onboarding/budget'),
  firstPlan('/onboarding/first-plan'),
  home('/home'),
  plan('/plan'),
  shop('/shop'),
  family('/family'),
  more('/more'),
  recipeDetail('/recipe'),
  pantry('/pantry'),
  drinks('/drinks'),
  members('/members'),
  spending('/spending'),
  calendar('/calendar'),
  votes('/votes'),
  insights('/insights'),
  vault('/vault'),
  subscriptions('/subscriptions'),
  privacy('/privacy'),
  notifications('/notifications'),
  feedback('/feedback'),
  tripReview('/trip-review'),
  offlineStatus('/offline-status'),
  games('/games'),
  kidsHome('/kids/home'),
  kidsVote('/kids/vote'),
  kidsQuest('/kids/quest'),
  kidsBadges('/kids/badges'),
  kidsChef('/kids/chef'),
  kidsPassport('/kids/passport');

  const AppRoute(this.path);
  final String path;
}

const _publicPaths = {'/welcome', '/preview'};
const _onboardingPaths = {
  '/onboarding/account',
  '/onboarding/household',
  '/onboarding/food-needs',
  '/onboarding/budget',
  '/onboarding/first-plan',
};
const _kidsPaths = {
  '/kids/home',
  '/kids/vote',
  '/kids/quest',
  '/kids/badges',
  '/kids/chef',
  '/kids/passport',
  '/games',
  '/feedback',
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final store = ref.watch(appStoreProvider);
  final router = GoRouter(
    initialLocation: AppRoute.welcome.path,
    refreshListenable: store,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!store.isSignedIn) {
        return _publicPaths.contains(path) ? null : AppRoute.welcome.path;
      }
      if (store.circle == null) {
        // Signed in but no household yet: force onboarding (except account step).
        if (path == AppRoute.account.path ||
            path == AppRoute.household.path ||
            path == AppRoute.foodNeeds.path ||
            path == AppRoute.budget.path ||
            path == AppRoute.firstPlan.path) {
          return null;
        }
        return AppRoute.household.path;
      }
      // Signed in with circle: keep minors inside kids-safe surfaces.
      if (store.actorIsMinor &&
          !_kidsPaths.contains(path) &&
          !path.startsWith('/games/')) {
        return AppRoute.kidsHome.path;
      }
      if (!store.actorIsMinor &&
          _kidsPaths.contains(path) &&
          path != '/games' &&
          path != '/feedback') {
        // Adults previewing kids surfaces: allow via switch only.
      }
      if (_publicPaths.contains(path) || _onboardingPaths.contains(path)) {
        return store.actorIsMinor ? AppRoute.kidsHome.path : AppRoute.home.path;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.welcome.path,
        builder: (c, s) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoute.preview.path,
        builder: (c, s) => const GuestPreviewPage(),
      ),
      GoRoute(
        path: AppRoute.account.path,
        builder: (c, s) => const AccountPage(),
      ),
      GoRoute(
        path: AppRoute.household.path,
        builder: (c, s) => const HouseholdPage(),
      ),
      GoRoute(
        path: AppRoute.foodNeeds.path,
        builder: (c, s) => const FoodNeedsPage(),
      ),
      GoRoute(
        path: AppRoute.budget.path,
        builder: (c, s) => const BudgetPage(),
      ),
      GoRoute(
        path: AppRoute.firstPlan.path,
        builder: (c, s) => const FirstPlanPage(),
      ),
      GoRoute(path: AppRoute.home.path, builder: (c, s) => const HomePage()),
      GoRoute(
        path: AppRoute.plan.path,
        builder: (c, s) => const WeekPlanPage(),
      ),
      GoRoute(
        path: AppRoute.shop.path,
        builder: (c, s) => const GroceryListPage(),
      ),
      GoRoute(
        path: AppRoute.family.path,
        builder: (c, s) => const FamilyPage(),
      ),
      GoRoute(path: AppRoute.more.path, builder: (c, s) => const MorePage()),
      GoRoute(
        path: '${AppRoute.recipeDetail.path}/:id',
        builder: (c, s) => RecipeDetailPage(recipeId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.pantry.path,
        builder: (c, s) => const PantryPage(),
      ),
      GoRoute(
        path: AppRoute.drinks.path,
        builder: (c, s) => const DrinksPage(),
      ),
      GoRoute(
        path: AppRoute.members.path,
        builder: (c, s) => const MembersPage(),
      ),
      GoRoute(
        path: AppRoute.spending.path,
        builder: (c, s) => const SpendingPage(),
      ),
      GoRoute(
        path: AppRoute.calendar.path,
        builder: (c, s) => const ShoppingCalendarPage(),
      ),
      GoRoute(path: AppRoute.votes.path, builder: (c, s) => const VotesPage()),
      GoRoute(
        path: AppRoute.insights.path,
        builder: (c, s) => const InsightsPage(),
      ),
      GoRoute(path: AppRoute.vault.path, builder: (c, s) => const VaultPage()),
      GoRoute(
        path: AppRoute.subscriptions.path,
        builder: (c, s) => const SubscriptionsPage(),
      ),
      GoRoute(
        path: AppRoute.privacy.path,
        builder: (c, s) => const PrivacyPage(),
      ),
      GoRoute(
        path: AppRoute.notifications.path,
        builder: (c, s) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoute.feedback.path,
        builder: (c, s) => const FeedbackPage(),
      ),
      GoRoute(
        path: AppRoute.tripReview.path,
        builder: (c, s) => const TripReviewPage(),
      ),
      GoRoute(
        path: AppRoute.offlineStatus.path,
        builder: (c, s) => const OfflineStatusPage(),
      ),
      GoRoute(
        path: AppRoute.games.path,
        builder: (c, s) => const GamesLobbyPage(),
      ),
      GoRoute(
        path: '${AppRoute.games.path}/:id',
        builder: (c, s) => GamePage(gameId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.kidsHome.path,
        builder: (c, s) => const KidsHomePage(),
      ),
      GoRoute(
        path: AppRoute.kidsVote.path,
        builder: (c, s) => const KidsVotePage(),
      ),
      GoRoute(
        path: AppRoute.kidsQuest.path,
        builder: (c, s) => const KidsQuestPage(),
      ),
      GoRoute(
        path: AppRoute.kidsBadges.path,
        builder: (c, s) => const KidsBadgesPage(),
      ),
      GoRoute(
        path: AppRoute.kidsChef.path,
        builder: (c, s) => const KidsChefPage(),
      ),
      GoRoute(
        path: AppRoute.kidsPassport.path,
        builder: (c, s) => const KidsPassportPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
