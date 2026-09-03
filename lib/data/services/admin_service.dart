import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/listing.dart';
import '../../models/profile.dart';
import '../../models/report.dart';
import '../providers.dart';

/// Admin oversight actions (BRAIN §4, §8) over the in-memory repos.
class AdminService {
  AdminService(this.ref);

  final Ref ref;

  /// Toggle a business's verified badge — how a business earns the ✓.
  Future<void> toggleVerified(Profile profile) async {
    await ref
        .read(profileRepositoryProvider)
        .updateProfile(profile.copyWith(verifiedStatus: !profile.verifiedStatus));
    ref.invalidate(allProfilesProvider);
    ref.invalidate(profileByIdProvider(profile.id));
  }

  /// Remove a listing (archive it immediately).
  Future<void> removeListing(Listing listing) async {
    await ref
        .read(listingRepositoryProvider)
        .updateListing(listing.copyWith(status: ListingStatus.archived));
    ref.invalidate(allListingsProvider);
    ref.invalidate(marketplaceListingsProvider);
    ref.invalidate(listingByIdProvider(listing.id));
  }

  Future<void> resolveReport(Report report) async {
    await ref
        .read(reportRepositoryProvider)
        .updateReport(report.copyWith(status: ReportStatus.resolved));
    ref.invalidate(allReportsProvider);
  }
}
