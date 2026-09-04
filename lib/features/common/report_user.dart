import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../models/report.dart';

/// Shows a reason picker and files a real report against [reportedUserId].
Future<void> showReportUserSheet(
  BuildContext context,
  WidgetRef ref, {
  required String reportedUserId,
  String? subjectLabel,
}) async {
  const reasons = [
    'Scam or fraud',
    'Abusive behavior',
    'Spam',
    "Didn't honor the deal",
    'Other',
  ];
  final reason = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Report user',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          for (final r in reasons)
            ListTile(
              title: Text(r),
              onTap: () => Navigator.pop(context, r),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (reason == null) return;

  final me = ref.read(currentUserProvider);
  try {
    await ref.read(reportRepositoryProvider).createReport(
          Report(
            id: 'pending',
            reportedBy: me.id,
            reportedUser: reportedUserId,
            reason: reason,
            subjectLabel: subjectLabel,
          ),
        );
    ref.invalidate(allReportsProvider);
    ref.invalidate(adminStatsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted — thank you')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't submit report — try again")),
      );
    }
  }
}
