import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/beon_config.dart';
import '../config/beon_theme.dart';
import '../data/api_client.dart';
import '../data/local_storage.dart';
import '../data/services/auth_service.dart';
import '../data/services/chat_service.dart';
import '../data/services/ticket_service.dart';
import '../data/services/reverb_service.dart';
import '../data/services/polling_service.dart';
import '../models/visitor.dart';
import '../models/channel_config.dart';

/// Provider for widget configuration
/// Must be overridden at the widget root
final configProvider = Provider<BeonConfig>((ref) {
  throw UnimplementedError(
    'configProvider must be overridden with ProviderScope',
  );
}, dependencies: []);

/// Provider for theme configuration
final themeProvider = Provider<BeonTheme>((ref) {
  final baseConfig = ref.watch(configProvider);
  final config = ref.watch(effectiveConfigProvider).valueOrNull ?? baseConfig;
  return BeonTheme.fromPrimaryColor(config.primaryColor);
}, dependencies: [configProvider, effectiveConfigProvider]);

/// Provider for local storage service
final localStorageProvider = Provider<LocalStorageService>((ref) {
  final config = ref.watch(configProvider);
  return LocalStorageService(
    scope: '${config.baseUrl}:${config.apiKey}:${config.userId ?? 'visitor'}',
  );
}, dependencies: [configProvider]);

/// Provider for API client
final apiClientProvider = Provider<BeonApiClient>((ref) {
  final config = ref.watch(configProvider);
  final client = BeonApiClient(config);
  ref.onDispose(client.close);
  return client;
}, dependencies: [configProvider]);

/// Provider for auth service
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(localStorageProvider);
  final config = ref.watch(configProvider);
  return AuthService(apiClient, storage, config);
}, dependencies: [apiClientProvider, localStorageProvider, configProvider]);

/// Provider for current visitor (async)
/// Ensures storage is initialized before auth service runs
final visitorProvider = FutureProvider<Visitor>(
  (ref) async {
    // Initialize storage first
    final storage = ref.watch(localStorageProvider);
    final authService = ref.watch(authServiceProvider);
    final channelFuture = ref.watch(channelConfigProvider.future);
    await storage.init();
    final channel = await channelFuture;
    return authService.initialize(
      requireAuthenticatedUser: channel?.settings.widgetType == 'users_login',
    );
  },
  dependencies: [
    localStorageProvider,
    authServiceProvider,
    channelConfigProvider,
  ],
);

/// Provider for chat service
final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final config = ref.watch(configProvider);
  final authService = ref.watch(authServiceProvider);

  return ChatService(
    apiClient,
    config,
    () => authService.currentVisitor?.id ?? '',
    ({String? messageContent, String? conversationUId}) =>
        authService.generateMetadata(
          messageContent: messageContent,
          conversationUid: conversationUId,
        ),
    () => authService.conversationUid,
    (uid) => authService.conversationUid = uid,
    () => authService.clearInitialMessage(),
  );
}, dependencies: [apiClientProvider, configProvider, authServiceProvider]);

/// Provider for Reverb WebSocket service
final reverbServiceProvider = Provider.family<ReverbService, String>((
  ref,
  visitorId,
) {
  return SimpleFlutterReverb(
    endpoint: Uri.parse(ref.watch(configProvider).wsUrl),
  );
}, dependencies: [configProvider]);

/// Provider for polling service
final pollingServiceProvider = Provider<PollingService>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final config = ref.watch(configProvider);
  return PollingService(chatService, interval: config.pollingInterval);
}, dependencies: [chatServiceProvider, configProvider]);

/// Provider for channel configuration from API
///
/// Fetches channel settings including:
/// - Pre-chat form field visibility
/// - Primary color
/// - Position
/// - Welcome message
final channelConfigProvider = FutureProvider<ChannelConfig?>((ref) async {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.fetchChannelConfig();
}, dependencies: [chatServiceProvider]);

/// Provider for effective configuration (merged API + user config)
///
/// User-provided values take precedence, API values are used as defaults
final effectiveConfigProvider = FutureProvider<BeonConfig>((ref) async {
  final userConfig = ref.watch(configProvider);
  final channelConfig = await ref.watch(channelConfigProvider.future);

  if (channelConfig == null) {
    return userConfig;
  }

  final settings = channelConfig.settings;

  return userConfig.copyWith(
    channelId: channelConfig.id,
    headerTitle: userConfig.headerTitle ?? channelConfig.name,
    ticketsEnabled: userConfig.ticketsEnabled ?? settings.ticketsEnabled,
    ticketCategories: userConfig.ticketCategories.isNotEmpty
        ? userConfig.ticketCategories
        : settings.ticketCategories,
    avatarUrl: userConfig.avatarUrl ?? settings.avatarUrl,
    primaryColor: userConfig.primaryColor == const Color(0xFF00BCD4)
        ? settings.primaryColor
        : userConfig.primaryColor,
    position: _parsePosition(settings.position),
    welcomeMessage: userConfig.welcomeMessage ?? settings.welcomeMessage,
    preChatFormEnabled: settings.widgetType == 'users_login'
        ? false
        : settings.preChatFormEnabled,
    preChatNameEnabled: settings.preChatFields.name,
    preChatEmailEnabled: settings.preChatFields.email,
    preChatPhoneEnabled: settings.preChatFields.phone,
    preChatMessageEnabled: settings.preChatFields.message,
  );
}, dependencies: [configProvider, channelConfigProvider]);

BeonPosition _parsePosition(String? pos) {
  switch (pos?.toLowerCase()) {
    case 'bottom-left':
    case 'bottomleft':
      return BeonPosition.bottomLeft;
    case 'top-right':
    case 'topright':
      return BeonPosition.topRight;
    case 'top-left':
    case 'topleft':
      return BeonPosition.topLeft;
    default:
      return BeonPosition.bottomRight;
  }
}

final ticketServiceProvider = Provider<TicketService>(
  (ref) => TicketService(
    ref.watch(apiClientProvider),
    ref.watch(configProvider),
    ref.watch(authServiceProvider),
  ),
  dependencies: [apiClientProvider, configProvider, authServiceProvider],
);
