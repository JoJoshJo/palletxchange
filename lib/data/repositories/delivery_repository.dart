import '../../models/delivery.dart';

abstract interface class DeliveryRepository {
  /// Open, unclaimed delivery jobs (no driver assigned yet).
  Future<List<Delivery>> getOpenJobs();

  /// Deliveries assigned to a driver.
  Future<List<Delivery>> getDeliveriesForDriver(String driverId);

  Future<Delivery?> getDeliveryById(String id);

  Future<Delivery> updateDelivery(Delivery delivery);
}
