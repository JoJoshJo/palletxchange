import 'dart:typed_data';

/// Bucket names (kept here so callers don't sprinkle string literals).
class StorageBuckets {
  static const listingPhotos = 'listing-photos';
  static const driverDocs = 'driver-docs';
  static const deliveryProof = 'delivery-proof';
}

/// Uploads binary assets to Storage. Listing photos are public; driver docs and
/// delivery proof are private (accessed via signed URLs).
abstract interface class StorageRepository {
  /// Public listing photo → returns its public URL.
  Future<String> uploadListingPhoto({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  });

  /// Driver document (license/insurance) → path `{uid}/{kind}/{file}` in the
  /// private driver-docs bucket. Returns the storage path.
  Future<String> uploadDriverDoc({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
    required String kind, // 'license' | 'insurance'
  });

  /// Delivery proof → path `{dealId}/{kind}/{file}` in the private
  /// delivery-proof bucket. Returns the storage path.
  Future<String> uploadDeliveryProof({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
    required String dealId,
    required String kind, // 'pickup' | 'delivery'
  });

  /// A time-limited signed URL for a private object.
  Future<String> signedUrl({
    required String bucket,
    required String path,
    int expiresSeconds = 3600,
  });
}
