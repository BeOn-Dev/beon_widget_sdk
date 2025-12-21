import 'package:flutter/foundation.dart';

import '../utils/app_functions/app_functions.dart';

/// Type of message content

/// Status of a sent message
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
  unread,
}

/// Reaction/emoji on a message
@immutable
class MessageReaction {
  final int? id;
  final String? emoji;

  const MessageReaction({this.id, this.emoji});

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'],
      emoji: json['emoji'],
    );
  }

  Map<String, dynamic> toJson() =>
      {
        if (id != null) 'id': id,
        if (emoji != null) 'emoji': emoji,
      };
}
enum SendMessageType {
  text,
  audio,
  document,
  image,
  note,
  video,
  location,
  info,
  sticker,
  stored_document
}
enum MessageType {
  myMessage,
  clientMessage,
}

/// Represents a chat message
@immutable
class Message {
  int? id;
  String? uId;
  int? conversationId;

  String? body;
  String? localPath;
  String? status;
  SendMessageType? type;
  MessageType? messageType;
  String? messageId;
  String? createdAt;
  int? channelId;
  String? agentName;
  MessageStatus? messageStatus;
  ReactModel? react;
  double? longitude;
  double? latitude;
  Message? replay;
  DocumentFileType? documentFileType;
  bool? isSendingError;
  LibraryModel? libraryModel;

  Message({
    this.id,
    this.body,
    this.status,
    this.type,
    this.messageType,
    this.messageId,
    this.createdAt,
    this.react,
    this.conversationId,
    this.localPath,
    this.channelId,
    this.agentName,
    this.messageStatus,
    this.uId,
    this.documentFileType,
    this.replay,
    this.isSendingError,
    this.longitude,
    this.latitude,
    this.libraryModel,
  });

  Message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    // Sanitize body to prevent UTF-16 encoding errors
    // BUT don't sanitize URLs (audio/video/image/document) as it corrupts them
    if (json['body'] != null) {
      final bodyStr = json['body'].toString();
      // Check if it's a URL - don't sanitize URLs
      if (bodyStr.startsWith('http://') || bodyStr.startsWith('https://')) {
        body = bodyStr; // Keep URL intact
      } else {
        body = AppFunctions.sanitizeString(bodyStr); // Sanitize text only
      }
    } else {
      body = null;
    }
    uId = json['uid']?.toString();
    status = json['status']?.toString();
    conversationId = json['conversation_id'] != null
        ? int.parse(json['conversation_id'].toString())
        : null;
    type = json['type'] != null
        ? AppFunctions.getSendMessageType(type: json['type'])
        : null;

    if (json['message_type'] != null) {
      messageType = AppFunctions.getMessageType(messageType: json["message_type"]);
    }

    messageId = json['message_id']?.toString();
    createdAt = json['created_at']?.toString();
    agentName = json['agent_name'] != null
        ? AppFunctions.sanitizeString(json['agent_name'].toString())
        : null;
    longitude = json['long'] != null ? double.tryParse(json['long'].toString()) : null;
    latitude = json['lat'] != null ? double.tryParse(json['lat'].toString()) : null;
    messageStatus = json['status'] != null
        ? AppFunctions.getMessageStatus(status: json['status'])
        : null;

    react = json['react'] != null ? ReactModel.fromJson(json['react']) : null;
    replay =
    json['replay'] != null ? Message.fromJson(json['replay']) : null;
  }


  /// Convert to JSON

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

}

/// Response metadata for paginated messages
@immutable
class MessagesMeta {
  final int currentPage;
  final int total;
  final int lastPage;
  final int perPage;

  const MessagesMeta({
    required this.currentPage,
    required this.total,
    required this.lastPage,
    required this.perPage,
  });

  factory MessagesMeta.fromJson(Map<String, dynamic> json) {
    return MessagesMeta(
      currentPage: int.tryParse(json['current_page']?.toString() ?? '1') ?? 1,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
    );
  }
}

/// Response wrapper for messages API
@immutable
class MessagesResponse {
  final MessagesMeta meta;
  final List<Message> messages;
  final int? conversationId;

  const MessagesResponse({
    required this.meta,
    required this.messages,
    this.conversationId,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final records = data['records'] ?? data['messages'] ?? [];


    // Extract conversation ID from data.conversation.id
    int? convId;
    if (data['conversation'] != null) {
      final conv = data['conversation'];
      if (conv is Map) {
        convId = conv['id'] is int
            ? conv['id']
            : int.tryParse(conv['id']?.toString() ?? '');
      }
    }

    return MessagesResponse(
      meta: MessagesMeta.fromJson(data['meta'] ?? {}),
      messages: ((records as List)
          .map((record) => Message.fromJson(record))
          .toList()).toSet().toList(),
      conversationId: convId,
    );
  }
}


class ReactModel {
  int? id;
  String? emoji;

  ReactModel({this.id, this.emoji});

  ReactModel.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    // Sanitize emoji to prevent UTF-16 encoding errors
    emoji = json["emoji"] != null
        ? AppFunctions.sanitizeString(json["emoji"])
        : null;
  }

  @override
  List<Object> get props => [
    id??0,
    emoji??"",
  ];

}


enum DocumentFileType { pdf, word, excel, etc }
class LibraryModel  {
  int? id;
  String? name;
  String? description;
  String? uId;
  String? file;
  int? createdBy;
  int? accountId;
  SendMessageType? subType;
  SendMessageType? type;
  int? useTimes;
  int? conversationId;
  Message? replyMessage;

  LibraryModel({
    this.id,
    this.name,
    this.uId,
    this.description,
    this.file,
    this.createdBy,
    this.accountId,
    this.type,
    this.useTimes,
    this.conversationId,
    this.replyMessage,
  });

  LibraryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    file = json['file'];
    createdBy = json['created_by'];
    accountId = json['account_id'];
    subType = json['type'] != null
        ? AppFunctions.getSendMessageType(type: json['type'])
        : null;
    type = SendMessageType.stored_document;
    useTimes = json['use_times'];
  }

  Map<String, dynamic> toJson() => {
    "media_url": file,
    "sub_type": subType?.name,
    "type": type?.name,
    "uid": uId,
    "file_id": id,
    "conversation_id": conversationId,
    if (replyMessage != null)
      "replay": {"body": replyMessage?.body, "replay_id": replyMessage?.id}
  };

  @override
  // TODO: implement props
  List<Object?> get props => [
    id,
    name,
    description,
    file,
    uId,
    createdBy,
    accountId,
    type,
    useTimes,
    conversationId,
    replyMessage,
  ];
}