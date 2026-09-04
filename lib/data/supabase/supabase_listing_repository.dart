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

    final rows = await query.order('created_at', ascending: false);
    var listings = (rows as List).map((r) => _fromRow(r)).toList();

    // Free-text search across title/city/state/type (client-side).
    final q = filter.search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      listings = listings.where((l) {
        final hay = [
          l.title,
          l.city ?? '',
          l.state ?? '',
          l.palletType.label,
        ].join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    return listings;
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
  Future<List<Listing>> getAllListings() async {
    final rows = await _c
        .from('listings')
        .select(_select)
        .order('created_at', ascending: false);
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
