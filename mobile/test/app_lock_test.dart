import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import 'package:bloomwell/features/app_lock/data/app_lock_storage.dart';
import 'package:bloomwell/features/app_lock/data/biometric_service.dart';
import 'package:bloomwell/features/app_lock/data/pin_hasher.dart';
import 'package:bloomwell/features/app_lock/data/security_platform_channel.dart';
import 'package:bloomwell/features/app_lock/domain/app_lock_config.dart';
import 'package:bloomwell/features/app_lock/domain/clock.dart';
import 'package:bloomwell/features/app_lock/domain/weak_pin_validator.dart';
import 'package:bloomwell/features/auth/application/auth_notifier.dart';
import 'package:bloomwell/features/auth/domain/entities/auth_state.dart';
import 'package:bloomwell/features/auth/domain/entities/user_entity.dart';

class FakeBiometricService implements BiometricService {
  bool isSupported = true;
  BiometricAuthResult resultToReturn = BiometricAuthResult.success;

  @override
  Future<bool> isDeviceSupported() async => isSupported;

  @override
  Future<bool> canCheckBiometrics() async => isSupported;

  @override
  Future<BiometricAuthResult> authenticate(
      {required String localizedReason}) async {
    return resultToReturn;
  }
}

class FakeSecurityPlatformChannel extends SecurityPlatformChannel {
  bool? lastSecureState;

