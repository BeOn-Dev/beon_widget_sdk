import 'package:web/web.dart' as web;
import 'beon_config.dart';

/// Loads widget configuration from HTML script tag attributes
///
/// Expects a script tag in the format:
/// ```html
/// <script
///   src="path/to/widget.js"
///   data-api-key="your-api-key"
///   data-widget-id="your-widget-id"
///   data-color="#00BCD4"
///   data-position="bottom-right"
///   data-user-id="optional-user-id"
///   data-direction="ltr">
/// </script>
/// ```
class ScriptLoader {
  /// Load configuration from DOM script tag
  ///
  /// Returns null if no script tag with data-api-key is found
  static BeonConfig? loadFromDOM() {
    try {
      final script = web.document.querySelector('script[data-api-key]');
      if (script == null) {
        return null;
      }

      final configMap = <String, String?>{
        'apiKey': script.getAttribute('data-api-key'),
        'widgetId': script.getAttribute('data-widget-id'),
        'primaryColor': script.getAttribute('data-color'),
        'position': script.getAttribute('data-position'),
        'externalUserId': script.getAttribute('data-user-id'),
        'welcomeMessage': script.getAttribute('data-welcome-message'),
        'enableSounds': script.getAttribute('data-enable-sounds'),
        'direction': script.getAttribute('data-direction'),
        'locale': script.getAttribute('data-locale'),
        'headerTitle': script.getAttribute('data-header-title'),
        'headerSubtitle': script.getAttribute('data-header-subtitle'),
      };

      return BeonConfig.fromMap(configMap);
    } catch (e) {
      // Not running in web environment or DOM access failed
      return null;
    }
  }

  /// Check if running in web environment
  static bool get isWebEnvironment {
    try {
      web.document;
      return true;
    } catch (_) {
      return false;
    }
  }
}
