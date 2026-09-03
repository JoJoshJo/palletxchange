import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Seller name + green verified check + star rating — shown on the card and on
/// the listing detail (trust-on-the-card, BRAIN §11).
class SellerTrustLine extends StatelessWidget {
  const SellerTrustLine({
    super.key,
    required this.name,
    required this.verified,
    this.rating,
    this.dense = false,
  });

  final String name;
  final bool verified;
  final double? rating;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final nameStyle = TextStyle(
      fontSize: dense ? 13 : 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    return Row(
      children: [
        Flexible(
          child: Text(name, overflow: TextOverflow.ellipsis, style: nameStyle),
        ),
        if (verified) ...[
          const SizedBox(width: 4),
          const Icon(Icons.verified, size: 15, color: AppColors.green),
        ],
        if (rating != null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.star_rounded, size: 15, color: AppColors.orange),
          const SizedBox(width: 2),
          Text(
            rating!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// A condition-grade badge (BRAIN §11 — condition shown as a clear badge).
class ConditionBadge extends StatelessWidget {
  const ConditionBadge({super.key, required this.label, this.recyclable = false});

  final String label;
  final bool recyclable;

  @override
  Widget build(BuildContext context) {
    final color = recyclable ? AppColors.teal : AppColors.slate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// A small icon + text tag (pickup/delivery, distance, quantity).
class MetaTag extends StatelessWidget {
  const MetaTag({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
