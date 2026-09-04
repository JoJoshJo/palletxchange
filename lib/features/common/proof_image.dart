import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../data/repositories/storage_repository.dart';

/// A thumbnail for a private storage object, loaded via a signed URL. Tapping
/// opens it full-screen. Shows a graceful placeholder if missing/unauthorized.
class ProofImage extends ConsumerWidget {
  const ProofImage({
    super.key,
    required this.bucket,
    required this.path,
    this.size = 72,
  });

  final String bucket;
  final String path;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(signedUrlProvider((bucket: bucket, path: path)));
    return urlAsync.when(
      loading: () => _box(const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      )),
      error: (_, _) => _box(const Icon(Icons.broken_image_outlined,
          color: AppColors.textMuted)),
      data: (url) => GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _box(const Icon(
                Icons.broken_image_outlined, color: AppColors.textMuted)),
          ),
        ),
      ),
    );
  }

  Widget _box(Widget child) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

/// Convenience for delivery proof.
class DeliveryProofImage extends StatelessWidget {
  const DeliveryProofImage({super.key, required this.path, this.size = 72});
  final String path;
  final double size;

  @override
  Widget build(BuildContext context) =>
      ProofImage(bucket: StorageBuckets.deliveryProof, path: path, size: size);
}
