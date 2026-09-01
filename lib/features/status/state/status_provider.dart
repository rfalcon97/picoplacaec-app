import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/state/auth_controller.dart';
import '../data/status_repository.dart';
import '../models/vehicle_status.dart';

final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepository(ref.watch(apiClientProvider));
});

final myVehiclesStatusProvider = FutureProvider<List<VehicleStatus>>((ref) {
  // Watching auth state (not just reading it) means this refetches whenever
  // the session changes — login, logout, or switching to a different user —
  // instead of serving another user's cached vehicle list.
  ref.watch(authControllerProvider);
  return ref.watch(statusRepositoryProvider).fetchMyVehiclesStatus();
});
