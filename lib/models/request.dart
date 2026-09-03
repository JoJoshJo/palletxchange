import 'enums.dart';

/// A buyer's Special Request (BRAIN §6). `targetSellerId` null = broadcast to
/// the market; set = a targeted request to one seller.
class PalletRequest {
  const PalletRequest({
    required this.id,
    required this.buyerId,
    this.targetSellerId,
    this.palletTypeNeeded,
    this.palletSizeNeeded,
    required this.quantityNeeded,
    this.preferredCondition,
    this.maxPrice,
    this.pickupOrDelivery = FulfillmentMethod.pickup,
    this.neededByDate,
    this.location,
    this.notes,
    this.status = RequestStatus.open,
    this.createdAt,
  });

  final String id;
  final String buyerId;
  final String? targetSellerId;
  final PalletType? palletTypeNeeded;
  final PalletSize? palletSizeNeeded;
  final int quantityNeeded;
  final PalletCondition? preferredCondition;
  final double? maxPrice;
  final FulfillmentMethod pickupOrDelivery;
  final DateTime? neededByDate;
  final String? location;
  final String? notes;
  final RequestStatus status;
  final DateTime? createdAt;

  bool get isBroadcast => targetSellerId == null;

  factory PalletRequest.fromJson(Map<String, dynamic> json) => PalletRequest(
        id: json['id'] as String,
        buyerId: json['buyer_id'] as String,
        targetSellerId: json['target_seller_id'] as String?,
        palletTypeNeeded:
            PalletType.fromValue(json['pallet_type_needed'] as String?),
        palletSizeNeeded:
            PalletSize.fromValue(json['pallet_size_needed'] as String?),
        quantityNeeded: json['quantity_needed'] as int? ?? 0,
        preferredCondition:
            PalletCondition.fromValue(json['preferred_condition'] as String?),
        maxPrice: (json['max_price'] as num?)?.toDouble(),
        pickupOrDelivery:
            FulfillmentMethod.fromValue(json['pickup_or_delivery'] as String?) ??
                FulfillmentMethod.pickup,
        neededByDate: json['needed_by_date'] == null
            ? null
            : DateTime.parse(json['needed_by_date'] as String),
        location: json['location'] as String?,
        notes: json['notes'] as String?,
        status: RequestStatus.fromValue(json['status'] as String?) ??
            RequestStatus.open,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'buyer_id': buyerId,
        'target_seller_id': targetSellerId,
        'pallet_type_needed': palletTypeNeeded?.value,
        'pallet_size_needed': palletSizeNeeded?.value,
        'quantity_needed': quantityNeeded,
        'preferred_condition': preferredCondition?.value,
        'max_price': maxPrice,
        'pickup_or_delivery': pickupOrDelivery.value,
        'needed_by_date': neededByDate?.toIso8601String(),
        'location': location,
        'notes': notes,
        'status': status.value,
        'created_at': createdAt?.toIso8601String(),
      };

  PalletRequest copyWith({
    String? id,
    String? buyerId,
    String? targetSellerId,
    PalletType? palletTypeNeeded,
    PalletSize? palletSizeNeeded,
    int? quantityNeeded,
    PalletCondition? preferredCondition,
    double? maxPrice,
    FulfillmentMethod? pickupOrDelivery,
    DateTime? neededByDate,
    String? location,
    String? notes,
    RequestStatus? status,
    DateTime? createdAt,
  }) =>
      PalletRequest(
        id: id ?? this.id,
        buyerId: buyerId ?? this.buyerId,
        targetSellerId: targetSellerId ?? this.targetSellerId,
        palletTypeNeeded: palletTypeNeeded ?? this.palletTypeNeeded,
        palletSizeNeeded: palletSizeNeeded ?? this.palletSizeNeeded,
        quantityNeeded: quantityNeeded ?? this.quantityNeeded,
        preferredCondition: preferredCondition ?? this.preferredCondition,
        maxPrice: maxPrice ?? this.maxPrice,
        pickupOrDelivery: pickupOrDelivery ?? this.pickupOrDelivery,
        neededByDate: neededByDate ?? this.neededByDate,
        location: location ?? this.location,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}
