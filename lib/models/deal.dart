import 'enums.dart';

/// A deal between a buyer and seller (was `transactions`; BRAIN §6).
class Deal {
  const Deal({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    this.driverId,
    required this.quantity,
    required this.pricePerPallet,
    this.fulfillmentMethod = FulfillmentMethod.pickup,
    this.deliveryAddress,
    this.deliveryFee = 0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.dealStatus = DealStatus.pending,
    this.pickupTime,
    this.completedAt,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final String? driverId;
  final int quantity;
  final double pricePerPallet;
  final FulfillmentMethod fulfillmentMethod;
  final String? deliveryAddress;
  final double deliveryFee;
  final PaymentStatus paymentStatus;
  final DealStatus dealStatus;
  final DateTime? pickupTime;
  final DateTime? completedAt;
  final String? notes;
  final DateTime? createdAt;

  /// total_price = quantity × price_per_pallet (BRAIN §6, §7).
  double get totalPrice => quantity * pricePerPallet;

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
        id: json['id'] as String,
        listingId: json['listing_id'] as String,
        buyerId: json['buyer_id'] as String,
        sellerId: json['seller_id'] as String,
        driverId: json['driver_id'] as String?,
        quantity: json['quantity'] as int? ?? 0,
        pricePerPallet: (json['price_per_pallet'] as num?)?.toDouble() ?? 0,
        fulfillmentMethod: FulfillmentMethod.fromValue(
                json['fulfillment_method'] as String?) ??
            FulfillmentMethod.pickup,
        deliveryAddress: json['delivery_address'] as String?,
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
        paymentStatus:
            PaymentStatus.fromValue(json['payment_status'] as String?) ??
                PaymentStatus.unpaid,
        dealStatus: DealStatus.fromValue(json['deal_status'] as String?) ??
            DealStatus.pending,
        pickupTime: json['pickup_time'] == null
            ? null
            : DateTime.parse(json['pickup_time'] as String),
        completedAt: json['completed_at'] == null
            ? null
            : DateTime.parse(json['completed_at'] as String),
        notes: json['notes'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'listing_id': listingId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'driver_id': driverId,
        'quantity': quantity,
        'price_per_pallet': pricePerPallet,
        'total_price': totalPrice,
        'fulfillment_method': fulfillmentMethod.value,
        'delivery_address': deliveryAddress,
        'delivery_fee': deliveryFee,
        'payment_status': paymentStatus.value,
        'deal_status': dealStatus.value,
        'pickup_time': pickupTime?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt?.toIso8601String(),
      };

  Deal copyWith({
    String? id,
    String? listingId,
    String? buyerId,
    String? sellerId,
    String? driverId,
    int? quantity,
    double? pricePerPallet,
    FulfillmentMethod? fulfillmentMethod,
    String? deliveryAddress,
    double? deliveryFee,
    PaymentStatus? paymentStatus,
    DealStatus? dealStatus,
    DateTime? pickupTime,
    DateTime? completedAt,
    String? notes,
    DateTime? createdAt,
  }) =>
      Deal(
        id: id ?? this.id,
        listingId: listingId ?? this.listingId,
        buyerId: buyerId ?? this.buyerId,
        sellerId: sellerId ?? this.sellerId,
        driverId: driverId ?? this.driverId,
        quantity: quantity ?? this.quantity,
        pricePerPallet: pricePerPallet ?? this.pricePerPallet,
        fulfillmentMethod: fulfillmentMethod ?? this.fulfillmentMethod,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        dealStatus: dealStatus ?? this.dealStatus,
        pickupTime: pickupTime ?? this.pickupTime,
        completedAt: completedAt ?? this.completedAt,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}
