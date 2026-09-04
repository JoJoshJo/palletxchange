/// An in-app notification row (BRAIN §9). Push (FCM) is layered on later.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.dealId,
    this.requestId,
    this.conversationId,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final String? dealId;
  final String? requestId;
  final String? conversationId;
  final bool read;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String?,
        dealId: json['deal_id'] as String?,
        requestId: json['request_id'] as String?,
        conversationId: json['conversation_id'] as String?,
        read: json['read'] as bool? ?? false,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );
}
