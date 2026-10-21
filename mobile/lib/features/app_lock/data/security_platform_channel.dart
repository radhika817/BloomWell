import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel bridge to control Android's window FLAG_SECURE
/// (which blocks screenshots and recents thumbnail previews).
class SecurityPlatformChannel {
  SecurityPlatformChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.bloomwell.app/security');

  final MethodChannel _channel;

  /// Sets or clears FLAG_SECURE on Android window.
  /// Safely catches MissingPluginException on other platforms or if android/ is not configured.
  Future<void> setFlagSecure(bool enabled) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('setFlagSecure', {'enabled': enabled});
    } catch (_) {
      // Ignored gracefully on unsupported platforms or when Android native code is not active
    }
  }
}
