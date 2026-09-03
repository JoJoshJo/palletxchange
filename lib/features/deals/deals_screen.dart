import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../core/widgets/trust_widgets.dart';
import '../../data/providers.dart';
import '../../models/deal.dart';
import 'widgets/deal_status_chip.dart';

/// Which side of the book the user is viewing.
final dealsTabProvider = StateProvider<int>((ref) => 0); // 0 = Buying, 1 = Selling

class DealsScreen extends ConsumerWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final tab = ref.watch(dealsTabProvider);
    final dealsAsync = ref.watch(myDealsProvider);

    return Scaffold(
      appBar: AppBar(title: const BrandWordmark()),
      body: Column(
        children: [
          _Segments(selected: tab),
          const Divider(height: 1),
          Expanded(
            child: dealsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const Center(child: Text("Couldn't load deals")),
              data: (deals) {
                final buying =
                    deals.where((d) => d.buyerId == me.id).toList();
                final selling =
                    deals.where((d) => d.sellerId == me.id).toList();
                final shown = tab == 0 ? buying : selling;
                if (shown.isEmpty) {
                  return _EmptyDeals(buying: tab == 0);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myDealsProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => DealCard(deal: shown[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Segments extends ConsumerWidget {
  const _Segments({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Buying')),
          ButtonSegment(value: 1, label: Text('Selling')),
        ],
        selected: {selected},
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.orange
                  : AppColors.surface),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.onDark
                  : AppColors.textPrimary),
        ),
        onSelectionChanged: (s) =>
            ref.read(dealsTabProvider.notifier).state = s.first,
      ),
    );
  }
}

class DealCard extends ConsumerWidget {
  const DealCard({super.key, required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final counterpartyId = deal.buyerId == me.id ? deal.sellerId : deal.buyerId;
    final counterparty = ref.watch(profileByIdProvider(counterpartyId));
    final listing = ref.watch(listingByIdProvider(deal.listingId));

    final title = listing.valueOrNull?.title ?? 'Listing';

    return Card(
      child: InkWell(
        onTap: () => context.push('/deals/deal/${deal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: counterparty.valueOrNull == null
                        ? const SizedBox(height: 18)
                        : SellerTrustLine(
                            name: counterparty.value!.displayName,
                            verified: counterparty.value!.verifiedStatus,
                            rating: counterparty.value!.rating,
                            dense: true,
                          ),
                  ),
                  DealStatusChip(status: deal.dealStatus),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  MetaTag(
                    icon: Icons.inventory_2_outlined,
                    label: '${deal.quantity} pallets',
                  ),
                  const SizedBox(width: 14),
                  MetaTag(
                    icon: deal.fulfillmentMethod.value == 'delivery'
                        ? Icons.local_shipping_outlined
                        : Icons.store_outlined,
                    label: deal.fulfillmentMethod.label,
                  ),
                  const Spacer(),
                  Text(
                    moneyWhole(deal.totalPrice + deal.deliveryFee),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDeals extends StatelessWidget {
  const _EmptyDeals({required this.buying});

  final bool buying;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.handshake_outlined,
            size: 56, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Center(
          child: Text(
            buying ? 'No deals on the buy side yet' : 'No deals on the sell side yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            buying
                ? 'Request a deal from a listing to get started.'
                : 'Incoming deals on your listings will show here.',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
