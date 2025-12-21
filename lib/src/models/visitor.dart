import 'package:flutter/foundation.dart';

/// Represents a chat visitor/user
@immutable
class Visitor {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? externalId;
  final Map<String, dynamic>? customData;
  final DateTime createdAt;
  final DateTime? lastSeenAt;

  const Visitor({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.externalId,
    this.customData,
    required this.createdAt,
    this.lastSeenAt,
  });

  /// Check if visitor has completed pre-chat form
  bool get hasCompletedPreChat => name != null && name!.isNotEmpty;

  /// Get display name (name or fallback)
  String get displayName => name ?? 'Visitor';

  /// Create from JSON response
  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      externalId: (json['external_id'] ?? json['externalId'])?.toString(),
      customData: json['custom_data'] ?? json['customData'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      lastSeenAt: json['last_seen_at'] != null || json['lastSeenAt'] != null
          ? _parseDateTime(json['last_seen_at'] ?? json['lastSeenAt'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (externalId != null) 'external_id': externalId,
      if (customData != null) 'custom_data': customData,
      'created_at': createdAt.toIso8601String(),
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt!.toIso8601String(),
    };
  }

  /// Copy with modified values
  Visitor copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? externalId,
    Map<String, dynamic>? customData,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) {
    return Visitor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      externalId: externalId ?? this.externalId,
      customData: customData ?? this.customData,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Visitor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Visitor(id: $id, name: $name)';
}

/// Pre-chat form data submitted by visitor
@immutable
class PreChatData {
  final String name;
  final String phone;
  final String? email;
  final String? initialMessage;
  final Map<String, dynamic>? customFields;

  const PreChatData({
    required this.name,
    required this.phone,
    this.email,
    this.initialMessage,
    this.customFields,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (initialMessage != null) 'initial_message': initialMessage,
        if (customFields != null) ...customFields!,
      };
}
