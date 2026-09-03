import '../../models/delivery.dart';

abstract interface class DeliveryRepository {
  /// Open, unclaimed delivery jobs (no driver assigned yet).
  Future<List<Delivery>> getOpenJobs();

  /// Deliveries assigned to a driver.
  Future<List<Delivery>> getDeliveriesForDriver(String driverId);

  Future<Delivery?> getDeliveryById(String id);

  /// Creates a job for a delivery deal (called when a delivery deal is
  /// accepted). Driver is unassigned until claimed.
  Future<Delivery> createDelivery(Delivery delivery);

  Future<Delivery> updateDelivery(Delivery delivery);
}
