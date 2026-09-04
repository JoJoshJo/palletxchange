import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_notification.dart';
import '../repositories/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseClient get _c => Supabase.instance.client;
  String get _uid => _c.auth.currentUser?.id ?? '';

  @override
  Future<List<AppNotification>> getMyNotifications() async {
    final rows = await _c
        .from('notifications')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List).map((r) => AppNotification.fromJson(r)).toList();
  }

  @override
  Future<void> markRead(String id) async {
    await _c.from('notifications').update({'read': true}).eq('id', id);
  }

  @override
  Future<void> markAllRead() async {
    await _c
        .from('notifications')
        .update({'read': true})
        .eq('user_id', _uid)
        .eq('read', false);
  }
}

/// Ungated-dev fallback.
class FakeNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> getMyNotifications() async => const [];
  @override
  Future<void> markRead(String id) async {}
  @override
  Future<void> markAllRead() async {}
}
