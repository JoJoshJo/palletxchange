import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/thread_screen.dart';
import '../../features/create_listing/create_listing_screen.dart';
import '../../features/deals/deal_detail_screen.dart';
import '../../features/deals/deals_screen.dart';
import '../../features/listing_detail/listing_detail_screen.dart';
import '../../features/admin/admin_home.dart';
import '../../features/driver/driver_home.dart';
import '../../features/marketplace/marketplace_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/special_request/matches_screen.dart';
import '../../features/special_request/special_request_screen.dart';
import '../../features/storefront/storefront_screen.dart';
import '../../features/you/you_screen.dart';

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
              builder: (_, _) => const YouScreen(),
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
    // DEV role surfaces (until real auth in M3).
    GoRoute(
      path: '/driver',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const DriverHome(),
    ),
    GoRoute(
      path: '/admin',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const AdminHome(),
    ),
    // Storefront profile.
    GoRoute(
      path: '/profile/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          StorefrontScreen(profileId: state.pathParameters['id']!),
    ),
    // Special Request (optional ?sellerId=) → its matches result.
    GoRoute(
      path: '/request',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => SpecialRequestScreen(
        sellerId: state.uri.queryParameters['sellerId'],
      ),
      routes: [
        GoRoute(
          path: 'matches/:id',
          parentNavigatorKey: _rootKey,
          builder: (_, state) =>
              MatchesScreen(requestId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
