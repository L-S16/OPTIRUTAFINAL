import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_provider.dart';
import '../../utils/geocoding_helper.dart';

class AsignarConductorScreen extends StatefulWidget {
  final Pedido pedido;

  const AsignarConductorScreen({super.key, required this.pedido});

  @override
  State<AsignarConductorScreen> createState() => _AsignarConductorScreenState();
}

class _AsignarConductorScreenState extends State<AsignarConductorScreen> {
  String? _selectedConductorId;
  String? _selectedConductorNombre;
  bool _isLoading = false;
  List<Map<String, String>> _conductores = [];
  bool _loadingConductores = true;

  late TextEditingController _clienteController;
  late TextEditingController _telefonoController;
  late TextEditingController _detalleController;

  final List<Map<String, String>> _fallbackConductores = [
    {'id': 'cond-01', 'nombre': 'Juan Pérez', 'correo': 'juan@optiruta.com', 'tipoLicencia': 'Tipo B'},
    {'id': 'cond-02', 'nombre': 'Carlos Gómez', 'correo': 'carlos@optiruta.com', 'tipoLicencia': 'Tipo C'},
    {'id': 'cond-03', 'nombre': 'Luis Martínez', 'correo': 'luis@optiruta.com', 'tipoLicencia': 'Tipo E'},
  ];

