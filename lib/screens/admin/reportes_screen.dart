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
}
