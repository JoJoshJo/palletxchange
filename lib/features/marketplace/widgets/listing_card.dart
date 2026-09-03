import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pallet_photo.dart';
import '../../../core/widgets/trust_widgets.dart';
import '../../../models/listing.dart';

/// Marketplace listing card (BRAIN §11): photo, title, price/pallet,
/// condition-grade badge, qty, seller name + green ✓ + ★rating, distance,
/// pickup/delivery tag.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final seller = listing.seller;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                PalletPhoto(
                  url: listing.photos.isNotEmpty ? listing.photos.first : null,
                  height: 168,
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: ConditionBadge(
                    label: listing.condition.grade,
                    recyclable: listing.condition.isRecyclable,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _PricePill(listing: listing),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
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
                  const Divider(height: 20),
                  if (seller != null)
                    SellerTrustLine(
                      name: seller.displayName,
                      verified: seller.verifiedStatus,
                      rating: seller.rating,
                      dense: true,
                    ),
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

class _PricePill extends StatelessWidget {
  const _PricePill({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final free = listing.isFree;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: free ? AppColors.green : AppColors.navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        free ? 'Free' : money(listing.pricePerPallet),
        style: const TextStyle(
          color: AppColors.onDark,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
