import '../../models/deal.dart';
import '../repositories/deal_repository.dart';

/// In-memory [DealRepository]. Empty to start — deals are created from the
/// Request Deal flow (stubbed in Milestone 1).
class FakeDealRepository implements DealRepository {
  final List<Deal> _deals = [];
  int _idSeq = 1;

  @override
  Future<List<Deal>> getDealsForUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _deals
        .where((d) =>
            d.buyerId == userId ||
            d.sellerId == userId ||
            d.driverId == userId)
        .toList();
  }

  @override
  Future<Deal?> getDealById(String id) async {
    for (final d in _deals) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<Deal> createDeal(Deal deal) async {
    final stored = deal.copyWith(
      id: 'd_${_idSeq++}',
      createdAt: DateTime.now(),
    );
    _deals.add(stored);
    return stored;
  }
}
