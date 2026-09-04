import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/supabase_config.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../data/auth/app_auth.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';
import '../deals/deals_screen.dart';

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const BrandWordmark()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.navy,
                child: Text(
                  me.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
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
                            me.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (me.verifiedStatus) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              size: 18, color: AppColors.green),
                        ],
                      ],
                    ),
                    Text(
                      me.accountType.label,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _TraderDashboard(),
          const SizedBox(height: 24),
          if (me.isAdmin)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_outlined, color: AppColors.teal),
              title: const Text(
                'Admin panel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal,
                ),
              ),
              trailing: const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.textMuted),
              onTap: () => context.push('/admin'),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.storefront_outlined, color: AppColors.textMuted),
            title: const Text(
              'My storefront',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textMuted),
            onTap: () => context.push('/profile/${me.id}'),
          ),
          _MenuItem(icon: Icons.settings_outlined, label: 'Settings'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.block, color: AppColors.textMuted),
            title: const Text(
              'Blocked users',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textMuted),
            onTap: () => context.push('/blocked'),
          ),
          _MenuItem(icon: Icons.help_outline, label: 'Help & support'),
          _MenuItem(
            icon: Icons.delete_outline,
            label: 'Delete account',
            danger: true,
          ),
          if (SupabaseConfig.isConfigured) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await appAuth.signOut();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFC0392B) : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: danger ? color : AppColors.textMuted),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing:
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label — coming soon')),
      ),
    );
  }
}

/// The trader's own business summary (sell + buy sides), from real data.
class _TraderDashboard extends ConsumerWidget {
  const _TraderDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final dealsAsync = ref.watch(myDealsProvider);
    final listingsAsync = ref.watch(sellerActiveListingsProvider(me.id));

    final deals = dealsAsync.valueOrNull ?? const [];
    final activeListings = listingsAsync.valueOrNull?.length ?? 0;

    final sell = deals.where((d) => d.sellerId == me.id);
    final buy = deals.where((d) => d.buyerId == me.id);
    final incoming =
        sell.where((d) => d.dealStatus == DealStatus.pending).length;
    final completedSales =
        sell.where((d) => d.dealStatus == DealStatus.completed).toList();
    final revenue = completedSales.fold<double>(
        0, (s, d) => s + d.totalPrice + d.deliveryFee);
    final activeBuys = buy
        .where((d) =>
            d.dealStatus == DealStatus.pending ||
            d.dealStatus == DealStatus.accepted)
        .length;
    final completedBuys =
        buy.where((d) => d.dealStatus == DealStatus.completed).toList();
    final spent =
        completedBuys.fold<double>(0, (s, d) => s + d.totalPrice + d.deliveryFee);

    void openDeals(int tab) {
      ref.read(dealsTabProvider.notifier).state = tab;
      context.go('/deals');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DashHeader('Selling'),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatTile(
              value: '$activeListings',
              label: 'Active listings',
              icon: Icons.inventory_2_outlined,
              color: AppColors.orange,
              onTap: () => context.push('/profile/${me.id}'),
            ),
            const SizedBox(width: 10),
            _StatTile(
              value: '$incoming',
              label: 'Incoming deals',
              icon: Icons.call_received,
              color: const Color(0xFF9A6700),
              onTap: () => openDeals(1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatTile(
              value: '${completedSales.length}',
              label: 'Completed sales',
              icon: Icons.check_circle_outline,
              color: AppColors.green,
              onTap: () => openDeals(1),
            ),
            const SizedBox(width: 10),
            _StatTile(
              value: moneyWhole(revenue),
              label: 'Revenue',
              icon: Icons.payments_outlined,
              color: AppColors.teal,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _DashHeader('Buying'),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatTile(
              value: '$activeBuys',
              label: 'Active deals',
              icon: Icons.handshake_outlined,
              color: AppColors.orange,
              onTap: () => openDeals(0),
            ),
            const SizedBox(width: 10),
            _StatTile(
              value: '${completedBuys.length}',
              label: 'Purchases',
              icon: Icons.shopping_bag_outlined,
              color: AppColors.green,
              onTap: () => openDeals(0),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatTile(
              value: moneyWhole(spent),
              label: 'Total spent',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.teal,
            ),
            const SizedBox(width: 10),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}

class _DashHeader extends StatelessWidget {
  const _DashHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
