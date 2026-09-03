import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/auth/app_auth.dart';

/// Email/password login + signup. Clean vertical mobile-first form; the auth
/// logic (Supabase signup/login/PKCE/emailRedirectTo) is unchanged.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isSignUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo + wordmark.
                    Column(
                      children: [
                        SvgPicture.asset(
                          'assets/branding/palletxchange_icon.svg',
                          width: 64,
                          height: 64,
                        ),
                        const SizedBox(height: 14),
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Pallet',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                              TextSpan(
                                text: 'Xchange',
                                style: TextStyle(color: AppColors.orange),
                              ),
                            ],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    Text(
                      _isSignUp ? 'Create your account' : 'Welcome',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? 'Buy, sell, and move pallets.'
                          : 'Log in to keep trading.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 32),

                    // Email.
                    const _FieldLabel('Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'you@company.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (!s.contains('@') || !s.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password.
                    const _FieldLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').length < 6 ? 'At least 6 characters' : null,
                    ),

                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => context.push('/reset-request'),
                          child: const Text('Forgot password?'),
                        ),
                      ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _Banner(text: _error!, error: true),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 16),
                      _Banner(text: _info!, error: false),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _busy ? null : _resend,
                          child: const Text('Resend confirmation email'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.onDark,
                              ),
                            )
                          : Text(_isSignUp ? 'Create account' : 'Log in'),
                    ),

                    const SizedBox(height: 24),
                    _ModeSwitch(
                      isSignUp: _isSignUp,
                      onTap: _busy
                          ? null
                          : () => setState(() {
                                _isSignUp = !_isSignUp;
                                _error = null;
                                _info = null;
                              }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    final email = _email.text.trim();
    final password = _password.text;

    try {
      if (_isSignUp) {
        final res = await appAuth.signUp(email: email, password: password);
        if (res.session == null && mounted) {
          setState(() {
            _info = 'Check your email to confirm your account, then log in.';
            _isSignUp = false;
          });
        }
      } else {
        await appAuth.signIn(email: email, password: password);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email to resend.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await appAuth.resendConfirmation(email);
      if (mounted) setState(() => _info = 'Confirmation email sent again.');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't resend — try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
}

/// Bottom prompt: muted question + orange, tappable action word.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.isSignUp, required this.onTap});

  final bool isSignUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final question =
        isSignUp ? 'Already have an account?' : "Don't have an account?";
    final action = isSignUp ? 'Log in' : 'Sign up';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$question  '),
            TextSpan(
              text: action,
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? const Color(0xFFC0392B) : AppColors.green;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline,
              size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: color, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
