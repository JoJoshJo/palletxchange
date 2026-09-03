import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/enums.dart';

/// Colored status chip: pending=amber, accepted=green, completed=green-muted
/// with a check, cancelled/declined=grey.
class DealStatusChip extends StatelessWidget {
  const DealStatusChip({super.key, required this.status});

  final DealStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg, String label, IconData icon) = switch (status) {
      DealStatus.pending => (
          const Color(0xFF9A6700),
          const Color(0xFFFFF3D6),
          'Pending',
          Icons.hourglass_top,
        ),
      DealStatus.accepted => (
          AppColors.green,
          const Color(0xFFE2F1E9),
          'Accepted',
          Icons.check_circle_outline,
        ),
      DealStatus.completed => (
          AppColors.teal,
          const Color(0xFFE1EEEC),
          'Completed',
          Icons.verified,
        ),
      DealStatus.cancelled => (
          AppColors.textMuted,
          AppColors.surface,
          'Cancelled',
          Icons.cancel_outlined,
        ),
      DealStatus.declined => (
          AppColors.textMuted,
          AppColors.surface,
          'Declined',
          Icons.block,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
