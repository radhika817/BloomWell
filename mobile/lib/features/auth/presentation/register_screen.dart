import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bloom_background.dart';
import '../../../core/widgets/bloom_mascot.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_notifier.dart';

/// Screen allowing new students to create an account.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedTimezone = 'Asia/Kolkata';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const List<String> _availableTimezones = [
    'Asia/Kolkata',
    'UTC',
    'America/New_York',
    'America/Los_Angeles',
    'America/Chicago',
    'Europe/London',
    'Europe/Paris',
    'Asia/Tokyo',
    'Asia/Singapore',
    'Australia/Sydney',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authNotifierProvider.notifier).clearError();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).register(
          email: _emailController.text,
          password: _passwordController.text,
          timezone: _selectedTimezone,
          displayName: _displayNameController.text.trim().isEmpty
              ? null
              : _displayNameController.text.trim(),
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: BloomBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BloomMascot(size: 84.0),
                    const SizedBox(height: 14.0),
                    Text(
                      l10n?.authRegisterTitle ?? 'Join BloomWell',
                      style: AppTypography.display.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      l10n?.authRegisterSubtitle ??
                          'A private, supportive wellness sanctuary designed for students.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20.0),
                    GlassCard(
                      padding: const EdgeInsets.all(22.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (authState.errorMessage != null) ...[
                              _buildErrorCard(
                                message: authState.rateLimitSeconds != null &&
                                        l10n != null
                                    ? l10n.authErrorRateLimited(
                                        authState.rateLimitSeconds!)
                                    : (authState.errorMessage ??
                                        l10n?.authErrorGeneric ??
                                        'An error occurred'),
                              ),
                              const SizedBox(height: 16.0),
                            ],
                            // Email
                            Text(
                              l10n?.authEmail ?? 'Email address',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 6.0),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: l10n?.authEmailPlaceholder ??
                                    'you@campus.edu',
                                prefixIcon: const Icon(
                                  Icons.alternate_email_rounded,
                                  color: AppColors.deepPurple,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryPurple,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n?.authEmailRequired ??
                                      'Email is required';
                                }
                                if (!value.contains('@') ||
                                    !value.contains('.')) {
                                  return l10n?.authEmailInvalid ??
                                      'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14.0),
                            // Display Name (optional)
                            Text(
                              l10n?.authDisplayName ??
                                  'Display Name (optional)',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 6.0),
                            TextFormField(
                              controller: _displayNameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: l10n?.authDisplayNamePlaceholder ??
                                    'What should we call you?',
                                prefixIcon: const Icon(
                                  Icons.face_rounded,
                                  color: AppColors.deepPurple,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryPurple,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14.0),
                            // Timezone Selector
                            Text(
                              l10n?.authTimezone ?? 'Timezone',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 6.0),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTimezone,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.deepPurple,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                              ),
                              items: _availableTimezones.map((tz) {
                                return DropdownMenuItem(
                                  value: tz,
                                  child:
                                      Text(tz, style: AppTypography.bodyMedium),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedTimezone = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 14.0),
                            // Password
                            Text(
                              l10n?.authPassword ?? 'Password',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 6.0),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: l10n?.authPasswordPlaceholder ??
                                    'At least 10 characters',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.deepPurple,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.secondaryText,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryPurple,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n?.authPasswordRequired ??
                                      'Password is required';
                                }
                                if (value.length < 10) {
                                  return l10n?.authPasswordMinLength ??
                                      'Password must be at least 10 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14.0),
                            // Confirm Password
                            Text(
                              l10n?.authPasswordConfirm ?? 'Confirm Password',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 6.0),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText:
                                    l10n?.authPasswordConfirmPlaceholder ??
                                        'Re-enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock_reset_rounded,
                                  color: AppColors.deepPurple,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.secondaryText,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryPurple,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n?.authPasswordRequired ??
                                      'Password is required';
                                }
                                if (value != _passwordController.text) {
                                  return l10n?.authPasswordMismatch ??
                                      'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24.0),
                            // Register Button
                            GradientButton(
                              label: authState.isAuthenticating
                                  ? (l10n?.authRegistering ??
                                      'Creating your account...')
                                  : (l10n?.authRegister ?? 'Register'),
                              isExpanded: true,
                              onPressed:
                                  authState.isAuthenticating ? () {} : _submit,
                            ),
                            const SizedBox(height: 14.0),
                            // Navigation to Login
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: Text(
                                l10n?.authLoginPrompt ??
                                    'Already have an account? Sign In',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.deepPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard({required String message}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.blushPink,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.softRose.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.deepPurple,
            size: 20,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
