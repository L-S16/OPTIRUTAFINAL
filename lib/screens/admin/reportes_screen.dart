import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReportesScreen extends StatefulWidget {
  final int initialTab;
  const ReportesScreen({super.key, this.initialTab = 0});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  
  // Filtros para la pestaña de Reportes
  String _searchQuery = '';
  String _estadoFiltro = 'Todos';
  String _prioridadFiltro = 'Todos';

  // Coordenadas base para ciudades comunes de la ruta de despacho (Guayaquil -> Quito)
  LatLng _getLatLngFromDireccion(String direccion, String id) {
    final dirLower = direccion.toLowerCase();
    LatLng base;
    if (dirLower.contains('quito')) {
      base = const LatLng(-0.1807, -78.4678);
    } else if (dirLower.contains('latacunga')) {
      base = const LatLng(-0.9316, -78.6155);
    } else if (dirLower.contains('ambato')) {
      base = const LatLng(-1.2491, -78.6167);
    } else if (dirLower.contains('guayaquil')) {
      base = const LatLng(-2.1708, -79.9224);
    } else if (dirLower.contains('sangolqui') || dirLower.contains('sangolquí')) {
      base = const LatLng(-0.3323, -78.4419);
    } else if (dirLower.contains('aloag') || dirLower.contains('alóag')) {
      base = const LatLng(-0.4677, -78.5835);
    } else {
      // Centrado en Ambato como punto central de la ruta
      base = const LatLng(-1.2491, -78.6167);
    }

    // Aplicar dispersión (jitter) usando el hash del ID para evitar solapamientos exactos
    final double latOffset = ((id.hashCode & 0xFF) - 128) * 0.0003;
    final double lngOffset = (((id.hashCode >> 8) & 0xFF) - 128) * 0.0003;
    return LatLng(base.latitude + latOffset, base.longitude + lngOffset);
  }

  double _getMarkerHue(String estado) {
    switch (estado) {
      case 'Entregado':
        return BitmapDescriptor.hueGreen;
      case 'En Ruta':
        return BitmapDescriptor.hueAzure;
      case 'Asignado':
        return BitmapDescriptor.hueYellow;
      case 'Pendiente':
      case 'Reprogramado':
        return BitmapDescriptor.hueOrange;
      case 'Cancelada':
      case 'Cancelado':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueRed;
    }
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // HUA-08: Simular la exportación de reportes de entregas en formato PDF/Excel/CSV
  void _simularExportar(int totalPedidos) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool exportando = true;
            String formato = 'PDF';

            // Simular carga de exportación
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                setDialogState(() {
                  exportando = false;
                });
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Exportar Reporte de Entregas'),
              content: exportando
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text('Generando archivo $formato para $totalPedidos pedidos...'),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 60),
                        const SizedBox(height: 15),
                        const Text(
                          '¡Reporte Generado!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'El reporte ha sido exportado exitosamente en formato $formato.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
              actions: [
                if (!exportando)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monitoreo & Reportes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent[700],
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Monitoreo en Vivo'),
            Tab(icon: Icon(Icons.analytics), text: 'Reporte de Entregas'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rutas').snapshots(),
        builder: (context, rutasSnapshot) {
          // Mapear qué conductor tiene asignado qué pedido {pedidoId: conductorId}
          final Map<String, String> conductorPorPedido = {};
          if (rutasSnapshot.hasData) {
            for (var doc in rutasSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final conductorId = data['conductorId']?.toString() ?? 'Sin Conductor';
              final pedidos = List<String>.from(data['pedidos'] ?? []);
              for (var pedId in pedidos) {
                conductorPorPedido[pedId] = conductorId;
              }
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
            builder: (context, pedidosSnapshot) {
              if (pedidosSnapshot.hasError) {
                return const Center(child: Text('Error al obtener datos de Firestore.'));
              }
              if (pedidosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final pedidos = pedidosSnapshot.data?.docs ?? [];

              return TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Evitar deslizamientos accidentales en el mapa
                children: [
                  // PESTAÑA 1: MONITOREO EN VIVO (MAPA)
                  _buildMapaMonitoreo(pedidos),

                  // PESTAÑA 2: REPORTE DE ENTREGAS
                  _buildReporteEntregas(pedidos, conductorPorPedido),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMapaMonitoreo(List<QueryDocumentSnapshot> pedidos) {
    // Generar marcadores para los pedidos activos en ruta o entregados
    final Set<Marker> markers = {};
    
    for (var doc in pedidos) {
      final data = doc.data() as Map<String, dynamic>;
      final id = data['id'] ?? doc.id;
      final cliente = data['cliente'] ?? 'Cliente';
      final direccion = data['direccion'] ?? '';
      final estado = data['estado'] ?? 'Pendiente';
      final cajas = data['numeroCajas'] ?? 0;

      final latLng = _getLatLngFromDireccion(direccion, id);

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(estado)),
          infoWindow: InfoWindow(
            title: '$id - $cliente',
            snippet: 'Estado: $estado | Cajas: $cajas\nDir: $direccion',
          ),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(-1.2491, -78.6167), // Centrado en Ambato como punto intermedio del país
            zoom: 7.5,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
        ),
        // Leyenda del mapa flotante
        Positioned(
          top: 15,
          left: 15,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: Colors.white.withValues(alpha: 0.95),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estados de Pedidos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const Divider(height: 8),
                  _buildLegendItem('Pendiente / Reprogramado', Colors.orange),
                  _buildLegendItem('Asignado (Sin Cargar)', Colors.orange[800]!),
                  _buildLegendItem('En Ruta', Colors.blueAccent),
                  _buildLegendItem('Entregado', Colors.green),
                  _buildLegendItem('Cancelado', Colors.red),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildReporteEntregas(List<QueryDocumentSnapshot> pedidos, Map<String, String> conductorPorPedido) {
    // Filtrado de la lista de pedidos
    final filteredPedidos = pedidos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final id = (data['id'] ?? doc.id).toString().toLowerCase();
      final cliente = (data['cliente'] ?? '').toString().toLowerCase();
      final direccion = (data['direccion'] ?? '').toString().toLowerCase();
      final estado = data['estado'] ?? 'Pendiente';
      final prioridad = data['prioridad'] ?? 'Media';

      final matchesSearch = id.contains(_searchQuery) || cliente.contains(_searchQuery) || direccion.contains(_searchQuery);
      final matchesEstado = _estadoFiltro == 'Todos' || estado == _estadoFiltro;
      final matchesPrioridad = _prioridadFiltro == 'Todos' || prioridad == _prioridadFiltro;

      return matchesSearch && matchesEstado && matchesPrioridad;
    }).toList();

    // Cálculos de Resumen
    int total = pedidos.length;
    int entregados = pedidos.where((d) => (d.data() as Map)['estado'] == 'Entregado').length;
    int enRuta = pedidos.where((d) => (d.data() as Map)['estado'] == 'En Ruta').length;
    int asignados = pedidos.where((d) => (d.data() as Map)['estado'] == 'Asignado').length;
    int pendientes = pedidos.where((d) => (d.data() as Map)['estado'] == 'Pendiente').length;

    return Column(
      children: [
        // Cuadro Resumen KPI
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildKpiCard('Total', total.toString(), Colors.blueAccent),
              _buildKpiCard('Entregado', entregados.toString(), Colors.green),
              _buildKpiCard('En Ruta', enRuta.toString(), Colors.purple),
              _buildKpiCard('Asignado', asignados.toString(), Colors.amber[800]!),
              _buildKpiCard('Pendiente', pendientes.toString(), Colors.orange),
            ],
          ),
        ),

        // Barra de Búsqueda y Filtros
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: const InputDecoration(
                      labelText: 'Buscar por ID, cliente o dirección...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _estadoFiltro,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                            DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                            DropdownMenuItem(value: 'Asignado', child: Text('Asignado')),
                            DropdownMenuItem(value: 'En Ruta', child: Text('En Ruta')),
                            DropdownMenuItem(value: 'Entregado', child: Text('Entregado')),
                          ],
                          onChanged: (val) => setState(() => _estadoFiltro = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _prioridadFiltro,
                          decoration: const InputDecoration(
                            labelText: 'Prioridad',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                            DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                            DropdownMenuItem(value: 'Media', child: Text('Media')),
                            DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                          ],
                          onChanged: (val) => setState(() => _prioridadFiltro = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Listado de Resultados
        Expanded(
          child: filteredPedidos.isEmpty
              ? const Center(child: Text('No hay registros que coincidan con los filtros.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  itemCount: filteredPedidos.length,
                  itemBuilder: (context, index) {
                    final doc = filteredPedidos[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final id = data['id'] ?? doc.id;
                    final cliente = data['cliente'] ?? 'Cliente';
                    final direccion = data['direccion'] ?? 'Sin dirección';
                    final prioridad = data['prioridad'] ?? 'Media';
                    final estado = data['estado'] ?? 'Pendiente';
                    final cajas = data['numeroCajas'] ?? 0;
                    
                    // Conductor asignado cruzando la información de la colección de rutas
                    final conductorAsignado = conductorPorPedido[id] ?? 'No asignado';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(estado).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                estado,
                                style: TextStyle(color: _getEstadoColor(estado), fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cliente, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text('Destino: $direccion', style: const TextStyle(fontSize: 12)),
                              Text('Cajas: $cajas | Prioridad: $prioridad', style: const TextStyle(fontSize: 12)),
                              const Divider(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Conductor: $conductorAsignado',
                                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Botón Exportar Flotante / Inferior
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _simularExportar(filteredPedidos.length),
              icon: const Icon(Icons.download),
              label: const Text('Exportar Reporte', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.08),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
