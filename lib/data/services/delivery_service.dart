import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/delivery.dart';
import '../../models/enums.dart';
import '../fake/fake_seed.dart';
import '../providers.dart';

/// Driver actions over the in-memory delivery board: claim a job, advance its
/// status, and (stub) attach proof photos.
class DeliveryService {
  DeliveryService(this.ref);

  final Ref ref;

  Future<void> claim(Delivery delivery) async {
    await ref.read(deliveryRepositoryProvider).updateDelivery(
          delivery.copyWith(
            driverId: FakeSeed.demoDriver.id,
            deliveryStatus: DeliveryStatus.driverAssigned,
          ),
        );
    _refresh(delivery.id);
  }

  Future<void> advance(Delivery delivery, DeliveryStatus next) async {
    await ref.read(deliveryRepositoryProvider).updateDelivery(
          delivery.copyWith(
            deliveryStatus: next,
            deliveryTime:
                next == DeliveryStatus.delivered ? DateTime.now() : null,
          ),
        );
    _refresh(delivery.id);
  }

  /// Stub proof upload — real camera/Storage upload arrives in Milestone 3.
  Future<void> addProofOfPickup(Delivery delivery) async {
    await ref.read(deliveryRepositoryProvider).updateDelivery(
          delivery.copyWith(
            proofOfPickup:
                'https://example.com/proof/pickup_${delivery.id}.jpg',
          ),
        );
    _refresh(delivery.id);
  }

  Future<void> addProofOfDelivery(Delivery delivery) async {
    await ref.read(deliveryRepositoryProvider).updateDelivery(
          delivery.copyWith(
            proofOfDelivery:
                'https://example.com/proof/delivery_${delivery.id}.jpg',
          ),
        );
    _refresh(delivery.id);
  }

  void _refresh(String deliveryId) {
    ref.invalidate(openJobsProvider);
    ref.invalidate(myDeliveriesProvider);
    ref.invalidate(deliveryByIdProvider(deliveryId));
  }
}
