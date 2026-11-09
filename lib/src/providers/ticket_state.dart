import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket.dart';
import '../data/services/ticket_service.dart';
import '../data/services/reverb_service.dart';
import 'providers.dart';

class TicketState {
  final TicketPage page;
  final String filter;
  final SupportTicket? selected;
  final List<TicketReply> replies;
  final bool loading;
  final bool submitting;
  final bool loadingMore;
  final bool hasMoreReplies;
  final String? error;
  const TicketState({
    this.page = const TicketPage(),
    this.filter = 'all',
    this.selected,
    this.replies = const [],
    this.loading = false,
    this.submitting = false,
    this.loadingMore = false,
    this.hasMoreReplies = false,
    this.error,
  });
  TicketState copyWith({
    TicketPage? page,
    String? filter,
    SupportTicket? selected,
    bool clearSelection = false,
    List<TicketReply>? replies,
    bool? loading,
    bool? submitting,
    bool? loadingMore,
    bool? hasMoreReplies,
    String? error,
  }) => TicketState(
    page: page ?? this.page,
    filter: filter ?? this.filter,
    selected: clearSelection ? null : selected ?? this.selected,
    replies: replies ?? this.replies,
    loading: loading ?? this.loading,
    submitting: submitting ?? this.submitting,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
    error: error,
  );
}

class TicketStateNotifier extends StateNotifier<TicketState> {
  final TicketService service;
  final int? conversationId;
  int _generation = 0;
  int _listPage = 1;
  int _replyPage = 1;
  Timer? _timer;
  final ReverbService Function()? createReverb;
  final bool pollingFallback;
  ReverbService? _socket;
  TicketStateNotifier(
    this.service,
    this.conversationId, {
    this.createReverb,
    this.pollingFallback = false,
  }) : super(const TicketState());

  void selectFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> load({String? filter, bool more = false}) async {
    if (more && (state.loading || state.loadingMore || !state.page.hasMore)) {
      return;
    }
    _timer?.cancel();
    _socket?.close();
    _socket = null;
    final generation = ++_generation;
    final selectedFilter = filter ?? state.filter;
    state = state.copyWith(
      filter: selectedFilter,
      loading: !more,
      loadingMore: more,
      clearSelection: true,
      submitting: false,
      replies: [],
    );
    try {
      final pageNumber = more ? _listPage + 1 : 1;
      final page = await service.fetchTickets(
        page: pageNumber,
        status: selectedFilter,
        conversationId: conversationId,
      );
      if (!mounted || generation != _generation) return;
      _listPage = pageNumber;
      state = state.copyWith(
        page: TicketPage(
          records: more
              ? [...state.page.records, ...page.records]
              : page.records,
          counts: page.counts,
          hasMore: page.hasMore,
        ),
        loading: false,
        loadingMore: false,
      );
    } catch (_) {
      if (mounted && generation == _generation) {
        state = state.copyWith(
          loading: false,
          loadingMore: false,
          error: 'load',
        );
      }
    }
  }

