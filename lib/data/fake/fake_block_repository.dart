import '../repositories/block_repository.dart';

class FakeBlockRepository implements BlockRepository {
  final Set<String> _blocked = {};

  @override
  Future<List<String>> getMyBlockedIds() async => _blocked.toList();

  @override
  Future<void> block(String userId) async {
    _blocked.add(userId);
  }

  @override
  Future<void> unblock(String userId) async {
    _blocked.remove(userId);
  }
}
