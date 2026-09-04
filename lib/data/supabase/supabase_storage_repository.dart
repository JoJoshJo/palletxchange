import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/storage_repository.dart';

/// Real [StorageRepository] over Supabase Storage.
class SupabaseStorageRepository implements StorageRepository {
  SupabaseClient get _c => Supabase.instance.client;
  final _rng = Random.secure();

  String _uid() {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw StateError('No signed-in user');
    return uid;
  }

  String _fileName(String ext) =>
      '${DateTime.now().microsecondsSinceEpoch}_'
      '${_rng.nextInt(1 << 32).toRadixString(16)}.$ext';

  Future<void> _upload(
    String bucket,
    String path,
    Uint8List bytes,
    String contentType,
  ) async {
    await _c.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
  }

  @override
  Future<String> uploadListingPhoto({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final path = '${_uid()}/${_fileName(fileExtension)}';
    await _upload(StorageBuckets.listingPhotos, path, bytes, contentType);
    return _c.storage.from(StorageBuckets.listingPhotos).getPublicUrl(path);
  }

  @override
  Future<String> uploadDriverDoc({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
    required String kind,
  }) async {
    // {uid}/{kind}/{file} — RLS keys off foldername[1] = uid.
    final path = '${_uid()}/$kind/${_fileName(fileExtension)}';
    await _upload(StorageBuckets.driverDocs, path, bytes, contentType);
    return path;
  }

  @override
  Future<String> uploadDeliveryProof({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
    required String dealId,
    required String kind,
  }) async {
    // {dealId}/{kind}/{file} — RLS keys off foldername[1] = deal id.
    final path = '$dealId/$kind/${_fileName(fileExtension)}';
    await _upload(StorageBuckets.deliveryProof, path, bytes, contentType);
    return path;
  }

  @override
  Future<String> signedUrl({
    required String bucket,
    required String path,
    int expiresSeconds = 3600,
  }) {
    return _c.storage.from(bucket).createSignedUrl(path, expiresSeconds);
  }
}

/// Ungated-dev fallback: storage unavailable.
class NoopStorageRepository implements StorageRepository {
  @override
  Future<String> uploadListingPhoto({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async =>
      throw UnsupportedError('Storage unavailable (Supabase not configured)');

  @override
  Future<String> uploadDriverDoc({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
    required String kind,
  }) async =>
      throw UnsupportedError('Storage unavailable');

  @override
  Future<String> uploadDeliveryProof({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
    required String dealId,
    required String kind,
  }) async =>
      throw UnsupportedError('Storage unavailable');

  @override
  Future<String> signedUrl({
    required String bucket,
    required String path,
    int expiresSeconds = 3600,
  }) async =>
      throw UnsupportedError('Storage unavailable');
}
