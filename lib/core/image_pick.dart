import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'theme/app_colors.dart';

class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.fileExtension,
    required this.contentType,
  });
  final Uint8List bytes;
  final String fileExtension;
  final String contentType;
}

String _contentTypeFor(String ext) {
  switch (ext.toLowerCase()) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    default:
      return 'image/jpeg';
  }
}

/// Prompts Camera/Gallery, returns the picked image bytes (compressed) or null.
Future<PickedImage?> pickImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final x = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    imageQuality: 75,
  );
  if (x == null) return null;
  final bytes = await x.readAsBytes();
  final ext = x.name.contains('.') ? x.name.split('.').last.toLowerCase() : 'jpg';
  return PickedImage(
    bytes: bytes,
    fileExtension: ext,
    contentType: _contentTypeFor(ext),
  );
}
