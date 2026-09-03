import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // Legacy anon JWT (still valid); the newer `publishableKey` param is for
      // the sb_publishable_* key format.
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(const ProviderScope(child: PalletXchangeApp()));
}

class PalletXchangeApp extends StatelessWidget {
  const PalletXchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PalletXchange',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
