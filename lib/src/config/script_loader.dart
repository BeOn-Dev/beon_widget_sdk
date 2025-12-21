// Platform-aware script loader for widget configuration
//
// Uses conditional imports to provide:
// - Web: Full DOM access to read configuration from script tag attributes
// - iOS/Android: Stub that returns null (config must be passed directly)
export 'script_loader_stub.dart'
    if (dart.library.js_interop) 'script_loader_web.dart';
