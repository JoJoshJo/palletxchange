import 'dart:math';

/// Great-circle distance in statute miles (Haversine).
double haversineMiles(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusMiles = 3958.8;
  double toRad(double d) => d * pi / 180.0;
  final dLat = toRad(lat2 - lat1);
  final dLon = toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return earthRadiusMiles * 2 * atan2(sqrt(a), sqrt(1 - a));
}
