/// Supabase connection config, injected at build time via
/// `--dart-define-from-file=env.json` (env.json is gitignored).
///
/// Run/build with:
///   flutter run   --dart-define-from-file=env.json
///   flutter build apk --debug --dart-define-from-file=env.json
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True when both values were provided at build time.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
