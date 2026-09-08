import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/api_error.dart';
import '../../ads/interstitial_ad_service.dart';
import '../../cities/state/cities_provider.dart';
import '../models/place_suggestion.dart';
import '../models/route_option.dart';
import '../models/route_plan.dart';
import '../models/weather_info.dart';
import '../state/routes_provider.dart';

const _searchDebounce = Duration(milliseconds: 400);
const _mainRouteColor = Colors.blue;
const _alternativeRouteColor = Colors.orange;
const _zoomStep = 1.0;

class RoutePlannerScreen extends ConsumerStatefulWidget {
  const RoutePlannerScreen({super.key, this.initialCityId});

  /// Pre-selects the city used to decide "good/bad weather" — a convenience
  /// default (e.g. the user's first vehicle's city) that they can still
  /// change with the dropdown, since this screen isn't tied to one vehicle.
  final String? initialCityId;

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen> {
  final _destinationController = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  PlaceSuggestion? _selectedDestination;
  String? _selectedCityId;
  bool _searching = false;
  bool _loadingPlan = false;
  RoutePlan? _plan;
  String? _error;

  Position? _myPosition;
  bool _loadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _selectedCityId = widget.initialCityId;
    _loadMyLocation();
    // Start preloading the interstitial as soon as the screen opens, so it
    // has time to finish loading before the user taps "Buscar ruta" — an ad
    // requested for the first time right on that tap usually isn't ready yet.
    ref.read(interstitialAdServiceProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  /// Fetches the device's current position so the screen can show "you are
  /// here" on open, before the user has even picked a destination.
  Future<void> _loadMyLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final position = await _getPosition();
      if (mounted) setState(() => _myPosition = position);
    } catch (error) {
      if (mounted) setState(() => _locationError = extractErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    setState(() => _selectedDestination = null);
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(_searchDebounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final results = await ref.read(routesRepositoryProvider).searchPlaces(query);
      if (mounted) setState(() => _suggestions = results);
    } catch (_) {
      // A failed search just leaves the suggestion list empty — the user can retype.
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectDestination(PlaceSuggestion place) {
    setState(() {
      _selectedDestination = place;
      _suggestions = [];
      _destinationController.text = place.label;
    });
  }

  Future<Position> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Activa la ubicación (GPS) del dispositivo para calcular la ruta');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Se necesita permiso de ubicación para calcular la ruta');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _planRoute() async {
    final destination = _selectedDestination;
    final cityId = _selectedCityId;
    if (destination == null || cityId == null) return;

    setState(() {
      _loadingPlan = true;
      _error = null;
    });
    try {
      // Shown before every route search, not just the first — see the
      // eager preload() call in initState for why this reliably has an ad ready.
      await ref.read(interstitialAdServiceProvider).showIfReady();
      final position = await _getPosition();
      final plan = await ref.read(routesRepositoryProvider).planRoute(
            originLat: position.latitude,
            originLng: position.longitude,
            destLat: destination.lat,
            destLng: destination.lon,
            cityId: cityId,
          );
      if (mounted) setState(() => _plan = plan);
    } catch (error) {
      if (mounted) setState(() => _error = extractErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Planificar ruta')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                citiesAsync.when(
                  data: (cities) => DropdownButtonFormField<String>(
                    initialValue: _selectedCityId,
                    decoration: const InputDecoration(labelText: 'Ciudad (para evaluar el clima)'),
                    items: cities.map((city) => DropdownMenuItem(value: city.id, child: Text(city.name))).toList(),
                    onChanged: (value) => setState(() => _selectedCityId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(extractErrorMessage(error)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: 'Destino',
                    hintText: 'Busca una dirección o lugar',
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                  ),
                  onChanged: _onQueryChanged,
                ),
                if (_suggestions.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(top: 4),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final place = _suggestions[index];
                          return ListTile(
                            dense: true,
                            title: Text(place.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () => _selectDestination(place),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: (_selectedDestination == null || _selectedCityId == null || _loadingPlan)
                      ? null
                      : _planRoute,
                  icon: _loadingPlan
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.alt_route),
                  label: Text(_loadingPlan ? 'Calculando...' : 'Buscar ruta'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final plan = _plan;
    if (plan != null) {
      if (plan.routes.isEmpty) {
        return const Center(child: Text('No se encontró una ruta hacia ese destino.'));
      }
      return Column(
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _WeatherBanner(weather: plan.weather)),
          const SizedBox(height: 12),
          Expanded(child: _RouteMap(routes: plan.routes)),
          _RouteList(routes: plan.routes),
        ],
      );
    }

    // No route planned yet — show where the user is right now.
    if (_loadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_locationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_locationError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadMyLocation, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    final position = _myPosition;
    if (position == null) return const SizedBox.shrink();
    return _MyLocationMap(position: position);
  }
}

/// Floating +/- buttons over a map, since flutter_map (unlike Google Maps)
/// doesn't render its own zoom controls — pinch-to-zoom still works too.
class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({required this.mapController});

  final MapController mapController;

  void _zoomBy(double delta) {
    final camera = mapController.camera;
    mapController.move(camera.center, camera.zoom + delta);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Column(
        children: [
          _ZoomButton(icon: Icons.add, onPressed: () => _zoomBy(_zoomStep)),
          const SizedBox(height: 8),
          _ZoomButton(icon: Icons.remove, onPressed: () => _zoomBy(-_zoomStep)),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(icon: Icon(icon), onPressed: onPressed),
    );
  }
}

/// Shown as soon as the screen opens, before any route has been planned —
/// just the OSM street tiles centered on the user with a small "you are
/// here" dot, so there's always something on screen while they pick a
/// destination.
class _MyLocationMap extends StatefulWidget {
  const _MyLocationMap({required this.position});

  final Position position;

  @override
  State<_MyLocationMap> createState() => _MyLocationMapState();
}

class _MyLocationMapState extends State<_MyLocationMap> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final here = LatLng(widget.position.latitude, widget.position.longitude);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: here, initialZoom: 16),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ec.picoplaca.app_movil',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: here,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _mainRouteColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        _MapZoomControls(mapController: _mapController),
      ],
    );
  }
}

class _WeatherBanner extends StatelessWidget {
  const _WeatherBanner({required this.weather});

  final WeatherInfo weather;

  @override
  Widget build(BuildContext context) {
    final bad = weather.isBadWeather;
    final color = bad ? Colors.red : Colors.green;
    final text = bad
        ? 'Clima adverso en la ciudad: ${weather.description} · se muestran rutas alternativas'
        : 'Buen clima en la ciudad: ${weather.description} · se mantiene la ruta principal';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(bad ? Icons.cloudy_snowing : Icons.wb_sunny, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _RouteMap extends StatefulWidget {
  const _RouteMap({required this.routes});

  final List<RouteOption> routes;

  @override
  State<_RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<_RouteMap> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routes = widget.routes;
    final mainRoute = routes.firstWhere((r) => r.isMain, orElse: () => routes.first);
    final bounds = LatLngBounds.fromPoints(mainRoute.geometry);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCameraFit: CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32))),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ec.picoplaca.app_movil',
            ),
            PolylineLayer(
              polylines: [
                for (final route in routes)
                  Polyline(
                    points: route.geometry,
                    color: route.isMain ? _mainRouteColor : _alternativeRouteColor,
                    strokeWidth: route.isMain ? 5 : 4,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: mainRoute.geometry.first,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                Marker(
                  point: mainRoute.geometry.last,
                  child: const Icon(Icons.location_on, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
        _MapZoomControls(mapController: _mapController),
      ],
    );
  }
}

class _RouteList extends StatelessWidget {
  const _RouteList({required this.routes});

  final List<RouteOption> routes;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 160),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          final km = (route.distanceMeters / 1000).toStringAsFixed(1);
          final minutes = (route.durationSeconds / 60).round();
          return ListTile(
            dense: true,
            leading: Icon(Icons.circle, size: 12, color: route.isMain ? _mainRouteColor : _alternativeRouteColor),
            title: Text(route.label),
            trailing: Text('$km km · $minutes min'),
          );
        },
      ),
    );
  }
}
