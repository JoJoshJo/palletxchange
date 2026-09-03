import 'package:flutter/material.dart';

import '../../core/dev/dev_role_switch.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const BrandWordmark(),
          actions: [
            IconButton(
              tooltip: 'Switch role (dev)',
              icon: const Icon(Icons.switch_account_outlined),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: AppColors.bg,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: DevRoleSwitch(),
                ),
              ),
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
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminOverviewTab(),
            AdminUsersTab(),
            AdminListingsTab(),
            AdminReportsTab(),
          ],
        ),
      ),
    );
  }
}
