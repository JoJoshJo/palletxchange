import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/storage_repository.dart';

/// Real [StorageRepository] over Supabase Storage. Files are written under
/// `{uid}/{random}/{name}` so bucket RLS can gate writes to the owner.
class SupabaseStorageRepository implements StorageRepository {
  SupabaseClient get _c => Supabase.instance.client;
  final _rng = Random.secure();

  String _uid() {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw StateError('No signed-in user');
    return uid;
  }

  String _path(String ext) {
    final folder = List.generate(16, (_) => _rng.nextInt(16).toRadixString(16))
        .join();
    final name = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    return '${_uid()}/$folder/$name';
  }

  Future<String> _uploadPublic({
    required String bucket,
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final path = _path(fileExtension);
    await _c.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return _c.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> _uploadPrivate({
    required String bucket,
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final path = _path(fileExtension);
    await _c.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    // Private buckets: return the storage path; consumers create signed URLs.
    return path;
  }

  @override
  Future<String> uploadListingPhoto({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) =>
      _uploadPublic(
        bucket: 'listing-photos',
        bytes: bytes,
        fileExtension: fileExtension,
        contentType: contentType,
      );

  @override
  Future<String> uploadDriverDoc({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) =>
      _uploadPrivate(
        bucket: 'driver-docs',
        bytes: bytes,
        fileExtension: fileExtension,
        contentType: contentType,
      );

  @override
  Future<String> uploadDeliveryProof({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) =>
      _uploadPrivate(
        bucket: 'delivery-proof',
        bytes: bytes,
        fileExtension: fileExtension,
        contentType: contentType,
      );
}

/// Fallback for ungated dev (no Supabase): uploads are unavailable.
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
  }) async =>
      throw UnsupportedError('Storage unavailable');

  @override
  Future<String> uploadDeliveryProof({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async =>
      throw UnsupportedError('Storage unavailable');
}
