import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapaRutaScreen extends StatefulWidget {
  const MapaRutaScreen({super.key});

  @override
  State<MapaRutaScreen> createState() => _MapaRutaScreenState();
}

class _MapaRutaScreenState extends State<MapaRutaScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStreamSubscription;

  // IMPORTANTE: Debes colocar tu API Key de Google Maps aquí para que se dibuje la ruta
  final String _googleMapsApiKey = "TU_API_KEY_AQUI";

  // Coordenadas fijas
  final LatLng _destinoLatacunga = const LatLng(-0.9322, -78.6155);

  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];

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

      // Obtener posición inicial PRIMERO con un timeout
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("Timeout obteniendo ubicación actual.");
        // Si falla, usamos unas coordenadas por defecto cerca de Ambato
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

      // Una vez tenemos la posición actual, obtenemos la ruta hacia Latacunga
      await _getPolyline();
    } catch (e) {
      debugPrint("Error inicializando mapa: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
      // Iniciar el seguimiento en vivo independientemente
      _startLocationTracking();
    }
  }

  Future<void> _getPolyline() async {
    if (_currentPosition == null) return;
    
    LatLng origenActual = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    PolylinePoints polylinePoints = PolylinePoints(apiKey: _googleMapsApiKey);

    try {
      // ignore: deprecated_member_use
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        // ignore: deprecated_member_use
        request: PolylineRequest(
          origin: PointLatLng(origenActual.latitude, origenActual.longitude),
          destination: PointLatLng(_destinoLatacunga.latitude, _destinoLatacunga.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta_conductor'),
              color: Colors.blue,
              points: _polylineCoordinates,
              width: 5,
            ),
          );
        });
        return; // Salir si tuvo éxito
      } else {
        debugPrint("Error obteniendo ruta: ${result.errorMessage}");
      }
    } catch (e) {
      debugPrint("Excepción al obtener polyline: $e");
    }

    // Si falla (por excepción o falta de API KEY), dibujamos una línea recta temporalmente
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_directa'),
          color: Colors.blue,
          points: [origenActual, _destinoLatacunga],
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Línea punteada
        ),
      );
    });
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null) {
          setState(() {
            _currentPosition = position;
          });

          // Mover la cámara a la nueva posición automáticamente
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 16.0,
                tilt: 45.0, // Perspectiva 3D tipo navegación
              ),
            ),
          );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta en curso'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null 
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
                        : _destinoLatacunga,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Centramos la cámara al inicio en la posición del conductor
                    if (_currentPosition != null) {
                      controller.animateCamera(CameraUpdate.newLatLngZoom(
                          LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 16.0));
                    }
                  },
                  markers: {
                    if (_currentPosition != null)
                      Marker(
                        markerId: const MarkerId('origen'),
                        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        infoWindow: const InfoWindow(title: 'Tú (Origen)'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      ),
                    Marker(
                      markerId: const MarkerId('destino'),
                      position: _destinoLatacunga,
                      infoWindow: const InfoWindow(title: 'Destino: Latacunga'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                  polylines: _polylines,
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
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 18.0),
                                );
                              }
                            },
                            child: const Icon(Icons.my_location),
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
