import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/auth/app_auth.dart';

/// Shown right after signup when email confirmation is required.
class ConfirmEmailScreen extends StatefulWidget {
  const ConfirmEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  bool _busy = false;
  String? _message;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/branding/palletxchange_icon.svg',
                    width: 56,
                    height: 56,
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.mark_email_unread_outlined,
                      size: 44, color: AppColors.orange),
                  const SizedBox(height: 12),
                  const Text(
                    'Confirm your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                            text: 'We sent a confirmation link to '),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            color: AppColors.onDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                            text: ' — open it to activate your account.'),
                      ],
                      style: const TextStyle(
                        color: AppColors.onDarkMuted,
                        height: 1.5,
                      ),
                    ),
                    textAlign: TextAlign.center,
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
                        if (_message != null) ...[
                          Text(
                            _message!,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  _sent ? AppColors.green : const Color(0xFFC0392B),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
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
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await appAuth.resendConfirmation(widget.email);
      if (mounted) {
        setState(() {
          _sent = true;
          _message = 'Sent again — check your inbox.';
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
