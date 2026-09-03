import '../../models/enums.dart';
import '../../models/listing.dart';
import '../../models/request.dart';

/// A listing paired with its match score against a request.
class ScoredListing {
  const ScoredListing({required this.listing, required this.score});
  final Listing listing;
  final int score;
}

/// Smart matching (BRAIN §7), max score 12. Reusable for both broadcast and
/// targeted requests, and for match-on-new-listing later. In Supabase this
/// becomes an RPC/Edge Function with the identical scoring.
abstract final class MatchingService {
  static const int maxScore = 12;

  /// Score one listing against a request. Higher = better fit; 0 = no signal.
  static int score(Listing listing, PalletRequest request) {
    var s = 0;
    if (request.palletTypeNeeded != null &&
        listing.palletType == request.palletTypeNeeded) {
      s += 3;
    }
    if (request.palletSizeNeeded != null &&
        listing.palletSize == request.palletSizeNeeded) {
      s += 3;
    }
    if (listing.quantityAvailable >= request.quantityNeeded) {
      s += 2;
    }
    if (request.preferredCondition != null &&
        listing.condition == request.preferredCondition) {
      s += 2;
    }
    if (request.maxPrice != null && listing.pricePerPallet <= request.maxPrice!) {
      s += 2;
    }
    if (request.pickupOrDelivery == FulfillmentMethod.delivery &&
        listing.deliveryAvailable) {
      s += 1;
    }
    if (request.pickupOrDelivery == FulfillmentMethod.pickup &&
        listing.pickupAvailable) {
      s += 1;
    }
    return s;
  }

  /// Score every active listing against [request]; return score > 0 sorted
  /// descending. Targeted requests can restrict [listings] to one seller first.
  static List<ScoredListing> matches(
    PalletRequest request,
    List<Listing> listings,
  ) {
    final scored = <ScoredListing>[];
    for (final l in listings) {
      if (l.status != ListingStatus.active) continue;
      final s = score(l, request);
      if (s > 0) scored.add(ScoredListing(listing: l, score: s));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }
}
