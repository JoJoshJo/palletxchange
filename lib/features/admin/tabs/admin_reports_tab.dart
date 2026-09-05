import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../models/enums.dart';
import '../admin_user_detail_screen.dart';

Future<void> _removeListing(WidgetRef ref, String listingId) async {
  final listing =
      await ref.read(listingRepositoryProvider).getListingById(listingId);
  if (listing != null) {
    await ref.read(adminServiceProvider).removeListing(listing);
  }
}

class AdminReportsTab extends ConsumerWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allReportsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("Couldn't load reports")),
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(
            child: Text(
              'No reports.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = reports[i];
            final open = r.status == ReportStatus.open;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.reason,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: open
                              ? const Color(0xFFFFF3D6)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          r.status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: open
                                ? const Color(0xFF9A6700)
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (r.subjectLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      r.subjectLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (r.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      r.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (r.reportedUser != null)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(
                                  userId: r.reportedUser!),
                            ),
                          ),
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: const Text('View user'),
                        ),
                      if (r.listingId != null)
                        OutlinedButton.icon(
                          onPressed: () => _removeListing(ref, r.listingId!),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC0392B),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Remove listing'),
                        ),
                      if (open)
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(adminServiceProvider).resolveReport(r),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 40),
                          ),
                          child: const Text('Resolve'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
