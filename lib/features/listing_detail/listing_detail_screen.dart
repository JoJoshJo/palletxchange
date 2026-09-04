import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pallet_photo.dart';
import '../../core/widgets/trust_widgets.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';
import '../../models/listing.dart';
import '../../models/report.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingByIdProvider(listingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Listing')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text("Couldn't load listing")),
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('Listing not found'));
          }
          return _Content(listing: listing);
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final seller = listing.seller;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 1. Photos — swipeable carousel when there are several.
              _PhotoCarousel(photos: listing.photos),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.locationLabel} · ${distanceLabel(listing.distanceMiles)}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 2. Price.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          listing.isFree ? 'Free' : money(listing.pricePerPallet),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!listing.isFree) ...[
                          const SizedBox(width: 6),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              '/ pallet',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        ConditionBadge(
                          label: listing.condition.label,
                          recyclable: listing.condition.isRecyclable,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, indent: 20, endIndent: 20),
              // 3. Seller trust (tap → storefront).
              if (seller != null)
                InkWell(
                  onTap: () => context.push('/profile/${seller.id}'),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.navy,
                          child: Text(
                            seller.displayName.characters.first.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.onDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SellerTrustLine(
                                name: seller.displayName,
                                verified: seller.verifiedStatus,
                                rating: seller.rating,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                seller.verifiedStatus
                                    ? 'Verified business'
                                    : 'Unverified seller',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // 4. Spec grid.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SpecGrid(listing: listing),
              ),
              if (listing.notes != null && listing.notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        listing.notes!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Address gated until a deal exists (BRAIN §11).
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock_outline, size: 18, color: AppColors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Exact pickup address is shown after a deal is opened.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(child: _ReportButton(listing: listing)),
              const SizedBox(height: 16),
            ],
          ),
        ),
        _StickyActions(listing: listing),
      ],
    );
  }
}

/// Creates a real report record (fixes the prototype's no-op report button).
class _ReportButton extends ConsumerWidget {
  const _ReportButton({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _report(context, ref),
      style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
      icon: const Icon(Icons.flag_outlined, size: 18),
      label: const Text('Report this listing'),
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    const reasons = [
      'Misleading condition',
      'Wrong quantity or price',
      'Prohibited item',
      'Spam or scam',
      'Other',
    ];
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Report listing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            for (final r in reasons)
              ListTile(
                title: Text(r),
                onTap: () => Navigator.pop(context, r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null) return;

    final me = ref.read(currentUserProvider);
    await ref.read(reportRepositoryProvider).createReport(
          Report(
            id: 'pending',
            reportedBy: me.id,
            reportedUser: listing.sellerId,
            listingId: listing.id,
            reason: reason,
            subjectLabel: listing.title,
          ),
        );
    ref.invalidate(allReportsProvider);
    ref.invalidate(adminStatsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted — thank you')),
      );
    }
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.photos});

  final List<String> photos;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    if (photos.isEmpty) {
      return const PalletPhoto(height: 260, width: double.infinity);
    }
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => PalletPhoto(
              url: photos[i],
              height: 260,
              width: double.infinity,
            ),
          ),
          if (photos.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.onDark : AppColors.onDarkMuted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final specs = <(IconData, String, String)>[
      (Icons.category_outlined, 'Type', listing.palletType.label),
      (Icons.straighten, 'Size', listing.palletSize.label),
      (
        Icons.inventory_2_outlined,
        'Available',
        '${listing.quantityAvailable} pallets'
      ),
      (Icons.shopping_cart_outlined, 'Min order', '${listing.minOrderQuantity}'),
      (
        Icons.local_shipping_outlined,
        'Fulfillment',
        [
          if (listing.pickupAvailable) 'Pickup',
          if (listing.deliveryAvailable) 'Delivery',
        ].join(' · '),
      ),
      if (listing.forkliftAvailable)
        (Icons.precision_manufacturing_outlined, 'Forklift', 'On site'),
      if (listing.loadingDockAvailable)
        (Icons.warehouse_outlined, 'Loading dock', 'Available'),
      if (listing.exchangeAllowed)
        (Icons.swap_horiz, 'Exchange', 'Accepted'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.0,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: specs
          .map((s) => _SpecCell(icon: s.$1, label: s.$2, value: s.$3))
          .toList(),
    );
  }
}

class _SpecCell extends StatelessWidget {
  const _SpecCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyActions extends ConsumerStatefulWidget {
  const _StickyActions({required this.listing});

  final Listing listing;

  @override
  ConsumerState<_StickyActions> createState() => _StickyActionsState();
}

class _StickyActionsState extends ConsumerState<_StickyActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final isOwnListing = widget.listing.sellerId == me.id;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: isOwnListing
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _busy
                        ? null
                        : () =>
                            context.push('/edit-listing/${widget.listing.id}'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _archive,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC0392B),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _requestDeal,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.onDark,
                            ),
                          )
                        : const Icon(Icons.handshake_outlined),
                    label: const Text('Request Deal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    // Messaging must originate from a deal or request — send a
                    // targeted Special Request to ask this seller (BRAIN §5).
                    onPressed: _busy
                        ? null
                        : () => context
                            .push('/request?sellerId=${widget.listing.sellerId}'),
                    child: const Text('Message'),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _requestDeal() async {
    final blocked =
        ref.read(blockedIdsProvider).valueOrNull ?? const <String>{};
    if (blocked.contains(widget.listing.sellerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've blocked this seller. Unblock to deal.")),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final dealId =
          await ref.read(dealServiceProvider).requestDeal(widget.listing);
      if (mounted) context.go('/deals/deal/$dealId');
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the deal — try again.")),
        );
      }
    }
  }

  Future<void> _archive() async {
    setState(() => _busy = true);
    // Warn if there are open deals on this listing.
    int activeDeals = 0;
    try {
      activeDeals = await ref
          .read(dealRepositoryProvider)
          .activeDealCountForListing(widget.listing.id);
    } catch (_) {/* non-fatal */}
    if (!mounted) return;
    setState(() => _busy = false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove listing?'),
        content: Text(
          activeDeals > 0
              ? 'This listing has $activeDeals open deal(s). Removing it hides '
                  'it from the marketplace, but those deals stay active. You can '
                  're-list it later. Remove anyway?'
              : 'This hides the listing from the marketplace. You can re-list it '
                  'later from My Storefront.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B),
              minimumSize: const Size(96, 44),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(listingRepositoryProvider).updateListing(
            widget.listing.copyWith(status: ListingStatus.archived),
          );
      ref.invalidate(marketplaceListingsProvider);
      ref.invalidate(listingByIdProvider(widget.listing.id));
      ref.invalidate(sellerActiveListingsProvider(widget.listing.sellerId));
      ref.invalidate(sellerArchivedListingsProvider(widget.listing.sellerId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing removed')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't remove — try again.")),
        );
      }
    }
  }
}
