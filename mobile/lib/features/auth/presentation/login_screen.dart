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

/// Screen allowing existing students to log in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authNotifierProvider.notifier).clearError();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
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
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BloomMascot(size: 88.0),
                    const SizedBox(height: 16.0),
                    Text(
                      l10n?.authLoginTitle ?? 'Welcome Back',
                      style: AppTypography.display.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      l10n?.authLoginSubtitle ??
                          'Log in to access your gentle self-care space.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24.0),
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
                            // Email Field
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
                            const SizedBox(height: 16.0),
                            // Password Field
                            Text(
                              l10n?.authPassword ?? 'Password',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 6.0),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
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
                            const SizedBox(height: 24.0),
                            // Sign In Button
                            GradientButton(
                              label: authState.isAuthenticating
                                  ? (l10n?.authLoggingIn ?? 'Logging in...')
                                  : (l10n?.authLogin ?? 'Log In'),
                              isExpanded: true,
                              onPressed:
                                  authState.isAuthenticating ? () {} : _submit,
                            ),
                            const SizedBox(height: 14.0),
                            // Navigation to Register
                            TextButton(
                              onPressed: () => context.go('/register'),
                              child: Text(
                                l10n?.authRegisterPrompt ??
                                    "Don't have an account? Create one",
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
