import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/conversation.dart';
import '../models/deal.dart';
import '../models/delivery.dart';
import '../models/enums.dart';
import '../models/listing.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/report.dart';
import '../models/request.dart';
import 'fake/fake_deal_repository.dart';
import 'fake/fake_delivery_repository.dart';
import 'fake/fake_listing_repository.dart';
import 'fake/fake_message_repository.dart';
import 'fake/fake_profile_repository.dart';
import 'fake/fake_report_repository.dart';
import 'fake/fake_request_repository.dart';
import 'fake/fake_review_repository.dart';
import 'fake/fake_seed.dart';
import 'repositories/deal_repository.dart';
import 'repositories/delivery_repository.dart';
import 'repositories/listing_repository.dart';
import 'repositories/message_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/report_repository.dart';
import 'repositories/request_repository.dart';
import 'repositories/review_repository.dart';
import 'repositories/storage_repository.dart';
import 'services/admin_service.dart';
import 'services/deal_service.dart';
import 'services/delivery_service.dart';
import 'services/matching_service.dart';
import 'services/message_service.dart';
import 'services/request_service.dart';
import 'supabase/supabase_deal_repository.dart';
import 'supabase/supabase_delivery_repository.dart';
import 'supabase/supabase_listing_repository.dart';
import 'supabase/supabase_message_repository.dart';
import 'supabase/supabase_profile_repository.dart';
import 'supabase/supabase_report_repository.dart';
import 'supabase/supabase_request_repository.dart';
import 'supabase/supabase_review_repository.dart';
import 'supabase/supabase_storage_repository.dart';
import 'auth/app_auth.dart';

/// Repository providers. profiles + listings are REAL (Supabase) when the app
/// is configured; the rest remain fake until their swap. Fake fallbacks keep
/// the app runnable in ungated dev (no env).
final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseListingRepository()
      : FakeListingRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseProfileRepository()
      : FakeProfileRepository();
});

final dealRepositoryProvider = Provider<DealRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseDealRepository()
      : FakeDealRepository();
});

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseRequestRepository()
      : FakeRequestRepository();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseReviewRepository()
      : FakeReviewRepository();
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseMessageRepository()
      : FakeMessageRepository();
});

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseDeliveryRepository()
      : FakeDeliveryRepository();
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseReportRepository()
      : FakeReportRepository();
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseStorageRepository()
      : NoopStorageRepository();
});

/// The signed-in user's profile, refetched when the auth user changes.
final currentProfileProvider = FutureProvider<Profile>((ref) {
  if (SupabaseConfig.isConfigured) ref.watch(appAuthProvider);
  return ref.watch(profileRepositoryProvider).getCurrentProfile();
});

/// Bridges the [AppAuth] ChangeNotifier into Riverpod so everything derived
/// from the current user re-runs when the auth user changes (login / logout /
/// account switch).
final appAuthProvider = ChangeNotifierProvider<AppAuth>((ref) => appAuth);

/// Synchronous access to the signed-in user's profile. Reactive to auth
/// changes via [appAuthProvider]; never serves a cache whose id doesn't match
/// the current session user. A minimal fallback covers the brief window before
/// the profile row is fetched.
final currentUserProvider = Provider<Profile>((ref) {
  if (!SupabaseConfig.isConfigured) return FakeSeed.currentUser;
  final auth = ref.watch(appAuthProvider);
  final cached = auth.currentProfile; // already id-guarded
  if (cached != null) return cached;
  final user = Supabase.instance.client.auth.currentUser;
  return Profile(
    id: user?.id ?? 'unknown',
    name: user?.email ?? 'You',
    email: user?.email,
    accountType: AccountType.individual,
  );
});

final profileByIdProvider =
    FutureProvider.family<Profile?, String>((ref, id) {
  return ref.watch(profileRepositoryProvider).getProfileById(id);
});

// ── Listings ──

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

// ── Deals ──

final dealServiceProvider = Provider<DealService>((ref) => DealService(ref));

/// Deals where the current user is buyer, seller, or driver.
final myDealsProvider = FutureProvider<List<Deal>>((ref) {
  final me = ref.watch(currentUserProvider);
  return ref.watch(dealRepositoryProvider).getDealsForUser(me.id);
});

final dealByIdProvider = FutureProvider.family<Deal?, String>((ref, id) {
  return ref.watch(dealRepositoryProvider).getDealById(id);
});

/// Whether the current user has already reviewed a given deal.
final hasReviewedProvider =
    FutureProvider.family<bool, String>((ref, dealId) {
  final me = ref.watch(currentUserProvider);
  return ref
      .watch(reviewRepositoryProvider)
      .hasReviewed(dealId: dealId, reviewerId: me.id);
});

/// A seller's active listings (for their storefront).
final sellerActiveListingsProvider =
    FutureProvider.family<List<Listing>, String>((ref, sellerId) async {
  final all =
      await ref.watch(listingRepositoryProvider).getListingsBySeller(sellerId);
  return all.where((l) => l.status == ListingStatus.active).toList();
});

