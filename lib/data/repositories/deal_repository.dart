import '../../models/deal.dart';

abstract interface class DealRepository {
  /// Deals where the user is buyer, seller, or driver.
  Future<List<Deal>> getDealsForUser(String userId);

  /// Every deal (admin oversight; RLS admin-bypass).
  Future<List<Deal>> getAllDeals();

  Future<Deal?> getDealById(String id);

  Future<Deal> createDeal(Deal deal);

  /// Persists a mutated deal (state-machine transitions, delivery-fee quote).
  Future<Deal> updateDeal(Deal deal);

  /// Count of pending/accepted deals attached to a listing (used to warn
  /// before archiving).
  Future<int> activeDealCountForListing(String listingId);
}
