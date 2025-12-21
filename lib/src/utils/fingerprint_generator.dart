import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/metadata.dart';

/// Generates device and browser fingerprints for visitor identification
class FingerprintGenerator {
  static const _uuid = Uuid();

  /// Generate SHA-256 hash from string
  static String _hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate device fingerprint
  static String generateDeviceFingerprint(DeviceInfo deviceInfo) {
    return _hash(deviceInfo.fingerprintString);
  }

  /// Generate browser fingerprint
  static String generateBrowserFingerprint(BrowserInfo browserInfo) {
    return _hash(browserInfo.fingerprintString);
  }

  /// Generate session fingerprint (unique per session)
  static String generateSessionFingerprint() {
    return _hash(_uuid.v4());
  }

  /// Generate unique visitor ID
  static String generateVisitorId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _uuid.v4().substring(0, 8).replaceAll('-', '');
    return 'widget_${timestamp}_$random';
  }

  /// Generate unique message ID
    static String generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _uuid.v4().substring(0, 6).replaceAll('-', '');
    return 'msg_${timestamp}_$random';
  }

  /// Get default device info (for non-web platforms)
  static DeviceInfo getDefaultDeviceInfo() {
    return const DeviceInfo(
      screen: '1920x1080',
      platform: 'Flutter',
      cores: 4,
      memory: 8,
    );
  }

  /// Get default browser info (for non-web platforms)
  static BrowserInfo getDefaultBrowserInfo() {
    return const BrowserInfo(
      userAgent: 'Flutter/BeonWidgetSDK',
      language: 'en',
    );
  }
}
