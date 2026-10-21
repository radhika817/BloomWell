/// Supported auto-lock timeout durations after backgrounding.
enum AutoLockTimeout {
  immediately,
  thirtySeconds,
  oneMinute,
  fiveMinutes;

  Duration get duration {
    switch (this) {
      case AutoLockTimeout.immediately:
        return Duration.zero;
      case AutoLockTimeout.thirtySeconds:
        return const Duration(seconds: 30);
      case AutoLockTimeout.oneMinute:
        return const Duration(minutes: 1);
      case AutoLockTimeout.fiveMinutes:
        return const Duration(minutes: 5);
    }
  }

  static AutoLockTimeout fromString(String? value) {
    switch (value) {
      case 'immediately':
        return AutoLockTimeout.immediately;
      case 'thirtySeconds':
        return AutoLockTimeout.thirtySeconds;
      case 'oneMinute':
        return AutoLockTimeout.oneMinute;
      case 'fiveMinutes':
        return AutoLockTimeout.fiveMinutes;
      default:
        return AutoLockTimeout.thirtySeconds;
    }
  }

  String toStorageString() => name;
}

/// Represents the in-memory state of the App Lock and Discreet Mode subsystem.
class AppLockState {
  const AppLockState({
    required this.isLocked,
    required this.isCovered,
    required this.isPinSet,
    required this.isBiometricsEnabled,
    required this.timeout,
    required this.failedAttempts,
    required this.lockoutUntil,
    required this.hidePreviewsAndScreenshots,
    required this.isInitialized,
    this.statusMessage,
  });

  const AppLockState.initial()
      : isLocked = false,
        isCovered = false,
        isPinSet = false,
        isBiometricsEnabled = false,
        timeout = AutoLockTimeout.thirtySeconds,
        failedAttempts = 0,
        lockoutUntil = null,
        hidePreviewsAndScreenshots = true,
        isInitialized = false,
        statusMessage = null;

  final bool isLocked;
  final bool isCovered;
  final bool isPinSet;
  final bool isBiometricsEnabled;
  final AutoLockTimeout timeout;
  final int failedAttempts;
  final DateTime? lockoutUntil;
  final bool hidePreviewsAndScreenshots;
  final bool isInitialized;
  final String? statusMessage;

  bool get isLockEnabled => isPinSet;

  /// Returns true if currently in a time-based lockout delay.
  bool isLockoutActive(DateTime now) {
    if (lockoutUntil == null) return false;
    return now.isBefore(lockoutUntil!);
  }

  /// Calculates remaining lockout seconds.
  int remainingLockoutSeconds(DateTime now) {
    if (lockoutUntil == null) return 0;
    final diff = lockoutUntil!.difference(now).inSeconds;
    return diff > 0 ? diff : 0;
  }

  AppLockState copyWith({
    bool? isLocked,
    bool? isCovered,
    bool? isPinSet,
    bool? isBiometricsEnabled,
    AutoLockTimeout? timeout,
    int? failedAttempts,
    DateTime? Function()? lockoutUntil,
    bool? hidePreviewsAndScreenshots,
    bool? isInitialized,
    String? Function()? statusMessage,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      isCovered: isCovered ?? this.isCovered,
      isPinSet: isPinSet ?? this.isPinSet,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      timeout: timeout ?? this.timeout,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: lockoutUntil != null ? lockoutUntil() : this.lockoutUntil,
      hidePreviewsAndScreenshots:
          hidePreviewsAndScreenshots ?? this.hidePreviewsAndScreenshots,
      isInitialized: isInitialized ?? this.isInitialized,
      statusMessage:
          statusMessage != null ? statusMessage() : this.statusMessage,
    );
  }
}
