import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/auth/app_auth.dart';

/// Shown to a banned account — no access to the app.
class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

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
                const Icon(Icons.gpp_bad_outlined,
                    size: 56, color: AppColors.orange),
                const SizedBox(height: 20),
                const Text(
                  'Your account is suspended',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access to PalletXchange has been suspended by an '
                  'administrator. Contact support if you think this is a '
                  'mistake.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.onDarkMuted, height: 1.5),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 200,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await appAuth.signOut();
                      if (context.mounted) context.go('/auth');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onDark,
                      side: const BorderSide(color: AppColors.onDarkMuted),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
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