/// Count of a seller's completed deals (shown on the storefront header).
final sellerCompletedDealsProvider =
    FutureProvider.family<int, String>((ref, sellerId) async {
  final deals = await ref.watch(dealRepositoryProvider).getDealsForUser(sellerId);
  return deals
      .where((d) => d.sellerId == sellerId && d.dealStatus == DealStatus.completed)
      .length;
});

// ── Requests + matching ──

final requestServiceProvider =
    Provider<RequestService>((ref) => RequestService(ref));

final requestByIdProvider =
    FutureProvider.family<PalletRequest?, String>((ref, id) {
  return ref.watch(requestRepositoryProvider).getRequestById(id);
});

/// Scored matches for a request (BRAIN §7). Targeted requests are restricted to
/// the target seller's listings first; broadcast scores the whole market.
final matchesForRequestProvider =
    FutureProvider.family<List<ScoredListing>, String>((ref, requestId) async {
  final request =
      await ref.watch(requestRepositoryProvider).getRequestById(requestId);
  if (request == null) return const [];
  final repo = ref.watch(listingRepositoryProvider);
  final listings = request.targetSellerId != null
      ? await repo.getListingsBySeller(request.targetSellerId!)
      : await repo.getListings();
  return MatchingService.matches(request, listings);
});

// ── Messages ──

final messageServiceProvider =
    Provider<MessageService>((ref) => MessageService(ref));

final myConversationsProvider = FutureProvider<List<Conversation>>((ref) {
  final me = ref.watch(currentUserProvider);
  return ref.watch(messageRepositoryProvider).getConversationsForUser(me.id);
});

final conversationByIdProvider =
    FutureProvider.family<Conversation?, String>((ref, id) {
  return ref.watch(messageRepositoryProvider).getConversationById(id);
});

final messagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.watch(messageRepositoryProvider).getMessages(conversationId);
});

// ── Deliveries (driver job board) ──

final deliveryServiceProvider =
    Provider<DeliveryService>((ref) => DeliveryService(ref));

/// The signed-in driver = the current user (their account_type is driver).
final currentDriverProvider =
    Provider<Profile>((ref) => ref.watch(currentUserProvider));

final openJobsProvider = FutureProvider<List<Delivery>>((ref) {
  return ref.watch(deliveryRepositoryProvider).getOpenJobs();
});

final myDeliveriesProvider = FutureProvider<List<Delivery>>((ref) {
  final driver = ref.watch(currentDriverProvider);
  return ref.watch(deliveryRepositoryProvider).getDeliveriesForDriver(driver.id);
});

final deliveryByIdProvider =
    FutureProvider.family<Delivery?, String>((ref, id) {
  return ref.watch(deliveryRepositoryProvider).getDeliveryById(id);
});

/// Driver earnings = sum of completed-delivery fees (computed, not hardcoded).
final driverEarningsProvider = FutureProvider<double>((ref) async {
  final deliveries = await ref.watch(myDeliveriesProvider.future);
  return deliveries
      .where((d) => d.deliveryStatus == DeliveryStatus.completed)
      .fold<double>(0, (sum, d) => sum + d.deliveryFee);
});

// ── Admin oversight ──

final adminServiceProvider =
    Provider<AdminService>((ref) => AdminService(ref));

final allProfilesProvider = FutureProvider<List<Profile>>((ref) {
  return ref.watch(profileRepositoryProvider).getAllProfiles();
});

final allListingsProvider = FutureProvider<List<Listing>>((ref) {
  return ref.watch(listingRepositoryProvider).getAllListings();
});

final allReportsProvider = FutureProvider<List<Report>>((ref) {
  return ref.watch(reportRepositoryProvider).getAllReports();
});

/// Aggregate counts for the admin overview.
class AdminStats {
  const AdminStats({
    required this.users,
    required this.activeListings,
    required this.dealsByStatus,
    required this.openReports,
  });
  final int users;
  final int activeListings;
  final Map<DealStatus, int> dealsByStatus;
  final int openReports;
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final profiles = await ref.watch(allProfilesProvider.future);
  final listings = await ref.watch(allListingsProvider.future);
  final reports = await ref.watch(allReportsProvider.future);

  // Deals across all known users (dedup by id).
  final dealRepo = ref.watch(dealRepositoryProvider);
  final seen = <String, DealStatus>{};
  for (final p in profiles) {
    for (final d in await dealRepo.getDealsForUser(p.id)) {
      seen[d.id] = d.dealStatus;
    }
  }
  final byStatus = <DealStatus, int>{};
  for (final s in seen.values) {
    byStatus[s] = (byStatus[s] ?? 0) + 1;
  }

  return AdminStats(
    users: profiles.length,
    activeListings:
        listings.where((l) => l.status == ListingStatus.active).length,
    dealsByStatus: byStatus,
    openReports: reports.where((r) => r.status == ReportStatus.open).length,
  );
});
