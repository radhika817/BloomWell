import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/bloom_buddy/presentation/bloom_buddy_placeholder_screen.dart';
import '../features/breathe/presentation/breathe_placeholder_screen.dart';
import '../features/comfort/presentation/comfort_placeholder_screen.dart';
import '../features/cycle_care/presentation/cycle_care_placeholder_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/journal/presentation/journal_placeholder_screen.dart';
import '../features/mood/presentation/mood_placeholder_screen.dart';
import '../features/profile/presentation/profile_placeholder_screen.dart';
import '../features/resources/presentation/help_placeholder_screen.dart';
import '../features/study_planner/presentation/study_planner_placeholder_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme/app_colors.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// GoRouter configuration providing stateful bottom navigation and feature routes.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    // Auth & app-lock guard placeholder: return '/login' or '/lock' when active.
    return null;
  },
  routes: <RouteBase>[
    // 5-tab persistent navigation shell
    StatefulShellRoute.indexedStack(
      builder: (
        BuildContext context,
        GoRouterState state,
        StatefulNavigationShell navigationShell,
      ) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.borderLight, width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: BottomNavigationBar(
                  currentIndex: navigationShell.currentIndex,
                  onTap: (int index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  backgroundColor: Colors.white,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: AppColors.deepPurple,
                  unselectedItemColor: AppColors.mutedText,
                  selectedFontSize: 11.5,
                  unselectedFontSize: 11,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.cottage_outlined),
                      activeIcon: const Icon(Icons.cottage_rounded),
                      label: l10n?.navHome ?? 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.favorite_border_rounded),
                      activeIcon: const Icon(Icons.favorite_rounded),
                      label: l10n?.navMood ?? 'My Mood',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.spa_outlined),
                      activeIcon: const Icon(Icons.spa_rounded),
                      label: l10n?.navCycleCare ?? 'CycleCare',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.auto_awesome_outlined),
                      activeIcon: const Icon(Icons.auto_awesome_rounded),
                      label: l10n?.navBloomBuddy ?? 'Bloom Buddy',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline_rounded),
                      activeIcon: const Icon(Icons.person_rounded),
                      label: l10n?.navProfile ?? 'Profile',
                    ),
                  ],
                ),
              ),
            ),
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
                  MoodPlaceholderScreen(
                onReturnHome: () => context.go('/'),
              ),
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
          BreathePlaceholderScreen(onReturnHome: () => context.pop()),
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
  ],
);
