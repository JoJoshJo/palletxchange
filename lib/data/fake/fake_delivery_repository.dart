import '../../models/delivery.dart';
import '../../models/enums.dart';
import '../repositories/delivery_repository.dart';

/// In-memory [DeliveryRepository]. Seeded with a few open jobs (delivery deals
/// with no driver yet) plus one in-progress delivery assigned to the demo
/// driver.
class FakeDeliveryRepository implements DeliveryRepository {
  FakeDeliveryRepository() : _deliveries = _seed();

  final List<Delivery> _deliveries;

  static List<Delivery> _seed() {
    final now = DateTime(2026, 8, 26, 8);
    return [
      Delivery(
        id: 'del1',
        dealId: 'd1',
        pickupAddress: '1200 Foster St NW, Atlanta, GA 30318',
        dropoffAddress: '120 Peachtree Center Ave, Atlanta, GA 30303',
        deliveryStatus: DeliveryStatus.requested,
        pickupCity: 'Atlanta',
        dropoffCity: 'Atlanta',
        listingTitle: 'Heat-treated (ISPM-15) export pallets',
        quantity: 10,
        deliveryFee: 85,
        legMiles: 4.2,
        createdAt: now,
      ),
      Delivery(
        id: 'del2',
        dealId: 'seed-open-2',
        pickupAddress: '3500 Peachtree Industrial Blvd, Duluth, GA 30096',
        dropoffAddress: '900 Circle 75 Pkwy, Atlanta, GA 30339',
        deliveryStatus: DeliveryStatus.requested,
        pickupCity: 'Duluth',
        dropoffCity: 'Atlanta',
        listingTitle: 'Plastic pallets — hygienic, 48x48',
        quantity: 24,
        deliveryFee: 140,
        legMiles: 22.6,
        createdAt: now,
      ),
      Delivery(
        id: 'del3',
        dealId: 'seed-open-3',
        pickupAddress: '2100 Cobb Pkwy, Smyrna, GA 30080',
        dropoffAddress: '55 Ivan Allen Jr Blvd, Atlanta, GA 30308',
        deliveryStatus: DeliveryStatus.requested,
        pickupCity: 'Smyrna',
        dropoffCity: 'Atlanta',
        listingTitle: 'Euro (EPAL) pallets — certified',
        quantity: 16,
        deliveryFee: 110,
        legMiles: 11.4,
        createdAt: now,
      ),
      // In-progress, already assigned to the demo driver.
      Delivery(
        id: 'del4',
        dealId: 'seed-assigned-1',
        driverId: 'driver_me',
        pickupAddress: '1000 Marietta St NW, Atlanta, GA 30318',
        dropoffAddress: '4300 Buford Hwy, Chamblee, GA 30341',
        deliveryStatus: DeliveryStatus.pickedUp,
        pickupCity: 'Atlanta',
        dropoffCity: 'Chamblee',
        listingTitle: 'Standard 48x40 pallets — steady supply',
        quantity: 30,
        deliveryFee: 120,
        legMiles: 13.1,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      // A completed delivery (feeds Earnings).
      Delivery(
        id: 'del5',
        dealId: 'seed-done-1',
        driverId: 'driver_me',
        pickupAddress: '500 Bishop St NW, Atlanta, GA 30318',
        dropoffAddress: '191 Peachtree St NE, Atlanta, GA 30303',
        deliveryStatus: DeliveryStatus.completed,
        pickupCity: 'Atlanta',
        dropoffCity: 'Atlanta',
        listingTitle: 'Block pallets — heavy duty 48x48',
        quantity: 12,
        deliveryFee: 75,
        legMiles: 3.4,
        proofOfPickup: 'https://example.com/proof/pickup_del5.jpg',
        proofOfDelivery: 'https://example.com/proof/delivery_del5.jpg',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  @override
  Future<List<Delivery>> getOpenJobs() async {
    await _latency();
    return _deliveries
        .where((d) =>
            d.driverId == null && d.deliveryStatus == DeliveryStatus.requested)
        .toList();
  }

  @override
  Future<List<Delivery>> getDeliveriesForDriver(String driverId) async {
    await _latency();
    return _deliveries.where((d) => d.driverId == driverId).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
  }

  @override
  Future<Delivery?> getDeliveryById(String id) async {
    await _latency();
    for (final d in _deliveries) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<Delivery> updateDelivery(Delivery delivery) async {
    await _latency();
    final i = _deliveries.indexWhere((d) => d.id == delivery.id);
    if (i != -1) _deliveries[i] = delivery;
    return delivery;
  }
}
