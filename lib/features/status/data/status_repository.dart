import '../../../core/api_client.dart';
import '../models/vehicle_status.dart';

class StatusRepository {
  StatusRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<VehicleStatus>> fetchMyVehiclesStatus() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/status/vehicles');
    return response.data!.map((e) => VehicleStatus.fromJson(e as Map<String, dynamic>)).toList();
  }
}