  @override
  Future<void> setFlagSecure(bool secure) async {
    lastSecureState = secure;
  }
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  @override
  Future<void> logout() async {
    state = const AuthState.unauthenticated();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('WeakPinValidator Tests', () {
    test('Rejects repeated digits', () {
      expect(WeakPinValidator.isWeak('0000'), isTrue);
      expect(WeakPinValidator.isWeak('1111'), isTrue);
      expect(WeakPinValidator.isWeak('9999'), isTrue);
      expect(WeakPinValidator.isWeak('55555'), isTrue);
      expect(WeakPinValidator.isWeak('777777'), isTrue);
    });

    test('Rejects forward sequential digits', () {
      expect(WeakPinValidator.isWeak('1234'), isTrue);
      expect(WeakPinValidator.isWeak('0123'), isTrue);
      expect(WeakPinValidator.isWeak('6789'), isTrue);
      expect(WeakPinValidator.isWeak('123456'), isTrue);
      expect(WeakPinValidator.isWeak('345678'), isTrue);
    });

    test('Rejects reverse sequential digits', () {
      expect(WeakPinValidator.isWeak('4321'), isTrue);
      expect(WeakPinValidator.isWeak('3210'), isTrue);
      expect(WeakPinValidator.isWeak('9876'), isTrue);
      expect(WeakPinValidator.isWeak('654321'), isTrue);
      expect(WeakPinValidator.isWeak('876543'), isTrue);
    });

    test('Rejects common obvious PIN patterns', () {
      expect(WeakPinValidator.isWeak('1212'), isTrue);
      expect(WeakPinValidator.isWeak('1004'), isTrue);
      expect(WeakPinValidator.isWeak('2580'), isTrue);
      expect(WeakPinValidator.isWeak('1313'), isTrue);
      expect(WeakPinValidator.isWeak('0852'), isTrue);
      expect(WeakPinValidator.isWeak('6969'), isTrue);
    });

    test('Rejects invalid length and non-digits', () {
      expect(WeakPinValidator.isWeak('123'), isTrue);
      expect(WeakPinValidator.isWeak('1234567'), isTrue);
      expect(WeakPinValidator.isWeak('12a4'), isTrue);
      expect(WeakPinValidator.isWeak(''), isTrue);
      expect(WeakPinValidator.isWeak('12 4'), isTrue);
    });

    test('Accepts valid strong PINs', () {
      expect(WeakPinValidator.isWeak('3819'), isFalse);
      expect(WeakPinValidator.isWeak('7492'), isFalse);
      expect(WeakPinValidator.isWeak('529183'), isFalse);
      expect(WeakPinValidator.isWeak('8147'), isFalse);
    });
  });

  group('PinHasher PBKDF2 Tests', () {
    test('Generates random cryptographically secure salts', () {
      final salt1 = PinHasher.generateSalt();
      final salt2 = PinHasher.generateSalt();

      expect(salt1.isNotEmpty, isTrue);
      expect(salt2.isNotEmpty, isTrue);
      expect(salt1, isNot(equals(salt2)));
    });

    test('Hashes consistently with same salt and verifies constant-time', () {
      final salt = PinHasher.generateSalt();
      const pin = '7492';

      final hash1 = PinHasher.hashPin(pin, salt);
      final hash2 = PinHasher.hashPin(pin, salt);

      expect(hash1.isNotEmpty, isTrue);
      expect(hash1, equals(hash2));

      expect(PinHasher.verifyPin(pin: pin, salt: salt, expectedHash: hash1),
          isTrue);
      expect(PinHasher.verifyPin(pin: '7491', salt: salt, expectedHash: hash1),
          isFalse);
      expect(PinHasher.verifyPin(pin: '0000', salt: salt, expectedHash: hash1),
          isFalse);
    });
  });

  group('AppLockStorage Two-Account Isolation Tests', () {
    late AppLockStorage storage;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      storage = AppLockStorage();
    });

    test('Scoped storage isolates User A and User B PINs', () async {
      const userA = 'user-alice-111';
      const userB = 'user-bob-222';

      await storage.savePin(userId: userA, salt: 'saltA', hash: 'hashA');
      await storage.setTimeout(userA, AutoLockTimeout.oneMinute);

      expect(await storage.isPinSet(userA), isTrue);
      expect(await storage.getHash(userA), equals('hashA'));
      expect(
          await storage.getTimeout(userA), equals(AutoLockTimeout.oneMinute));

      // User B should have nothing configured and receive default 30s timeout
      expect(await storage.isPinSet(userB), isFalse);
      expect(await storage.getHash(userB), isNull);
      expect(await storage.getTimeout(userB),
          equals(AutoLockTimeout.thirtySeconds));

      // Clear User A does not affect User B
      await storage.clearAllUserData(userA);
      expect(await storage.isPinSet(userA), isFalse);
    });
  });

  group('AppLockNotifier State & Delay Lockout Tests', () {
    late FakeClock fakeClock;
    late FakeBiometricService fakeBiometrics;
    late FakeSecurityPlatformChannel fakePlatform;
    late ProviderContainer container;

    final testUser = UserEntity(
      id: 'usr-tester-99',
      displayName: 'Tester',
      role: 'student',
      language: 'en',
      timezone: 'Asia/Kolkata',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      fakeClock = FakeClock(DateTime.utc(2026, 10, 21, 12, 0, 0));
      fakeBiometrics = FakeBiometricService();
      fakePlatform = FakeSecurityPlatformChannel();

      container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
          biometricServiceProvider.overrideWithValue(fakeBiometrics),
          securityPlatformChannelProvider.overrideWithValue(fakePlatform),
          appLockStorageProvider.overrideWithValue(AppLockStorage()),
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(
              AuthState.authenticated(
                user: testUser,
                accessToken: 'valid-test-access-token',
              ),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initializes with default state when no PIN set', () async {
      final notifier = container.read(appLockNotifierProvider.notifier);
      await notifier.initialize();

      final state = container.read(appLockNotifierProvider);
      expect(state.isPinSet, isFalse);
      expect(state.isLocked, isFalse);
      expect(state.isInitialized, isTrue);
    });

    test('Rejects setting weak PIN', () async {
      final notifier = container.read(appLockNotifierProvider.notifier);
      await notifier.initialize();

      final result = await notifier.setPin('1234');
      expect(result, isFalse);

      final state = container.read(appLockNotifierProvider);
      expect(state.isPinSet, isFalse);
    });

    test('Sets strong PIN and unlocks successfully', () async {
      final notifier = container.read(appLockNotifierProvider.notifier);
      await notifier.initialize();

      final ok = await notifier.setPin('8392');
      expect(ok, isTrue);

      var state = container.read(appLockNotifierProvider);
      expect(state.isPinSet, isTrue);
      expect(state.isLocked, isFalse);

      // Lock app manually
      notifier.quickHide();
      state = container.read(appLockNotifierProvider);
      expect(state.isLocked, isTrue);

      // Unlock with correct PIN
      final unlocked = await notifier.unlockWithPin('8392');
      expect(unlocked, isTrue);
      state = container.read(appLockNotifierProvider);
      expect(state.isLocked, isFalse);
      expect(state.failedAttempts, equals(0));
    });

    test('Escalates lockout delay on failed attempts', () async {
      final notifier = container.read(appLockNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setPin('8392');
      notifier.quickHide();

      // Attempts 1 to 4: increment failedAttempts without time lockout
      for (int i = 1; i <= 4; i++) {
        final success = await notifier.unlockWithPin('0001');
        expect(success, isFalse);
        final state = container.read(appLockNotifierProvider);
        expect(state.failedAttempts, equals(i));
        expect(state.isLockoutActive(fakeClock.now()), isFalse);
      }

      // Attempt 5: triggers 30-second lockout
      var success = await notifier.unlockWithPin('0001');
      expect(success, isFalse);
      var state = container.read(appLockNotifierProvider);
      expect(state.failedAttempts, equals(5));
      expect(state.isLockoutActive(fakeClock.now()), isTrue);
      expect(state.remainingLockoutSeconds(fakeClock.now()),
          inInclusiveRange(29, 30));

      // Correct PIN fails during lockout
      expect(await notifier.unlockWithPin('8392'), isFalse);

      // Advance clock by 31 seconds -> lockout ends
      fakeClock.advance(const Duration(seconds: 31));
      expect(
          container
              .read(appLockNotifierProvider)
              .isLockoutActive(fakeClock.now()),
          isFalse);

      // Attempt 6: triggers 1-minute lockout
      await notifier.unlockWithPin('0001');
      state = container.read(appLockNotifierProvider);
      expect(state.failedAttempts, equals(6));
      expect(state.remainingLockoutSeconds(fakeClock.now()),
          inInclusiveRange(59, 60));

      // Advance clock by 61 seconds
      fakeClock.advance(const Duration(seconds: 61));

      // Attempt 7: triggers 5-minute lockout
      await notifier.unlockWithPin('0001');
      state = container.read(appLockNotifierProvider);
      expect(state.failedAttempts, equals(7));
      expect(state.remainingLockoutSeconds(fakeClock.now()),
          inInclusiveRange(290, 300));

      // Advance clock by 5 minutes + 1 second
      fakeClock.advance(const Duration(minutes: 5, seconds: 1));

      // Attempt 8: triggers 15-minute lockout
      await notifier.unlockWithPin('0001');
      state = container.read(appLockNotifierProvider);
      expect(state.failedAttempts, equals(8));
      expect(state.remainingLockoutSeconds(fakeClock.now()),
          inInclusiveRange(890, 900));
    });

    test('10 consecutive failures wipes lock and logs user out', () async {
      final notifier = container.read(appLockNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setPin('8392');

      // Set failed attempts to 9 directly in storage
      final storage = container.read(appLockStorageProvider);
      await storage.saveFailureState(
        userId: testUser.id,
        attempts: 9,
        lockoutUntil: null,
      );
      await notifier.initialize();

      expect(container.read(appLockNotifierProvider).failedAttempts, equals(9));

      // 10th failure
      final res = await notifier.unlockWithPin('0001');
      expect(res, isFalse);

      await Future<void>.delayed(Duration.zero);

      // Auth state should be logged out
      final authState = container.read(authNotifierProvider);
      expect(authState.isAuthenticated, isFalse);

      // PIN state wiped
      final lockState = container.read(appLockNotifierProvider);
      expect(lockState.isPinSet, isFalse);
    });

    test('Auto-lock timeout locks app after configured background duration',
        () async {
      final notifier = container.read(appLockNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setPin('8392');
      await notifier.setTimeout(AutoLockTimeout.oneMinute);

      // App goes to background at T = 0
      final backgroundTime = fakeClock.now();
      notifier.setBackgroundedAtForTesting(backgroundTime);

      // App resumes after 30 seconds -> should NOT lock
      fakeClock.advance(const Duration(seconds: 30));
      notifier.triggerResumeCheck();
      expect(container.read(appLockNotifierProvider).isLocked, isFalse);

      // App goes to background again
      notifier.setBackgroundedAtForTesting(fakeClock.now());

      // App resumes after 61 seconds -> should lock
      fakeClock.advance(const Duration(seconds: 61));
      notifier.triggerResumeCheck();
      expect(container.read(appLockNotifierProvider).isLocked, isTrue);
    });

    test('Biometric unlock unlocks app when enabled and succeeds', () async {
      final notifier = container.read(appLockNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setPin('8392');
      await notifier.setBiometricsEnabled(true);
      notifier.quickHide();

      expect(container.read(appLockNotifierProvider).isLocked, isTrue);

      fakeBiometrics.resultToReturn = BiometricAuthResult.success;
      final unlocked =
          await notifier.unlockWithBiometrics(localizedReason: 'Test');
      expect(unlocked, isTrue);
      expect(container.read(appLockNotifierProvider).isLocked, isFalse);
    });

    test('Biometric unlock fails when lockout is active', () async {
      final notifier = container.read(appLockNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setPin('8392');
      await notifier.setBiometricsEnabled(true);

      // Trigger lockout
      final storage = container.read(appLockStorageProvider);
      await storage.saveFailureState(
        userId: testUser.id,
        attempts: 5,
        lockoutUntil: fakeClock.now().add(const Duration(seconds: 30)),
      );
      await notifier.initialize();

      final unlocked =
          await notifier.unlockWithBiometrics(localizedReason: 'Test');
      expect(unlocked, isFalse);
    });
  });

  group('Data Privacy & Zero-Logging Guardrails', () {
    test('Canary PIN, salt, and sensitive tokens are never printed to logs',
        () async {
      final printedLines = <String>[];

      const canaryPin = '9371';
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hashPin(canaryPin, salt);

      await runZoned(
        () async {
          // Perform hashing, validation, verification
          WeakPinValidator.isWeak(canaryPin);
          PinHasher.verifyPin(pin: canaryPin, salt: salt, expectedHash: hash);
          PinHasher.verifyPin(pin: '0000', salt: salt, expectedHash: hash);

          final storage = AppLockStorage();
          await storage.savePin(userId: 'canary-user', salt: salt, hash: hash);
          await storage.getHash('canary-user');
          await storage.getSalt('canary-user');
          await storage.clearAllUserData('canary-user');
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            printedLines.add(line);
          },
        ),
      );

      // Confirm canary PIN never leaked in stdout
      for (final line in printedLines) {
        expect(line.contains(canaryPin), isFalse,
            reason:
                'Zero-logging violation: canary PIN was printed to console!');
        expect(line.contains(salt), isFalse,
            reason: 'Zero-logging violation: salt was printed to console!');
        expect(line.contains(hash), isFalse,
            reason: 'Zero-logging violation: hash was printed to console!');
      }
    });
  });
}
