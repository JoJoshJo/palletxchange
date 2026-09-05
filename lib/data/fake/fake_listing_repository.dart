import '../../models/enums.dart';
import '../../models/listing.dart';
import '../repositories/listing_repository.dart';
import 'fake_seed.dart';

/// In-memory [ListingRepository]. Holds a mutable list so a listing created in
/// the Sell flow shows up in Browse within the same session.
class FakeListingRepository implements ListingRepository {
  FakeListingRepository() : _listings = FakeSeed.listings();

  final List<Listing> _listings;
  int _idSeq = 100;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  List<Listing> _page(List<Listing> src, int offset, int limit) {
    if (offset >= src.length) return const [];
    return src.sublist(offset, (offset + limit).clamp(0, src.length));
  }

  @override
  Future<List<Listing>> getListings({
    ListingFilter filter = const ListingFilter(),
    int limit = 25,
    int offset = 0,
  }) async {
    await _latency();
    final all = _listings
        .where((l) => l.status == ListingStatus.active)
        .where((l) => _matches(l, filter))
        .toList()
      ..sort((a, b) =>
          (a.distanceMiles ?? 1e9).compareTo(b.distanceMiles ?? 1e9));
    return _page(all, offset, limit);
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
    // Fake: reuse the seed distances; ignore radius precision.
    return getListings(filter: filter, limit: limit, offset: offset);
  }

  @override
  Future<Listing?> getListingById(String id) async {
    await _latency();
    for (final l in _listings) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  Future<List<Listing>> getListingsByIds(List<String> ids) async {
    await _latency();
    return _listings.where((l) => ids.contains(l.id)).toList();
  }

  @override
  Future<List<Listing>> getListingsBySeller(String sellerId) async {
    await _latency();
    return _listings.where((l) => l.sellerId == sellerId).toList();
  }

  @override
  Future<List<Listing>> getAllListings({int limit = 25, int offset = 0}) async {
    await _latency();
    return _page(_listings, offset, limit);
  }

  @override
  Future<Listing> createListing(Listing listing) async {
    await _latency();
    final stored = listing.copyWith(
      id: 'l_new_${_idSeq++}',
      createdAt: DateTime.now(),
      seller: FakeSeed.sellerById(listing.sellerId) ?? FakeSeed.currentUser,
      distanceMiles: 0,
    );
    _listings.insert(0, stored);
    return stored;
  }

  @override
  Future<Listing> updateListing(Listing listing) async {
    await _latency();
    final i = _listings.indexWhere((l) => l.id == listing.id);
    if (i != -1) _listings[i] = listing;
    return listing;
  }

  bool _matches(Listing l, ListingFilter f) {
    if (f.isEmpty) return true;
    if (f.search != null && f.search!.trim().isNotEmpty) {
      final q = f.search!.toLowerCase();
      final hay = [
        l.title,
        l.city ?? '',
        l.state ?? '',
        l.palletType.label,
      ].join(' ').toLowerCase();
      if (!hay.contains(q)) return false;
    }
    if (f.type != null && l.palletType != f.type) return false;
    if (f.size != null && l.palletSize != f.size) return false;
    if (f.condition != null && l.condition != f.condition) return false;
    if (f.recyclableOnly && !l.condition.isRecyclable) return false;
    if (f.freeOnly && !l.isFree) return false;
    if (f.deliveryOnly && !l.deliveryAvailable) return false;
    if (f.maxPrice != null && l.pricePerPallet > f.maxPrice!) return false;
    return true;
  }
}
