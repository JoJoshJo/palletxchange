import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Branded fallback shown for any unmatched route or router error — replaces
/// go_router's raw red exception page. Never show the default page to a user.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/branding/palletxchange_icon.svg',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message ?? "We couldn't open that page.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onDarkMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: () => context.go('/browse'),
                    child: const Text('Go home'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text(
                    'Back to log in',
                    style: TextStyle(color: AppColors.onDarkMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
