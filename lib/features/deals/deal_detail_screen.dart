import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/trust_widgets.dart';
import '../../data/providers.dart';
import '../../models/deal.dart';
import '../../models/enums.dart';
import '../../models/review.dart';
import '../common/proof_image.dart';
import 'widgets/deal_status_chip.dart';
import 'widgets/review_sheet.dart';

class DealDetailScreen extends ConsumerWidget {
  const DealDetailScreen({super.key, required this.dealId});

  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dealByIdProvider(dealId));
    return Scaffold(
      appBar: AppBar(title: const Text('Deal')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text("Couldn't load deal")),
        data: (deal) => deal == null
            ? const Center(child: Text('Deal not found'))
            : _DealBody(deal: deal),
      ),
    );
  }
}

class _DealBody extends ConsumerWidget {
  const _DealBody({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final isSeller = deal.sellerId == me.id;
    final counterpartyId = isSeller ? deal.buyerId : deal.sellerId;
    final counterparty = ref.watch(profileByIdProvider(counterpartyId));
    final listing = ref.watch(listingByIdProvider(deal.listingId));
    final isDelivery = deal.fulfillmentMethod == FulfillmentMethod.delivery;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listing.valueOrNull?.title ?? 'Listing',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DealStatusChip(status: deal.dealStatus),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isSeller ? 'You are selling' : 'You are buying',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Summary card.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (counterparty.valueOrNull != null)
                      _row(
                        'Counterparty',
                        child: SellerTrustLine(
                          name: counterparty.value!.displayName,
                          verified: counterparty.value!.verifiedStatus,
                          rating: counterparty.value!.rating,
                          dense: true,
                        ),
                      ),
                    _divider(),
                    if (!isSeller && deal.dealStatus == DealStatus.pending)
                      _row(
                        'Quantity',
                        child: _QuantityEditor(
                          deal: deal,
                          minOrder: listing.valueOrNull?.minOrderQuantity ?? 1,
                          available: listing.valueOrNull?.quantityAvailable,
                        ),
                      )
                    else
                      _row('Quantity', value: '${deal.quantity} pallets'),
                    _divider(),
                    _row('Unit price', value: money(deal.pricePerPallet)),
                    _divider(),
                    _row('Fulfillment', value: deal.fulfillmentMethod.label),
                    if (isDelivery) ...[
                      _divider(),
                      _row(
                        'Delivery fee',
                        value: deal.deliveryFee > 0
                            ? money(deal.deliveryFee)
                            : (isSeller ? 'Tap to quote' : 'Not yet quoted'),
                      ),
                    ],
                    _divider(),
                    _row(
                      'Total',
                      value: moneyWhole(deal.totalPrice + deal.deliveryFee),
                      emphasize: true,
                    ),
                  ],
                ),
              ),

              if (isSeller && isDelivery && !_isTerminal(deal)) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _quoteDeliveryFee(context, ref, deal),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text(deal.deliveryFee > 0
                      ? 'Update delivery quote'
                      : 'Enter delivery quote'),
                ),
              ],

              if (isDelivery) ...[
                const SizedBox(height: 16),
                _DeliveryProofSection(dealId: deal.id),
              ],

              if (deal.dealStatus == DealStatus.completed) ...[
                const SizedBox(height: 16),
                _ReviewEntry(deal: deal),
              ],

              if (deal.notes != null && deal.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deal.notes!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        _ActionBar(deal: deal, isSeller: isSeller),
      ],
    );
  }

  static bool _isTerminal(Deal d) =>
      d.dealStatus == DealStatus.completed ||
      d.dealStatus == DealStatus.cancelled ||
      d.dealStatus == DealStatus.declined;

  Widget _row(String label, {String? value, Widget? child, bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: child ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: emphasize ? 18 : 14,
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                    color:
                        emphasize ? AppColors.navy : AppColors.textPrimary,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.border);

  Future<void> _quoteDeliveryFee(
      BuildContext context, WidgetRef ref, Deal deal) async {
    final controller = TextEditingController(
      text: deal.deliveryFee > 0 ? deal.deliveryFee.toStringAsFixed(2) : '',
    );
    final fee = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delivery quote'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: const InputDecoration(
            prefixText: '\$ ',
            hintText: '0.00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text) ?? 0),
            style: ElevatedButton.styleFrom(minimumSize: const Size(88, 44)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (fee != null) {
      await ref.read(dealServiceProvider).setDeliveryFee(deal, fee);
    }
  }
}

/// Buyer-only, pending-only stepper to change the requested quantity, bounded
/// by the listing's min order and available quantity.
class _QuantityEditor extends ConsumerWidget {
  const _QuantityEditor({
    required this.deal,
    required this.minOrder,
    this.available,
  });

  final Deal deal;
  final int minOrder;
  final int? available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxQ = available ?? deal.quantity;
    final canDec = deal.quantity > minOrder;
    final canInc = deal.quantity < maxQ;

    Future<void> set(int q) async {
      if (q < minOrder) return;
      if (available != null && q > available!) return;
      await ref.read(dealServiceProvider).updateQuantity(deal, q);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _StepBtn(
              icon: Icons.remove,
              enabled: canDec,
              onTap: () => set(deal.quantity - 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '${deal.quantity}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _StepBtn(
              icon: Icons.add,
              enabled: canInc,
              onTap: () => set(deal.quantity + 1),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          available != null
              ? 'Min $minOrder · $available available'
              : 'Min $minOrder',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.orange : AppColors.border,
        ),
      ),
    );
  }
}

