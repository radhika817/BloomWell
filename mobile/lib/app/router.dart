import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../features/bloom_buddy/presentation/bloom_buddy_placeholder_screen.dart';
import '../features/breathe/presentation/breathe_placeholder_screen.dart';
import '../features/cycle_care/presentation/cycle_care_placeholder_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/journal/presentation/journal_placeholder_screen.dart';
import '../features/mood/presentation/mood_placeholder_screen.dart';
import '../features/profile/presentation/profile_placeholder_screen.dart';

/// Navigation shell providing the persistent bottom navigation bar
/// across Home, My Mood, CycleCare, Bloom Buddy, and Profile.
class BloomWellNavigationShell extends StatefulWidget {
  const BloomWellNavigationShell({super.key});

  @override
  State<BloomWellNavigationShell> createState() =>
      _BloomWellNavigationShellState();
}

class _BloomWellNavigationShellState extends State<BloomWellNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToJournal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => JournalPlaceholderScreen(
          onReturnHome: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _navigateToBreathe() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BreathePlaceholderScreen(
          onReturnHome: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onNavigateToJournal: _navigateToJournal,
        onNavigateToCycleCare: () => _onTabSelected(2),
        onNavigateToBreathe: _navigateToBreathe,
        onNavigateToBloomBuddy: () => _onTabSelected(3),
      ),
      MoodPlaceholderScreen(
        onReturnHome: () => _onTabSelected(0),
      ),
      CycleCarePlaceholderScreen(
        onReturnHome: () => _onTabSelected(0),
      ),
      BloomBuddyPlaceholderScreen(
        onReturnHome: () => _onTabSelected(0),
      ),
      ProfilePlaceholderScreen(
        onReturnHome: () => _onTabSelected(0),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.deepPurple,
              unselectedItemColor: AppColors.mutedText,
              selectedFontSize: 11.5,
              unselectedFontSize: 11,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.cottage_outlined),
                  activeIcon: Icon(Icons.cottage_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border_rounded),
                  activeIcon: Icon(Icons.favorite_rounded),
                  label: 'My Mood',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.spa_outlined),
                  activeIcon: Icon(Icons.spa_rounded),
                  label: 'CycleCare',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome_outlined),
                  activeIcon: Icon(Icons.auto_awesome_rounded),
                  label: 'Bloom Buddy',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