  Future<void> open(SupportTicket ticket) async {
    _timer?.cancel();
    _socket?.close();
    _socket = null;
    final generation = ++_generation;
    _replyPage = 1;
    state = state.copyWith(
      selected: ticket,
      replies: [],
      loading: true,
      hasMoreReplies: false,
      loadingMore: false,
    );
    try {
      final details = await service.fetchTicket(ticket.id);
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        selected: details.ticket,
        replies: details.messages,
        loading: false,
        hasMoreReplies: details.hasMore,
      );
      _subscribe(details.ticket);
      if (pollingFallback) {
        _timer = Timer.periodic(
          const Duration(seconds: 15),
          (_) => _refreshReplies(),
        );
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        state = state.copyWith(loading: false, error: 'load');
      }
    }
  }

  void _subscribe(SupportTicket ticket) {
    if (createReverb == null) return;
    try {
      _socket = createReverb!();
      final generation = _generation;
      _socket!.listen((event) {
        if (!mounted ||
            generation != _generation ||
            event is! WebsocketResponse ||
            !['ticket_message', '.ticket_message'].contains(event.event)) {
          return;
        }
        final payload = event.data?['message'] ?? event.data;
        if (payload is! Map) return;
        final json = Map<String, dynamic>.from(payload);
        if (!TicketReply.isVisible(json) ||
            json['message_type'] == 'incoming') {
          return;
        }
        state = state.copyWith(
          replies: _merge(state.replies, [TicketReply.fromJson(json)]),
        );
      }, 'tickets_public_${ticket.uuid ?? ticket.id}');
    } catch (_) {
      _socket?.close();
      _socket = null;
    }
  }

  Future<void> _refreshReplies() async {
    final selected = state.selected;
    final generation = _generation;
    if (selected == null ||
        state.loading ||
        state.submitting ||
        state.loadingMore) {
      return;
    }
    try {
      final details = await service.fetchTicket(selected.id);
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        selected: details.ticket,
        replies: _merge(state.replies, details.messages),
      );
    } catch (_) {
      /* A background refresh keeps the currently visible conversation. */
    }
  }

  List<TicketReply> _merge(
    List<TicketReply> existing,
    List<TicketReply> incoming,
  ) {
    final byId = <String, TicketReply>{};
    for (final item in [...existing, ...incoming]) {
      byId[item.id.isNotEmpty
              ? item.id
              : '${item.createdAt}:${item.content}:${item.fromAgent}'] =
          item;
    }
    final values = byId.values.toList();
    values.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
    return values;
  }

  Future<void> loadMoreReplies() async {
    final ticket = state.selected;
    if (ticket == null ||
        state.loading ||
        state.loadingMore ||
        !state.hasMoreReplies) {
      return;
    }
    final generation = _generation;
    state = state.copyWith(loadingMore: true);
    try {
      final details = await service.fetchTicket(
        ticket.id,
        page: _replyPage + 1,
      );
      if (!mounted || generation != _generation) return;
      _replyPage++;
      state = state.copyWith(
        replies: _merge(state.replies, details.messages),
        hasMoreReplies: details.hasMore,
        loadingMore: false,
      );
    } catch (_) {
      if (mounted && generation == _generation) {
        state = state.copyWith(loadingMore: false, error: 'load');
      }
    }
  }

  Future<bool> create({
    required String categoryId,
    required String subject,
    required String description,
  }) async {
    if (state.submitting) return false;
    state = state.copyWith(submitting: true);
    try {
      final ticket = await service.createTicket(
        categoryId: categoryId,
        subject: subject,
        description: description,
        conversationId: conversationId,
      );
      if (!mounted) return false;
      state = state.copyWith(submitting: false);
      await open(ticket);
      return true;
    } catch (_) {
      if (mounted) state = state.copyWith(submitting: false, error: 'create');
      return false;
    }
  }

  Future<bool> send(String text) async {
    final ticket = state.selected;
    if (ticket == null ||
        ticket.isClosed ||
        state.submitting ||
        text.trim().isEmpty) {
      return false;
    }
    final generation = _generation;
    state = state.copyWith(submitting: true);
    try {
      final reply = await service.sendReply(ticket.id, text.trim());
      if (!mounted || generation != _generation) return true;
      final confirmed = reply == null || reply.content.isEmpty
          ? TicketReply(
              id: 'local-${DateTime.now().microsecondsSinceEpoch}',
              content: text.trim(),
              createdAt: DateTime.now().toIso8601String(),
            )
          : reply;
      state = state.copyWith(
        submitting: false,
        replies: _merge(state.replies, [confirmed]),
      );
      return true;
    } catch (_) {
      if (mounted && generation == _generation) {
        state = state.copyWith(submitting: false, error: 'send');
      }
      return false;
    }
  }

  void back() {
    _timer?.cancel();
    _socket?.close();
    _socket = null;
    load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socket?.close();
    super.dispose();
  }
}

final ticketStateProvider = StateNotifierProvider.autoDispose
    .family<TicketStateNotifier, TicketState, int?>(
      (ref, id) => TicketStateNotifier(
        ref.watch(ticketServiceProvider),
        id,
        createReverb: () => SimpleFlutterReverb(
          endpoint: Uri.parse(ref.read(configProvider).wsUrl),
        ),
        pollingFallback: ref.watch(configProvider).enablePollingFallback,
      ),
      dependencies: [ticketServiceProvider, configProvider],
    );
