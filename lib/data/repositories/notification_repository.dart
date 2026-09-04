import '../../models/app_notification.dart';

abstract interface class NotificationRepository {
  /// The current user's notifications, newest first.
  Future<List<AppNotification>> getMyNotifications();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}
