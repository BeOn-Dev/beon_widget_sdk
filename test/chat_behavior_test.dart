import 'dart:async';
import 'dart:convert';
import 'package:beon_widget_sdk/beon_widget_sdk.dart';
import 'package:beon_widget_sdk/src/data/api_client.dart';
import 'package:beon_widget_sdk/src/data/local_storage.dart';
import 'package:beon_widget_sdk/src/data/services/auth_service.dart';
import 'package:beon_widget_sdk/src/data/services/chat_service.dart';
import 'package:beon_widget_sdk/src/data/services/reverb_service.dart';
import 'package:beon_widget_sdk/src/models/metadata.dart';
import 'package:beon_widget_sdk/src/models/message.dart';
import 'package:beon_widget_sdk/src/providers/chat_state.dart';
import 'package:beon_widget_sdk/src/providers/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Client extends Mock implements BeonApiClient {}

class _Chat extends Mock implements ChatService {}

class _Socket implements ReverbService {
  void Function(dynamic)? callback;
  String? channel;
  bool closed = false;
  @override
  void listen(
    void Function(dynamic) onData,
    String name, {
    bool isPrivate = false,
  }) {
    callback = onData;
    channel = name;
  }

  @override
  void close() {
    closed = true;
  }
}

Message message(
  int id,
  String body, {
  int? conversationId,
  bool private = false,
}) => Message(
  id: id,
  body: body,
  conversationId: conversationId,
  type: SendMessageType.text,
  isPrivate: private,
  messageType: MessageType.myMessage,
  messageStatus: MessageStatus.sent,
  createdAt: DateTime(2026, 11, 9, 10, 0, id).toIso8601String(),
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  group('Dashboard identity and persistence', () {
    test(
      'explicit signed-in user replaces cached visitor and bypasses prechat',
      () async {
        final storage = LocalStorageService();
        await storage.init();
        await storage.saveVisitor(
          Visitor(id: 'old-visitor', createdAt: DateTime(2026)),
        );
        await storage.saveConversationUid('old-chat');
        final auth = AuthService(
          _Client(),
          storage,
          const BeonConfig(
            apiKey: 'test',
            user: BeonUser(
              id: '5049',
              name: 'Example | acc 237',
              email: 'example@example.com',
            ),
          ),
        );
        final visitor = await auth.initialize(requireAuthenticatedUser: true);
        expect(visitor.id, '5049');
        expect(visitor.name, 'Example | acc 237');
        expect(auth.isPreChatCompleted, isTrue);
        expect(auth.conversationUid, isNull);
        expect(auth.generateMetadata().userId, '5049');
      },
    );
    test('users_login never silently creates an anonymous visitor', () async {
      final storage = LocalStorageService();
      await storage.init();
      final auth = AuthService(
        _Client(),
        storage,
        const BeonConfig(apiKey: 'test'),
      );
      await expectLater(
        auth.initialize(requireAuthenticatedUser: true),
        throwsStateError,
      );
      expect(storage.getVisitor(), isNull);
    });
    test('history and prechat are isolated per channel and user', () async {
      final one = LocalStorageService(scope: 'channel-a:user-1');
      final otherChannel = LocalStorageService(scope: 'channel-b:user-1');
      final otherUser = LocalStorageService(scope: 'channel-a:user-2');
      await one.init();
      await otherChannel.init();
      await otherUser.init();
      await one.cacheMessages([message(1, 'one')]);
      await one.setPreChatCompleted(true);
      expect(otherChannel.getCachedMessages(), isNull);
      expect(otherUser.getCachedMessages(), isNull);
      expect(otherUser.getPreChatCompleted(), isFalse);
      await otherChannel.clear();
      expect(one.getCachedMessages()!.single.body, 'one');
    });
    test(
      'dashboard string booleans and authenticated prechat settings parse',
      () {
        final settings = ChannelSettings.fromJson({
          'widget_type': 'users_login',
          'tickets_enabled': '1',
          'prechat_form_enabled': '0',
          'prechat_fields': {
            'name': '1',
            'email': '1',
            'phone': '0',
            'message': '1',
          },
        });
        expect(settings.widgetType, 'users_login');
        expect(settings.ticketsEnabled, isTrue);
        expect(settings.preChatFormEnabled, isFalse);
        expect(settings.preChatFields.phone, isFalse);
      },
    );
  });
  group('Widget API contract', () {
    late _Client client;
    late ChatService service;
    setUp(() {
      client = _Client();
      service = ChatService(
        client,
        const BeonConfig(apiKey: 'test'),
        () => '5049',
        ({String? messageContent, String? conversationUId}) => MessageMetadata(
          userId: '5049',
          deviceFingerprint: 'device',
          browserFingerprint: 'browser',
          sessionFingerprint: 'session',
          deviceInfo: const DeviceInfo(
            screen: '',
            platform: '',
            cores: 1,
            memory: 1,
          ),
          browserInfo: const BrowserInfo(userAgent: '', language: 'en'),
          timestamp: DateTime(2026),
          widgetVersion: 'test',
          displayName: 'Example',
          senderName: 'Example',
        ),
        () => 'old-random-chat',
        (_) {},
      );
    });
    test(
      'history always uses stable user ID and token, even without local chat',
      () async {
        when(
          () => client.get(
            '/messages',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: {
              'status': 200,
              'data': {
                'meta': {'current_page': '1', 'last_page': 2, 'per_page': 10},
                'conversation': {'id': 42},
                'records': [
                  {
                    'id': '1',
                    'body': 'hello',
                    'message_type': 'outgoing',
                    'type': 'text',
                  },
                ],
              },
            },
          ),
        );
        final (records, id) = await service.fetchHistory();
        expect(id, 42);
        expect(records.single.id, 1);
        expect(service.historyHasMore, isTrue);
        verify(
          () => client.get(
            '/messages',
            queryParameters: {
              'uid': '5049',
              'token': 'test',
              'page': 1,
              'limit': 10,
            },
          ),
        ).called(1);
      },
    );
    test('a fresh visitor 404 produces an empty chat', () async {
      when(
        () => client.get(
          '/messages',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 404),
        ),
      );
      final (records, _) = await service.fetchHistory();
      expect(records, isEmpty);
      expect(service.historyHasMore, isFalse);
    });
    test(
      'send uses dashboard meta_data and unwraps nested acknowledgements',
      () async {
        when(
          () => client.post('/message/send', data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: {
              'status': true,
              'data': {
                'message': {'id': 7},
                'conversation_id': 42,
              },
            },
          ),
        );
        final sent = await service.sendMessage('Hello');
        expect(sent.id, 7);
        expect(sent.conversationId, 42);
        final payload =
            verify(
                  () => client.post(
                    '/message/send',
                    data: captureAny(named: 'data'),
                  ),
                ).captured.single
                as Map;
        expect(payload['id'], '5049');
        expect(payload['meta_data']['userId'], '5049');
        expect(payload.containsKey('metadata'), isFalse);
      },
    );
    test('video uploads keep media type, URL and encoded metadata', () async {
      when(
        () => client.uploadFile(
          '/message/send',
          filePath: 'clip.mp4',
          fileName: 'clip.mp4',
          extraData: any(named: 'extraData'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: {
            'data': {'id': 9, 'url': 'https://example.com/clip.mp4'},
          },
        ),
      );
      final sent = await service.sendMessageWithAttachment(
        filePath: 'clip.mp4',
        fileName: 'clip.mp4',
        type: SendMessageType.video,
      );
      expect(sent.type, SendMessageType.video);
      expect(sent.body, 'https://example.com/clip.mp4');
      final payload =
          verify(
                () => client.uploadFile(
                  '/message/send',
                  filePath: 'clip.mp4',
                  fileName: 'clip.mp4',
                  extraData: captureAny(named: 'extraData'),
                ),
              ).captured.single
              as Map;
      expect(payload['type'], 'video');
      expect(jsonDecode(payload['metadata'])['userId'], '5049');
    });
  });
  group('Chat lifecycle', () {
    late _Chat service;
    late _Socket socket;
    late ProviderContainer container;
    setUp(() {
      service = _Chat();
      socket = _Socket();
      when(
        () => service.fetchHistory(page: 1),
      ).thenAnswer((_) async => (<Message>[], null));
      container = ProviderContainer(
        overrides: [
          configProvider.overrideWithValue(const BeonConfig(apiKey: 'test')),
          chatServiceProvider.overrideWithValue(service),
          reverbServiceProvider('42').overrideWithValue(socket),
        ],
      );
    });
    tearDown(() => container.dispose());
    Future<ChatStateNotifier> init() async {
      final notifier = container.read(chatStateProvider.notifier);
      await pumpEventQueue();
      return notifier;
    }

    test('repeated message text with different IDs is retained', () async {
      when(() => service.fetchHistory(page: 1)).thenAnswer(
        (_) async => ([message(1, 'Same'), message(2, 'Same')], null),
      );
      await init();
      expect(container.read(chatStateProvider).messages.length, 2);
    });
    test('private notes never enter chat history', () async {
      when(() => service.fetchHistory(page: 1)).thenAnswer(
        (_) async => (
          [message(1, 'Public'), message(2, 'Private', private: true)],
          null,
        ),
      );
      await init();
      expect(container.read(chatStateProvider).messages.map((m) => m.body), [
        'Public',
      ]);
    });
    test(
      'first send reloads history to connect realtime and enable tickets',
      () async {
        final notifier = await init();
        when(
          () => service.sendMessage('Hello'),
        ).thenAnswer((_) async => message(7, 'Hello'));
        when(
          () => service.fetchHistory(page: 1),
        ).thenAnswer((_) async => ([message(7, 'Hello')], 42));
        await notifier.sendMessage('Hello');
        expect(container.read(chatStateProvider).conversationId, 42);
        expect(socket.channel, 'conversation_id_42');
        expect(container.read(chatStateProvider).messages.length, 1);
      },
    );
    test(
      'socket acknowledgement does not duplicate an already sent message',
      () async {
        when(
          () => service.fetchHistory(page: 1),
        ).thenAnswer((_) async => ([message(7, 'Hello')], 42));
        await init();
        socket.callback!(
          WebsocketResponse(
            event: 'conversations_message',
            data: {
              'conversation_id': 42,
              'last_message': {
                'id': 7,
                'body': 'Hello',
                'message_type': 'incoming',
                'type': 'text',
                'status': 'read',
              },
            },
          ),
        );
        expect(container.read(chatStateProvider).messages.length, 1);
        expect(
          container.read(chatStateProvider).messages.single.messageStatus,
          MessageStatus.read,
        );
      },
    );
    test(
      'failed attachment retries the file rather than its path as text',
      () async {
        final notifier = await init();
        when(
          () => service.sendMessageWithAttachment(
            filePath: 'clip.mp4',
            fileName: 'clip.mp4',
            type: SendMessageType.video,
          ),
        ).thenThrow(Exception('offline'));
        await notifier.sendMessageWithAttachment(
          filePath: 'clip.mp4',
          fileName: 'clip.mp4',
          type: SendMessageType.video,
        );
        final failed = container.read(chatStateProvider).messages.single;
        expect(failed.messageStatus, MessageStatus.failed);
        when(
          () => service.sendMessageWithAttachment(
            filePath: 'clip.mp4',
            fileName: 'clip.mp4',
            type: SendMessageType.video,
          ),
        ).thenAnswer((_) async => message(9, 'clip', conversationId: 42));
        await notifier.retryMessage(failed.id!);
        verifyNever(() => service.sendMessage(any()));
        expect(container.read(chatStateProvider).isSending, isFalse);
        expect(
          container.read(chatStateProvider).messages.single.messageStatus,
          MessageStatus.sent,
        );
      },
    );
    test('repeated send taps create one submission while pending', () async {
      final notifier = await init();
      final pending = Completer<Message>();
      when(
        () => service.sendMessage('Hello'),
      ).thenAnswer((_) => pending.future);
      final sending = notifier.sendMessage('Hello');
      await notifier.sendMessage('Hello');
      pending.complete(message(7, 'Hello', conversationId: 42));
      await sending;
      verify(() => service.sendMessage('Hello')).called(1);
    });
  });
}
