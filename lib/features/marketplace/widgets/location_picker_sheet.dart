import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/location_provider.dart';

/// A few known metro-area cities as a reliable fallback when geocoding is
/// unavailable, and as quick picks.
const _quickCities = <(String, double, double)>[
  ('Atlanta, GA', 33.7490, -84.3880),
  ('Marietta, GA', 33.9526, -84.5499),
  ('Smyrna, GA', 33.8840, -84.5144),
  ('Duluth, GA', 34.0029, -84.1446),
  ('East Point, GA', 33.6795, -84.4394),
  ('Sandy Springs, GA', 33.9304, -84.3733),
];

Future<void> showLocationPicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet();

  @override
  ConsumerState<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  final _manual = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _useCurrentLocation,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.onDark,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Use my current location'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFC0392B))),
          ],
          const SizedBox(height: 16),
          const Text(
            'Or enter a city',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manual,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _useManual(),
            decoration: InputDecoration(
              hintText: 'City, State (e.g. Fayetteville, GA)',
              prefixIcon: const Icon(Icons.place_outlined),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _busy ? null : _useManual,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quick pick',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickCities.map((c) {
              return ActionChip(
                label: Text(c.$1),
                onPressed: () {
                  ref.read(locationProvider.notifier).setLocation(
                        label: c.$1,
                        lat: c.$2,
                        lng: c.$3,
                      );
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _fail('Location services are off. Turn them on or enter a city.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _fail('Location permission denied. Enter a city instead.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      var label = 'Current location';
      try {
        final marks = await Geocoding()
            .placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final m = marks.first;
          final city = m.locality ?? m.subAdministrativeArea ?? '';
          final st = m.administrativeArea ?? '';
          final joined = [city, st].where((s) => s.isNotEmpty).join(', ');
          if (joined.isNotEmpty) label = joined;
        }
      } catch (_) {/* reverse-geocode optional */}
      if (!mounted) return;
      ref.read(locationProvider.notifier).setLocation(
            label: label,
            lat: pos.latitude,
            lng: pos.longitude,
          );
      Navigator.pop(context);
    } catch (_) {
      _fail("Couldn't get your location. Enter a city instead.");
    }
  }

  Future<void> _useManual() async {
    final text = _manual.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await Geocoding().locationFromAddress(text);
      if (results.isEmpty) {
        _fail("Couldn't find that place. Try 'City, State' or a quick pick.");
        return;
      }
      if (!mounted) return;
      ref.read(locationProvider.notifier).setLocation(
            label: text,
            lat: results.first.latitude,
            lng: results.first.longitude,
          );
      Navigator.pop(context);
    } catch (_) {
      _fail("Couldn't find that place. Try 'City, State' or a quick pick.");
    }
  }

  void _fail(String msg) {
    if (mounted) {
      setState(() {
        _busy = false;
        _error = msg;
      });
    }
  }
}
