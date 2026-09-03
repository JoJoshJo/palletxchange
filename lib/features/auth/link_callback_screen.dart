import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/auth/app_auth.dart';

/// Landing point for the `com.palletxchange.app://login-callback` deep link.
///
/// If the URL carries an error (e.g. otp_expired) → a clean "Link expired"
/// screen with resend. Otherwise supabase_flutter is exchanging the code for a
/// session in the background — we show a "confirming…" state and the router
/// redirect takes over once the session lands.
class LinkCallbackScreen extends StatelessWidget {
  const LinkCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final qp = GoRouterState.of(context).uri.queryParameters;
    final hasError = qp.containsKey('error') ||
        qp.containsKey('error_code') ||
        qp.containsKey('error_description');

    if (hasError) {
      return _LinkExpired(
        description: qp['error_description']?.replaceAll('+', ' '),
      );
    }
    return const _Confirming();
  }
}

class _Confirming extends StatelessWidget {
  const _Confirming();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/branding/palletxchange_icon.svg',
              width: 64,
              height: 64,
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirming your account…',
              style: TextStyle(color: AppColors.onDarkMuted),
            ),
            const SizedBox(height: 24),
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
    );
  }
}

class _LinkExpired extends StatefulWidget {
  const _LinkExpired({this.description});

  final String? description;

  @override
  State<_LinkExpired> createState() => _LinkExpiredState();
}

class _LinkExpiredState extends State<_LinkExpired> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/branding/palletxchange_icon.svg',
                    width: 56,
                    height: 56,
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.link_off,
                      size: 40, color: AppColors.orange),
                  const SizedBox(height: 12),
                  const Text(
                    'Link expired or already used',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description ??
                        'That confirmation link is no longer valid. Enter your '
                            'email and we\'ll send a fresh one.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.onDarkMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _message!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _sent
                                  ? AppColors.green
                                  : const Color(0xFFC0392B),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _busy ? null : _resend,
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: AppColors.onDark,
                                  ),
                                )
                              : const Text('Resend confirmation email'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/auth'),
                          child: const Text('Back to log in'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resend() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _sent = false;
        _message = 'Enter a valid email.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await appAuth.resendConfirmation(email);
      if (mounted) {
        setState(() {
          _sent = true;
          _message = 'Sent — check your inbox for a new link.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) setState(() => _message = "Couldn't resend — try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
