import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../models/enums.dart';

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("Couldn't load stats")),
      data: (s) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allProfilesProvider);
          ref.invalidate(allListingsProvider);
          ref.invalidate(allDealsProvider);
          ref.invalidate(allReportsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Headline cards.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _Card(
                  icon: Icons.people_outline,
                  color: AppColors.teal,
                  value: '${s.totalUsers}',
                  label: 'Users',
                ),
                _Card(
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.orange,
                  value: '${s.activeListings}',
                  label: 'Active listings',
                ),
                _Card(
                  icon: Icons.handshake_outlined,
                  color: AppColors.green,
                  value:
                      '${s.dealsByStatus.values.fold<int>(0, (a, b) => a + b)}',
                  label: 'Total deals',
                ),
                _Card(
                  icon: Icons.flag_outlined,
                  color: const Color(0xFFC0392B),
                  value: '${s.openReports}',
                  label: 'Open reports',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Completed deal value.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moneyWhole(s.completedDealValue),
                    style: const TextStyle(
                      color: AppColors.onDark,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Completed deal value (potential — payments not processed '
                    'in-app yet)',
                    style: TextStyle(color: AppColors.onDarkMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _Section('Users by type'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in AccountType.values)
                  _Pill(label: t.label, count: s.usersByType[t] ?? 0),
              ],
            ),
            const SizedBox(height: 20),

            _Section('Deals by status'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final st in DealStatus.values)
                  _Pill(
                    label: st.value[0].toUpperCase() + st.value.substring(1),
                    count: s.dealsByStatus[st] ?? 0,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            _Section('Activity'),
            const SizedBox(height: 10),
            _ActivityRow(label: 'New signups', v7: s.signups7, v30: s.signups30),
            _ActivityRow(label: 'New listings', v7: s.listings7, v30: s.listings30),
            _ActivityRow(label: 'New deals', v7: s.deals7, v30: s.deals30),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.label, required this.v7, required this.v30});
  final String label;
  final int v7;
  final int v30;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          _mini('7d', v7),
          const SizedBox(width: 16),
          _mini('30d', v30),
        ],
      ),
    );
  }

  Widget _mini(String period, int value) => Column(
        children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(period,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      );
}
