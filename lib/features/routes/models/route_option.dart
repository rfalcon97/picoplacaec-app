import 'package:latlong2/latlong.dart';

class RouteOption {
  const RouteOption({
    required this.label,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
  });

  final String label;
  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> geometry;

  bool get isMain => label == 'Principal';

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    final points = json['geometry'] as List<dynamic>;
    return RouteOption(
      label: json['label'] as String,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      durationSeconds: (json['durationSeconds'] as num).toDouble(),
      geometry: points.map((p) {
        final pair = p as List<dynamic>;
        return LatLng((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
      }).toList(),
    );
  }
}
