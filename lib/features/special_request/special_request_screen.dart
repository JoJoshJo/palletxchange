import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../data/providers.dart';
import '../../models/enums.dart';
import '../../models/request.dart';
import 'widgets/request_form_section.dart';

class SpecialRequestScreen extends ConsumerStatefulWidget {
  const SpecialRequestScreen({super.key, this.sellerId});

  /// When set, the request is targeted to one seller; otherwise it broadcasts.
  final String? sellerId;

  @override
  ConsumerState<SpecialRequestScreen> createState() =>
      _SpecialRequestScreenState();
}

class _SpecialRequestScreenState extends ConsumerState<SpecialRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _maxPrice = TextEditingController();
  final _location = TextEditingController(text: 'Atlanta, GA');
  final _notes = TextEditingController();

  PalletType _type = PalletType.standardWooden;
  PalletSize _size = PalletSize.s48x40;
  PalletCondition? _condition; // null = any
  FulfillmentMethod _fulfillment = FulfillmentMethod.pickup;
  DateTime? _neededBy;

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_quantity, _maxPrice, _location, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _targeted => widget.sellerId != null;

  @override
  Widget build(BuildContext context) {
    final seller =
        _targeted ? ref.watch(profileByIdProvider(widget.sellerId!)) : null;
    final sellerName = seller?.valueOrNull?.displayName;

    return Scaffold(
      appBar: AppBar(title: const BrandWordmark()),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              _targeted
                  ? 'Request from ${sellerName ?? 'this seller'}'
                  : 'Request pallets',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _targeted
                  ? "Aimed at this one seller — they clearly deal in pallets, but haven't posted exactly this."
                  : "We'll match you with nearby sellers.",
              style: const TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),

            RequestFormSection(
              title: 'What you need',
              icon: Icons.inventory_2_outlined,
              children: [
                RequestFormField.dropdown<PalletType>(
                  label: 'Type',
                  value: _type,
                  options: PalletType.values,
                  optionLabel: (t) => t.label,
                  onChanged: (v) => setState(() => _type = v!),
                ),
                RequestFormField.dropdown<PalletSize>(
                  label: 'Size',
                  value: _size,
                  options: PalletSize.values,
                  optionLabel: (s) => s.label,
                  onChanged: (v) => setState(() => _size = v!),
                ),
                RequestFormField.dropdown<PalletCondition?>(
                  label: 'Preferred condition',
                  value: _condition,
                  options: [null, ...PalletCondition.values],
                  optionLabel: (c) => c?.label ?? 'Any condition',
                  onChanged: (v) => setState(() => _condition = v),
                ),
                RequestFormField.text(
                  label: 'Quantity needed',
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter a quantity';
                    return null;
                  },
                ),
                RequestFormField.text(
                  label: 'Max price per pallet (optional)',
                  controller: _maxPrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                ),
              ],
            ),

            RequestFormSection(
              title: 'Logistics',
              icon: Icons.local_shipping_outlined,
              children: [
                RequestFormField.dropdown<FulfillmentMethod>(
                  label: 'Pickup or delivery',
                  value: _fulfillment,
                  options: FulfillmentMethod.values,
                  optionLabel: (f) => f.label,
                  onChanged: (v) => setState(() => _fulfillment = v!),
                ),
                _NeededByField(
                  value: _neededBy,
                  onPick: (d) => setState(() => _neededBy = d),
                ),
                RequestFormField.text(
                  label: 'Location',
                  controller: _location,
                ),
                RequestFormField.text(
                  label: 'Notes',
                  controller: _notes,
                  maxLines: 3,
                  hint: 'Anything a seller should know',
                ),
              ],
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onDark,
                      ),
                    )
                  : Text(_targeted ? 'Send request' : 'Find matches'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Can't send a targeted request to a user you've blocked.
    if (widget.sellerId != null) {
      final blocked =
          ref.read(blockedIdsProvider).valueOrNull ?? const <String>{};
      if (blocked.contains(widget.sellerId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You've blocked this user. Unblock to contact them.")),
        );
        return;
      }
    }
    setState(() => _saving = true);

    final me = ref.read(currentUserProvider);
    final request = PalletRequest(
      id: 'pending',
      buyerId: me.id,
      targetSellerId: widget.sellerId,
      palletTypeNeeded: _type,
      palletSizeNeeded: _size,
      quantityNeeded: int.tryParse(_quantity.text) ?? 0,
      preferredCondition: _condition,
      maxPrice: _maxPrice.text.trim().isEmpty
          ? null
          : double.tryParse(_maxPrice.text),
      pickupOrDelivery: _fulfillment,
      neededByDate: _neededBy,
      location: _location.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    try {
      final stored = await ref.read(requestServiceProvider).create(request);
      if (!mounted) return;
      context.pushReplacement('/request/matches/${stored.id}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't send — try again")),
      );
    }
  }
}

class _NeededByField extends StatelessWidget {
  const _NeededByField({required this.value, required this.onPick});

  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Needed by (optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now.add(const Duration(days: 7)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) onPick(picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    value == null
                        ? 'Any time'
                        : DateFormat('EEE, MMM d, y').format(value!),
                    style: TextStyle(
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
