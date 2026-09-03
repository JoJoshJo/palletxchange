import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pallet_photo.dart';
import '../../../core/widgets/trust_widgets.dart';
import '../../../models/listing.dart';

/// Marketplace listing card (BRAIN §11), top-banner layout:
/// [short image banner] → [title + price row] →
/// [condition badge · qty · distance · pickup/delivery] → [seller ✓ ★rating].
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  /// Shorter banner strip so the empty state never dominates the card.
  static const double _bannerHeight = 156;

  @override
  Widget build(BuildContext context) {
    final seller = listing.seller;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner — full width, fixed short height; the Card clips the
            // rounded top corners. cover for real photos, compact placeholder
            // otherwise (handled inside PalletPhoto).
            PalletPhoto(
              url: listing.photos.isNotEmpty ? listing.photos.first : null,
              height: _bannerHeight,
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + price on one row.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _PriceLabel(listing: listing),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Meta row — condition badge first, then qty / distance /
                  // fulfillment.
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConditionBadge(
                        label: listing.condition.grade,
                        recyclable: listing.condition.isRecyclable,
                      ),
                      MetaTag(
                        icon: Icons.inventory_2_outlined,
                        label: '${listing.quantityAvailable} available',
                      ),
                      if (listing.distanceMiles != null)
                        MetaTag(
                          icon: Icons.place_outlined,
                          label: distanceLabel(listing.distanceMiles),
                        ),
                      MetaTag(
                        icon: listing.deliveryAvailable
                            ? Icons.local_shipping_outlined
                            : Icons.store_outlined,
                        label: _fulfillmentLabel(listing),
                      ),
                    ],
                  ),
                  if (seller != null) ...[
                    const Divider(height: 20),
                    GestureDetector(
                      onTap: () => context.push('/profile/${seller.id}'),
                      behavior: HitTestBehavior.opaque,
                      child: SellerTrustLine(
                        name: seller.displayName,
                        verified: seller.verifiedStatus,
                        rating: seller.rating,
                        dense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fulfillmentLabel(Listing l) {
    if (l.pickupAvailable && l.deliveryAvailable) return 'Pickup · Delivery';
    if (l.deliveryAvailable) return 'Delivery';
    return 'Pickup';
  }
}

/// Bold navy price aligned to the title row. "Free" renders in green;
/// priced listings show "$X.XX" with a small muted "/pallet".
class _PriceLabel extends StatelessWidget {
  const _PriceLabel({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    if (listing.isFree) {
      return const Text(
        'Free',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.green,
        ),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: money(listing.pricePerPallet)),
          const TextSpan(
            text: ' /pallet',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      textAlign: TextAlign.right,
    );
  }
}
