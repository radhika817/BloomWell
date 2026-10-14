import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/bloom_nav_bar.dart';
import '../features/bloom_buddy/presentation/bloom_buddy_placeholder_screen.dart';
import '../features/breathe/presentation/breathing_screen.dart';
import '../features/comfort/presentation/comfort_placeholder_screen.dart';
import '../features/cycle_care/presentation/cycle_care_placeholder_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/journal/presentation/journal_placeholder_screen.dart';
import '../features/mood/presentation/mood_screen.dart';
import '../features/profile/presentation/profile_placeholder_screen.dart';
import '../features/resources/presentation/help_placeholder_screen.dart';
import '../features/study_planner/presentation/study_planner_placeholder_screen.dart';
import '../features/welcome/presentation/welcome_screen.dart';
import '../l10n/app_localizations.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// GoRouter configuration providing stateful bottom navigation with floating
/// BloomNavBar, deep feature routes, and debug welcome preview.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    // Auth & app-lock guard placeholder: return '/login' or '/lock' when active.
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
                  CycleCarePlaceholderScreen(
                onReturnHome: () => context.go('/'),
              ),
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
          ComfortPlaceholderScreen(onReturnHome: () => context.pop()),
    ),
    GoRoute(
      path: '/study-planner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          StudyPlannerPlaceholderScreen(onReturnHome: () => context.pop()),
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
  ],
);
