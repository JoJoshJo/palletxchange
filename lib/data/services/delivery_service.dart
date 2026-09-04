import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Uploads a proof photo to the private delivery-proof bucket, stores its
  /// path on the delivery, and notifies the delivery requester.
  /// [kind] is 'pickup' or 'delivery'.
  Future<void> uploadProof({
    required Delivery delivery,
    required String kind,
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final path = await ref.read(storageRepositoryProvider).uploadDeliveryProof(
          bytes: bytes,
          fileExtension: fileExtension,
          contentType: contentType,
          dealId: delivery.dealId,
          kind: kind,
        );
    await ref.read(deliveryRepositoryProvider).updateDelivery(
          kind == 'pickup'
              ? delivery.copyWith(proofOfPickup: path)
              : delivery.copyWith(proofOfDelivery: path),
        );
    // Notify the requester (buyer/seller per delivery_paid_by) via RPC.
    try {
      await Supabase.instance.client.rpc('notify_delivery_proof', params: {
        'p_deal': delivery.dealId,
        'p_kind': kind,
      });
    } catch (_) {/* notification is best-effort */}
    _refresh(delivery.id);
    ref.invalidate(deliveryForDealProvider(delivery.dealId));
  }

  void _refresh(String deliveryId) {
    ref.invalidate(openJobsProvider);
    ref.invalidate(myDeliveriesProvider);
    ref.invalidate(deliveryByIdProvider(deliveryId));
  }
}
