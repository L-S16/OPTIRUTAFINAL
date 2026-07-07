import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_provider.dart';

class EditarPedidoScreen extends StatefulWidget {
  final Pedido pedido;

  const EditarPedidoScreen({super.key, required this.pedido});

  @override
  State<EditarPedidoScreen> createState() => _EditarPedidoScreenState();
}

class _EditarPedidoScreenState extends State<EditarPedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clienteController;
  late TextEditingController _direccionController;
  late TextEditingController _cajasController;
  late String _prioridadSeleccionada;
  late String _estadoSeleccionada;
  bool _isLoading = false;

  final List<String> _prioridades = ['Alta', 'Media', 'Baja'];
  final List<String> _estados = ['Pendiente', 'En Ruta', 'Entregado'];

  @override
  void initState() {
    super.initState();
    _clienteController = TextEditingController(text: widget.pedido.cliente);
    _direccionController = TextEditingController(text: widget.pedido.direccion);
    _cajasController = TextEditingController(text: widget.pedido.numeroCajas.toString());
    _prioridadSeleccionada = widget.pedido.prioridad;
    _estadoSeleccionada = widget.pedido.estado;
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _direccionController.dispose();
    _cajasController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String cliente = _clienteController.text.trim();
    final String direccion = _direccionController.text.trim();
    final int numeroCajas = int.parse(_cajasController.text.trim());

    final pedidoActualizado = Pedido(
      id: widget.pedido.id,
      cliente: cliente,
      direccion: direccion,
      prioridad: _prioridadSeleccionada,
      estado: _estadoSeleccionada,
      numeroCajas: numeroCajas,
      zona: widget.pedido.zona, // Preservar la zona
    );

    try {
      // Esperar a que se complete la actualización en Firestore
      await Provider.of<PedidoProvider>(context, listen: false).actualizarPedido(pedidoActualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pedido actualizado exitosamente: ${widget.pedido.id}',
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
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al actualizar pedido: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el pedido: $e'),
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

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Entregado':
        return Colors.teal;
      case 'En Ruta':
        return Colors.blueAccent;
      case 'Pendiente':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Editar Pedido',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blueAccent[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modificar Pedido',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Pedido ID: ${widget.pedido.id}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles del Envío',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(height: 25),
                          
                          // CLIENTE
                          TextFormField(
                            controller: _clienteController,
                            decoration: InputDecoration(
                              labelText: 'Cliente / Nombre Comercial',
                              prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingrese el nombre del cliente';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // DIRECCION
                          TextFormField(
                            controller: _direccionController,
                            decoration: InputDecoration(
                              labelText: 'Dirección de Entrega',
                              prefixIcon: const Icon(Icons.location_on, color: Colors.blueAccent),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingrese la dirección';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // NUMERO DE CAJAS & PRIORIDAD
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CAJAS
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  controller: _cajasController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Nº Cajas',
                                    prefixIcon: const Icon(Icons.inbox, color: Colors.blueAccent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Requerido';
                                    }
                                    final num = int.tryParse(value);
                                    if (num == null || num <= 0) {
                                      return 'Inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 15),
                              
                              // PRIORIDAD
                              Expanded(
                                flex: 6,
                                child: DropdownButtonFormField<String>(
                                  value: _prioridadSeleccionada,
                                  decoration: InputDecoration(
                                    labelText: 'Prioridad',
                                    prefixIcon: Icon(Icons.flag, color: _getPriorityColor(_prioridadSeleccionada)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                  ),
                                  items: _prioridades.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(value),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(value),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _prioridadSeleccionada = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ESTADO DEL PEDIDO
                          DropdownButtonFormField<String>(
                            value: _estadoSeleccionada,
                            decoration: InputDecoration(
                              labelText: 'Estado del Pedido',
                              prefixIcon: Icon(Icons.info_outline, color: _getEstadoColor(_estadoSeleccionada)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            items: _estados.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _getEstadoColor(value),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                    _estadoSeleccionada = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 35),

                          // BOTON DE ACCION
                          SizedBox(
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
                              onPressed: _isLoading ? null : _guardarCambios,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save),
                                        SizedBox(width: 10),
                                        Text(
                                          'Guardar Cambios',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
