import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/auth/app_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configured = SupabaseConfig.isConfigured;
  if (configured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // Legacy anon JWT (still valid); the newer `publishableKey` param is for
      // the sb_publishable_* key format.
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
      // PKCE: the confirmation-email deep link carries a code that
      // supabase_flutter auto-exchanges for a session on open (warm or cold).
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    appAuth = AppAuth(Supabase.instance.client);
  }

  runApp(ProviderScope(child: PalletXchangeApp(gated: configured)));
}

class PalletXchangeApp extends StatefulWidget {
  const PalletXchangeApp({super.key, required this.gated});

  final bool gated;

  @override
  State<PalletXchangeApp> createState() => _PalletXchangeAppState();
}

class _PalletXchangeAppState extends State<PalletXchangeApp> {
  late final GoRouter _router =
      createRouter(auth: widget.gated ? appAuth : null);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PalletXchange',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
