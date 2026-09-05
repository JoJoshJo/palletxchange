import '../../models/enums.dart';
import '../../models/listing.dart';

/// Marketplace filter criteria (BRAIN §7). All null/false = no filter.
class ListingFilter {
  const ListingFilter({
    this.search,
    this.type,
    this.size,
    this.condition,
    this.recyclableOnly = false,
    this.freeOnly = false,
    this.deliveryOnly = false,
    this.maxPrice,
  });

  final String? search;
  final PalletType? type;
  final PalletSize? size;
  final PalletCondition? condition;
  final bool recyclableOnly;
  final bool freeOnly;
  final bool deliveryOnly;
  final double? maxPrice;

  bool get isEmpty =>
      (search == null || search!.isEmpty) &&
      type == null &&
      size == null &&
      condition == null &&
      !recyclableOnly &&
      !freeOnly &&
      !deliveryOnly &&
      maxPrice == null;

  ListingFilter copyWith({
    String? search,
    PalletType? type,
    PalletSize? size,
    PalletCondition? condition,
    bool? recyclableOnly,
    bool? freeOnly,
    bool? deliveryOnly,
    double? maxPrice,
    bool clearType = false,
    bool clearSize = false,
    bool clearCondition = false,
    bool clearMaxPrice = false,
  }) =>
      ListingFilter(
        search: search ?? this.search,
        type: clearType ? null : (type ?? this.type),
        size: clearSize ? null : (size ?? this.size),
        condition: clearCondition ? null : (condition ?? this.condition),
        recyclableOnly: recyclableOnly ?? this.recyclableOnly,
        freeOnly: freeOnly ?? this.freeOnly,
        deliveryOnly: deliveryOnly ?? this.deliveryOnly,
        maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      );
}

/// Read/write access to listings. The fake implementation runs in memory;
/// a Supabase implementation swaps in behind the same interface (BRAIN §12).
abstract interface class ListingRepository {
  /// Active marketplace listings, optionally filtered + paged.
  Future<List<Listing>> getListings({
    ListingFilter filter,
    int limit,
    int offset,
  });

  /// Paged marketplace query with optional server-side radius (nearest-first,
  /// distance attached). Used by the marketplace; falls back to [getListings]
  /// + client-side distance when radius/coords are unavailable.
  Future<List<Listing>> searchListings({
    ListingFilter filter = const ListingFilter(),
    double? lat,
    double? lng,
    int? radiusMiles,
    int limit = 25,
    int offset = 0,
  });

  Future<Listing?> getListingById(String id);

  /// Fetch several listings by id (used by server-side matching).
  Future<List<Listing>> getListingsByIds(List<String> ids);

  /// Listings belonging to one seller (any status).
  Future<List<Listing>> getListingsBySeller(String sellerId);

  /// Every listing, any status (admin oversight), paged.
  Future<List<Listing>> getAllListings({int limit, int offset});

  /// Persists a new listing and returns the stored copy (with id).
  Future<Listing> createListing(Listing listing);

  Future<Listing> updateListing(Listing listing);
}
