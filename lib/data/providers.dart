import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing.dart';
import '../models/profile.dart';
import 'fake/fake_deal_repository.dart';
import 'fake/fake_listing_repository.dart';
import 'fake/fake_profile_repository.dart';
import 'fake/fake_request_repository.dart';
import 'repositories/deal_repository.dart';
import 'repositories/listing_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/request_repository.dart';

/// Repository providers. Swapping to Supabase later = override just these in
/// ProviderScope; no UI or controller changes required (BRAIN §6, §12).
final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return FakeListingRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FakeProfileRepository();
});

final dealRepositoryProvider = Provider<DealRepository>((ref) {
  return FakeDealRepository();
});

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return FakeRequestRepository();
});

/// The signed-in user's profile (fixed demo trader until auth lands).
final currentProfileProvider = FutureProvider<Profile>((ref) {
  return ref.watch(profileRepositoryProvider).getCurrentProfile();
});

/// Active marketplace filters.
final listingFilterProvider =
    StateProvider<ListingFilter>((ref) => const ListingFilter());

/// The marketplace list, reactive to the current filter and to newly created
/// listings (the repository instance is shared, so createListing shows up on
/// the next load).
final marketplaceListingsProvider = FutureProvider<List<Listing>>((ref) {
  final filter = ref.watch(listingFilterProvider);
  return ref.watch(listingRepositoryProvider).getListings(filter: filter);
});

/// A single listing by id (for the detail screen).
final listingByIdProvider =
    FutureProvider.family<Listing?, String>((ref, id) {
  return ref.watch(listingRepositoryProvider).getListingById(id);
});
