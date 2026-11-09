import 'package:flutter/foundation.dart';

/// Identity supplied by the host for a channel configured as `users_login`.
@immutable
class BeonUser {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  const BeonUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });
}
