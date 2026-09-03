import '../../models/enums.dart';
import '../../models/request.dart';
import '../repositories/request_repository.dart';

/// In-memory [RequestRepository], seeded with a couple of broadcast requests.
class FakeRequestRepository implements RequestRepository {
  FakeRequestRepository() : _requests = _seed();

  final List<PalletRequest> _requests;
  int _idSeq = 100;

  static List<PalletRequest> _seed() {
    final now = DateTime(2026, 8, 26, 10);
    return [
      PalletRequest(
        id: 'r1',
        buyerId: 's4',
        quantityNeeded: 40,
        palletTypeNeeded: PalletType.standardWooden,
        palletSizeNeeded: PalletSize.s48x40,
        preferredCondition: PalletCondition.usedGood,
        maxPrice: 14.0,
        pickupOrDelivery: FulfillmentMethod.pickup,
        location: 'East Point, GA',
        notes: 'Need standard GMA pallets for a recurring shipment.',
        status: RequestStatus.open,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      PalletRequest(
        id: 'r2',
        buyerId: 's3',
        quantityNeeded: 20,
        palletTypeNeeded: PalletType.plastic,
        palletSizeNeeded: PalletSize.s48x48,
        pickupOrDelivery: FulfillmentMethod.delivery,
        location: 'Duluth, GA',
        notes: 'Food-grade plastic pallets, delivery preferred.',
        status: RequestStatus.open,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  @override
  Future<List<PalletRequest>> getOpenRequests() async {
    await _latency();
    return _requests
        .where((r) => r.targetSellerId == null && r.status == RequestStatus.open)
        .toList();
  }

  @override
  Future<List<PalletRequest>> getRequestsByBuyer(String buyerId) async {
    await _latency();
    return _requests.where((r) => r.buyerId == buyerId).toList();
  }

  @override
  Future<PalletRequest?> getRequestById(String id) async {
    await _latency();
    for (final r in _requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<PalletRequest> createRequest(PalletRequest request) async {
    await _latency();
    final stored = request.copyWith(
      id: 'r_${_idSeq++}',
      createdAt: DateTime.now(),
    );
    _requests.add(stored);
    return stored;
  }
}
