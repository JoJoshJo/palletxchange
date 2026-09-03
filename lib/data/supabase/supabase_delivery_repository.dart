import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/delivery.dart';
import '../../models/enums.dart';
import '../repositories/delivery_repository.dart';

/// Real [DeliveryRepository]. Card fields (title, qty, fee, cities) are pulled
/// from the linked deal + listing via an embed; the deliveries table stores
/// only addresses, status, and proof URLs.
class SupabaseDeliveryRepository implements DeliveryRepository {
  SupabaseClient get _c => Supabase.instance.client;

  static const _select =
      '*, deal:deals(quantity, delivery_fee, delivery_address, '
      'listing:listings(title, city))';

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.parse(v as String);

  static String? _cityOf(String address) {
    final parts = address.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 2) return parts[parts.length - 2];
    return address.isEmpty ? null : address;
  }

  Delivery _fromRow(Map<String, dynamic> row) {
    final deal = row['deal'] as Map<String, dynamic>?;
    final listing = deal?['listing'] as Map<String, dynamic>?;
    final dropoff = row['dropoff_address'] as String? ?? '';
    return Delivery(
      id: row['id'] as String,
      dealId: row['deal_id'] as String,
      driverId: row['driver_id'] as String?,
      pickupAddress: row['pickup_address'] as String? ?? '',
      dropoffAddress: dropoff,
      pickupTime: _dt(row['pickup_time']),
      deliveryTime: _dt(row['delivery_time']),
      deliveryStatus:
          DeliveryStatus.fromValue(row['delivery_status'] as String?) ??
              DeliveryStatus.requested,
      proofOfPickup: row['proof_of_pickup'] as String?,
      proofOfDelivery: row['proof_of_delivery'] as String?,
      deliveryNotes: row['delivery_notes'] as String?,
      createdAt: _dt(row['created_at']),
      pickupCity: listing?['city'] as String?,
      dropoffCity: _cityOf(dropoff),
      listingTitle: listing?['title'] as String?,
      quantity: deal?['quantity'] as int?,
      deliveryFee: (deal?['delivery_fee'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<List<Delivery>> getOpenJobs() async {
    final rows = await _c
        .from('deliveries')
        .select(_select)
        .isFilter('driver_id', null)
        .eq('delivery_status', 'requested')
        .order('created_at', ascending: false);
    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  @override
  Future<List<Delivery>> getDeliveriesForDriver(String driverId) async {
    final rows = await _c
        .from('deliveries')
        .select(_select)
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  @override
  Future<Delivery?> getDeliveryById(String id) async {
    final row =
        await _c.from('deliveries').select(_select).eq('id', id).maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Delivery> createDelivery(Delivery delivery) async {
    final payload = {
      'deal_id': delivery.dealId,
      'pickup_address': delivery.pickupAddress,
      'dropoff_address': delivery.dropoffAddress,
      'delivery_status': delivery.deliveryStatus.value,
    };
    final row =
        await _c.from('deliveries').insert(payload).select(_select).single();
    return _fromRow(row);
  }

  @override
  Future<Delivery> updateDelivery(Delivery delivery) async {
    final payload = {
      'driver_id': delivery.driverId,
      'delivery_status': delivery.deliveryStatus.value,
      'pickup_time': delivery.pickupTime?.toIso8601String(),
      'delivery_time': delivery.deliveryTime?.toIso8601String(),
      'proof_of_pickup': delivery.proofOfPickup,
      'proof_of_delivery': delivery.proofOfDelivery,
      'delivery_notes': delivery.deliveryNotes,
    };
    final row = await _c
        .from('deliveries')
        .update(payload)
        .eq('id', delivery.id)
        .select(_select)
        .maybeSingle();
    return row == null ? delivery : _fromRow(row);
  }
}
