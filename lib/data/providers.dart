import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import '../models/deal.dart';
import '../models/enums.dart';
import '../models/listing.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/request.dart';
import 'fake/fake_deal_repository.dart';
import 'fake/fake_listing_repository.dart';
import 'fake/fake_message_repository.dart';
import 'fake/fake_profile_repository.dart';
import 'fake/fake_request_repository.dart';
import 'fake/fake_review_repository.dart';
import 'fake/fake_seed.dart';
import 'repositories/deal_repository.dart';
import 'repositories/listing_repository.dart';
import 'repositories/message_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/request_repository.dart';
import 'repositories/review_repository.dart';
import 'services/deal_service.dart';
import 'services/matching_service.dart';
import 'services/message_service.dart';
import 'services/request_service.dart';

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

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return FakeReviewRepository();
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return FakeMessageRepository();
});

/// The signed-in user's profile (fixed demo trader until auth lands).
final currentProfileProvider = FutureProvider<Profile>((ref) {
  return ref.watch(profileRepositoryProvider).getCurrentProfile();
});

/// Synchronous access to the demo user's id/profile — the whole app assumes a
/// signed-in trader (real auth arrives in Milestone 3).
final currentUserProvider = Provider<Profile>((ref) => FakeSeed.currentUser);

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
