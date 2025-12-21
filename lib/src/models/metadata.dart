import 'package:flutter/foundation.dart';

/// Device information for fingerprinting
@immutable
class DeviceInfo {
  final String screen;
  final String platform;
  final int cores;
  final int memory;

  const DeviceInfo({
    required this.screen,
    required this.platform,
    required this.cores,
    required this.memory,
  });

  Map<String, dynamic> toJson() => {
        'screen': screen,
        'platform': platform,
        'cores': cores,
        'memory': memory,
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      screen: json['screen'] ?? '',
      platform: json['platform'] ?? '',
      cores: json['cores'] ?? 0,
      memory: json['memory'] ?? 0,
    );
  }

  /// Generate fingerprint string for hashing
  String get fingerprintString => '$screen|$platform|$cores|$memory';
}

/// Browser information for fingerprinting
@immutable
class BrowserInfo {
  final String userAgent;
  final String language;
  final String? timezone;

  const BrowserInfo({
    required this.userAgent,
    required this.language,
    this.timezone,
  });

  Map<String, dynamic> toJson() => {
        'userAgent': userAgent,
        'language': language,
        if (timezone != null) 'timezone': timezone,
      };

  factory BrowserInfo.fromJson(Map<String, dynamic> json) {
    return BrowserInfo(
      userAgent: json['userAgent'] ?? '',
      language: json['language'] ?? '',
      timezone: json['timezone'],
    );
  }

  /// Generate fingerprint string for hashing
  String get fingerprintString => '$userAgent|$language|${timezone ?? ''}';
}

/// Visitor info for message metadata
@immutable
class VisitorInfo {
  final String name;
  final String phone;
  final String? email;
  final String? message;

  const VisitorInfo({
    required this.name,
    required this.phone,
    this.email,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (message != null) 'message': message,
      };

  factory VisitorInfo.fromJson(Map<String, dynamic> json) {
    return VisitorInfo(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

/// Complete metadata for message requests
@immutable
class MessageMetadata {
  final String userId;
  final String deviceFingerprint;
  final String browserFingerprint;
  final String sessionFingerprint;
  final DeviceInfo deviceInfo;
  final BrowserInfo browserInfo;
  final DateTime timestamp;
  final String widgetVersion;
  final String displayName;
  final VisitorInfo? visitorInfo;
  final String senderName;

  const MessageMetadata({
    required this.userId,
    required this.deviceFingerprint,
    required this.browserFingerprint,
    required this.sessionFingerprint,
    required this.deviceInfo,
    required this.browserInfo,
    required this.timestamp,
    required this.widgetVersion,
    required this.displayName,
    this.visitorInfo,
    required this.senderName,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'deviceFingerprint': deviceFingerprint,
        'browserFingerprint': browserFingerprint,
        'sessionFingerprint': sessionFingerprint,
        'deviceInfo': deviceInfo.toJson(),
        'browserInfo': browserInfo.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'widgetVersion': widgetVersion,
        'displayName': displayName,
        if (visitorInfo != null) 'visitorInfo': visitorInfo!.toJson(),
        'senderName': senderName,
      };

  factory MessageMetadata.fromJson(Map<String, dynamic> json) {
    return MessageMetadata(
      userId: json['userId'] ?? '',
      deviceFingerprint: json['deviceFingerprint'] ?? '',
      browserFingerprint: json['browserFingerprint'] ?? '',
      sessionFingerprint: json['sessionFingerprint'] ?? '',
      deviceInfo: DeviceInfo.fromJson(json['deviceInfo'] ?? {}),
      browserInfo: BrowserInfo.fromJson(json['browserInfo'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      widgetVersion: json['widgetVersion'] ?? '1.0.0',
      displayName: json['displayName'] ?? '',
      visitorInfo: json['visitorInfo'] != null
          ? VisitorInfo.fromJson(json['visitorInfo'])
          : null,
      senderName: json['senderName'] ?? '',
    );
  }
}