/// Delivery proof photos (signed URLs), visible to the deal's parties.
class _DeliveryProofSection extends ConsumerWidget {
  const _DeliveryProofSection({required this.dealId});

  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(deliveryForDealProvider(dealId));
    final delivery = async.valueOrNull;
    if (delivery == null) return const SizedBox.shrink();
    final pickup = delivery.proofOfPickup;
    final drop = delivery.proofOfDelivery;
    if ((pickup == null || pickup.isEmpty) && (drop == null || drop.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery proof',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (pickup != null && pickup.isNotEmpty) ...[
              Column(
                children: [
                  DeliveryProofImage(path: pickup, size: 80),
                  const SizedBox(height: 4),
                  const Text('Pickup',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(width: 12),
            ],
            if (drop != null && drop.isNotEmpty)
              Column(
                children: [
                  DeliveryProofImage(path: drop, size: 80),
                  const SizedBox(height: 4),
                  const Text('Delivery',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _ReviewEntry extends ConsumerWidget {
  const _ReviewEntry({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewed = ref.watch(hasReviewedProvider(deal.id));
    return reviewed.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (already) {
        if (already) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle, color: AppColors.green, size: 18),
                SizedBox(width: 10),
                Text(
                  'Thanks — your review is in.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }
        return OutlinedButton.icon(
          onPressed: () => _openReviewSheet(context, ref),
          icon: const Icon(Icons.star_outline),
          label: const Text('Leave a review'),
        );
      },
    );
  }

  Future<void> _openReviewSheet(BuildContext context, WidgetRef ref) async {
    final me = ref.read(currentUserProvider);
    final reviewedUserId =
        deal.sellerId == me.id ? deal.buyerId : deal.sellerId;
    final result = await showModalBottomSheet<ReviewResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ReviewSheet(),
    );
    if (result == null) return;
    await ref.read(dealServiceProvider).submitReview(
          Review(
            id: 'pending',
            dealId: deal.id,
            reviewerId: me.id,
            reviewedUserId: reviewedUserId,
            rating: result.overall,
            communicationRating: result.communication,
            accuracyRating: result.accuracy,
            deliveryRating: result.delivery,
            reviewText: result.text,
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted')),
      );
    }
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.deal, required this.isSeller});

  final Deal deal;
  final bool isSeller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(dealServiceProvider);
    final buttons = <Widget>[];

    switch (deal.dealStatus) {
      case DealStatus.pending:
        if (isSeller) {
          buttons.add(Expanded(
            child: ElevatedButton(
              onPressed: () => service.accept(deal),
              child: const Text('Accept'),
            ),
          ));
          buttons.add(const SizedBox(width: 10));
          buttons.add(Expanded(
            child: OutlinedButton(
              onPressed: () => service.decline(deal),
              child: const Text('Decline'),
            ),
          ));
        } else {
          buttons.add(Expanded(
            child: OutlinedButton(
              onPressed: () => service.cancel(deal),
              child: const Text('Cancel request'),
            ),
          ));
        }
      case DealStatus.accepted:
        buttons.add(Expanded(
          child: ElevatedButton(
            onPressed: () => service.complete(deal),
            child: const Text('Mark complete'),
          ),
        ));
        buttons.add(const SizedBox(width: 10));
        buttons.add(Expanded(
          child: OutlinedButton(
            onPressed: () => service.cancel(deal),
            child: const Text('Cancel'),
          ),
        ));
      case DealStatus.completed:
      case DealStatus.cancelled:
      case DealStatus.declined:
        break;
    }

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (buttons.isNotEmpty) ...[
            Row(children: buttons),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final convId = await ref
                    .read(messageServiceProvider)
                    .openDealThread(deal);
                if (context.mounted) context.push('/chat/thread/$convId');
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Message'),
            ),
          ),
        ],
      ),
    );
  }
}
