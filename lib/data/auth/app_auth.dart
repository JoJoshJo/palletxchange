import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// App-wide auth + profile-completion state, used by the router to gate access.
///
/// Kept as a plain [ChangeNotifier] (not Riverpod) so it can be a go_router
/// `refreshListenable` and be read synchronously inside `redirect`.
class AppAuth extends ChangeNotifier {
  AppAuth(this._client) {
    _session = _client.auth.currentSession;
    _sub = _client.auth.onAuthStateChange.listen((data) async {
      _session = data.session;
      await _refreshProfile();
      notifyListeners();
    });
    _bootstrap();
  }

  final SupabaseClient _client;
  StreamSubscription<AuthState>? _sub;

  Session? _session;
  bool _profileComplete = false;
  bool _loading = true;

  Session? get session => _session;
  bool get isLoggedIn => _session != null;
  bool get profileComplete => _profileComplete;
  bool get loading => _loading;
  String? get userId => _session?.user.id;
  String? get email => _session?.user.email;

  Future<void> _bootstrap() async {
    await _refreshProfile();
    _loading = false;
    notifyListeners();
  }

  /// Reads the profiles row and marks the profile complete once onboarding has
  /// set a name.
  Future<void> _refreshProfile() async {
    if (_session == null) {
      _profileComplete = false;
      return;
    }
    try {
      final row = await _client
          .from('profiles')
          .select('name, account_type')
          .eq('id', _session!.user.id)
          .maybeSingle();
      final name = row?['name'] as String?;
      _profileComplete = name != null && name.trim().isNotEmpty;
    } catch (_) {
      _profileComplete = false;
    }
  }

  /// Re-check profile completion (call after onboarding saves).
  Future<void> refresh() async {
    await _refreshProfile();
    notifyListeners();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Set once in main() after Supabase.initialize().
late AppAuth appAuth;
