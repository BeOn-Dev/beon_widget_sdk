import 'beon_config.dart';

/// Stub implementation of ScriptLoader for non-web platforms (iOS, Android)
///
/// On native platforms, DOM access is not available, so this returns null
/// and the widget must receive configuration directly via constructor.
class ScriptLoader {
  /// Returns null on non-web platforms
  ///
  /// Configuration must be provided directly to BeonChatWidget on iOS/Android
  static BeonConfig? loadFromDOM() => null;

  /// Always returns false on non-web platforms
  static bool get isWebEnvironment => false;
}
