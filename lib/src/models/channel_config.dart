import 'package:flutter/material.dart';

/// Pre-chat form field configuration from API
class PreChatFields {
  final bool name;
  final bool email;
  final bool phone;
  final bool message;

  const PreChatFields({
    this.name = true,
    this.email = false,
    this.phone = true,
    this.message = true,
  });

  factory PreChatFields.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PreChatFields();
    }
    return PreChatFields(
      name: json['name'] ?? true,
      email: json['email'] ?? false,
      phone: json['phone'] ?? true,
      message: json['message'] ?? true,
    );
  }
}

/// Channel settings from API
class ChannelSettings {
  final String position;
  final Color primaryColor;
  final PreChatFields preChatFields;
  final List<String> allowedDomains;
  final String? welcomeMessage;
  final bool preChatFormEnabled;

  const ChannelSettings({
    this.position = 'bottom-right',
    this.primaryColor = const Color(0xFF00BCD4),
    this.preChatFields = const PreChatFields(),
    this.allowedDomains = const [],
    this.welcomeMessage,
    this.preChatFormEnabled = true,
  });

  factory ChannelSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ChannelSettings();
    }
    return ChannelSettings(
      position: json['position']?.toString() ?? 'bottom-right',
      primaryColor: _parseColor(json['primary_color']?.toString()),
      preChatFields: PreChatFields.fromJson(json['prechat_fields']),
      allowedDomains: (json['allowed_domains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      welcomeMessage: json['welcome_message']?.toString(),
      preChatFormEnabled: json['prechat_form_enabled'] ?? true,
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return const Color(0xFF00BCD4);
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

/// Channel configuration from API response
///
/// Response format:
/// ```json
/// {
///   "status": 200,
///   "message": "Get channel",
///   "data": {
///     "id": 93,
///     "name": "BeOn Website",
///     "identifier": "website",
///     "token": "...",
///     "settings": { ... }
///   }
/// }
/// ```
class ChannelConfig {
  final int id;
  final String name;
  final String identifier;
  final String? icon;
  final String? color;
  final ChannelSettings settings;
  final String token;
  final bool isActive;
  final int sessionStatus;

  const ChannelConfig({
    required this.id,
    required this.name,
    required this.identifier,
    this.icon,
    this.color,
    required this.settings,
    required this.token,
    this.isActive = true,
    this.sessionStatus = 1,
  });

  factory ChannelConfig.fromJson(Map<String, dynamic> json) {
    return ChannelConfig(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      identifier: json['identifier']?.toString() ?? '',
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
      settings: ChannelSettings.fromJson(json['settings']),
      token: json['token']?.toString() ?? '',
      isActive: json['is_active'] == 1,
      sessionStatus: json['session_status'] is int ? json['session_status'] : int.tryParse(json['session_status']?.toString() ?? '1') ?? 1,
    );
  }

  /// Parse from API response wrapper
  static ChannelConfig? fromApiResponse(Map<String, dynamic> response) {
    if (response['status'] != 200 || response['data'] == null) {
      return null;
    }
    return ChannelConfig.fromJson(response['data']);
  }
}
