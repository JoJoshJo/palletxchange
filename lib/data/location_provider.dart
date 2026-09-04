import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/supabase_config.dart';
import 'auth/app_auth.dart';

/// The active marketplace search location + radius.
class SearchLocation {
  const SearchLocation({
    required this.label,
    this.lat,
    this.lng,
    this.radiusMiles = 50,
  });

  final String label;
  final double? lat;
  final double? lng;
  final int radiusMiles;

  bool get hasCoords => lat != null && lng != null;

  SearchLocation copyWith({
    String? label,
    double? lat,
    double? lng,
    int? radiusMiles,
    bool clearCoords = false,
  }) =>
      SearchLocation(
        label: label ?? this.label,
        lat: clearCoords ? null : (lat ?? this.lat),
        lng: clearCoords ? null : (lng ?? this.lng),
        radiusMiles: radiusMiles ?? this.radiusMiles,
      );
}

const _kLabel = 'loc_label';
const _kLat = 'loc_lat';
const _kLng = 'loc_lng';
const _kRadius = 'loc_radius';

/// Holds the active location; defaults to the user's profile city/coords, is
/// changeable (GPS or manual), and persists the last choice across sessions.
class LocationController extends StateNotifier<SearchLocation> {
  LocationController(this.ref)
      : super(const SearchLocation(label: 'Set location')) {
    _init();
  }

  final Ref ref;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLabel);
    if (saved != null) {
      state = SearchLocation(
        label: saved,
        lat: prefs.getDouble(_kLat),
        lng: prefs.getDouble(_kLng),
        radiusMiles: prefs.getInt(_kRadius) ?? 50,
      );
      return;
    }
    // No saved choice — default from the signed-in profile (never Atlanta).
    final profile = SupabaseConfig.isConfigured ? appAuth.currentProfile : null;
    if (profile != null) {
      final label = [profile.city, profile.state]
          .where((p) => p != null && p.isNotEmpty)
          .join(', ');
      state = SearchLocation(
        label: label.isEmpty ? 'Set location' : label,
        lat: profile.latitude,
        lng: profile.longitude,
        radiusMiles: 50,
      );
    }
  }

  Future<void> _persist(SearchLocation loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLabel, loc.label);
    await prefs.setInt(_kRadius, loc.radiusMiles);
    if (loc.lat != null) {
      await prefs.setDouble(_kLat, loc.lat!);
    } else {
      await prefs.remove(_kLat);
    }
    if (loc.lng != null) {
      await prefs.setDouble(_kLng, loc.lng!);
    } else {
      await prefs.remove(_kLng);
    }
  }

  void setLocation({required String label, double? lat, double? lng}) {
    final next = state.copyWith(
      label: label,
      lat: lat,
      lng: lng,
      clearCoords: lat == null || lng == null,
    );
    state = next;
    _persist(next);
  }

  void setRadius(int miles) {
    final next = state.copyWith(radiusMiles: miles);
    state = next;
    _persist(next);
  }
}

final locationProvider =
    StateNotifierProvider<LocationController, SearchLocation>(
  (ref) => LocationController(ref),
);
