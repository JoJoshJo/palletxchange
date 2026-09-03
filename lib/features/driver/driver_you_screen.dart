import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../data/auth/app_auth.dart';
import '../../data/providers.dart';

class DriverYouScreen extends ConsumerWidget {
  const DriverYouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = ref.watch(currentDriverProvider);
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
                  driver.name.characters.first.toUpperCase(),
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
                        Text(
                          driver.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (driver.rating != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.orange),
                          Text(
                            driver.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Text(
                      'Driver',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (driver.driverApproved)
            Row(
              children: const [
                Icon(Icons.verified, size: 18, color: AppColors.green),
                SizedBox(width: 8),
                Text('Approved driver',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            )
          else
            Row(
              children: const [
                Icon(Icons.hourglass_top, size: 18, color: AppColors.teal),
                SizedBox(width: 8),
                Text('Approval pending',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await appAuth.signOut();
              if (context.mounted) context.go('/auth');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
