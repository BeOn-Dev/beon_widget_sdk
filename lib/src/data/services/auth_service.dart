import '../api_client.dart';
import '../local_storage.dart';
import '../../models/visitor.dart';
import '../../models/metadata.dart';
import '../../utils/fingerprint_generator.dart';
import '../../config/beon_config.dart';

/// Service for managing visitor authentication and fingerprinting
class AuthService {
  final BeonApiClient _apiClient;
  final LocalStorageService _storage;
  final BeonConfig _config;

  Visitor? _currentVisitor;
  String? _deviceFingerprint;
  String? _browserFingerprint;
  String? _sessionFingerprint;
  DeviceInfo? _deviceInfo;
  BrowserInfo? _browserInfo;
  String? _initialMessage;
  String? _conversationUid;

  AuthService(this._apiClient, this._storage, this._config);

  /// Get/set initial message from pre-chat form
  String? get initialMessage => _initialMessage;
  set initialMessage(String? value) => _initialMessage = value;

  /// Get/set conversation ID (used as uid for API requests)
  String? get conversationUid => _conversationUid ?? _storage.getConversationUid();
  set conversationUid(String? value) {
    _conversationUid = value;
    if (value != null) {
      _storage.saveConversationUid(value);
    }
  }

  /// Get current visitor
  Visitor? get currentVisitor => _currentVisitor;

  /// Get device fingerprint
  String get deviceFingerprint =>
      _deviceFingerprint ?? FingerprintGenerator.generateSessionFingerprint();

  /// Get browser fingerprint
  String get browserFingerprint =>
      _browserFingerprint ?? FingerprintGenerator.generateSessionFingerprint();

  /// Get session fingerprint
  String get sessionFingerprint =>
      _sessionFingerprint ?? FingerprintGenerator.generateSessionFingerprint();

  /// Get device info
  DeviceInfo get deviceInfo =>
      _deviceInfo ?? FingerprintGenerator.getDefaultDeviceInfo();

  /// Get browser info
  BrowserInfo get browserInfo =>
      _browserInfo ?? FingerprintGenerator.getDefaultBrowserInfo();

  /// Initialize auth service and get/create visitor
  Future<Visitor> initialize() async {
    // Generate session fingerprint (new each session)
    _sessionFingerprint = FingerprintGenerator.generateSessionFingerprint();

    // Get device and browser info
    _deviceInfo = _getDeviceInfo();
    _browserInfo = _getBrowserInfo();

    // Generate fingerprints
    _deviceFingerprint =
        FingerprintGenerator.generateDeviceFingerprint(_deviceInfo!);
    _browserFingerprint =
        FingerprintGenerator.generateBrowserFingerprint(_browserInfo!);

    // Check for existing visitor
    final existingId = _storage.getVisitorId();
    final existingVisitor = _storage.getVisitor();

    if (existingId != null && existingVisitor != null) {
      _currentVisitor = existingVisitor;
      _apiClient.setVisitorId(existingId);

      // Validate with server if needed
      try {
        await _validateWidget();
      } catch (e) {
        // Continue with cached visitor if validation fails
      }

      return _currentVisitor!;
    }

    // Check for external user ID from config
    if (_config.externalUserId != null) {
      return _createVisitor(_config.externalUserId!);
    }

    // Generate new visitor ID
    final newId = FingerprintGenerator.generateVisitorId();
    return _createVisitor(newId);
  }

  /// Create a new visitor
  Future<Visitor> _createVisitor(String id) async {
    final visitor = Visitor(
      id: id,
      createdAt: DateTime.now(),
    );

    await _storage.saveVisitorId(id);
    await _storage.saveVisitor(visitor);
    _currentVisitor = visitor;
    _apiClient.setVisitorId(id);

    return visitor;
  }

  /// Update visitor with pre-chat form data
  Future<Visitor> updateVisitor(PreChatData preChatData) async {
    if (_currentVisitor == null) {
      throw StateError('No visitor initialized');
    }

    final updatedVisitor = _currentVisitor!.copyWith(
      name: preChatData.name,
      phone: preChatData.phone,
      email: preChatData.email,
    );

    // Store initial message for first API request
    _initialMessage = preChatData.initialMessage;

    await _storage.saveVisitor(updatedVisitor);
    await _storage.setPreChatCompleted(true);
    _currentVisitor = updatedVisitor;

    return updatedVisitor;
  }

  /// Validate widget API key
  Future<bool> _validateWidget() async {
    try {
      final response =
          await _apiClient.get('/channels/validate/${_config.apiKey}');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if pre-chat is completed
  /// Only uses local storage flag - not visitor name from API
  /// This ensures form shows on fresh install even if API returns visitor data
  bool get isPreChatCompleted {
    return _storage.getPreChatCompleted();
  }

  /// Generate message metadata
  /// If [messageContent] is provided, it will be included in visitorInfo
  MessageMetadata generateMetadata({String? messageContent, String? conversationUid}) {
    // Use provided message or the stored initial message
    final message = messageContent ?? _initialMessage;

    return MessageMetadata(
      userId: _currentVisitor?.id ?? '',
      deviceFingerprint: deviceFingerprint,
      browserFingerprint: browserFingerprint,
      sessionFingerprint: sessionFingerprint,
      deviceInfo: deviceInfo,
      browserInfo: browserInfo,
      timestamp: DateTime.now(),
      widgetVersion: _config.widgetVersion,
      displayName: _currentVisitor?.displayName ?? 'Visitor',
      visitorInfo: _currentVisitor != null
          ? VisitorInfo(
              name: _currentVisitor?.name ?? (conversationUid??''),
              phone: _currentVisitor?.phone ?? '',
              email: _currentVisitor?.email,
              message: message,
            )
          : null,
      senderName: _currentVisitor?.displayName ?? 'Visitor',
    );
  }

  /// Clear the initial message (call after first message is sent)
  void clearInitialMessage() {
    _initialMessage = null;
  }

  /// Get device info (platform-specific)
  DeviceInfo _getDeviceInfo() {
    // TODO: Implement web-specific device detection
    return FingerprintGenerator.getDefaultDeviceInfo();
  }

  /// Get browser info (platform-specific)
  BrowserInfo _getBrowserInfo() {
    // TODO: Implement web-specific browser detection
    return FingerprintGenerator.getDefaultBrowserInfo();
  }

  /// Clear visitor data
  Future<void> logout() async {
    await _storage.clear();
    _currentVisitor = null;
  }
}
