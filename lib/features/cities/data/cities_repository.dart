import '../../../core/api_client.dart';
import '../models/city.dart';
import '../models/city_schedule.dart';

class CitiesRepository {
  CitiesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<City>> fetchActiveCities() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/cities');
    return response.data!.map((e) => City.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CitySchedule> fetchCitySchedule(String slug) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/cities/$slug');
    return CitySchedule.fromJson(response.data!);
  }
}
