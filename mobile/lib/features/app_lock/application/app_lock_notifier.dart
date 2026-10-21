import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/router.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../data/app_lock_storage.dart';
import '../data/biometric_service.dart';
import '../data/pin_hasher.dart';
import '../data/security_platform_channel.dart';
import '../domain/app_lock_config.dart';
import '../domain/clock.dart';
import '../domain/weak_pin_validator.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final appLockStorageProvider = Provider<AppLockStorage>((ref) {
  return AppLockStorage();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return LocalBiometricService();
});

final securityPlatformChannelProvider =
    Provider<SecurityPlatformChannel>((ref) {
  return SecurityPlatformChannel();
});

/// Riverpod notifier managing the App Lock and Discreet Mode lifecycle and authentication state.
class AppLockNotifier extends Notifier<AppLockState> {
  late final AppLockStorage _storage;
  late final BiometricService _biometrics;
  late final SecurityPlatformChannel _platformChannel;
  late final Clock _clock;
  AppLifecycleListener? _lifecycleListener;
  DateTime? _backgroundedAt;

  @protected
  @override
  set state(AppLockState value) {
    super.state = value;
    routerRefreshNotifier.updateLock(value.isLocked);
  }

  @override
  AppLockState build() {
    _storage = ref.watch(appLockStorageProvider);
    _biometrics = ref.watch(biometricServiceProvider);
    _platformChannel = ref.watch(securityPlatformChannelProvider);
    _clock = ref.watch(clockProvider);

    _lifecycleListener = AppLifecycleListener(
      onInactive: _handleInactive,
      onPause: _handlePause,
      onResume: _handleResume,
    );

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        if (state.isPinSet || state.isLocked) {
          handleUserLoggedOut();
        }
      }
    });

    ref.onDispose(() {
      _lifecycleListener?.dispose();
    });

    return const AppLockState.initial();
  }

  String _getUserId() {
    final authState = ref.read(authNotifierProvider);
    return authState.user?.id ?? 'guest';
  }

  /// Restores App Lock configuration on application startup.
  Future<void> initialize() async {
    final userId = _getUserId();
    final isPinSet = await _storage.isPinSet(userId);
    final biometricsEnabled = await _storage.isBiometricsEnabled(userId);
    final timeout = await _storage.getTimeout(userId);
    final blockScreenshots = await _storage.getBlockScreenshots(userId);
    final failedAttempts = await _storage.getFailedAttempts(userId);
    final lockoutUntil = await _storage.getLockoutUntil(userId);

    // Enforce cold-start lock if PIN is set and session exists
    final shouldLockOnStart =
        isPinSet && ref.read(authNotifierProvider).isAuthenticated;

    state = AppLockState(
      isLocked: shouldLockOnStart,
      isCovered: false,
      isPinSet: isPinSet,
      isBiometricsEnabled: biometricsEnabled,
      timeout: timeout,
      failedAttempts: failedAttempts,
      lockoutUntil: lockoutUntil,
      hidePreviewsAndScreenshots: blockScreenshots,
      isInitialized: true,
    );

    if (blockScreenshots && isPinSet) {
      await _platformChannel.setFlagSecure(true);
    }
  }

  void _handleInactive() {
    // When inactive (e.g. app switcher invoked), immediately cover UI if configured
    if (state.hidePreviewsAndScreenshots || state.isLocked) {
      state = state.copyWith(isCovered: true);
    }
  }

  void _handlePause() {
    _backgroundedAt = _clock.now();
    if (state.hidePreviewsAndScreenshots || state.isLocked) {
      state = state.copyWith(isCovered: true);
    }
  }

  void _handleResume() {
    final now = _clock.now();
    bool shouldLock = state.isLocked;

    if (state.isLockEnabled && _backgroundedAt != null) {
      final elapsed = now.difference(_backgroundedAt!);
      if (elapsed >= state.timeout.duration) {
        shouldLock = true;
      }
    }

    _backgroundedAt = null;
    state = state.copyWith(
      isCovered: false,
      isLocked: shouldLock,
    );
  }

  /// Sets background timestamp directly for testing purposes.
  void setBackgroundedAtForTesting(DateTime time) {
    _backgroundedAt = time;
  }

  /// Triggers app-switcher / resume check directly for unit tests.
  void triggerResumeCheck() {
    _handleResume();
  }

  /// Quick-hide action: immediately locks the app if PIN is configured,
  /// or presents the neutral privacy cover screen if no PIN exists.
  void quickHide() {
    if (state.isLockEnabled) {
      state = state.copyWith(isLocked: true, isCovered: false);
    } else {
      state = state.copyWith(isCovered: true);
    }
  }

  /// Dismisses neutral privacy cover when triggered by Quick-Hide without a PIN.
  void dismissCover() {
    if (!state.isLocked) {
      state = state.copyWith(isCovered: false);
    }
  }

  /// Sets up a new PIN (4 to 6 digits).
  Future<bool> setPin(String newPin) async {
    if (WeakPinValidator.isWeak(newPin)) {
      return false;
    }

    final userId = _getUserId();
    final salt = PinHasher.generateSalt();
    final hash = PinHasher.hashPin(newPin, salt);

    await _storage.savePin(userId: userId, salt: salt, hash: hash);
    await _storage.clearFailureState(userId);

    state = state.copyWith(
      isPinSet: true,
      isLocked: false,
      failedAttempts: 0,
      lockoutUntil: () => null,
    );

    if (state.hidePreviewsAndScreenshots) {
      await _platformChannel.setFlagSecure(true);
    }

    return true;
  }

  /// Verifies entered PIN against secure storage with attempt limiting & lockouts.
  Future<bool> unlockWithPin(String pin) async {
    final now = _clock.now();
    if (state.isLockoutActive(now)) {
      return false;
    }

    final userId = _getUserId();
    final salt = await _storage.getSalt(userId);
    final expectedHash = await _storage.getHash(userId);

    if (salt == null || expectedHash == null) {
      state = state.copyWith(isLocked: false);
      return true;
    }

    final isValid = PinHasher.verifyPin(
      pin: pin,
      salt: salt,
      expectedHash: expectedHash,
    );

    if (isValid) {
      await _storage.clearFailureState(userId);
      state = state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        lockoutUntil: () => null,
        statusMessage: () => null,
      );
      return true;
    }

    // Handle failure and escalating lockouts
    final newAttempts = state.failedAttempts + 1;

    // After 10 cumulative failures, require full re-login and wipe all private state
    if (newAttempts >= 10) {
      await _handleTenFailuresLockout(userId);
      return false;
    }

    DateTime? lockoutUntil;
    if (newAttempts == 5) {
      lockoutUntil = now.add(const Duration(seconds: 30));
    } else if (newAttempts == 6) {
      lockoutUntil = now.add(const Duration(minutes: 1));
    } else if (newAttempts == 7) {
      lockoutUntil = now.add(const Duration(minutes: 5));
    } else if (newAttempts >= 8) {
      lockoutUntil = now.add(const Duration(minutes: 15));
    }

    await _storage.saveFailureState(
      userId: userId,
      attempts: newAttempts,
      lockoutUntil: lockoutUntil,
    );

    state = state.copyWith(
      failedAttempts: newAttempts,
      lockoutUntil: () => lockoutUntil,
    );

    return false;
  }

  Future<void> _handleTenFailuresLockout(String userId) async {
    await _storage.clearAllUserData(userId);
    state = const AppLockState.initial();
    await ref.read(authNotifierProvider.notifier).logout();
  }

  /// Attempts biometric authentication if supported and enabled.
  Future<bool> unlockWithBiometrics({required String localizedReason}) async {
    final now = _clock.now();
    if (state.isLockoutActive(now)) return false;
    if (!state.isBiometricsEnabled || !state.isPinSet) return false;

    final result =
        await _biometrics.authenticate(localizedReason: localizedReason);
    if (result == BiometricAuthResult.success) {
      final userId = _getUserId();
      await _storage.clearFailureState(userId);
      state = state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        lockoutUntil: () => null,
      );
      return true;
    }

    return false;
  }

  /// Changes the existing PIN after verifying the current one.
  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final userId = _getUserId();
    final salt = await _storage.getSalt(userId);
    final hash = await _storage.getHash(userId);
    if (salt == null || hash == null) return false;

    if (!PinHasher.verifyPin(pin: currentPin, salt: salt, expectedHash: hash)) {
      return false;
    }

    return await setPin(newPin);
  }

  /// Turns off app lock after verifying the current PIN.
  Future<bool> disableLock({required String currentPin}) async {
    final userId = _getUserId();
    final salt = await _storage.getSalt(userId);
    final hash = await _storage.getHash(userId);
    if (salt == null || hash == null) return false;

    if (!PinHasher.verifyPin(pin: currentPin, salt: salt, expectedHash: hash)) {
      return false;
    }

    await _storage.deletePin(userId);
    await _storage.clearFailureState(userId);
    await _platformChannel.setFlagSecure(false);

    state = state.copyWith(
      isPinSet: false,
      isLocked: false,
      isBiometricsEnabled: false,
      failedAttempts: 0,
      lockoutUntil: () => null,
    );

    return true;
  }

  /// Toggles biometric unlock.
  Future<bool> setBiometricsEnabled(bool enabled) async {
    final userId = _getUserId();
    if (enabled) {
      final supported = await _biometrics.canCheckBiometrics();
      if (!supported) return false;
    }
    await _storage.setBiometricsEnabled(userId, enabled);
    state = state.copyWith(isBiometricsEnabled: enabled);
    return true;
  }

  /// Updates auto-lock background timeout.
  Future<void> setTimeout(AutoLockTimeout timeout) async {
    final userId = _getUserId();
    await _storage.setTimeout(userId, timeout);
    state = state.copyWith(timeout: timeout);
  }

  /// Updates hide previews and block screenshots setting.
  Future<void> setBlockScreenshots(bool block) async {
    final userId = _getUserId();
    await _storage.setBlockScreenshots(userId, block);
    state = state.copyWith(hidePreviewsAndScreenshots: block);
    if (state.isPinSet) {
      await _platformChannel.setFlagSecure(block);
    }
  }

  /// Forgot PIN: logs user out and wipes local lock state after confirmation.
  Future<void> forgotPinAndLogout() async {
    final userId = _getUserId();
    await _storage.clearAllUserData(userId);
    state = const AppLockState.initial();
    await ref.read(authNotifierProvider.notifier).logout();
  }

  /// Clears in-memory lock state on standard user logout.
  Future<void> handleUserLoggedOut() async {
    final userId = _getUserId();
    await _storage.clearAllUserData(userId);
    state = const AppLockState.initial();
    await _platformChannel.setFlagSecure(false);
  }
}

final appLockNotifierProvider =
    NotifierProvider<AppLockNotifier, AppLockState>(AppLockNotifier.new);
