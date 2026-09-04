import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/app_auth.dart';
import '../providers.dart';

/// Driver onboarding: upload license / insurance to the private driver-docs
/// bucket and record the paths on the driver's profile.
class DriverService {
  DriverService(this.ref);
  final Ref ref;

  /// [kind] is 'license' or 'insurance'.
  Future<void> submitDoc({
    required String kind,
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final me = ref.read(currentUserProvider);
    final path = await ref.read(storageRepositoryProvider).uploadDriverDoc(
          bytes: bytes,
          fileExtension: fileExtension,
          contentType: contentType,
          kind: kind,
        );
    final updated = kind == 'license'
        ? me.copyWith(driverLicenseUrl: path)
        : me.copyWith(driverInsuranceUrl: path);
    await ref.read(profileRepositoryProvider).updateProfile(updated);
    // Refresh the cached profile so the UI reflects the submission.
    await appAuth.refresh();
  }
}
