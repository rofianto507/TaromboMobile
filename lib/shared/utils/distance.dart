import 'dart:math';

/// Jarak antar dua titik koordinat dalam kilometer (rumus haversine).
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0; // radius bumi (km)
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _deg2rad(double deg) => deg * (pi / 180);

String formatDistanceKm(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}
