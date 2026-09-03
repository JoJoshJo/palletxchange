import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../models/delivery.dart';
import '../../models/enums.dart';

class DeliveryDetailScreen extends ConsumerWidget {
  const DeliveryDetailScreen({super.key, required this.deliveryId});

  final String deliveryId;

  /// The advance order for an assigned delivery.
  static const _flow = [
    DeliveryStatus.driverAssigned,
    DeliveryStatus.pickedUp,
    DeliveryStatus.inTransit,
    DeliveryStatus.delivered,
    DeliveryStatus.completed,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(deliveryByIdProvider(deliveryId));
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text("Couldn't load delivery")),
        data: (delivery) => delivery == null
            ? const Center(child: Text('Delivery not found'))
            : _Body(delivery: delivery),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(deliveryServiceProvider);
    final currentIdx =
        DeliveryDetailScreen._flow.indexOf(delivery.deliveryStatus);
    final nextStatus = currentIdx >= 0 &&
            currentIdx < DeliveryDetailScreen._flow.length - 1
        ? DeliveryDetailScreen._flow[currentIdx + 1]
        : null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                delivery.listingTitle ?? 'Pallet delivery',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${delivery.quantity ?? 0} pallets · fee ${moneyWhole(delivery.deliveryFee)}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Addresses (revealed to the assigned driver).
              _AddressCard(
                icon: Icons.circle,
                iconColor: AppColors.green,
                label: 'Pickup',
                address: delivery.pickupAddress,
              ),
              const SizedBox(height: 10),
              _AddressCard(
                icon: Icons.place,
                iconColor: AppColors.orange,
                label: 'Drop-off',
                address: delivery.dropoffAddress,
              ),
              const SizedBox(height: 20),

              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _Stepper(currentIndex: currentIdx),
              const SizedBox(height: 20),

              const Text(
                'Proof photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _ProofButton(
                label: 'Pickup proof',
                attached: delivery.proofOfPickup != null,
                onTap: () => service.addProofOfPickup(delivery),
              ),
              const SizedBox(height: 10),
              _ProofButton(
                label: 'Delivery proof',
                attached: delivery.proofOfDelivery != null,
                onTap: () => service.addProofOfDelivery(delivery),
              ),
            ],
          ),
        ),
        if (nextStatus != null)
          Container(
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => service.advance(delivery, nextStatus),
                child: Text(_advanceLabel(nextStatus)),
              ),
            ),
          ),
      ],
    );
  }

  static String _advanceLabel(DeliveryStatus next) => switch (next) {
        DeliveryStatus.pickedUp => 'Mark picked up',
        DeliveryStatus.inTransit => 'Mark in transit',
        DeliveryStatus.delivered => 'Mark delivered',
        DeliveryStatus.completed => 'Complete delivery',
        _ => 'Advance',
      };
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.35,
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

class _Stepper extends StatelessWidget {
  const _Stepper({required this.currentIndex});

  final int currentIndex;

  static const _labels = [
    'Assigned',
    'Picked up',
    'In transit',
    'Delivered',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _labels.length; i++)
          _StepRow(
            label: _labels[i],
            done: i <= currentIndex,
            current: i == currentIndex,
            isLast: i == _labels.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.current,
    required this.isLast,
  });

  final String label;
  final bool done;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.green : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done ? AppColors.green : AppColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 13, color: AppColors.onDark)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.border),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 1),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                color:
                    done ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofButton extends StatelessWidget {
  const _ProofButton({
    required this.label,
    required this.attached,
    required this.onTap,
  });

  final String label;
  final bool attached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: attached ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: attached ? AppColors.green : AppColors.textPrimary,
      ),
      icon: Icon(attached ? Icons.check_circle : Icons.add_a_photo_outlined),
      label: Text(attached ? '$label attached' : 'Add $label'),
    );
  }
}
