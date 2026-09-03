import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A compact "pickup city → dropoff city" route indicator.
class RouteLine extends StatelessWidget {
  const RouteLine({
    super.key,
    required this.from,
    required this.to,
    this.bold = true,
  });

  final String from;
  final String to;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 15,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: AppColors.textPrimary,
    );
    return Row(
      children: [
        const Icon(Icons.circle, size: 9, color: AppColors.green),
        const SizedBox(width: 6),
        Flexible(child: Text(from, overflow: TextOverflow.ellipsis, style: style)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, size: 15, color: AppColors.textMuted),
        ),
        const Icon(Icons.place, size: 12, color: AppColors.orange),
        const SizedBox(width: 4),
        Flexible(child: Text(to, overflow: TextOverflow.ellipsis, style: style)),
      ],
    );
  }
}
