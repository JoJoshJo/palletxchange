import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/location/geo.dart';
import 'location_provider.dart';
import 'paging.dart';
import '../models/app_notification.dart';
import '../models/conversation.dart';
import '../models/deal.dart';
import '../models/delivery.dart';
import '../models/enums.dart';
import '../models/listing.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/report.dart';
import '../models/request.dart';
import 'fake/fake_block_repository.dart';
import 'fake/fake_deal_repository.dart';
import 'fake/fake_delivery_repository.dart';
import 'fake/fake_listing_repository.dart';
import 'fake/fake_message_repository.dart';
import 'fake/fake_profile_repository.dart';
import 'fake/fake_report_repository.dart';
import 'fake/fake_request_repository.dart';
import 'fake/fake_review_repository.dart';
import 'fake/fake_seed.dart';
import 'repositories/block_repository.dart';
import 'repositories/deal_repository.dart';
import 'repositories/delivery_repository.dart';
import 'repositories/listing_repository.dart';
import 'repositories/message_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/report_repository.dart';
import 'repositories/request_repository.dart';
import 'repositories/review_repository.dart';
import 'repositories/storage_repository.dart';
import 'services/admin_service.dart';
import 'services/deal_service.dart';
import 'services/delivery_service.dart';
import 'services/driver_service.dart';
import 'services/matching_service.dart';
import 'services/message_service.dart';
import 'services/request_service.dart';
import 'supabase/supabase_block_repository.dart';
import 'supabase/supabase_deal_repository.dart';
import 'supabase/supabase_delivery_repository.dart';
import 'supabase/supabase_listing_repository.dart';
import 'supabase/supabase_message_repository.dart';
import 'supabase/supabase_notification_repository.dart';
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

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseBlockRepository()
      : FakeBlockRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseConfig.isConfigured
      ? SupabaseNotificationRepository()
      : FakeNotificationRepository();
});

/// The current user's notifications, newest first (reactive to auth).
final myNotificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  if (SupabaseConfig.isConfigured) ref.watch(appAuthProvider);
  return ref.watch(notificationRepositoryProvider).getMyNotifications();
});

/// Unread notification count for the bell badge.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(myNotificationsProvider).valueOrNull ?? const [];
  return list.where((n) => !n.read).length;
});

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService(ref));

class NotificationService {
  NotificationService(this.ref);
  final Ref ref;

  Future<void> markRead(String id) async {
    await ref.read(notificationRepositoryProvider).markRead(id);
    ref.invalidate(myNotificationsProvider);
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.invalidate(myNotificationsProvider);
  }

  void refresh() => ref.invalidate(myNotificationsProvider);
}

/// Ids the current user has blocked (drives hiding + contact guards).
final blockedIdsProvider = FutureProvider<Set<String>>((ref) async {
  if (SupabaseConfig.isConfigured) ref.watch(appAuthProvider);
  final ids = await ref.watch(blockRepositoryProvider).getMyBlockedIds();
  return ids.toSet();
});

/// Block / unblock actions that refresh the affected views.
final blockServiceProvider = Provider<BlockService>((ref) => BlockService(ref));

class BlockService {
  BlockService(this.ref);
  final Ref ref;

  Future<void> block(String userId) async {
    await ref.read(blockRepositoryProvider).block(userId);
    _refresh();
  }

  Future<void> unblock(String userId) async {
    await ref.read(blockRepositoryProvider).unblock(userId);
    _refresh();
  }

  void _refresh() {
    ref.invalidate(blockedIdsProvider);
    ref.invalidate(marketplaceListingsProvider);
  }
}

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

