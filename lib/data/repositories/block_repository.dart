/// One-directional user blocks, private to the blocker.
abstract interface class BlockRepository {
  /// Ids the current user has blocked.
  Future<List<String>> getMyBlockedIds();

  Future<void> block(String userId);

  Future<void> unblock(String userId);
}
