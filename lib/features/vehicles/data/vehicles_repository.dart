import '../../../core/api_client.dart';
import '../models/vehicle.dart';

class VehiclesRepository {
  VehiclesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Vehicle>> fetchMyVehicles() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/vehicles');
    return response.data!.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Vehicle> createVehicle({
    required String nickname,
    required int plateDigit,
    required String cityId,
    required String reminderTime,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/vehicles',
      data: {'nickname': nickname, 'plateDigit': plateDigit, 'cityId': cityId, 'reminderTime': reminderTime},
    );
    return Vehicle.fromJson(response.data!);
  }

  Future<Vehicle> updateVehicle({
    required String id,
    required String nickname,
    required int plateDigit,
    required String cityId,
    required String reminderTime,
  }) async {
    final response = await _apiClient.dio.patch<Map<String, dynamic>>(
      '/vehicles/$id',
      data: {'nickname': nickname, 'plateDigit': plateDigit, 'cityId': cityId, 'reminderTime': reminderTime},
    );
    return Vehicle.fromJson(response.data!);
  }

  Future<void> deleteVehicle(String id) => _apiClient.dio.delete('/vehicles/$id');
}
