import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/bloom_nav_bar.dart';
import '../features/bloom_buddy/presentation/bloom_buddy_placeholder_screen.dart';
import '../features/breathe/presentation/breathing_screen.dart';
import '../features/comfort/presentation/comfort_screen.dart';
import '../features/cycle_care/presentation/cycle_care_screen.dart';
import '../features/exams/presentation/exams_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/journal/presentation/journal_placeholder_screen.dart';
import '../features/mood/presentation/mood_screen.dart';
import '../features/profile/presentation/profile_placeholder_screen.dart';
import '../features/resources/presentation/help_placeholder_screen.dart';
import '../features/routines/presentation/routines_screen.dart';
import '../features/self_care/presentation/screens/activity_detail_screen.dart';
import '../features/self_care/presentation/screens/activity_history_screen.dart';
import '../features/self_care/presentation/screens/self_care_studio_screen.dart';
import '../features/study_planner/presentation/study_planner_screen.dart';
import '../features/study_planner/presentation/planner_settings_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/welcome/presentation/welcome_screen.dart';
import '../features/app_lock/presentation/lock_screen.dart';
import '../features/app_lock/presentation/pin_setup_screen.dart';
import '../features/privacy_center/presentation/privacy_center_screen.dart';
import '../l10n/app_localizations.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Listenable that notifies GoRouter when the App Lock or authentication state transitions.
class RouterRefreshNotifier extends ChangeNotifier {
  bool _isLocked = false;
  bool get isLocked => _isLocked;

  void updateLock(bool locked) {
    if (_isLocked != locked) {
      _isLocked = locked;
      notifyListeners();
    }
  }
}

final RouterRefreshNotifier routerRefreshNotifier = RouterRefreshNotifier();

/// GoRouter configuration providing stateful bottom navigation with floating
/// BloomNavBar, deep feature routes, app lock protection, and debug welcome preview.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: routerRefreshNotifier,
  redirect: (BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    if (routerRefreshNotifier.isLocked) {
      if (loc != '/lock' && loc != '/lock/setup') {
        return '/lock';
      }
    } else {
      if (loc == '/lock') {
        return '/';
      }
    }
    return null;
  },
  routes: <RouteBase>[
    // 5-tab persistent navigation shell with floating soft glass BloomNavBar
    StatefulShellRoute.indexedStack(
      builder: (
        BuildContext context,
        GoRouterState state,
        StatefulNavigationShell navigationShell,
      ) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          extendBody: true,
          body: navigationShell,
          bottomNavigationBar: BloomNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (int index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            items: [
              BloomNavItem(
                icon: Icons.cottage_outlined,
                activeIcon: Icons.cottage_rounded,
                label: l10n?.navHome ?? 'Home',
              ),
              BloomNavItem(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: l10n?.navMood ?? 'My Mood',
              ),
              BloomNavItem(
                icon: Icons.spa_outlined,
                activeIcon: Icons.spa_rounded,
                label: l10n?.navCycleCare ?? 'CycleCare',
              ),
              BloomNavItem(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: l10n?.navBloomBuddy ?? 'Bloom Buddy',
              ),
              BloomNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: l10n?.navProfile ?? 'Profile',
              ),
            ],
          ),
        );
      },
      branches: <StatefulShellBranch>[
        // Tab 0: Home
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) =>
                  const HomeScreen(),
            ),
          ],
        ),
        // Tab 1: My Mood
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/mood',
              builder: (BuildContext context, GoRouterState state) =>
                  const MoodScreen(),
            ),
          ],
        ),
        // Tab 2: CycleCare
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/cycle-care',
              builder: (BuildContext context, GoRouterState state) =>
                  const CycleCareScreen(),
            ),
          ],
        ),
        // Tab 3: Bloom Buddy
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/bloom-buddy',
              builder: (BuildContext context, GoRouterState state) =>
                  BloomBuddyPlaceholderScreen(
                onReturnHome: () => context.go('/'),
              ),
            ),
          ],
        ),
        // Tab 4: Profile
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/profile',
              builder: (BuildContext context, GoRouterState state) =>
                  ProfilePlaceholderScreen(
                onReturnHome: () => context.go('/'),
              ),
            ),
          ],
        ),
      ],
    ),

    // Sub-routes pushed on top of the root navigator
    GoRoute(
      path: '/journal',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          JournalPlaceholderScreen(onReturnHome: () => context.pop()),
    ),
    GoRoute(
      path: '/breathe',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const BreathingScreen(),
    ),
    GoRoute(
      path: '/comfort',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const ComfortScreen(),
    ),
    GoRoute(
      path: '/self-care',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const SelfCareStudioScreen(),
    ),
    GoRoute(
      path: '/self-care/activity/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          ActivityDetailScreen(activityId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/self-care/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const ActivityHistoryScreen(),
    ),
    GoRoute(
      path: '/self-care/routines',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const RoutinesScreen(),
    ),
    GoRoute(
      path: '/exams',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const ExamsScreen(),
    ),
    GoRoute(
      path: '/study-planner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const StudyPlannerScreen(),
    ),
    GoRoute(
      path: '/study-planner/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const PlannerSettingsScreen(),
    ),
    GoRoute(
      path: '/insights',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const InsightsScreen(),
    ),
    GoRoute(
      path: '/help',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          HelpPlaceholderScreen(onReturnHome: () => context.pop()),
    ),
    GoRoute(
      path: '/welcome',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const RegisterScreen(),
    ),
    GoRoute(
      path: '/lock',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const LockScreen(),
    ),
    GoRoute(
      path: '/lock/setup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const PinSetupScreen(),
    ),
    GoRoute(
      path: '/profile/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const PrivacyCenterScreen(),
    ),
  ],
);
