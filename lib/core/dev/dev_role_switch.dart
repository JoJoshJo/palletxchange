import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import 'demo_role.dart';

/// DEV-ONLY control to view the app as Trader / Driver / Admin without real
/// auth. Goes away when Milestone 3 auth lands.
class DevRoleSwitch extends ConsumerWidget {
  const DevRoleSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(demoRoleProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.science_outlined, size: 16, color: AppColors.teal),
              SizedBox(width: 6),
              Text(
                'DEV · view app as',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<DemoRole>(
            segments: DemoRole.values
                .map((r) =>
                    ButtonSegment(value: r, label: Text(r.label)))
                .toList(),
            selected: {role},
            showSelectedIcon: false,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? AppColors.orange
                      : AppColors.bg),
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? AppColors.onDark
                      : AppColors.textPrimary),
            ),
            onSelectionChanged: (s) {
              final next = s.first;
              ref.read(demoRoleProvider.notifier).state = next;
              context.go(next.home);
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Switches which home + permissions the demo shows. Real accounts '
            'replace this in Milestone 3.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
