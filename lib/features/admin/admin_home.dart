import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../data/auth/app_auth.dart';
import 'tabs/admin_drivers_tab.dart';
import 'tabs/admin_listings_tab.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_reports_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_verification_tab.dart';

/// Admin oversight cockpit (BRAIN §8) — owner-only, no marketplace. This is an
/// admin account's dedicated home; they only administer.
class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const BrandWordmark(),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await appAuth.signOut();
                if (context.mounted) context.go('/auth');
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.onDarkMuted,
            indicatorColor: AppColors.orange,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Users'),
              Tab(text: 'Listings'),
              Tab(text: 'Reports'),
              Tab(text: 'Drivers'),
              Tab(text: 'Verification'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminOverviewTab(),
            AdminUsersTab(),
            AdminListingsTab(),
            AdminReportsTab(),
            AdminDriversTab(),
            AdminVerificationTab(),
          ],
        ),
      ),
    );
  }
}
