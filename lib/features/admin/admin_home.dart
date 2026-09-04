import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import 'tabs/admin_drivers_tab.dart';
import 'tabs/admin_listings_tab.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_reports_tab.dart';
import 'tabs/admin_users_tab.dart';

/// Admin oversight panel (BRAIN §8) — not a marketplace. A granted privilege,
/// surfaced here via the dev role switch.
class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const BrandWordmark(),
          actions: [
            IconButton(
              tooltip: 'Back to app',
              icon: const Icon(Icons.close),
              onPressed: () => context.go('/browse'),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.onDarkMuted,
            indicatorColor: AppColors.orange,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Drivers'),
              Tab(text: 'Users'),
              Tab(text: 'Listings'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminOverviewTab(),
            AdminDriversTab(),
            AdminUsersTab(),
            AdminListingsTab(),
            AdminReportsTab(),
          ],
        ),
      ),
    );
  }
}
