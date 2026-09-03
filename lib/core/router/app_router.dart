import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/thread_screen.dart';
import '../../features/create_listing/create_listing_screen.dart';
import '../../features/deals/deal_detail_screen.dart';
import '../../features/deals/deals_screen.dart';
import '../../features/listing_detail/listing_detail_screen.dart';
import '../../features/marketplace/marketplace_screen.dart';
import '../../features/placeholders/placeholder_screen.dart';
import '../../features/shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// App routes. Deep-link paths (`/listing/:id`, etc.) match BRAIN §9 so the
/// same routes carry over when auth + backend land.
final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/browse',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/browse',
              builder: (_, _) => const MarketplaceScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/sell',
              builder: (_, _) => const CreateListingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/deals',
              builder: (_, _) => const DealsScreen(),
              routes: [
                GoRoute(
                  path: 'deal/:id',
                  parentNavigatorKey: _rootKey,
                  builder: (_, state) =>
                      DealDetailScreen(dealId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (_, _) => const ChatListScreen(),
              routes: [
                GoRoute(
                  path: 'thread/:id',
                  parentNavigatorKey: _rootKey,
                  builder: (_, state) => ThreadScreen(
                    conversationId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/you',
              builder: (_, _) => const PlaceholderScreen(
                title: 'You',
                icon: Icons.person_outline,
                message:
                    'Your profile, storefront, listings, and settings — '
                    'coming soon.',
              ),
            ),
          ],
        ),
      ],
    ),
    // Top-level deep link alias for `/listing/:id`.
    GoRoute(
      path: '/listing/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          ListingDetailScreen(listingId: state.pathParameters['id']!),
    ),
  ],
);
