import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/deal.dart';
import '../../models/delivery.dart';
import '../../models/enums.dart';
import '../../models/listing.dart';
import '../../models/review.dart';
import '../providers.dart';

/// Drives the deal state machine (BRAIN §7). Inventory reserve-on-accept and
/// completed_at stamping are enforced by DB triggers — this service only issues
/// the status change and refreshes providers; it never does inventory math.
class DealService {
  DealService(this.ref);

  final Ref ref;

  /// Buyer opens a deal from a listing (Request Deal), then a thread opens.
  Future<String> requestDeal(Listing listing) async {
    final me = ref.read(currentUserProvider);
    final fulfillment = listing.pickupAvailable
        ? FulfillmentMethod.pickup
        : FulfillmentMethod.delivery;
    final created = await ref.read(dealRepositoryProvider).createDeal(
          Deal(
            id: 'pending',
            listingId: listing.id,
            buyerId: me.id,
            sellerId: listing.sellerId,
            quantity: listing.minOrderQuantity,
            pricePerPallet: listing.pricePerPallet,
            fulfillmentMethod: fulfillment,
            paymentStatus: listing.isFree
                ? PaymentStatus.notRequired
                : PaymentStatus.unpaid,
            dealStatus: DealStatus.pending,
          ),
        );

    // Open the thread with an auto message (BRAIN §5).
    await ref.read(messageServiceProvider).sendDealOpener(created, listing);

    ref.invalidate(myDealsProvider);
    ref.invalidate(myConversationsProvider);
    return created.id;
  }

  Future<void> accept(Deal deal) async {
    if (deal.dealStatus != DealStatus.pending) return;
    await ref
        .read(dealRepositoryProvider)
        .updateDeal(deal.copyWith(dealStatus: DealStatus.accepted));

    // Post the delivery leg to the driver job board (BRAIN §5).
    if (deal.fulfillmentMethod == FulfillmentMethod.delivery) {
      final listing =
          await ref.read(listingRepositoryProvider).getListingById(deal.listingId);
      final pickup = [listing?.address, listing?.city, listing?.state]
          .where((p) => p != null && p.isNotEmpty)
          .join(', ');
      await ref.read(deliveryRepositoryProvider).createDelivery(
            Delivery(
              id: 'pending',
              dealId: deal.id,
              pickupAddress: pickup.isEmpty ? 'Pickup TBD' : pickup,
              dropoffAddress: deal.deliveryAddress ?? 'Drop-off TBD',
              deliveryStatus: DeliveryStatus.requested,
            ),
          );
      ref.invalidate(openJobsProvider);
    }
    _refresh(deal);
  }

  Future<void> decline(Deal deal) async {
    if (deal.dealStatus != DealStatus.pending) return;
    await ref
        .read(dealRepositoryProvider)
        .updateDeal(deal.copyWith(dealStatus: DealStatus.declined));
    _refresh(deal);
  }

  Future<void> complete(Deal deal) async {
    if (deal.dealStatus != DealStatus.accepted) return;
    await ref
        .read(dealRepositoryProvider)
        .updateDeal(deal.copyWith(dealStatus: DealStatus.completed));
    _refresh(deal);
  }

  Future<void> cancel(Deal deal) async {
    if (deal.dealStatus == DealStatus.completed ||
        deal.dealStatus == DealStatus.cancelled ||
        deal.dealStatus == DealStatus.declined) {
      return;
    }
    await ref
        .read(dealRepositoryProvider)
        .updateDeal(deal.copyWith(dealStatus: DealStatus.cancelled));
    _refresh(deal);
  }

  /// Buyer edits the requested quantity while the deal is still pending (no
  /// inventory is reserved yet). total_price is recomputed by the DB trigger.
  Future<void> updateQuantity(Deal deal, int quantity) async {
    if (deal.dealStatus != DealStatus.pending) return;
    await ref
        .read(dealRepositoryProvider)
        .updateDeal(deal.copyWith(quantity: quantity));
    _refresh(deal);
  }

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

  void _refresh(Deal deal) {
    ref.invalidate(myDealsProvider);
    ref.invalidate(dealByIdProvider(deal.id));
    ref.invalidate(marketplaceListingsProvider);
    ref.invalidate(listingByIdProvider(deal.listingId));
  }
}
