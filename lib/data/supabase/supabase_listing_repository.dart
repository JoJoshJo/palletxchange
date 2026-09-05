import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/enums.dart';
import '../../models/listing.dart';
import '../../models/profile.dart';
import '../repositories/listing_repository.dart';

/// Real [ListingRepository] backed by the Supabase `listings` table, with the
/// seller profile embedded for the card/detail trust line. RLS gates access:
/// public marketplace = active listings; owners manage their own.
class SupabaseListingRepository implements ListingRepository {
  SupabaseClient get _c => Supabase.instance.client;

  // Embed the seller via the seller_id FK so cards show name/✓/rating.
  static const _select = '*, seller:profiles!listings_seller_id_fkey(*)';

  Listing _fromRow(Map<String, dynamic> row) {
    final listing = Listing.fromJson(row);
    final sellerRow = row['seller'];
    if (sellerRow is Map<String, dynamic>) {
      return listing.copyWith(seller: Profile.fromJson(sellerRow));
    }
    return listing;
  }

  @override
  Future<List<Listing>> getListings({
    ListingFilter filter = const ListingFilter(),
    int limit = 25,
    int offset = 0,
  }) async {
    var query =
        _c.from('listings').select(_select).eq('status', 'active');

    if (filter.type != null) {
      query = query.eq('pallet_type', filter.type!.value);
    }
    if (filter.size != null) {
      query = query.eq('pallet_size', filter.size!.value);
    }
    if (filter.condition != null) {
      query = query.eq('condition', filter.condition!.value);
    }
    if (filter.recyclableOnly) {
      query = query.inFilter('condition', [
        PalletCondition.damaged.value,
        PalletCondition.scrap.value,
      ]);
    }
    if (filter.freeOnly) query = query.eq('is_free', true);
    if (filter.deliveryOnly) query = query.eq('delivery_available', true);
    if (filter.maxPrice != null) {
      query = query.lte('price_per_pallet', filter.maxPrice!);
    }
    final q = filter.search?.trim();
    if (q != null && q.isNotEmpty) {
      // Server-side text search (title/city/state/type).
      query = query.or('title.ilike.%$q%,city.ilike.%$q%,'
          'state.ilike.%$q%,pallet_type.ilike.%$q%');
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  @override
  Future<List<Listing>> searchListings({
    ListingFilter filter = const ListingFilter(),
    double? lat,
    double? lng,
    int? radiusMiles,
    int limit = 25,
    int offset = 0,
  }) async {
    // No coords → plain paged query (client attaches no distance).
    if (lat == null || lng == null || radiusMiles == null) {
      return getListings(filter: filter, limit: limit, offset: offset);
    }
    try {
      final rows = await _c.rpc('listings_within_radius', params: {
        'p_lat': lat,
        'p_lng': lng,
        'p_radius_miles': radiusMiles.toDouble(),
        'p_limit': limit,
        'p_offset': offset,
        'p_type': filter.type?.value,
        'p_size': filter.size?.value,
        'p_condition': filter.condition?.value,
        'p_free_only': filter.freeOnly,
        'p_delivery_only': filter.deliveryOnly,
        'p_recyclable': filter.recyclableOnly,
        'p_max_price': filter.maxPrice,
        'p_search': filter.search?.trim(),
      });
      return (rows as List).map((r) {
        final map = r as Map<String, dynamic>;
        final listing = Listing.fromJson(map);
        final seller = map['seller'];
        final dist = (map['distance_miles'] as num?)?.toDouble();
        return listing.copyWith(
          seller: seller is Map<String, dynamic>
              ? Profile.fromJson(seller)
              : null,
          distanceMiles: dist,
        );
      }).toList();
    } catch (_) {
      // Fallback: paged plain query (radius not applied server-side).
      return getListings(filter: filter, limit: limit, offset: offset);
    }
  }

  @override
  Future<Listing?> getListingById(String id) async {
    final row =
        await _c.from('listings').select(_select).eq('id', id).maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<Listing>> getListingsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows =
        await _c.from('listings').select(_select).inFilter('id', ids);
    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  @override
  Future<List<Listing>> getListingsBySeller(String sellerId) async {
    final rows = await _c
        .from('listings')
        .select(_select)
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  @override
  Future<List<Listing>> getAllListings({int limit = 25, int offset = 0}) async {
    final rows = await _c
        .from('listings')
        .select(_select)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List).map((r) => _fromRow(r)).toList();
  }

  @override
  Future<Listing> createListing(Listing listing) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw StateError('No signed-in user');

    final payload = listing.toJson()
      ..remove('id')
      ..remove('created_at');
    // Trust the session, not client input, for ownership.
    payload['seller_id'] = uid;

    final row =
        await _c.from('listings').insert(payload).select(_select).single();
    return _fromRow(row);
  }

  @override
  Future<Listing> updateListing(Listing listing) async {
    final payload = listing.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('seller_id'); // never reassign ownership
    final row = await _c
        .from('listings')
        .update(payload)
        .eq('id', listing.id)
        .select(_select)
        .maybeSingle();
    return row == null ? listing : _fromRow(row);
  }
}
