import 'dart:typed_data';

/// Uploads binary assets to Storage. Listing photos are public; driver docs and
/// delivery proof are private (stubbed here for later wiring).
abstract interface class StorageRepository {
  /// Uploads a listing photo and returns its public URL. Path is namespaced by
  /// the owner's uid so Storage RLS can restrict writes to the owner.
  Future<String> uploadListingPhoto({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  });

  /// Later: driver license/insurance (private bucket).
  Future<String> uploadDriverDoc({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  });

  /// Later: pickup/delivery proof (private bucket).
  Future<String> uploadDeliveryProof({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  });
}
