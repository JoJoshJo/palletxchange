import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/image_pick.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../models/delivery.dart';
import '../../models/enums.dart';
import '../common/proof_image.dart';

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
              _ProofRow(
                label: 'Pickup proof',
                kind: 'pickup',
                path: delivery.proofOfPickup,
                delivery: delivery,
              ),
              const SizedBox(height: 12),
              _ProofRow(
                label: 'Delivery proof',
                kind: 'delivery',
                path: delivery.proofOfDelivery,
                delivery: delivery,
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

/// Driver-facing proof row: a signed-URL thumbnail when present, plus an
/// upload/replace action that stores to the private bucket.
class _ProofRow extends ConsumerStatefulWidget {
  const _ProofRow({
    required this.label,
    required this.kind,
    required this.path,
    required this.delivery,
  });

  final String label;
  final String kind; // 'pickup' | 'delivery'
  final String? path;
  final Delivery delivery;

  @override
  ConsumerState<_ProofRow> createState() => _ProofRowState();
}

class _ProofRowState extends ConsumerState<_ProofRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final has = widget.path != null && widget.path!.isNotEmpty;
    return Row(
      children: [
        if (has)
          DeliveryProofImage(path: widget.path!)
        else
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                has ? 'Uploaded' : 'Not uploaded yet',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : TextButton(
                onPressed: _upload,
                child: Text(has ? 'Replace' : 'Add'),
              ),
      ],
    );
  }

  Future<void> _upload() async {
    final picked = await pickImage(context);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(deliveryServiceProvider).uploadProof(
            delivery: widget.delivery,
            kind: widget.kind,
            bytes: picked.bytes,
            fileExtension: picked.fileExtension,
            contentType: picked.contentType,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.label} uploaded')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't upload — try again")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
