import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/deal.dart';
import '../../models/enums.dart';
import '../../models/review.dart';
import '../providers.dart';

/// Drives the deal state machine (BRAIN §7) over the in-memory repos and keeps
/// dependent providers fresh:
///   pending → accepted | declined
///   accepted → completed
///   any non-terminal → cancelled
/// Reserve-on-accept: decrement listing quantity on accept (floor 0 →
/// sold_out); restore it if an accepted deal is cancelled/declined.
class DealService {
  DealService(this.ref);

  final Ref ref;

  Future<void> accept(Deal deal) async {
    if (deal.dealStatus != DealStatus.pending) return;
    await _reserveInventory(deal);
    await ref
        .read(dealRepositoryProvider)
        .updateDeal(deal.copyWith(dealStatus: DealStatus.accepted));
    _refresh(deal);
  }

  Future<void> decline(Deal deal) async {
    if (deal.dealStatus != DealStatus.pending) return;
    // Pending never reserved inventory, so nothing to restore.
    await ref
        .read(dealRepositoryProvider)
        .updateDeal(deal.copyWith(dealStatus: DealStatus.declined));
    _refresh(deal);
  }

  Future<void> complete(Deal deal) async {
    if (deal.dealStatus != DealStatus.accepted) return;
    await ref.read(dealRepositoryProvider).updateDeal(deal.copyWith(
          dealStatus: DealStatus.completed,
          completedAt: DateTime.now(),
        ));
    _refresh(deal);
  }

  Future<void> cancel(Deal deal) async {
    if (deal.dealStatus == DealStatus.completed ||
        deal.dealStatus == DealStatus.cancelled ||
        deal.dealStatus == DealStatus.declined) {
      return;
    }
    // Restore inventory only if it had been reserved (accepted).
    if (deal.dealStatus == DealStatus.accepted) {
      await _restoreInventory(deal);
    }
    await ref
        .read(dealRepositoryProvider)
        .updateDeal(deal.copyWith(dealStatus: DealStatus.cancelled));
    _refresh(deal);
  }

  /// Seller sets a delivery-fee quote on a delivery deal.
  Future<void> setDeliveryFee(Deal deal, double fee) async {
    await ref
        .read(dealRepositoryProvider)
        .updateDeal(deal.copyWith(deliveryFee: fee));
    _refresh(deal);
  }

  Future<void> submitReview(Review review) async {
    await ref.read(reviewRepositoryProvider).createReview(review);
    ref.invalidate(hasReviewedProvider(review.dealId));
  }

  Future<void> _reserveInventory(Deal deal) async {
    final repo = ref.read(listingRepositoryProvider);
    final listing = await repo.getListingById(deal.listingId);
    if (listing == null) return;
    final next = (listing.quantityAvailable - deal.quantity).clamp(0, 1 << 31);
    await repo.updateListing(listing.copyWith(
      quantityAvailable: next,
      status: next == 0 ? ListingStatus.soldOut : listing.status,
    ));
  }

  Future<void> _restoreInventory(Deal deal) async {
    final repo = ref.read(listingRepositoryProvider);
    final listing = await repo.getListingById(deal.listingId);
    if (listing == null) return;
    final restored = listing.quantityAvailable + deal.quantity;
    await repo.updateListing(listing.copyWith(
      quantityAvailable: restored,
      status: listing.status == ListingStatus.soldOut
          ? ListingStatus.active
          : listing.status,
    ));
  }

  void _refresh(Deal deal) {
    ref.invalidate(myDealsProvider);
    ref.invalidate(dealByIdProvider(deal.id));
    ref.invalidate(marketplaceListingsProvider);
    ref.invalidate(listingByIdProvider(deal.listingId));
  }
}
