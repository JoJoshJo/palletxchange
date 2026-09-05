import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../models/enums.dart';

class AdminListingsTab extends ConsumerStatefulWidget {
  const AdminListingsTab({super.key});

  @override
  ConsumerState<AdminListingsTab> createState() => _AdminListingsTabState();
}

class _AdminListingsTabState extends ConsumerState<AdminListingsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allListingsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Search title, seller, city',
              prefixIcon: Icon(Icons.search, size: 20),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text("Couldn't load listings")),
            data: (all) {
              final listings = _query.isEmpty
                  ? all
                  : all.where((l) {
                      final hay = [
                        l.title,
                        l.seller?.displayName ?? '',
                        l.city ?? '',
                      ].join(' ').toLowerCase();
                      return hay.contains(_query);
                    }).toList();
              if (listings.isEmpty) {
                return const Center(
                  child: Text('No listings match.',
                      style: TextStyle(color: AppColors.textMuted)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: listings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final l = listings[i];
          final archived = l.status == ListingStatus.archived;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l.seller?.displayName ?? l.sellerId} · ${l.status.value} · ${pricePerPalletLabel(l)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (archived)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Removed',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () =>
                        ref.read(adminServiceProvider).removeListing(l),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFC0392B),
                    ),
                    child: const Text('Remove'),
                  ),
              ],
            ),
          );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
