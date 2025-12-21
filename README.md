# Beon Widget SDK

A fully-featured, customizable chat widget SDK for Flutter with real-time messaging support via WebSocket (Laravel Reverb).

## Features

- Real-time messaging via WebSocket (Laravel Reverb)
- Visitor persistence across sessions
- Pre-chat form for lead collection
- Customizable theming and positioning
- RTL/LTR language support
- File attachments
- Emoji picker
- Sound notifications
- Offline message caching
- Pagination support
- Polling fallback
- Fullscreen mode support

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  beon_widget_sdk: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Integration

```dart
import 'package:flutter/material.dart';
import 'package:beon_widget_sdk/beon_widget_sdk.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // Your app content
            MyMainContent(),

            // Beon Chat Widget (floating button + chat window)
            BeonChatWidget(
              config: BeonConfig(
                apiKey: 'your-api-key',
                primaryColor: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Fullscreen Mode

For a fullscreen chat experience:

```dart
BeonChatWidget(
  config: BeonConfig(
    apiKey: 'your-api-key',
    fullScreen: true,
    headerTitle: 'Support Chat',
    headerSubtitle: 'We typically reply within minutes',
  ),
)
```

### Web Embedding (via Script Tag)

For web applications, you can read configuration from HTML script tags:

```html
<script
  src="https://cdn.beon.chat/widget.js"
  data-api-key="your-api-key"
  data-color="#6366F1"
  data-position="bottom-right">
</script>
```

```dart
// In your Flutter web app
BeonChatWidget.fromScriptTag()
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `apiKey` | String | **required** | Your Beon API key |
| `primaryColor` | Color | Cyan | Primary theme color |
| `position` | BeonPosition | bottomRight | Widget position on screen |
| `headerTitle` | String? | null | Chat header title |
| `headerSubtitle` | String? | null | Chat header subtitle |
| `welcomeMessage` | String? | null | Initial welcome message |
| `preChatFormEnabled` | bool | true | Show pre-chat form |
| `preChatNameEnabled` | bool | true | Show name field in pre-chat form |
| `preChatEmailEnabled` | bool | false | Show email field in pre-chat form |
| `preChatPhoneEnabled` | bool | true | Show phone field in pre-chat form |
| `preChatMessageEnabled` | bool | true | Show message field in pre-chat form |
| `enableSounds` | bool | true | Enable notification sounds |
| `enablePollingFallback` | bool | false | Fall back to polling if WebSocket fails |
| `pollingInterval` | Duration | 5 seconds | Polling interval (when fallback enabled) |
| `textDirection` | TextDirection | ltr | Text direction for RTL support |
| `locale` | String | 'en' | Localization |
| `fullScreen` | bool | false | Enable fullscreen mode |
| `externalUserId` | String? | null | External user ID for identification |

## Widget Positions

```dart
BeonPosition.bottomRight  // Default
BeonPosition.bottomLeft
BeonPosition.topRight
BeonPosition.topLeft
```

## Customization

### Custom Theme

```dart
BeonChatWidget(
  config: BeonConfig(
    apiKey: 'your-api-key',
    primaryColor: const Color(0xFF6366F1),
    headerTitle: 'Beon Support',
    headerSubtitle: 'How can we help you?',
  ),
)
```

### RTL Support

```dart
BeonChatWidget(
  config: BeonConfig(
    apiKey: 'your-api-key',
    textDirection: TextDirection.rtl,
    locale: 'ar',
  ),
)
```

### Disable Pre-chat Form

```dart
BeonChatWidget(
  config: BeonConfig(
    apiKey: 'your-api-key',
    preChatFormEnabled: false,
  ),
)
```

## Architecture

The SDK uses:
- **Flutter Riverpod** for state management
- **Dio** for HTTP networking
- **WebSocket** (Laravel Reverb) for real-time messaging
- **SharedPreferences** for local storage

## Requirements

- Flutter SDK >= 3.22.0
- Dart SDK >= 3.8.1

## License

MIT License - see [LICENSE](LICENSE) file.
