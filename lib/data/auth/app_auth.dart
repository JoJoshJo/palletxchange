import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../models/profile.dart';

/// App-wide auth + profile-completion state, used by the router to gate access.
///
/// Kept as a plain [ChangeNotifier] (not Riverpod) so it can be a go_router
/// `refreshListenable` and be read synchronously inside `redirect`.
class AppAuth extends ChangeNotifier {
  AppAuth(this._client) {
    _session = _client.auth.currentSession;
    _sub = _client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _passwordRecovery = true;
      }
      final previousUserId = _session?.user.id;
      _session = data.session;
      // On any account change, drop the stale cache immediately so no screen
      // can render the previous user while the refetch is in flight.
      if (data.session?.user.id != previousUserId ||
          data.event == AuthChangeEvent.signedOut) {
        _profile = null;
        _profileComplete = false;
      }
      await _refreshProfile();
      notifyListeners();
    });
    _bootstrap();
  }

  final SupabaseClient _client;
  StreamSubscription<AuthState>? _sub;

  Session? _session;
  Profile? _profile;
  bool _profileComplete = false;
  bool _loading = true;
  bool _passwordRecovery = false;

  Session? get session => _session;
  bool get isLoggedIn => _session != null;
  bool get profileComplete => _profileComplete;
  bool get loading => _loading;

  /// The signed-in user's full profile row (cached; refreshed on auth change
  /// and after onboarding). Never returns a cache whose id doesn't match the
  /// current session user — that guards against serving a prior account.
  Profile? get currentProfile {
    final uid = _session?.user.id;
    if (_profile != null && _profile!.id == uid) return _profile;
    return null;
  }

  /// True while a recovery session is active (opened from a reset-password
  /// link) — the router routes to the "set new password" screen.
  bool get passwordRecovery => _passwordRecovery;

  String? get userId => _session?.user.id;
  String? get email => _session?.user.email;

  Future<void> _bootstrap() async {
    await _refreshProfile();
    _loading = false;
    notifyListeners();
  }

  /// Reads the profiles row, caches it, and marks the profile complete once
  /// onboarding has set a name.
  Future<void> _refreshProfile() async {
    if (_session == null) {
      _profile = null;
      _profileComplete = false;
      return;
    }
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', _session!.user.id)
          .maybeSingle();
      if (row == null) {
        _profile = null;
        _profileComplete = false;
        return;
      }
      _profile = Profile.fromJson(row);
      final name = _profile!.name;
      _profileComplete = name.trim().isNotEmpty;
    } catch (_) {
      _profile = null;
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
  }) async {
    // Never let a new signup ride a leftover device session. With email
    // confirmation ON, signUp returns no active session — so any previously
    // persisted session would otherwise leave the user "logged in" as the old
    // account. Clear it first.
    if (_client.auth.currentSession != null) {
      await _client.auth.signOut();
    }
    return _client.auth.signUp(
      email: email,
      password: password,
      // Confirmation email links back into the app via this deep link.
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  /// Re-send the confirmation email (e.g. the first one expired).
  Future<void> resendConfirmation(String email) {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    // Clear cache eagerly; the signedOut event also clears + notifies.
    _profile = null;
    _profileComplete = false;
    await _client.auth.signOut();
  }

  /// Send a password-reset email; the link returns to the app via the same
  /// login-callback deep link.
  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  /// Set a new password for the recovery session, then clear recovery mode.
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    _passwordRecovery = false;
    notifyListeners();
  }

  /// Abandon a recovery flow (e.g. user backs out).
  void clearPasswordRecovery() {
    if (_passwordRecovery) {
      _passwordRecovery = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Set once in main() after Supabase.initialize().
late AppAuth appAuth;
