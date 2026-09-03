import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth/app_auth.dart';
import '../../models/enums.dart';
import '../../features/admin/admin_home.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/link_callback_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/reset_request_screen.dart';
import '../../features/auth/set_password_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/common/error_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/thread_screen.dart';
import '../../features/create_listing/create_listing_screen.dart';
import '../../features/deals/deal_detail_screen.dart';
import '../../features/deals/deals_screen.dart';
import '../../features/driver/driver_home.dart';
import '../../features/listing_detail/listing_detail_screen.dart';
import '../../features/marketplace/marketplace_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/special_request/matches_screen.dart';
import '../../features/special_request/special_request_screen.dart';
import '../../features/storefront/storefront_screen.dart';
import '../../features/you/you_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Builds the app router. When [auth] is provided (Supabase configured), an
/// auth gate redirects: not logged in → /auth; logged in but no profile →
/// /onboarding; otherwise the app. When null, the app runs ungated (dev).
GoRouter createRouter({AppAuth? auth}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: auth == null ? '/browse' : '/splash',
    refreshListenable: auth,
    redirect: auth == null ? null : (context, state) => _guard(auth, state),
    errorBuilder: (context, state) =>
        ErrorScreen(message: state.error?.message),
    routes: _routes,
  );
}

String? _guard(AppAuth auth, GoRouterState state) {
  final loc = state.matchedLocation;

  // A recovery deep link opened a temporary session — force the set-password
  // screen until the user sets a new password (or cancels).
  if (auth.passwordRecovery) {
    return loc == '/set-password' ? null : '/set-password';
  }

  // The confirmation/recovery deep link lands here. If it carries an error we
  // keep the user on the callback screen (it shows "Link expired" + resend);
  // otherwise supabase_flutter is exchanging the code and the session/event
  // arrives shortly, at which point this guard routes onward.
  if (loc == '/login-callback') {
    final qp = state.uri.queryParameters;
    final hasError = qp.containsKey('error') ||
        qp.containsKey('error_code') ||
        qp.containsKey('error_description');
    if (hasError) return null;
    if (auth.isLoggedIn) {
      return auth.profileComplete ? '/browse' : '/onboarding';
    }
    return null; // exchange in progress — stay on the "confirming…" screen
  }

  if (auth.loading) return loc == '/splash' ? null : '/splash';

  final onAuth = loc == '/auth';
  final onReset = loc == '/reset-request';
  final onOnboarding = loc == '/onboarding';

  if (!auth.isLoggedIn) return (onAuth || onReset) ? null : '/auth';
  if (!auth.profileComplete) return onOnboarding ? null : '/onboarding';

  // Role-based home: drivers get the driver shell, traders the marketplace.
  final profile = auth.currentProfile;
  final isDriver = profile?.accountType == AccountType.driver;
  final isAdmin = profile?.isAdmin ?? false;
  final home = isDriver ? '/driver' : '/browse';

  // From auth/splash/onboarding/callback, land on the right home.
  if (onAuth ||
      onReset ||
      onOnboarding ||
      loc == '/splash' ||
      loc == '/login-callback') {
    return home;
  }

  // Admin panel is gated to admins.
  if (loc == '/admin' && !isAdmin) return home;

  // A driver cannot buy/sell — confine them to the driver shell (a driver who
  // is also an admin may still open /admin). Keep traders out of /driver.
  if (isDriver) {
    final allowed =
        loc == '/driver' || loc == '/set-password' || (loc == '/admin' && isAdmin);
    if (!allowed) return '/driver';
  } else if (loc == '/driver') {
    return '/browse';
  }
  return null;
}

final List<RouteBase> _routes = [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
    GoRoute(
      path: '/login-callback',
      builder: (_, _) => const LinkCallbackScreen(),
    ),
    GoRoute(
      path: '/reset-request',
      builder: (_, _) => const ResetRequestScreen(),
    ),
    GoRoute(
      path: '/set-password',
      builder: (_, _) => const SetPasswordScreen(),
    ),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
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
];
