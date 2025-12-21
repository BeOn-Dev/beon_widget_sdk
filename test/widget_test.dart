import 'package:flutter_test/flutter_test.dart';
import 'package:beon_widget_sdk/src/config/beon_config.dart';
import 'package:beon_widget_sdk/src/models/message.dart';
import 'package:beon_widget_sdk/src/models/visitor.dart';
import 'package:beon_widget_sdk/src/utils/validators.dart';

void main() {
  group('BeonConfig', () {
    test('has correct default values', () {
      final config = BeonConfig(
        apiKey: 'test-key',
      );

      expect(config.apiKey, 'test-key');
      expect(config.channelId, isNull);
      expect(config.position, BeonPosition.bottomRight);
      expect(config.enableSounds, true);
      expect(config.enablePollingFallback, false);
      expect(config.preChatFormEnabled, true);
      expect(config.preChatNameEnabled, true);
      expect(config.preChatEmailEnabled, false);
      expect(config.preChatPhoneEnabled, true);
      expect(config.preChatMessageEnabled, true);
    });

    test('fromMap parses correctly', () {
      final config = BeonConfig.fromMap({
        'apiKey': 'map-key',
        'primaryColor': '#FF0000',
        'position': 'bottom-left',
      });

      expect(config.apiKey, 'map-key');
      expect(config.position, BeonPosition.bottomLeft);
    });

    test('copyWith works correctly', () {
      final original = BeonConfig(
        apiKey: 'original-key',
      );

      final modified = original.copyWith(
        apiKey: 'new-key',
        channelId: 123,
        enableSounds: false,
      );

      expect(modified.apiKey, 'new-key');
      expect(modified.channelId, 123);
      expect(modified.enableSounds, false);
    });

    test('parses position correctly', () {
      expect(
        BeonConfig.fromMap({'apiKey': '', 'position': 'bottom-right'}).position,
        BeonPosition.bottomRight,
      );
      expect(
        BeonConfig.fromMap({'apiKey': '', 'position': 'bottom-left'}).position,
        BeonPosition.bottomLeft,
      );
      expect(
        BeonConfig.fromMap({'apiKey': '', 'position': 'top-right'}).position,
        BeonPosition.topRight,
      );
      expect(
        BeonConfig.fromMap({'apiKey': '', 'position': 'top-left'}).position,
        BeonPosition.topLeft,
      );
    });
  });

  group('Message', () {
    test('fromJson parses correctly', () {
      final message = Message.fromJson({
        'id': 123,
        'body': 'Hello world',
        'type': 'text',
        'status': 'sent',
        'message_type': 'my_message',
        'created_at': '2025-01-01T12:00:00Z',
      });

      expect(message.id, 123);
      expect(message.body, 'Hello world');
      expect(message.type, SendMessageType.text);
      expect(message.messageStatus, MessageStatus.sent);
      expect(message.messageType, MessageType.myMessage);
    });

    test('Message can be created with constructor', () {
      final message = Message(
        id: 456,
        body: 'Test message',
        type: SendMessageType.text,
        messageType: MessageType.clientMessage,
        messageStatus: MessageStatus.delivered,
        createdAt: '2025-01-01T12:00:00Z',
      );

      expect(message.id, 456);
      expect(message.body, 'Test message');
      expect(message.type, SendMessageType.text);
      expect(message.messageStatus, MessageStatus.delivered);
      expect(message.messageType, MessageType.clientMessage);
    });

    test('Message equality works by id', () {
      final message1 = Message(
        id: 789,
        body: 'Original content',
        messageType: MessageType.myMessage,
        createdAt: DateTime.now().toIso8601String(),
      );

      final message2 = Message(
        id: 789,
        body: 'Different content',
        messageType: MessageType.clientMessage,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(message1, equals(message2)); // Same id means equal
    });
  });

  group('Visitor', () {
    test('fromJson parses correctly', () {
      final visitor = Visitor.fromJson({
        'id': 'visitor-123',
        'name': 'John Doe',
        'phone': '+1234567890',
        'created_at': '2025-01-01T12:00:00Z',
      });

      expect(visitor.id, 'visitor-123');
      expect(visitor.name, 'John Doe');
      expect(visitor.phone, '+1234567890');
    });

    test('hasCompletedPreChat returns correct value', () {
      final visitorWithName = Visitor(
        id: 'v1',
        name: 'John',
        createdAt: DateTime.now(),
      );
      final visitorWithoutName = Visitor(
        id: 'v2',
        createdAt: DateTime.now(),
      );

      expect(visitorWithName.hasCompletedPreChat, true);
      expect(visitorWithoutName.hasCompletedPreChat, false);
    });

    test('displayName returns correct value', () {
      final visitorWithName = Visitor(
        id: 'v1',
        name: 'John',
        createdAt: DateTime.now(),
      );
      final visitorWithoutName = Visitor(
        id: 'v2',
        createdAt: DateTime.now(),
      );

      expect(visitorWithName.displayName, 'John');
      expect(visitorWithoutName.displayName, 'Visitor');
    });
  });

  group('Validators', () {
    test('validateName works correctly', () {
      expect(Validators.validateName(null), isNotNull);
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('A'), isNotNull);
      expect(Validators.validateName('John'), isNull);
      expect(Validators.validateName('John Doe'), isNull);
    });

    test('validatePhone works correctly', () {
      expect(Validators.validatePhone(null), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
      expect(Validators.validatePhone('123'), isNotNull);
      expect(Validators.validatePhone('12345678'), isNull);
      expect(Validators.validatePhone('+1234567890'), isNull);
    });

    test('validateEmail works correctly', () {
      expect(Validators.validateEmail(null), isNull); // Optional
      expect(Validators.validateEmail(''), isNull); // Optional
      expect(Validators.validateEmail('invalid'), isNotNull);
      expect(Validators.validateEmail('test@example.com'), isNull);
    });

    test('validateMessage works correctly', () {
      expect(Validators.validateMessage(null), isNotNull);
      expect(Validators.validateMessage(''), isNotNull);
      expect(Validators.validateMessage('Hello'), isNull);
    });
  });
}
