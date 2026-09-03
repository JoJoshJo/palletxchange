/// Supabase connection config, injected at build time via
/// `--dart-define-from-file=env.json` (env.json is gitignored).
///
/// Run/build with:
///   flutter run   --dart-define-from-file=env.json
///   flutter build apk --debug --dart-define-from-file=env.json
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Deep link the confirmation email redirects back into. Registered as a
  /// custom URL scheme on Android (intent-filter) and iOS (CFBundleURLTypes),
  /// and must be listed under Supabase → Auth → URL Configuration → Redirect
  /// URLs.
  static const String authRedirectUrl = 'com.palletxchange.app://login-callback';

  /// True when both values were provided at build time.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
