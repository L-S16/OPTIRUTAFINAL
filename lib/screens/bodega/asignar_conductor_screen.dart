import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_provider.dart';

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

  final List<Map<String, String>> _fallbackConductores = [
    {'id': 'cond-01', 'nombre': 'Juan Pérez', 'correo': 'juan@optiruta.com'},
    {'id': 'cond-02', 'nombre': 'Carlos Gómez', 'correo': 'carlos@optiruta.com'},
    {'id': 'cond-03', 'nombre': 'Luis Martínez', 'correo': 'luis@optiruta.com'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarConductores();
  }

  Future<void> _cargarConductores() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'conductor')
          .get();

      final List<Map<String, String>> loaded = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        loaded.add({
          'id': doc.id,
          'nombre': data['nombre'] ?? 'Conductor sin nombre',
          'correo': data['correo'] ?? '',
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

  void _guardarAsignacion() {
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

    // 1. Guardar la ruta en segundo plano (asíncronamente) sin bloquear la UI
    FirebaseFirestore.instance
        .collection('rutas')
        .where('conductorId', isEqualTo: _selectedConductorId)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final List<dynamic> currentPedidos = doc.data()['pedidos'] ?? [];
        if (!currentPedidos.contains(widget.pedido.id)) {
          currentPedidos.add(widget.pedido.id);
          doc.reference.update({'pedidos': currentPedidos}).then((_) {
            debugPrint("Pedido agregado a ruta existente de $_selectedConductorNombre.");
          }).catchError((e) {
            debugPrint("Error al actualizar ruta existente: $e");
          });
        }
      } else {
        final newRouteId = 'RUT-${DateTime.now().millisecondsSinceEpoch}';
        FirebaseFirestore.instance.collection('rutas').doc(newRouteId).set({
          'id': newRouteId,
          'conductorId': _selectedConductorId,
          'pedidos': [widget.pedido.id],
        }).then((_) {
          debugPrint("Nueva ruta creada para $_selectedConductorNombre.");
        }).catchError((e) {
          debugPrint("Error al crear nueva ruta: $e");
        });
      }
    }).catchError((e) {
      debugPrint("Error al consultar rutas de conductor: $e");
    });

    // 2. Crear el objeto pedido actualizado y guardar localmente de inmediato
    final pedidoActualizado = Pedido(
      id: widget.pedido.id,
      cliente: widget.pedido.cliente,
      direccion: widget.pedido.direccion,
      prioridad: widget.pedido.prioridad,
      estado: 'En Ruta',
      numeroCajas: widget.pedido.numeroCajas,
      zona: widget.pedido.zona,
    );

    if (mounted) {
      // Usar provider para actualizar localmente e iniciar guardado en Firestore del pedido de fondo
      Provider.of<PedidoProvider>(context, listen: false).actualizarPedido(pedidoActualizado);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pedido asignado a $_selectedConductorNombre y cambiado a estado "En Ruta".',
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
      
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
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
      body: Column(
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
                    Text(
                      widget.pedido.cliente,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.pedido.direccion,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
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
          Expanded(
            child: _loadingConductores
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _conductores.length,
                    itemBuilder: (context, index) {
                      final cond = _conductores[index];
                      final isSelected = _selectedConductorId == cond['id'];

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
                          groupValue: _selectedConductorId,
                          activeColor: Colors.blueAccent[700],
                          title: Text(
                            cond['nombre']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                          onChanged: (value) {
                            setState(() {
                              _selectedConductorId = value;
                              _selectedConductorNombre = cond['nombre'];
                            });
                          },
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
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
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
    );
  }
}
