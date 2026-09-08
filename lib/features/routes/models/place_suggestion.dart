class PlaceSuggestion {
  const PlaceSuggestion({required this.label, required this.lat, required this.lon});

  final String label;
  final double lat;
  final double lon;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) => PlaceSuggestion(
        label: json['label'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );
}
