import 'enums.dart';

/// A driver job-board entry tied to a delivery deal (BRAIN §6).
class Delivery {
  const Delivery({
    required this.id,
    required this.dealId,
    this.driverId,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupTime,
    this.deliveryTime,
    this.deliveryStatus = DeliveryStatus.requested,
    this.proofOfPickup,
    this.proofOfDelivery,
    this.deliveryNotes,
    this.createdAt,
    // UI-only denormalized fields for the job card.
    this.pickupCity,
    this.dropoffCity,
    this.listingTitle,
    this.quantity,
    this.deliveryFee = 0,
    this.legMiles,
  });

  final String id;
  final String dealId;
  final String? driverId;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final DeliveryStatus deliveryStatus;
  final String? proofOfPickup;
  final String? proofOfDelivery;
  final String? deliveryNotes;
  final DateTime? createdAt;

  final String? pickupCity;
  final String? dropoffCity;
  final String? listingTitle;
  final int? quantity;
  final double deliveryFee;
  final double? legMiles;

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
        id: json['id'] as String,
        dealId: json['deal_id'] as String,
        driverId: json['driver_id'] as String?,
        pickupAddress: json['pickup_address'] as String? ?? '',
        dropoffAddress: json['dropoff_address'] as String? ?? '',
        pickupTime: json['pickup_time'] == null
            ? null
            : DateTime.parse(json['pickup_time'] as String),
        deliveryTime: json['delivery_time'] == null
            ? null
            : DateTime.parse(json['delivery_time'] as String),
        deliveryStatus:
            DeliveryStatus.fromValue(json['delivery_status'] as String?) ??
                DeliveryStatus.requested,
        proofOfPickup: json['proof_of_pickup'] as String?,
        proofOfDelivery: json['proof_of_delivery'] as String?,
        deliveryNotes: json['delivery_notes'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deal_id': dealId,
        'driver_id': driverId,
        'pickup_address': pickupAddress,
        'dropoff_address': dropoffAddress,
        'pickup_time': pickupTime?.toIso8601String(),
        'delivery_time': deliveryTime?.toIso8601String(),
        'delivery_status': deliveryStatus.value,
        'proof_of_pickup': proofOfPickup,
        'proof_of_delivery': proofOfDelivery,
        'delivery_notes': deliveryNotes,
        'created_at': createdAt?.toIso8601String(),
      };

  Delivery copyWith({
    String? driverId,
    DeliveryStatus? deliveryStatus,
    DateTime? pickupTime,
    DateTime? deliveryTime,
    String? proofOfPickup,
    String? proofOfDelivery,
    String? deliveryNotes,
  }) =>
      Delivery(
        id: id,
        dealId: dealId,
        driverId: driverId ?? this.driverId,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        pickupTime: pickupTime ?? this.pickupTime,
        deliveryTime: deliveryTime ?? this.deliveryTime,
        deliveryStatus: deliveryStatus ?? this.deliveryStatus,
        proofOfPickup: proofOfPickup ?? this.proofOfPickup,
        proofOfDelivery: proofOfDelivery ?? this.proofOfDelivery,
        deliveryNotes: deliveryNotes ?? this.deliveryNotes,
        createdAt: createdAt,
        pickupCity: pickupCity,
        dropoffCity: dropoffCity,
        listingTitle: listingTitle,
        quantity: quantity,
        deliveryFee: deliveryFee,
        legMiles: legMiles,
      );
}
