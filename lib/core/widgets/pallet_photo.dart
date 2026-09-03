import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_colors.dart';

/// A listing photo with graceful fallbacks. When a listing has no uploaded
/// photo yet (Milestone 1 has none — camera upload arrives with Supabase),
/// this renders a branded placeholder tile instead of a broken image.
class PalletPhoto extends StatelessWidget {
  const PalletPhoto({
    super.key,
    this.url,
    this.height,
    this.width,
    this.borderRadius,
  });

  final String? url;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final placeholder = _Placeholder(height: height, width: width);

    final Widget child;
    if (url == null || url!.isEmpty) {
      child = placeholder;
    } else {
      child = CachedNetworkImage(
        imageUrl: url!,
        height: height,
        width: width,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(color: AppColors.surface),
        errorWidget: (_, _, _) => placeholder,
      );
    }
    return ClipRRect(borderRadius: radius, child: child);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.height, this.width});

  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.photo_camera_outlined,
              size: 26, color: AppColors.textMuted),
          SizedBox(height: 4),
          Text(
            'No photo',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
