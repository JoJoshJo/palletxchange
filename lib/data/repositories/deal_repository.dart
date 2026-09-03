import '../../models/deal.dart';

abstract interface class DealRepository {
  /// Deals where the user is buyer, seller, or driver.
  Future<List<Deal>> getDealsForUser(String userId);

  Future<Deal?> getDealById(String id);

  Future<Deal> createDeal(Deal deal);

  /// Persists a mutated deal (state-machine transitions, delivery-fee quote).
  Future<Deal> updateDeal(Deal deal);
}
