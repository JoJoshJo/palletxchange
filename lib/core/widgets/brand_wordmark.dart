import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// The app-bar brand lockup: the pallet mark (SVG asset) + "Pallet"(white) /
/// "Xchange"(orange) wordmark. Used as the AppBar title across the shell.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.markSize = 28});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/branding/palletxchange_icon.svg',
          width: markSize,
          height: markSize,
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Pallet',
                style: TextStyle(color: AppColors.onDark),
              ),
              TextSpan(
                text: 'Xchange',
                style: TextStyle(color: AppColors.orange),
              ),
            ],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
