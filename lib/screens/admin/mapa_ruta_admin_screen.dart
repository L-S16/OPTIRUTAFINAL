import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/pedido.dart';
import '../../utils/geocoding_helper.dart';

class MapaRutaAdminScreen extends StatefulWidget {
  final String rutaId;
  final List<String> pedidosIds;

  const MapaRutaAdminScreen({
    super.key,
    required this.rutaId,
    required this.pedidosIds,
  });

  @override
  State<MapaRutaAdminScreen> createState() => _MapaRutaAdminScreenState();
}

class _MapaRutaAdminScreenState extends State<MapaRutaAdminScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  List<Pedido> _pedidos = [];
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  final Map<String, LatLng> _pedidoCoords = {};
  
  StreamSubscription<DocumentSnapshot>? _conductorSubscription;
  LatLng? _driverLocation;

  // Origen por defecto: Bodega Principal (Ambato)
  final LatLng _origenBodega = const LatLng(-1.2491, -78.6167);

  @override
  void initState() {
    super.initState();
    _cargarDetallesPedidos();
  }

  @override
  void dispose() {
    _conductorSubscription?.cancel();
    super.dispose();
  }

  Color _getMarkerColor(String estado) {
    switch (estado) {
      case 'Entregado':
        return Colors.green;
      case 'En Ruta':
        return Colors.blue;
      case 'Asignado':
        return Colors.orange;
      case 'Pendiente':
      case 'Reprogramado':
        return Colors.amber;
      default:
        return Colors.red;
    }
  }

  Future<void> _cargarDetallesPedidos() async {
    try {
      final List<Pedido> loadedPedidos = [];
      for (var id in widget.pedidosIds) {
        final doc = await FirebaseFirestore.instance
            .collection('pedidos')
            .doc(id)
            .get();

        if (doc.exists && doc.data() != null) {
          loadedPedidos.add(Pedido.fromMap(doc.data()!));
        }
      }

      setState(() {
        _pedidos = loadedPedidos;
        _prepararMapa();
        _isLoading = false;
      });

      // Obtener el ID del conductor de la ruta y suscribirse a su posición
      final routeDoc = await FirebaseFirestore.instance
          .collection('rutas')
          .doc(widget.rutaId)
          .get();

      if (routeDoc.exists && routeDoc.data() != null) {
        final conductorId = routeDoc.data()?['conductorId'];
        if (conductorId != null && conductorId != 'No asignado') {
          _conductorSubscription = FirebaseFirestore.instance
              .collection('conductores')
              .doc(conductorId)
              .snapshots()
              .listen((snap) {
            if (snap.exists && snap.data() != null) {
              final data = snap.data() as Map<String, dynamic>;
              final lat = data['latitud'] as double?;
              final lng = data['longitud'] as double?;
              if (lat != null && lng != null) {
                if (mounted) {
                  setState(() {
                    _driverLocation = LatLng(lat, lng);
                    _prepararMapa();
                  });
                }
              }
            }
          });
        }
      }

      // Intentar geocodificar las paradas en segundo plano
      _geocodificarParadasBackground();
    } catch (e) {
      debugPrint("Error al cargar detalles de pedidos para mapa admin ($e).");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _geocodificarParadasBackground() async {
    bool actualizoAlguna = false;
    for (var pedido in _pedidos) {
      final result = await GeocodingHelper.buscarCoordenadasNominatim(pedido.direccion);
      if (result != null) {
        _pedidoCoords[pedido.id] = result;
        actualizoAlguna = true;
      }
    }
    if (actualizoAlguna && mounted) {
      setState(() {
        _prepararMapa();
      });
      // Ajustar la cámara para que quepan todos los marcadores reposicionados
      _ajustarCamara();
    }
  }

  void _prepararMapa() {
    _markers.clear();
    _polylines.clear();

    // 1. Agregar el marcador de la Bodega (Origen)
    _markers.add(
      Marker(
        point: _origenBodega,
        width: 50,
        height: 50,
        child: const Icon(
          Icons.warehouse,
          color: Colors.blueAccent,
          size: 32,
        ),
      ),
    );

    final List<LatLng> rutaCoordenadas = [_origenBodega];

    // 2. Agregar los marcadores de cada pedido y colectar coordenadas
    for (var pedido in _pedidos) {
      final coordinates = _pedidoCoords[pedido.id] ?? GeocodingHelper.getLatLngFromDireccion(pedido.direccion, pedido.id);
      rutaCoordenadas.add(coordinates);

      _markers.add(
        Marker(
          point: coordinates,
          width: 50,
          height: 50,
          child: Tooltip(
            message: '${pedido.cliente}\n${pedido.direccion}',
            child: Icon(
              Icons.location_on,
              color: _getMarkerColor(pedido.estado),
              size: 32,
            ),
          ),
        ),
      );
    }

    // 3. Dibujar la polilínea de la ruta
    if (rutaCoordenadas.length > 1) {
      _polylines.add(
        Polyline(
          points: rutaCoordenadas,
          color: Colors.blueAccent.shade700,
          strokeWidth: 5,
        ),
      );
    }

    // 4. Agregar marcador del Conductor (Seguimiento en Vivo)
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          point: _driverLocation!,
          width: 55,
          height: 55,
          child: const Tooltip(
            message: 'Ubicación en Vivo del Conductor',
            child: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }
  }

  void _ajustarCamara() {
    if (_markers.isEmpty) return;
    
    final points = _markers.map((m) => m.point).toList();
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(50.0),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Entregado':
        return Colors.green;
      case 'En Ruta':
        return Colors.blueAccent;
      case 'Asignado':
        return Colors.orange[800]!;
      case 'Pendiente':
      case 'Reprogramado':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = _pedidos.isNotEmpty
        ? (_pedidoCoords[_pedidos.first.id] ?? GeocodingHelper.getLatLngFromDireccion(_pedidos.first.direccion, _pedidos.first.id))
        : _origenBodega;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mapa Ruta ${widget.rutaId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Centrar Cámara',
            onPressed: _ajustarCamara,
          ),
        ],
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
                    initialZoom: 11,
                    onMapReady: () {
                      // Pequeña espera para ajustar cámara automáticamente
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _ajustarCamara();
                      });
                    },
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
                      markers: _markers,
                    ),
                  ],
                ),

                // Lista de paradas / pedidos en la parte inferior
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0, top: 12.0, bottom: 8.0, right: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Paradas en Ruta (${_pedidos.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Ruta Activa',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _pedidos.isEmpty
                              ? const Center(child: Text('No hay pedidos en esta ruta.'))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  itemCount: _pedidos.length,
                                  itemBuilder: (context, index) {
                                    final pedido = _pedidos[index];
                                    final coordinates = _pedidoCoords[pedido.id] ?? GeocodingHelper.getLatLngFromDireccion(pedido.direccion, pedido.id);

                                    return GestureDetector(
                                      onTap: () {
                                        _mapController.move(coordinates, 15.0);
                                      },
                                      child: Card(
                                        elevation: 3,
                                        margin: const EdgeInsets.only(right: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Container(
                                          width: 220,
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Parada #${index + 1}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blueAccent[700],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getEstadoColor(pedido.estado).withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      pedido.estado,
                                                      style: TextStyle(
                                                        color: _getEstadoColor(pedido.estado),
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                pedido.cliente,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      pedido.direccion,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (pedido.telefono != null && pedido.telefono!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.phone, size: 12, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      pedido.telefono!,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const Spacer(),
                                              Text(
                                                'Nº Cajas: ${pedido.numeroCajas}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
