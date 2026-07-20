import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/geocoding_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportesScreen extends StatefulWidget {
  final int initialTab;
  const ReportesScreen({super.key, this.initialTab = 0});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  
  // Filtros para la pestaña de Reportes
  String _searchQuery = '';
  String _estadoFiltro = 'Todos';
  String _prioridadFiltro = 'Todos';



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
    super.dispose();
  }

  // HUA-08: Exportación real de reportes de entregas a PDF utilizando pdf y printing
  Future<void> _exportarPDFReal(List<QueryDocumentSnapshot> pedidos, Map<String, String> conductorPorPedido) async {
    final pdf = pw.Document();

    // Cálculos de Resumen
    int total = pedidos.length;
    int entregados = pedidos.where((d) => (d.data() as Map)['estado'] == 'Entregado').length;
    int enRuta = pedidos.where((d) => (d.data() as Map)['estado'] == 'En Ruta').length;
    int pendientes = pedidos.where((d) => (d.data() as Map)['estado'] == 'Pendiente' || (d.data() as Map)['estado'] == 'Asignado').length;

    final dateParts = DateTime.now().toIso8601String().split('T');
    final String fechaActual = '${dateParts[0]} ${dateParts[1].substring(0, 5)}';

    final blueColor = PdfColor.fromHex('#1565c0');
    final greenColor = PdfColor.fromHex('#2e7d32');
    final purpleColor = PdfColor.fromHex('#6a1b9a');
    final orangeColor = PdfColor.fromHex('#ef6c00');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(
          marginBottom: 1.5 * PdfPageFormat.cm,
          marginTop: 1.5 * PdfPageFormat.cm,
          marginLeft: 1.5 * PdfPageFormat.cm,
          marginRight: 1.5 * PdfPageFormat.cm,
        ),
        build: (pw.Context context) {
          return [
            // Cabecera Principal
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'OPTIRUTA',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: blueColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Sistema Inteligente de Gestión de Rutas',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'REPORTE DE ENTREGAS',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Fecha: $fechaActual',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: blueColor, height: 25),
            
            // KPIs / Resumen
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfKpiCard('Total Pedidos', total.toString(), blueColor),
                _buildPdfKpiCard('Entregados', entregados.toString(), greenColor),
                _buildPdfKpiCard('En Ruta', enRuta.toString(), purpleColor),
                _buildPdfKpiCard('Pendientes', pendientes.toString(), orangeColor),
              ],
            ),
            pw.SizedBox(height: 25),

            // Título de la tabla
            pw.Text(
              'Detalle General de Despachos',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 10),

            // Tabla de Pedidos
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                bottom: pw.BorderSide(width: 1, color: PdfColors.grey400),
                top: pw.BorderSide(width: 1, color: PdfColors.grey400),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.5), // ID
                1: pw.FlexColumnWidth(3.5), // Cliente
                2: pw.FlexColumnWidth(4.5), // Dirección
                3: pw.FlexColumnWidth(2.0), // Prioridad
                4: pw.FlexColumnWidth(1.5), // Cajas
                5: pw.FlexColumnWidth(3.0), // Conductor
                6: pw.FlexColumnWidth(2.0), // Estado
              },
              children: [
                // Fila de Encabezado
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blueAccent700,
                  ),
                  children: [
                    _buildTableHeaderCell('ID Pedido'),
                    _buildTableHeaderCell('Cliente'),
                    _buildTableHeaderCell('Dirección'),
                    _buildTableHeaderCell('Prioridad', align: pw.TextAlign.center),
                    _buildTableHeaderCell('Cajas', align: pw.TextAlign.center),
                    _buildTableHeaderCell('Conductor'),
                    _buildTableHeaderCell('Estado', align: pw.TextAlign.center),
                  ],
                ),
                // Filas de Datos
                ...pedidos.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = data['id'] ?? doc.id;
                  final cliente = data['cliente'] ?? 'Cliente';
                  final direccion = data['direccion'] ?? 'Sin dirección';
                  final prioridad = data['prioridad'] ?? 'Media';
                  final estado = data['estado'] ?? 'Pendiente';
                  final cajas = (data['numeroCajas'] ?? 0).toString();
                  final conductor = conductorPorPedido[id] ?? 'No asignado';

                  return pw.TableRow(
                    children: [
                      _buildTableCell(id),
                      _buildTableCell(cliente),
                      _buildTableCell(direccion),
                      _buildTableCell(prioridad, align: pw.TextAlign.center),
                      _buildTableCell(cajas, align: pw.TextAlign.center),
                      _buildTableCell(conductor),
                      _buildTableCell(estado, align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Pie de página
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'OPTIRUTA © ${DateTime.now().year} - Reporte Generado del Sistema de Monitoreo',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Reporte_Entregas_${fechaActual.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      debugPrint("Error al exportar PDF real: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar el reporte PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método auxiliar para construir tarjetas de KPIs en el PDF
  static pw.Widget _buildPdfKpiCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(
          fontSize: 8,
          color: PdfColors.grey800,
        ),
      ),
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
    final List<Marker> markers = [];
    
    for (var doc in pedidos) {
      final data = doc.data() as Map<String, dynamic>;
      final id = data['id'] ?? doc.id;
      final cliente = data['cliente'] ?? 'Cliente';
      final direccion = data['direccion'] ?? '';
      final estado = data['estado'] ?? 'Pendiente';

      final latLng = GeocodingHelper.getLatLngFromDireccion(direccion, id);

      markers.add(
        Marker(
          point: latLng,
          width: 50,
          height: 50,
          child: Tooltip(
            message: '$id - $cliente\nEstado: $estado\n$direccion',
            child: Icon(
              Icons.location_on,
              color: _getEstadoColor(estado),
              size: 32,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(-1.2491, -78.6167), // Centrado en Ambato como punto intermedio del país
            initialZoom: 7.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.optiruta.final',
            ),
            MarkerLayer(
              markers: markers,
            ),
          ],
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                              tooltip: 'PDF Detallado',
                              onPressed: () => _exportarPDFDetallado(context, id),
                            ),
                            if (estado != 'Entregado' && estado != 'Cancelado' && estado != 'Cancelada')
                              IconButton(
                                icon: const Icon(Icons.alt_route, color: Colors.blueAccent),
                                tooltip: 'Reasignar Ruta',
                                onPressed: () => _reasignarRutaPedido(context, id),
                              ),
                          ],
                        ),
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
                                  const Spacer(),
                                  const Text('Ver Detalles', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () => _mostrarDetalleEntrega(context, id, estado, conductorAsignado),
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
              onPressed: () => _exportarPDFReal(filteredPedidos, conductorPorPedido),
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


  void _mostrarDetalleEntrega(BuildContext context, String pedidoId, String estado, String conductor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalle del Pedido: $pedidoId'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('entregas')
                  .where('pedidoId', isEqualTo: pedidoId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(heightFactor: 2, child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                // Intento buscar por numeroRuta si no se encontró por pedidoId
                if (docs.isEmpty) {
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('entregas')
                        .where('numeroRuta', isEqualTo: pedidoId)
                        .get(),
                    builder: (ctx, snap2) {
                      if (snap2.connectionState == ConnectionState.waiting) {
                        return const Center(heightFactor: 2, child: CircularProgressIndicator());
                      }
                      
                      final fallbackDocs = snap2.data?.docs ?? [];
                      if (fallbackDocs.isEmpty) {
                        return const Text('No hay detalles de entrega registrados aún para este pedido.');
                      }
                      return _buildEntregaDetalle(fallbackDocs.first, estado, conductor);
                    }
                  );
                }

                return _buildEntregaDetalle(docs.first, estado, conductor);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      }
    );
  }

  Widget _buildEntregaDetalle(QueryDocumentSnapshot doc, String estado, String conductor) {
    final data = doc.data() as Map<String, dynamic>;
    final observaciones = data['observaciones'] ?? 'Ninguna';
    final fotoBase64 = data['fotoBase64'];
    final firmaBase64 = data['firmaBase64'];
    final cajasDevueltas = data['cajasDevueltas'] ?? 0;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, size: 16),
              const SizedBox(width: 4),
              Text('Conductor: $conductor', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getEstadoColor(estado).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Estado Actual: $estado', style: TextStyle(color: _getEstadoColor(estado), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          const Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(observaciones),
          const SizedBox(height: 12),
          
          if (cajasDevueltas > 0 || estado == 'No entregado') ...[
            Text('Cajas Devueltas: $cajasDevueltas', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 12),
          ],

          if (fotoBase64 != null && fotoBase64.isNotEmpty) ...[
            const Text('Evidencia Fotográfica:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: Image.memory(
                base64Decode(fotoBase64),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          if (firmaBase64 != null && firmaBase64.isNotEmpty) ...[
            const Text('Firma del Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: Image.memory(
                base64Decode(firmaBase64),
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _reasignarRutaPedido(BuildContext context, String pedidoId) async {
    try {
      final routesSnapshot = await FirebaseFirestore.instance
          .collection('rutas')
          .get();

      final List<Map<String, dynamic>> activeRoutes = [];
      String? rutaActualId;

      for (var doc in routesSnapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final listPedidos = List<String>.from(data['pedidos'] ?? []);
        final estado = data['estado'] ?? 'Activa';

        if (listPedidos.contains(pedidoId)) {
          rutaActualId = id;
        }

        if (estado.toLowerCase() != 'cancelada') {
          activeRoutes.add({
            'id': id,
            'conductorId': data['conductorId'] ?? 'Sin conductor',
            'nombreConductor': data['nombreConductor'] ?? 'Sin conductor',
            'pedidos': listPedidos,
          });
        }
      }

      if (!context.mounted) return;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          String? selectedRouteId = rutaActualId;
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Reasignar Ruta de Pedido'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pedido: $pedidoId'),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedRouteId,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Nueva Ruta',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Ninguna (Retirar de ruta)', overflow: TextOverflow.ellipsis),
                        ),
                        ...activeRoutes.map((route) {
                          final rId = route['id'].toString();
                          final displayId = rId.length > 12 ? 'RUT-...${rId.substring(rId.length - 6)}' : rId;
                          return DropdownMenuItem<String>(
                            value: route['id'],
                            child: Text(
                              'Ruta $displayId (${route['nombreConductor']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedRouteId = val;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final batch = FirebaseFirestore.instance.batch();

                        for (var doc in routesSnapshot.docs) {
                          final data = doc.data();
                          final list = List<String>.from(data['pedidos'] ?? []);
                          if (list.contains(pedidoId)) {
                            list.remove(pedidoId);
                            batch.update(doc.reference, {'pedidos': list});
                          }
                        }

                        String nuevoConductorId = 'No asignado';
                        String nuevoConductorNombre = 'No asignado';

                        if (selectedRouteId != null) {
                          final selectedRoute = activeRoutes.firstWhere((r) => r['id'] == selectedRouteId);
                          final List<String> list = List<String>.from(selectedRoute['pedidos']);
                          if (!list.contains(pedidoId)) {
                            list.add(pedidoId);
                          }
                          batch.update(
                            FirebaseFirestore.instance.collection('rutas').doc(selectedRouteId),
                            {'pedidos': list},
                          );

                          nuevoConductorId = selectedRoute['conductorId'];
                          nuevoConductorNombre = selectedRoute['nombreConductor'];
                        }

                        batch.update(
                          FirebaseFirestore.instance.collection('entregas').doc('ENT-$pedidoId'),
                          {
                            'conductorId': nuevoConductorId,
                            'nombreConductor': nuevoConductorNombre,
                          },
                        );

                        batch.update(
                          FirebaseFirestore.instance.collection('pedidos').doc(pedidoId),
                          {
                            'estado': selectedRouteId != null ? 'Asignado' : 'Pendiente',
                          },
                        );

                        await batch.commit();

                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ruta del pedido reasignada correctamente')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al reasignar ruta: $e')),
                        );
                      }
                    },
                    child: const Text('Reasignar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reasignar: $e')),
      );
    }
  }

  Future<void> _exportarPDFDetallado(BuildContext context, String pedidoId) async {
    try {
      final pedidoDoc = await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .get();

      if (!pedidoDoc.exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el pedido en la base de datos.')),
        );
        return;
      }

      final pedidoData = pedidoDoc.data() as Map<String, dynamic>;

      DocumentSnapshot? entregaDoc;
      final docIdDirecto = 'ENT-$pedidoId';
      final docDirecto = await FirebaseFirestore.instance
          .collection('entregas')
          .doc(docIdDirecto)
          .get();

      if (docDirecto.exists) {
        entregaDoc = docDirecto;
      } else {
        final query = await FirebaseFirestore.instance
            .collection('entregas')
            .where('pedidoId', isEqualTo: pedidoId)
            .get();
        if (query.docs.isNotEmpty) {
          entregaDoc = query.docs.first;
        } else {
          final docPedidoId = await FirebaseFirestore.instance
              .collection('entregas')
              .doc(pedidoId)
              .get();
          if (docPedidoId.exists) {
            entregaDoc = docPedidoId;
          }
        }
      }

      Map<String, dynamic> entregaData = {};
      if (entregaDoc != null && entregaDoc.exists) {
        entregaData = entregaDoc.data() as Map<String, dynamic>;
      }

      final pdf = pw.Document();

      final cliente = pedidoData['cliente'] ?? 'Cliente';
      final direccion = pedidoData['direccion'] ?? 'Sin dirección';
      final prioridad = pedidoData['prioridad'] ?? 'Media';
      final estado = pedidoData['estado'] ?? 'Pendiente';
      final cajas = (pedidoData['numeroCajas'] ?? 0).toString();
      final conductor = entregaData['nombreConductor'] ?? 'No asignado';
      final observaciones = entregaData['observaciones'] ?? 'Sin observaciones';
      
      final String fechaActual = DateTime.now().toIso8601String().split('T')[0];

      pw.MemoryImage? signatureImage;
      final String? firmaBase64 = entregaData['firmaBase64'] ?? entregaData['firma'];
      if (firmaBase64 != null && firmaBase64.isNotEmpty) {
        try {
          signatureImage = pw.MemoryImage(base64Decode(firmaBase64));
        } catch (e) {
          debugPrint("Error decodificando firma base64: $e");
        }
      }

      pw.MemoryImage? photoImage;
      final String? fotoBase64 = entregaData['fotoBase64'] ?? entregaData['foto'];
      if (fotoBase64 != null && fotoBase64.isNotEmpty) {
        try {
          photoImage = pw.MemoryImage(base64Decode(fotoBase64));
        } catch (e) {
          debugPrint("Error decodificando foto base64: $e");
        }
      }

      final blueColor = PdfColor.fromHex('#1565c0');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'OPTIRUTA',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: blueColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Reporte Detallado de Pedido',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'PEDIDO ID: $pedidoId',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Fecha: $fechaActual',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 2, color: blueColor, height: 25),

                  pw.Text(
                    'Información del Pedido',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: blueColor),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        _buildPdfRow('Cliente:', cliente),
                        _buildPdfRow('Dirección de Entrega:', direccion),
                        _buildPdfRow('Estado Actual:', estado),
                        _buildPdfRow('Prioridad:', prioridad),
                        _buildPdfRow('Cantidad de Cajas:', cajas),
                        _buildPdfRow('Conductor Asignado:', conductor),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  pw.Text(
                    'Detalles del Despacho / Observaciones',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: blueColor),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Text(
                      observaciones,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    ),
                  ),
                  pw.SizedBox(height: 25),

                  if (estado == 'Entregado') ...[
                    pw.Text(
                      'Evidencias de Entrega',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: blueColor),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Firma del Cliente:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.SizedBox(height: 8),
                            signatureImage != null
                                ? pw.Container(
                                    width: 180,
                                    height: 100,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                                      color: PdfColors.white,
                                    ),
                                    child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                                  )
                                : pw.Text('No registrada', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Foto de Evidencia:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.SizedBox(height: 8),
                            photoImage != null
                                ? pw.Container(
                                    width: 180,
                                    height: 120,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                                      color: PdfColors.white,
                                    ),
                                    child: pw.Image(photoImage, fit: pw.BoxFit.cover),
                                  )
                                : pw.Text('No registrada', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          ],
                        ),
                      ],
                    ),
                  ],

                  pw.Spacer(),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'OPTIRUTA © ${DateTime.now().year} - Reporte Individual Generado del Sistema de Monitoreo',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Reporte_Detallado_Pedido_$pedidoId.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar el reporte PDF: $e')),
      );
    }
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey800),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
            ),
          ),

        ],
      ),
    );
  }
}