/// The marketplace list — paged/infinite-scroll. Distance + radius are applied
/// server-side (listings_within_radius RPC) when the active location has
/// coordinates; blocked sellers are filtered per page. Recreated whenever the
/// filter, location, or block set changes.
final marketplaceListingsProvider = StateNotifierProvider.autoDispose<
    PagedNotifier<Listing>, PagedState<Listing>>((ref) {
  final filter = ref.watch(listingFilterProvider);
  final loc = ref.watch(locationProvider);
  final blocked = ref.watch(blockedIdsProvider).valueOrNull ?? const <String>{};
  final repo = ref.watch(listingRepositoryProvider);
  return PagedNotifier<Listing>((offset, limit) async {
    var page = await repo.searchListings(
      filter: filter,
      lat: loc.hasCoords ? loc.lat : null,
      lng: loc.hasCoords ? loc.lng : null,
      radiusMiles: loc.hasCoords ? loc.radiusMiles : null,
      limit: limit,
      offset: offset,
    );
    // Client-side radius when the fallback (no RPC) returned raw rows.
    if (loc.hasCoords) {
      page = page.map((l) {
        if (l.distanceMiles != null) return l;
        if (l.latitude != null && l.longitude != null) {
          return l.copyWith(distanceMiles:
              haversineMiles(loc.lat!, loc.lng!, l.latitude!, l.longitude!));
        }
        return l;
      }).toList();
    }
    if (blocked.isNotEmpty) {
      page = page.where((l) => !blocked.contains(l.sellerId)).toList();
    }
    return page;
  }, pageSize: 20);
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
  return ref.watch(dealRepositoryProvider).getDealsForUser(me.id, limit: 100);
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

/// A seller's archived listings (owner-only re-list section on My Storefront).
final sellerArchivedListingsProvider =
    FutureProvider.family<List<Listing>, String>((ref, sellerId) async {
  final all =
      await ref.watch(listingRepositoryProvider).getListingsBySeller(sellerId);
  return all.where((l) => l.status == ListingStatus.archived).toList();
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

/// Scored matches for a request (BRAIN §7). Prefers the server-side RPC
/// (`match_listings_for_request`); falls back to client-side scoring if the RPC
/// is unavailable or errors.
final matchesForRequestProvider =
    FutureProvider.family<List<ScoredListing>, String>((ref, requestId) async {
  final request =
      await ref.watch(requestRepositoryProvider).getRequestById(requestId);
  if (request == null) return const [];
  final repo = ref.watch(listingRepositoryProvider);

  if (SupabaseConfig.isConfigured) {
    try {
      final rows = await Supabase.instance.client
          .rpc('match_listings_for_request', params: {'p_request_id': requestId});
      final scores = <String, int>{
        for (final r in (rows as List))
          r['listing_id'] as String: (r['score'] as num).toInt(),
      };
      if (scores.isEmpty) return const [];
      final listings = await repo.getListingsByIds(scores.keys.toList());
      final byId = {for (final l in listings) l.id: l};
      // Preserve the RPC's score-desc order.
      final ordered = scores.keys
          .where(byId.containsKey)
          .map((id) => ScoredListing(listing: byId[id]!, score: scores[id]!))
          .toList();
      return ordered;
    } catch (_) {
      // fall through to client-side scoring
    }
  }

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
  return ref.watch(messageRepositoryProvider).getConversationsForUser(me.id, limit: 50);
});

final conversationByIdProvider =
    FutureProvider.family<Conversation?, String>((ref, id) {
  return ref.watch(messageRepositoryProvider).getConversationById(id);
});

final messagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.watch(messageRepositoryProvider).getMessages(conversationId, limit: 100);
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

/// The delivery attached to a deal (for deal parties to view proof).
final deliveryForDealProvider =
    FutureProvider.family<Delivery?, String>((ref, dealId) {
  return ref.watch(deliveryRepositoryProvider).getDeliveryByDeal(dealId);
});

final driverServiceProvider =
    Provider<DriverService>((ref) => DriverService(ref));

/// Driver profiles awaiting approval that have submitted at least one doc.
final pendingDriversProvider = FutureProvider<List<Profile>>((ref) async {
  final all = await ref.watch(allProfilesProvider.future);
  return all
      .where((p) =>
          p.accountType == AccountType.driver &&
          !p.driverApproved &&
          p.hasDriverDocs)
      .toList();
});

/// A signed URL for a private storage object (driver docs / delivery proof).
final signedUrlProvider =
    FutureProvider.family<String, ({String bucket, String path})>((ref, args) {
  return ref
      .read(storageRepositoryProvider)
      .signedUrl(bucket: args.bucket, path: args.path);
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
  return ref.watch(profileRepositoryProvider).getAllProfiles(limit: 1000);
});

final allListingsProvider = FutureProvider<List<Listing>>((ref) {
  return ref.watch(listingRepositoryProvider).getAllListings(limit: 1000);
});

final allReportsProvider = FutureProvider<List<Report>>((ref) {
  return ref.watch(reportRepositoryProvider).getAllReports();
});

final allDealsProvider = FutureProvider<List<Deal>>((ref) {
  return ref.watch(dealRepositoryProvider).getAllDeals(limit: 1000);
});

/// Paged/infinite-scroll admin lists (the genuinely unbounded all-rows views).
final adminListingsPagingProvider = StateNotifierProvider.autoDispose<
    PagedNotifier<Listing>, PagedState<Listing>>((ref) {
  final repo = ref.watch(listingRepositoryProvider);
  return PagedNotifier<Listing>(
      (offset, limit) => repo.getAllListings(limit: limit, offset: offset),
      pageSize: 25);
});

final adminUsersPagingProvider = StateNotifierProvider.autoDispose<
    PagedNotifier<Profile>, PagedState<Profile>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return PagedNotifier<Profile>(
      (offset, limit) => repo.getAllProfiles(limit: limit, offset: offset),
      pageSize: 25);
});

/// Aggregate counts for the admin overview.
class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.usersByType,
    required this.activeListings,
    required this.dealsByStatus,
    required this.completedDealValue,
    required this.openReports,
    required this.signups7,
    required this.signups30,
    required this.listings7,
    required this.listings30,
    required this.deals7,
    required this.deals30,
  });
  final int totalUsers;
  final Map<AccountType, int> usersByType;
  final int activeListings;
  final Map<DealStatus, int> dealsByStatus;
  final double completedDealValue;
  final int openReports;
  final int signups7;
  final int signups30;
  final int listings7;
  final int listings30;
  final int deals7;
  final int deals30;
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final profiles = await ref.watch(allProfilesProvider.future);
  final listings = await ref.watch(allListingsProvider.future);
  final reports = await ref.watch(allReportsProvider.future);
  final deals = await ref.watch(allDealsProvider.future);

  final now = DateTime.now();
  final d7 = now.subtract(const Duration(days: 7));
  final d30 = now.subtract(const Duration(days: 30));
  int since(Iterable<DateTime?> dates, DateTime cutoff) =>
      dates.where((t) => t != null && t.isAfter(cutoff)).length;

  final byType = <AccountType, int>{};
  for (final p in profiles) {
    byType[p.accountType] = (byType[p.accountType] ?? 0) + 1;
  }

  final byStatus = <DealStatus, int>{};
  double completedValue = 0;
  for (final d in deals) {
    byStatus[d.dealStatus] = (byStatus[d.dealStatus] ?? 0) + 1;
    if (d.dealStatus == DealStatus.completed) {
      completedValue += d.totalPrice + d.deliveryFee;
    }
  }

  return AdminStats(
    totalUsers: profiles.length,
    usersByType: byType,
    activeListings:
        listings.where((l) => l.status == ListingStatus.active).length,
    dealsByStatus: byStatus,
    completedDealValue: completedValue,
    openReports: reports.where((r) => r.status == ReportStatus.open).length,
    signups7: since(profiles.map((p) => p.createdAt), d7),
    signups30: since(profiles.map((p) => p.createdAt), d30),
    listings7: since(listings.map((l) => l.createdAt), d7),
    listings30: since(listings.map((l) => l.createdAt), d30),
    deals7: since(deals.map((d) => d.createdAt), d7),
    deals30: since(deals.map((d) => d.createdAt), d30),
  );
});
