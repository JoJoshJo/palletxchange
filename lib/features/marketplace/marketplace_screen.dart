import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../data/location_provider.dart';
import '../../data/providers.dart';
import '../../data/repositories/listing_repository.dart';
import '../../models/enums.dart';
import '../notifications/notifications_screen.dart';
import 'widgets/listing_card.dart';
import 'widgets/location_picker_sheet.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(marketplaceListingsProvider);
    final filter = ref.watch(listingFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const BrandWordmark(),
        actions: const [NotificationBell()],
      ),
      body: Column(
        children: [
          const _LocationHeader(),
          const _SearchBar(),
          _FilterBar(filter: filter),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(marketplaceListingsProvider),
              child: listingsAsync.when(
                loading: () => const _LoadingList(),
                error: (e, _) => _ErrorState(
                  onRetry: () => ref.invalidate(marketplaceListingsProvider),
                ),
                data: (listings) {
                  if (listings.isEmpty) {
                    return _EmptyState(hasFilters: !filter.isEmpty, ref: ref);
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: listings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final l = listings[i];
                      return ListingCard(
                        listing: l,
                        onTap: () => context.push('/listing/${l.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationHeader extends ConsumerWidget {
  const _LocationHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(locationProvider);
    return Container(
      width: double.infinity,
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Flexible(
            child: InkWell(
              onTap: () => showLocationPicker(context, ref),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place, size: 18, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      loc.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const Spacer(),
          _RadiusSelector(current: loc.radiusMiles),
        ],
      ),
    );
  }
}

class _RadiusSelector extends ConsumerWidget {
  const _RadiusSelector({required this.current});

  final int current;

  static const _options = [10, 25, 50, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<int>(
      initialValue: current,
      onSelected: (v) => ref.read(locationProvider.notifier).setRadius(v),
      itemBuilder: (_) => _options
          .map((m) => PopupMenuItem(value: m, child: Text('Within $m mi')))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Within $current mi',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Debounced text search wired into the shared listing filter (matches
/// title/city/state/type in the repository).
class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(listingFilterProvider).search ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final f = ref.read(listingFilterProvider);
      ref.read(listingFilterProvider.notifier).state =
          f.copyWith(search: value);
      setState(() {}); // refresh the clear-button visibility
    });
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    final f = ref.read(listingFilterProvider);
    ref.read(listingFilterProvider.notifier).state = f.copyWith(search: '');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search pallets, city, type…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clear,
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});

  final ListingFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(ListingFilter next) =>
        ref.read(listingFilterProvider.notifier).state = next;

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Extra trailing pad so the last chip clearly peeks, signalling scroll.
        padding: const EdgeInsets.only(left: 16, right: 28),
        child: Row(
          children: [
            _ChoiceChipFilter<PalletType>(
              label: 'Type',
              value: filter.type,
              options: PalletType.values,
              optionLabel: (t) => t.label,
              onSelected: (t) => update(t == null
                  ? filter.copyWith(clearType: true)
                  : filter.copyWith(type: t)),
            ),
            const SizedBox(width: 8),
            _ChoiceChipFilter<PalletSize>(
              label: 'Size',
              value: filter.size,
              options: PalletSize.values,
              optionLabel: (s) => s.label,
              onSelected: (s) => update(s == null
                  ? filter.copyWith(clearSize: true)
                  : filter.copyWith(size: s)),
            ),
            const SizedBox(width: 8),
            _ChoiceChipFilter<PalletCondition>(
              label: 'Condition',
              value: filter.condition,
              options: PalletCondition.values,
              optionLabel: (c) => c.label,
              onSelected: (c) => update(c == null
                  ? filter.copyWith(clearCondition: true)
                  : filter.copyWith(condition: c)),
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: 'Recyclable',
              selected: filter.recyclableOnly,
              onChanged: (v) => update(filter.copyWith(recyclableOnly: v)),
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: 'Free',
              selected: filter.freeOnly,
              onChanged: (v) => update(filter.copyWith(freeOnly: v)),
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: 'Delivery',
              selected: filter.deliveryOnly,
              onChanged: (v) => update(filter.copyWith(deliveryOnly: v)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A chip that opens a bottom sheet to pick one enum value (or clear it).
class _ChoiceChipFilter<T> extends StatelessWidget {
  const _ChoiceChipFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    return GestureDetector(
      onTap: () async {
        final picked = await showModalBottomSheet<_Picked<T>>(
          context: context,
          backgroundColor: AppColors.bg,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _OptionSheet<T>(
            title: label,
            options: options,
            optionLabel: optionLabel,
            selected: value,
          ),
        );
        if (picked != null) onSelected(picked.value);
      },
      child: _ChipShell(
        selected: selected,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected ? optionLabel(value as T) : label),
            const SizedBox(width: 4),
            Icon(
              selected ? Icons.close : Icons.keyboard_arrow_down,
              size: 16,
              color: selected ? AppColors.onDark : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: _ChipShell(selected: selected, child: Text(label)),
    );
  }
}

class _ChipShell extends StatelessWidget {
  const _ChipShell({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.orange : AppColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.orange : AppColors.border,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.onDark : AppColors.textPrimary,
        ),
        child: child,
      ),
    );
  }
}

class _Picked<T> {
  const _Picked(this.value);
  final T? value;
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.optionLabel,
    required this.selected,
  });

  final String title;
  final List<T> options;
  final String Function(T) optionLabel;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (selected != null)
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, _Picked<T>(null)),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: options.map((o) {
                final isSel = o == selected;
                return ListTile(
                  title: Text(optionLabel(o)),
                  trailing: isSel
                      ? const Icon(Icons.check, color: AppColors.orange)
                      : null,
                  onTap: () => Navigator.pop(context, _Picked<T>(o)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters, required this.ref});

  final bool hasFilters;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.search_off, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Center(
          child: Text(
            hasFilters ? 'No listings match your filters' : 'No listings yet',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            "Can't find it? Post a request and we'll match you.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/request'),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Post a Special Request'),
            ),
          ),
        ),
        if (hasFilters) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: () => ref.read(listingFilterProvider.notifier).state =
                  const ListingFilter(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 44),
              ),
              child: const Text('Clear filters'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Couldn't load listings",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
