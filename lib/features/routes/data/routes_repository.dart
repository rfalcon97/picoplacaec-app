import '../../../core/api_client.dart';
import '../models/place_suggestion.dart';
import '../models/route_plan.dart';

class RoutesRepository {
  RoutesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/routes/search',
      queryParameters: {'query': query},
    );
    return response.data!.map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RoutePlan> planRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String cityId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/routes/plan',
      data: {
        'originLat': originLat,
        'originLng': originLng,
        'destLat': destLat,
        'destLng': destLng,
        'cityId': cityId,
      },
    );
    return RoutePlan.fromJson(response.data!);
  }
}
