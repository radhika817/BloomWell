# BloomWell Mobile App 🌸

The mobile client for BloomWell: a privacy-first menstrual wellness, self-care, and peer-support application for women students.

## Architecture

This project follows the feature-first modular architecture described in the system design:

```
lib/
├── main.dart                          # App entrypoint and System UI configuration
├── app/
│   ├── app.dart                       # Root BloomWellApp widget with M3 theme
│   ├── router.dart                    # Bottom navigation shell and route transitions
│   └── theme/
│       ├── app_colors.dart            # Approved pastel color palette
│       ├── app_spacing.dart           # Spacing, padding, and border radius tokens
│       ├── app_typography.dart        # Type hierarchy and text styles
│       └── app_theme.dart             # Flutter Material 3 ThemeData
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Global app constants and disclaimers
│   └── widgets/
│       ├── app_card.dart              # Reusable card with soft shadows and gradients
│       ├── bloom_button.dart          # Reusable tactile pill buttons
│       ├── decorative_badge.dart      # Pastel badges and tags
│       ├── placeholder_screen.dart    # Honest, informative placeholder screen
│       └── section_heading.dart       # Section title and subtitle header
└── features/
    ├── home/
    │   └── presentation/
    │       ├── home_screen.dart       # BloomWell Home Screen
    │       └── widgets/
    │           ├── greeting_header.dart      # "Hey, lovely! 🌷" greeting & discreet toggle
    │           ├── mood_checkin_card.dart    # 5 selectable moods (Happy, Calm, Okay, Sad, Stressed)
    │           ├── encouragement_card.dart   # Supportive daily encouragement quote & favorite
    │           ├── self_care_card.dart       # Individual routine card
    │           ├── self_care_section.dart    # 2-column grid (Journal, CycleCare, Breathe, Bloom Buddy)
    │           └── breathing_card.dart       # Interactive 4-phase mindful box breathing
    ├── mood/
    ├── cycle_care/
    ├── bloom_buddy/
    ├── profile/
    ├── journal/
    └── breathe/
```

## Running the App

### Prerequisites

- Flutter SDK (version 3.0.0 or later)
- Dart SDK (version 3.0.0 or later)
- An Android device/emulator, iOS simulator, or Chrome browser

### Commands

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```
