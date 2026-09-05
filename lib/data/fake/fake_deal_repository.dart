import '../../models/deal.dart';
import '../../models/enums.dart';
import '../repositories/deal_repository.dart';

/// In-memory [DealRepository], seeded with ~5 deals spanning states for the
/// demo trader ('me') — some buy-side, some sell-side.
///
/// The reserve-on-accept inventory logic lives in the DealService layer (it
/// spans deals + listings); this repository just stores deals.
class FakeDealRepository implements DealRepository {
  FakeDealRepository() : _deals = _seed();

  final List<Deal> _deals;
  int _idSeq = 100;

  static List<Deal> _seed() {
    final now = DateTime(2026, 8, 25, 9);
    return [
      // ── Buy-side (me = buyer) ──
      Deal(
        id: 'd1',
        listingId: 'l2',
        buyerId: 'me',
        sellerId: 's2',
        quantity: 10,
        pricePerPallet: 18.00,
        fulfillmentMethod: FulfillmentMethod.delivery,
        deliveryAddress: '120 Peachtree Center Ave, Atlanta, GA',
        paymentStatus: PaymentStatus.unpaid,
        dealStatus: DealStatus.pending,
        notes: 'Need HT pallets for an export order.',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Deal(
        id: 'd2',
        listingId: 'l1',
        buyerId: 'me',
        sellerId: 's1',
        quantity: 20,
        pricePerPallet: 12.50,
        fulfillmentMethod: FulfillmentMethod.pickup,
        paymentStatus: PaymentStatus.unpaid,
        dealStatus: DealStatus.accepted,
        pickupTime: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Deal(
        id: 'd3',
        listingId: 'l5',
        buyerId: 'me',
        sellerId: 's5',
        quantity: 8,
        pricePerPallet: 21.50,
        fulfillmentMethod: FulfillmentMethod.pickup,
        paymentStatus: PaymentStatus.paid,
        dealStatus: DealStatus.completed,
        completedAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      // ── Sell-side (me = seller, my listings l9 / l10) ──
      Deal(
        id: 'd4',
        listingId: 'l9',
        buyerId: 's3',
        sellerId: 'me',
        quantity: 15,
        pricePerPallet: 10.00,
        fulfillmentMethod: FulfillmentMethod.delivery,
        deliveryAddress: '3500 Peachtree Industrial Blvd, Duluth, GA',
        paymentStatus: PaymentStatus.unpaid,
        dealStatus: DealStatus.pending,
        notes: 'Can you deliver by Friday?',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Deal(
        id: 'd5',
        listingId: 'l10',
        buyerId: 's4',
        sellerId: 'me',
        quantity: 25,
        pricePerPallet: 8.00,
        fulfillmentMethod: FulfillmentMethod.pickup,
        paymentStatus: PaymentStatus.unpaid,
        dealStatus: DealStatus.accepted,
        pickupTime: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  @override
  Future<List<Deal>> getDealsForUser(String userId,
      {int limit = 25, int offset = 0}) async {
    await _latency();
    final all = _deals
        .where((d) =>
            d.buyerId == userId ||
            d.sellerId == userId ||
            d.driverId == userId)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
    if (offset >= all.length) return const [];
    return all.sublist(offset, (offset + limit).clamp(0, all.length));
  }

  @override
  Future<List<Deal>> getAllDeals({int limit = 25, int offset = 0}) async {
    await _latency();
    if (offset >= _deals.length) return const [];
    return _deals.sublist(offset, (offset + limit).clamp(0, _deals.length));
  }

  @override
  Future<Deal?> getDealById(String id) async {
    await _latency();
    for (final d in _deals) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<Deal> createDeal(Deal deal) async {
    await _latency();
    final stored = deal.copyWith(
      id: 'd_${_idSeq++}',
      createdAt: DateTime.now(),
    );
    _deals.add(stored);
    return stored;
  }

  @override
  Future<int> activeDealCountForListing(String listingId) async {
    await _latency();
    return _deals
        .where((d) =>
            d.listingId == listingId &&
            (d.dealStatus == DealStatus.pending ||
                d.dealStatus == DealStatus.accepted))
        .length;
  }

  @override
  Future<Deal> updateDeal(Deal deal) async {
    await _latency();
    final i = _deals.indexWhere((d) => d.id == deal.id);
    if (i != -1) _deals[i] = deal;
    return deal;
  }
}
