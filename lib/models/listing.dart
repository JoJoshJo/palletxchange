import 'enums.dart';
import 'profile.dart';

/// A pallet listing (BRAIN §6).
///
/// [seller] is an optional denormalized join used by the UI (card shows the
/// seller name + verified + rating). In Supabase this comes from a joined
/// select; the fake repo populates it directly.
class Listing {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.palletType,
    required this.palletSize,
    required this.condition,
    required this.quantityAvailable,
    this.minOrderQuantity = 1,
    required this.pricePerPallet,
    this.isFree = false,
    this.exchangeAllowed = false,
    this.pickupAvailable = true,
    this.deliveryAvailable = false,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.latitude,
    this.longitude,
    this.loadingDockAvailable = false,
    this.forkliftAvailable = false,
    this.stackable = true,
    this.photos = const [],
    this.notes,
    this.status = ListingStatus.active,
    this.unavailableSince,
    this.expiresAt,
    this.createdAt,
    this.distanceMiles,
    this.seller,
  });

  final String id;
  final String sellerId;
  final String title;
  final PalletType palletType;
  final PalletSize palletSize;
  final PalletCondition condition;
  final int quantityAvailable;
  final int minOrderQuantity;
  final double pricePerPallet;
  final bool isFree;
  final bool exchangeAllowed;
  final bool pickupAvailable;
  final bool deliveryAvailable;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final double? latitude;
  final double? longitude;
  final bool loadingDockAvailable;
  final bool forkliftAvailable;
  final bool stackable;
  final List<String> photos;
  final String? notes;
  final ListingStatus status;
  final DateTime? unavailableSince;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  /// UI-only, computed server-side from the viewer's lat/lon.
  final double? distanceMiles;

  /// UI-only denormalized seller.
  final Profile? seller;

  String get locationLabel {
    final parts = [city, state].where((p) => p != null && p.isNotEmpty);
    return parts.join(', ');
  }

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        sellerId: json['seller_id'] as String,
        title: json['title'] as String? ?? '',
        palletType: PalletType.fromValue(json['pallet_type'] as String?) ??
            PalletType.standardWooden,
        palletSize: PalletSize.fromValue(json['pallet_size'] as String?) ??
            PalletSize.s48x40,
        condition: PalletCondition.fromValue(json['condition'] as String?) ??
            PalletCondition.usedGood,
        quantityAvailable: json['quantity_available'] as int? ?? 0,
        minOrderQuantity: json['min_order_quantity'] as int? ?? 1,
        pricePerPallet: (json['price_per_pallet'] as num?)?.toDouble() ?? 0,
        isFree: json['is_free'] as bool? ?? false,
        exchangeAllowed: json['exchange_allowed'] as bool? ?? false,
        pickupAvailable: json['pickup_available'] as bool? ?? true,
        deliveryAvailable: json['delivery_available'] as bool? ?? false,
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        zip: json['zip'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        loadingDockAvailable: json['loading_dock_available'] as bool? ?? false,
        forkliftAvailable: json['forklift_available'] as bool? ?? false,
        stackable: json['stackable'] as bool? ?? true,
        photos: (json['photos'] as List?)?.cast<String>() ?? const [],
        notes: json['notes'] as String?,
        status: ListingStatus.fromValue(json['status'] as String?) ??
            ListingStatus.active,
        unavailableSince: json['unavailable_since'] == null
            ? null
            : DateTime.parse(json['unavailable_since'] as String),
        expiresAt: json['expires_at'] == null
            ? null
            : DateTime.parse(json['expires_at'] as String),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'title': title,
        'pallet_type': palletType.value,
        'pallet_size': palletSize.value,
        'condition': condition.value,
        'quantity_available': quantityAvailable,
        'min_order_quantity': minOrderQuantity,
        'price_per_pallet': pricePerPallet,
        'is_free': isFree,
        'exchange_allowed': exchangeAllowed,
        'pickup_available': pickupAvailable,
        'delivery_available': deliveryAvailable,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'latitude': latitude,
        'longitude': longitude,
        'loading_dock_available': loadingDockAvailable,
        'forklift_available': forkliftAvailable,
        'stackable': stackable,
        'photos': photos,
        'notes': notes,
        'status': status.value,
        'unavailable_since': unavailableSince?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };

  Listing copyWith({
    String? id,
    String? sellerId,
    String? title,
    PalletType? palletType,
    PalletSize? palletSize,
    PalletCondition? condition,
    int? quantityAvailable,
    int? minOrderQuantity,
    double? pricePerPallet,
    bool? isFree,
    bool? exchangeAllowed,
    bool? pickupAvailable,
    bool? deliveryAvailable,
    String? address,
    String? city,
    String? state,
    String? zip,
    double? latitude,
    double? longitude,
    bool? loadingDockAvailable,
    bool? forkliftAvailable,
    bool? stackable,
    List<String>? photos,
    String? notes,
    ListingStatus? status,
    DateTime? unavailableSince,
    DateTime? expiresAt,
    DateTime? createdAt,
    double? distanceMiles,
    Profile? seller,
  }) =>
      Listing(
        id: id ?? this.id,
        sellerId: sellerId ?? this.sellerId,
        title: title ?? this.title,
        palletType: palletType ?? this.palletType,
        palletSize: palletSize ?? this.palletSize,
        condition: condition ?? this.condition,
        quantityAvailable: quantityAvailable ?? this.quantityAvailable,
        minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
        pricePerPallet: pricePerPallet ?? this.pricePerPallet,
        isFree: isFree ?? this.isFree,
        exchangeAllowed: exchangeAllowed ?? this.exchangeAllowed,
        pickupAvailable: pickupAvailable ?? this.pickupAvailable,
        deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        zip: zip ?? this.zip,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        loadingDockAvailable: loadingDockAvailable ?? this.loadingDockAvailable,
        forkliftAvailable: forkliftAvailable ?? this.forkliftAvailable,
        stackable: stackable ?? this.stackable,
        photos: photos ?? this.photos,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        unavailableSince: unavailableSince ?? this.unavailableSince,
        expiresAt: expiresAt ?? this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
        distanceMiles: distanceMiles ?? this.distanceMiles,
        seller: seller ?? this.seller,
      );
}