  late LatLng _destinationLatLng;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _clienteController = TextEditingController(text: widget.pedido.cliente);
    _telefonoController = TextEditingController(text: widget.pedido.telefono ?? '');
    _detalleController = TextEditingController(text: widget.pedido.detalle ?? '');
    _destinationLatLng = GeocodingHelper.getLatLngFromDireccion(widget.pedido.direccion, widget.pedido.id);
    _cargarConductores();
    _geocodificarDireccion();
  }

  Future<void> _geocodificarDireccion() async {
    final result = await GeocodingHelper.buscarCoordenadasNominatim(widget.pedido.direccion);
    if (result != null && mounted) {
      setState(() {
        _destinationLatLng = result;
      });
      _mapController.move(result, 15.0);
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _telefonoController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  Future<void> _cargarConductores() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('conductores')
          .get();

      final List<Map<String, String>> loaded = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final String nombre = data['nombre'] ?? '';
        final String apellido = data['apellido'] ?? '';
        final String nombreCompleto = apellido.isNotEmpty ? '$nombre $apellido' : nombre;
        final String tipoLicencia = data['tipoLicencia'] ?? 'Sin licencia';
        
        loaded.add({
          'id': doc.id,
          'nombre': nombreCompleto.isNotEmpty ? nombreCompleto : 'Conductor sin nombre',
          'correo': data['correo'] ?? '',
          'tipoLicencia': tipoLicencia,
        });
      }

      setState(() {
        if (loaded.isNotEmpty) {
          _conductores = loaded;
        } else {
          _conductores = _fallbackConductores;
        }
        _loadingConductores = false;
      });
    } catch (e) {
      debugPrint("Error al cargar conductores de Firestore ($e). Usando conductores de prueba.");
      setState(() {
        _conductores = _fallbackConductores;
        _loadingConductores = false;
      });
    }
  }

  Future<void> _guardarAsignacion() async {
    if (_selectedConductorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un conductor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 0. Remover el pedido de cualquier ruta anterior asignada a otros conductores
      final oldRoutesQuery = await FirebaseFirestore.instance
          .collection('rutas')
          .where('pedidos', arrayContains: widget.pedido.id)
          .get();

      for (var doc in oldRoutesQuery.docs) {
        if (doc.data()['conductorId'] != _selectedConductorId) {
          final List<dynamic> oldPedidos = doc.data()['pedidos'] ?? [];
          oldPedidos.remove(widget.pedido.id);
          await doc.reference.update({'pedidos': oldPedidos});
          debugPrint("Pedido removido de la ruta anterior ${doc.id}.");
        }
      }

      // 1. Consultar y actualizar o crear la ruta en Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('rutas')
          .where('conductorId', isEqualTo: _selectedConductorId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final List<dynamic> currentPedidos = doc.data()['pedidos'] ?? [];
        if (!currentPedidos.contains(widget.pedido.id)) {
          currentPedidos.add(widget.pedido.id);
          await doc.reference.update({'pedidos': currentPedidos});
          debugPrint("Pedido agregado a ruta existente de $_selectedConductorNombre.");
        }
      } else {
        final newRouteId = 'RUT-${DateTime.now().millisecondsSinceEpoch}';
        await FirebaseFirestore.instance.collection('rutas').doc(newRouteId).set({
          'id': newRouteId,
          'conductorId': _selectedConductorId,
          'pedidos': [widget.pedido.id],
        });
        debugPrint("Nueva ruta creada para $_selectedConductorNombre.");
      }

      // 1.5 Crear/Actualizar la entrega en la colección 'entregas' para que le aparezca al conductor
      final entregaDocId = 'ENT-${widget.pedido.id}';
      await FirebaseFirestore.instance
          .collection('entregas')
          .doc(entregaDocId)
          .set({
        'id': entregaDocId,
        'pedidoId': widget.pedido.id,
        'numeroRuta': widget.pedido.id,
        'origen': 'Bodega Principal',
        'destino': widget.pedido.direccion,
        'estado': 'Por Cargar',
        'observaciones': '',
        'firmaBase64': null,
        'fotoBase64': null,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'conductorId': _selectedConductorId,
        'cliente': _clienteController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'detalle': _detalleController.text.trim(),
        'numeroCajas': widget.pedido.numeroCajas,
        'prioridad': widget.pedido.prioridad,
      });
      debugPrint("Entrega creada/actualizada para conductor $_selectedConductorNombre.");

      // 2. Crear el objeto pedido actualizado y guardar en Firestore & localmente
      final pedidoActualizado = Pedido(
        id: widget.pedido.id,
        cliente: _clienteController.text.trim(),
        direccion: widget.pedido.direccion,
        prioridad: widget.pedido.prioridad,
        estado: 'Asignado',
        numeroCajas: widget.pedido.numeroCajas,
        zona: widget.pedido.zona,
        telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
        detalle: _detalleController.text.trim().isNotEmpty ? _detalleController.text.trim() : null,
      );

      if (mounted) {
        await Provider.of<PedidoProvider>(context, listen: false).actualizarPedido(pedidoActualizado);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pedido asignado a $_selectedConductorNombre. Listo para carga.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.teal[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(15),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error al guardar asignación: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la asignación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Alta':
        return Colors.redAccent;
      case 'Media':
        return Colors.amber;
      case 'Baja':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Asignar Conductor',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera con datos del Pedido
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent[700],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Organizar Envío',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Asigna el pedido ${widget.pedido.id} a uno de los conductores disponibles.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tarjeta de detalles del pedido
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.pedido.id,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent[700],
                                    fontSize: 13,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(widget.pedido.prioridad).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.pedido.prioridad,
                                    style: TextStyle(
                                      color: _getPriorityColor(widget.pedido.prioridad),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Dirección: ${widget.pedido.direccion}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.pedido.zona != null && widget.pedido.zona!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.public, size: 14, color: Colors.purple),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Zona: ${widget.pedido.zona}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Mapa de Destino
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.map, color: Colors.black54, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Destino de la Entrega',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _destinationLatLng,
                                initialZoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.optiruta.final',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _destinationLatLng,
                                      width: 60,
                                      height: 60,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tarjeta para Editar Datos a Enviar al Conductor
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Datos de Entrega para el Conductor',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Divider(height: 20),
                            TextFormField(
                              controller: _clienteController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del Cliente',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _telefonoController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono del Cliente',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _detalleController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Detalle / Ítems del Pedido',
                                prefixIcon: Icon(Icons.receipt_long),
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // Título de Conductores
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.black54, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Conductores Disponibles',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Listado de Conductores
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: _loadingConductores
                        ? const Center(child: CircularProgressIndicator())
                        : _conductores.isEmpty
                            ? const Center(child: Text('No hay conductores disponibles.'))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _conductores.length,
                                itemBuilder: (context, index) {
                                  final cond = _conductores[index];
                                  final isSelected = _selectedConductorId == cond['id'];
                                  final tipoLicencia = cond['tipoLicencia'] ?? 'Sin licencia';

                                  return Card(
                                    elevation: isSelected ? 3 : 1,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected ? Colors.blueAccent[700]! : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: RadioListTile<String>(
                                      value: cond['id']!,
                                      // ignore: deprecated_member_use
                                      groupValue: _selectedConductorId,
                                      // ignore: deprecated_member_use
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedConductorId = value;
                                            _selectedConductorNombre = cond['nombre'];
                                          });
                                        }
                                      },
                                      activeColor: Colors.blueAccent[700],
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cond['nombre']!,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              tipoLicencia,
                                              style: TextStyle(
                                                color: Colors.blueAccent[700],
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        cond['correo']!,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      secondary: CircleAvatar(
                                        backgroundColor: isSelected ? Colors.blue[50] : Colors.grey[200],
                                        child: Icon(
                                          Icons.local_shipping,
                                          color: isSelected ? Colors.blueAccent[700] : Colors.grey[600],
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),

                  // Botón de Asignación
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                        ),
                        onPressed: _isLoading ? null : _guardarAsignacion,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add),
                            SizedBox(width: 10),
                            Text(
                              'Confirmar Asignación',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
