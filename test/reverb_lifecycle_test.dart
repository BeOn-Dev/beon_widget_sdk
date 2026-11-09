import 'dart:async';
import 'dart:convert';
import 'package:beon_widget_sdk/src/data/services/reverb_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _Channel extends Mock implements WebSocketChannel {}

class _Sink extends Mock implements WebSocketSink {}

void main() {
  testWidgets(
    'public socket subscribes after handshake and reconnects without leaked timers',
    (tester) async {
      final streams = <StreamController<dynamic>>[];
      final sinks = <_Sink>[];
      final endpoints = <Uri>[];
      WebSocketChannel connect(Uri uri) {
        endpoints.add(uri);
        final stream = StreamController<dynamic>();
        final sink = _Sink();
        final channel = _Channel();
        streams.add(stream);
        sinks.add(sink);
        when(() => channel.stream).thenAnswer((_) => stream.stream);
        when(() => channel.sink).thenReturn(sink);
        when(() => channel.ready).thenAnswer((_) async {});
        when(() => sink.close()).thenAnswer((_) async {});
        return channel;
      }

      final events = <String>[];
      final socket = SimpleFlutterReverb(
        endpoint: Uri.parse('wss://ws.beon.chat'),
        connector: connect,
      );
      socket.listen(
        (event) => events.add((event as WebsocketResponse).event),
        'tickets_public_ticket-uuid',
      );
      await tester.pump();
      verifyNever(() => sinks.first.add(any()));
      streams.first.add(
        jsonEncode({
          'event': 'pusher:connection_established',
          'data': {'socket_id': 'test'},
        }),
      );
      await tester.pump();
      final subscription = jsonDecode(
        verify(() => sinks.first.add(captureAny())).captured.single as String,
      );
      expect(subscription['data']['channel'], 'tickets_public_ticket-uuid');
      expect(endpoints.single.host, 'ws.beon.chat');
      await streams.first.close();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(streams.length, 2);
      expect(events, contains('beon:disconnected'));
      streams.last.add(
        jsonEncode({'event': 'pusher:connection_established', 'data': '{}'}),
      );
      await tester.pump();
      verify(() => sinks.last.add(any())).called(1);
      socket.close();
      unawaited(streams.last.close());
      await tester.pump(const Duration(seconds: 30));
      expect(streams.length, 2);
    },
  );
}
