import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapaRutaScreen extends StatefulWidget {
  const MapaRutaScreen({super.key});

  @override
  State<MapaRutaScreen> createState() => _MapaRutaScreenState();
}

class _MapaRutaScreenState extends State<MapaRutaScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Coordenadas fijas de destino
  final LatLng _destinoLatacunga = const LatLng(-0.9322, -78.6155);

  final List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _initMapAndLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initMapAndLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Los servicios de ubicación están deshabilitados.');
      } else {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _showErrorSnackBar('Los permisos de ubicación fueron denegados.');
          }
        }
      }

      // Obtener posición inicial
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("Timeout obteniendo ubicación actual.");
        return Position(
          longitude: -78.6167,
          latitude: -1.2491,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      });

      _dibujarRutaDirecta();
    } catch (e) {
      debugPrint("Error inicializando mapa: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
      _startLocationTracking();
    }
  }

  void _dibujarRutaDirecta() {
    if (_currentPosition == null) return;
    final LatLng origenActual = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          points: [origenActual, _destinoLatacunga],
          color: Colors.blueAccent,
          strokeWidth: 5,
        ),
      );
    });
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null) {
          setState(() {
            _currentPosition = position;
            _dibujarRutaDirecta();
          });

          // Mover la cámara a la nueva posición automáticamente
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            16.0,
          );

          // Subir a Firestore
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            FirebaseFirestore.instance.collection('conductores').doc(user.uid).update({
              'latitud': position.latitude,
              'longitud': position.longitude,
              'ultimaActualizacion': FieldValue.serverTimestamp(),
            }).catchError((e) {
              debugPrint("Error al subir ubicación a Firestore: $e");
            });
          }
        }
      },
    );
  }

  void _showErrorSnackBar(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _destinoLatacunga;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta en curso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Vista de Flutter Map (OpenStreetMap)
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.optiruta.final',
                    ),
                    PolylineLayer(
                      polylines: _polylines,
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 60,
                            height: 60,
                            child: const Tooltip(
                              message: 'Tú (Origen)',
                              child: Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          ),
                        Marker(
                          point: _destinoLatacunga,
                          width: 60,
                          height: 60,
                          child: const Tooltip(
                            message: 'Destino: Latacunga',
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Panel flotante de información
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Navegando hacia', style: TextStyle(color: Colors.grey)),
                              Text('Latacunga', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          FloatingActionButton(
                            backgroundColor: Colors.blue,
                            mini: true,
                            onPressed: () {
                              if (_currentPosition != null) {
                                _mapController.move(
                                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  17.0,
                                );
                              }
                            },
                            child: const Icon(Icons.my_location, color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
