/// A chat message (BRAIN §6). The thread ties to whichever of listing / deal /
/// request started it — threads never open as bare DMs.
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    this.listingId,
    this.dealId,
    this.requestId,
    required this.body,
    this.readStatus = false,
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String? listingId;
  final String? dealId;
  final String? requestId;
  final String body;
  final bool readStatus;
  final DateTime? createdAt;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        receiverId: json['receiver_id'] as String,
        listingId: json['listing_id'] as String?,
        dealId: json['deal_id'] as String?,
        requestId: json['request_id'] as String?,
        body: json['body'] as String? ?? '',
        readStatus: json['read_status'] as bool? ?? false,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'listing_id': listingId,
        'deal_id': dealId,
        'request_id': requestId,
        'body': body,
        'read_status': readStatus,
        'created_at': createdAt?.toIso8601String(),
      };

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? listingId,
    String? dealId,
    String? requestId,
    String? body,
    bool? readStatus,
    DateTime? createdAt,
  }) =>
      Message(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        senderId: senderId ?? this.senderId,
        receiverId: receiverId ?? this.receiverId,
        listingId: listingId ?? this.listingId,
        dealId: dealId ?? this.dealId,
        requestId: requestId ?? this.requestId,
        body: body ?? this.body,
        readStatus: readStatus ?? this.readStatus,
        createdAt: createdAt ?? this.createdAt,
      );
}
