import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/cities_repository.dart';
import '../models/city.dart';
import '../models/city_schedule.dart';

final citiesRepositoryProvider = Provider<CitiesRepository>((ref) {
  return CitiesRepository(ref.watch(apiClientProvider));
});

final citiesProvider = FutureProvider<List<City>>((ref) {
  return ref.watch(citiesRepositoryProvider).fetchActiveCities();
});

final cityScheduleProvider = FutureProvider.family<CitySchedule, String>((ref, slug) {
  return ref.watch(citiesRepositoryProvider).fetchCitySchedule(slug);
});
