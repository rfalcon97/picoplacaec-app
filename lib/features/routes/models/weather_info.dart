class WeatherInfo {
  const WeatherInfo({
    required this.temperatureC,
    required this.precipitationMm,
    required this.windSpeedKmh,
    required this.description,
    required this.isBadWeather,
  });

  final double temperatureC;
  final double precipitationMm;
  final double windSpeedKmh;
  final String description;
  final bool isBadWeather;

  factory WeatherInfo.fromJson(Map<String, dynamic> json) => WeatherInfo(
        temperatureC: (json['temperatureC'] as num).toDouble(),
        precipitationMm: (json['precipitationMm'] as num).toDouble(),
        windSpeedKmh: (json['windSpeedKmh'] as num).toDouble(),
        description: json['description'] as String,
        isBadWeather: json['isBadWeather'] as bool,
      );
}
