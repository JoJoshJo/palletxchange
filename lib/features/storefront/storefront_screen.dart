import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../models/profile.dart';
import '../marketplace/widgets/listing_card.dart';

class StorefrontScreen extends ConsumerWidget {
  const StorefrontScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(profileId));
    final listingsAsync = ref.watch(sellerActiveListingsProvider(profileId));
    final isOwnStorefront = ref.watch(currentUserProvider).id == profileId;

    return Scaffold(
      appBar: AppBar(title: const Text('Storefront')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text("Couldn't load storefront")),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Seller not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(profile: profile)),
              listingsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text("Couldn't load listings")),
                  ),
                ),
                data: (listings) {
                  if (listings.isEmpty) {
                    return const SliverToBoxAdapter(child: _NoListings());
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: listings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => ListingCard(
                        listing: listings[i],
                        onTap: () =>
                            context.push('/listing/${listings[i].id}'),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      // No "Special Request to yourself" on your own storefront.
      bottomNavigationBar: (profileAsync.valueOrNull == null || isOwnStorefront)
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/request?sellerId=$profileId'),
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Special Request'),
              ),
            ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(sellerCompletedDealsProvider(profile.id));
    final location = [profile.city, profile.state]
        .where((p) => p != null && p.isNotEmpty)
        .join(', ');

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.navy,
                child: Text(
                  profile.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (profile.verifiedStatus) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              size: 18, color: AppColors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 15, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (profile.rating != null)
                _Stat(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.orange,
                  value: profile.rating!.toStringAsFixed(1),
                  label: 'Rating',
                ),
              _Stat(
                icon: Icons.verified_outlined,
                iconColor: AppColors.green,
                value: profile.verifiedStatus ? 'Verified' : 'Unverified',
                label: 'Business',
              ),
              _Stat(
                icon: Icons.handshake_outlined,
                iconColor: AppColors.teal,
                value: dealsAsync.valueOrNull?.toString() ?? '—',
                label: 'Deals',
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Active listings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NoListings extends StatelessWidget {
  const _NoListings();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'No active listings right now',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Send a Special Request — they may have what you need.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
