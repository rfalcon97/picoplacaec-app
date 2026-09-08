import 'route_option.dart';
import 'weather_info.dart';

class RoutePlan {
  const RoutePlan({required this.weather, required this.routes});

  final WeatherInfo weather;
  final List<RouteOption> routes;

  factory RoutePlan.fromJson(Map<String, dynamic> json) => RoutePlan(
        weather: WeatherInfo.fromJson(json['weather'] as Map<String, dynamic>),
        routes: (json['routes'] as List<dynamic>)
            .map((r) => RouteOption.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}
