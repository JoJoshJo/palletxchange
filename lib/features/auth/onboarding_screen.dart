import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/auth/app_auth.dart';
import '../../models/enums.dart';

/// First-run profile setup — writes name, account type, and business details to
/// the user's profiles row. account_type here decides trader vs. driver.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _businessName = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController(text: 'Atlanta');
  final _state = TextEditingController(text: 'GA');

  AccountType _accountType = AccountType.individual;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _businessName, _phone, _city, _state]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _needsBusinessName => _accountType == AccountType.warehouse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _busy ? null : _signOut,
            child: const Text('Sign out',
                style: TextStyle(color: AppColors.onDarkMuted)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Tell us about you',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appAuth.email ?? '',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            const _Label('Account type'),
            const SizedBox(height: 8),
            _AccountTypePicker(
              value: _accountType,
              onChanged: (v) => setState(() => _accountType = v),
            ),
            const SizedBox(height: 20),

            const _Label('Your name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Full name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 16),

            // Business name applies to warehouses only (an individual is a
            // person, a driver is a service account).
            if (_needsBusinessName) ...[
              const _Label('Business name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _businessName,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(hintText: 'Company / warehouse'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your business name'
                    : null,
              ),
              const SizedBox(height: 16),
            ],

            const _Label('Phone (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '(404) 555-0100'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('City'),
                      const SizedBox(height: 6),
                      TextFormField(controller: _city),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('State'),
                      const SizedBox(height: 6),
                      TextFormField(controller: _state),
                    ],
                  ),
                ),
              ],
            ),

            if (_accountType == AccountType.driver) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.30)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drivers submit license + insurance for approval before '
                        'claiming jobs — that step comes next.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Color(0xFFC0392B))),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onDark,
                      ),
                    )
                  : const Text('Finish setup'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final uid = appAuth.userId;
    if (uid == null) {
      setState(() {
        _busy = false;
        _error = 'Session expired — sign in again.';
      });
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').update({
        'name': _name.text.trim(),
        'account_type': _accountType.value,
        // Only warehouses carry a business name.
        'business_name': (_needsBusinessName && _businessName.text.trim().isNotEmpty)
            ? _businessName.text.trim()
            : null,
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
      }).eq('id', uid);

      await appAuth.refresh();
      if (mounted) context.go('/browse');
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't save — try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await appAuth.signOut();
    if (mounted) context.go('/auth');
  }
}

class _AccountTypePicker extends StatelessWidget {
  const _AccountTypePicker({required this.value, required this.onChanged});

  final AccountType value;
  final ValueChanged<AccountType> onChanged;

  static const _meta = {
    AccountType.individual: (
      Icons.person_outline,
      'Buy and sell pallets as an individual.'
    ),
    AccountType.warehouse: (
      Icons.warehouse_outlined,
      'Business seller — bulk tools + verified badge eligible.'
    ),
    AccountType.driver: (
      Icons.local_shipping_outlined,
      'Deliver pallets — job board only.'
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: AccountType.values.map((t) {
        final selected = t == value;
        final (icon, blurb) = _meta[t]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(t),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? AppColors.orange.withValues(alpha: 0.06) : AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.orange : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      color: selected ? AppColors.orange : AppColors.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          blurb,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AppColors.orange),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
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
