import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomwell/app/theme/app_theme.dart';
import 'package:bloomwell/features/auth/presentation/login_screen.dart';
import 'package:bloomwell/features/auth/presentation/register_screen.dart';
import 'package:bloomwell/features/welcome/presentation/welcome_screen.dart';
import 'package:bloomwell/l10n/app_localizations.dart';

Widget createTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('LoginScreen renders email, password, and sign-in button',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log in to access your gentle self-care space.'),
        findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text("Don't have an account? Create one"), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation errors for empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const LoginScreen()));
    await tester.pumpAndSettle();

    // Tap Log In with empty form
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation error for short password',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const LoginScreen()));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'student@campus.edu');
    await tester.enterText(textFields.at(1), 'short');

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(
        find.text('Password must be at least 10 characters'), findsOneWidget);
  });

  testWidgets('RegisterScreen renders all fields and timezone dropdown',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Join BloomWell'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Display Name (optional)'), findsOneWidget);
    expect(find.text('Timezone'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Already have an account? Sign In'), findsOneWidget);
  });

  testWidgets('RegisterScreen validates password mismatch',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const RegisterScreen()));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'newstudent@campus.edu');
    await tester.enterText(textFields.at(2), 'password-number-one-123');
    await tester.enterText(textFields.at(3), 'different-password-456');

    final registerButton = find.text('Register');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('WelcomeScreen renders Create Account and Sign In buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const WelcomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to BloomWell'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Explore BloomWell'), findsOneWidget);
  });
}
