import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class CardsView extends StatefulWidget {
  const CardsView({super.key});

  @override
  State<CardsView> createState() => _CardsViewState();
}

class _CardsViewState extends State<CardsView> {
  final MapController mapController = MapController();

  static const LatLng casablanca = LatLng(33.5731, -7.5898);
  
  // Points de départ et d'arrivée
  LatLng? startPosition;
  LatLng? destinationPosition;
  
  // Tracé d'itinéraire & métriques (distance/durée)
  List<LatLng> routePoints = [];
  double distanceKm = 0.0;
  double durationMin = 0.0;
  bool isLoadingRoute = false;

  // Suivi GPS en temps réel
  LatLng? currentGpsPosition;
  StreamSubscription<Position>? positionStream;
  bool isGpsTracking = false;

  double zoom = 12.0;

  @override
  void dispose() {
    positionStream?.cancel();
    mapController.dispose();
    super.dispose();
  }

  // --- 1. Gestion de la sélection tactile (Départ / Destination) ---
  void handleTap(LatLng point) {
    setState(() {
      if (startPosition == null) {
        startPosition = point;
      } else if (destinationPosition == null) {
        destinationPosition = point;
        fetchRoute(); // Calculer l'itinéraire quand les 2 points sont définis
      } else {
        // Réinitialisation de la sélection si les deux étaient déjà choisis
        startPosition = point;
        destinationPosition = null;
        routePoints.clear();
        distanceKm = 0.0;
        durationMin = 0.0;
      }
    });
  }

  // --- 2. Calcul d'itinéraire & Distance/Durée via API OSRM ---
  Future<void> fetchRoute() async {
    if (startPosition == null || destinationPosition == null) return;

    setState(() {
      isLoadingRoute = true;
    });

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${startPosition!.longitude},${startPosition!.latitude};'
      '${destinationPosition!.longitude},${destinationPosition!.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;

        if (routes.isNotEmpty) {
          final route = routes[0];
          final geometry = route['geometry']['coordinates'] as List;

          final points = geometry
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();

          setState(() {
            routePoints = points;
            distanceKm = (route['distance'] as num) / 1000.0;
            durationMin = (route['duration'] as num) / 60.0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du calcul d\'itinéraire : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingRoute = false;
        });
      }
    }
  }

  // --- 3. Suivi GPS en temps réel ---
  Future<void> toggleGpsTracking() async {
    if (isGpsTracking) {
      await positionStream?.cancel();
      setState(() {
        isGpsTracking = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    setState(() {
      isGpsTracking = true;
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        currentGpsPosition = newPos;
      });
      mapController.move(newPos, mapController.camera.zoom);
    });
  }

  void changeZoom(double value) {
    final newZoom = (zoom + value).clamp(3.0, 18.0);
    mapController.move(mapController.camera.center, newZoom);
  }

  void resetMap() {
    setState(() {
      startPosition = null;
      destinationPosition = null;
      routePoints.clear();
      distanceKm = 0.0;
      durationMin = 0.0;
    });
    mapController.move(casablanca, 12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: casablanca,
              initialZoom: 12,
              minZoom: 3,
              maxZoom: 18,
              onTap: (tapPosition, point) => handleTap(point),
              onPositionChanged: (camera, hasGesture) {
                zoom = camera.zoom;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.multitask_app_1',
              ),

              // Tracé de l'itinéraire
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blue,
                    ),
                  ],
                ),

              // Marqueurs de départ, destination et position GPS
              MarkerLayer(
                markers: [
                  if (startPosition != null)
                    Marker(
                      point: startPosition!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  if (destinationPosition != null)
                    Marker(
                      point: destinationPosition!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  if (currentGpsPosition != null)
                    Marker(
                      point: currentGpsPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blueAccent,
                        size: 35,
                      ),
                    ),
                ],
              ),

              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // Boutons d'action (Zoom, Reset & Activer/Désactiver GPS)
          Positioned(
            top: 20,
            right: 15,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomPlus',
                  onPressed: () => changeZoom(1),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'zoomMinus',
                  onPressed: () => changeZoom(-1),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'resetMap',
                  onPressed: resetMap,
                  child: const Icon(Icons.home),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'gpsTracking',
                  backgroundColor: isGpsTracking ? Colors.green : null,
                  onPressed: toggleGpsTracking,
                  child: Icon(
                    isGpsTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                  ),
                ),
              ],
            ),
          ),

          // Carte récapitulative des coordonnées, de la distance et de la durée
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoadingRoute)
                      const CircularProgressIndicator()
                    else if (startPosition == null)
                      const Text(
                        'Touchez la carte pour définir le point de départ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )
                    else if (destinationPosition == null)
                      const Text(
                        'Touchez la carte pour définir la destination',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      )
                    else ...[
                      const Text(
                        'Itinéraire calculé',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Distance : ${distanceKm.toStringAsFixed(2)} km'),
                          Text('Durée : ${durationMin.toStringAsFixed(0)} min'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}