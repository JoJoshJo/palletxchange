import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../core/widgets/trust_widgets.dart';
import '../../data/providers.dart';
import '../../models/delivery.dart';
import 'delivery_detail_screen.dart';
import 'widgets/route_line.dart';

class DriverDeliveriesScreen extends ConsumerWidget {
  const DriverDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myDeliveriesProvider);
    return Scaffold(
      appBar: AppBar(title: const BrandWordmark()),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.bg,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: const Text(
              'My deliveries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const Center(child: Text("Couldn't load deliveries")),
              data: (items) {
                if (items.isEmpty) return const _Empty();
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myDeliveriesProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _DeliveryRow(delivery: items[i]),
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

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeliveryDetailScreen(deliveryId: delivery.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RouteLine(
                      from: delivery.pickupCity ?? '—',
                      to: delivery.dropoffCity ?? '—',
                    ),
                  ),
                  _DeliveryStatusPill(status: delivery.deliveryStatus.label),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                delivery.listingTitle ?? 'Pallet delivery',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  MetaTag(
                    icon: Icons.inventory_2_outlined,
                    label: '${delivery.quantity ?? 0} pallets',
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryStatusPill extends StatelessWidget {
  const _DeliveryStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.teal,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.route_outlined, size: 56, color: AppColors.textMuted),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No deliveries yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            'Claim a job to get started.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
