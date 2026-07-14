import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_provider.dart';

class ClasificarPedidosScreen extends StatefulWidget {
  const ClasificarPedidosScreen({super.key});

  @override
  State<ClasificarPedidosScreen> createState() => _ClasificarPedidosScreenState();
}

class _ClasificarPedidosScreenState extends State<ClasificarPedidosScreen> {
  final List<String> _zonas = ['Norte', 'Sur', 'Este', 'Oeste', 'Centro'];
  
  // Guardamos las clasificaciones en un mapa temporal {pedidoId: zona}
  final Map<String, String> _zonasSeleccionadas = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final pedidoProvider = Provider.of<PedidoProvider>(context);
    // Filtrar únicamente los pedidos pendientes
    final pedidosPendientes = pedidoProvider.pedidos.where((p) => p.estado == 'Pendiente').toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Clasificar por Zona',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
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
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 35, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clasificación Geográfica',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Asigna una zona a los pedidos pendientes para optimizar las rutas de entrega.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                if (pedidosPendientes.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pedidosPendientes.length} Pedido(s) Pendiente(s)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: pedidosPendientes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 70,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'No hay pedidos pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Todos los pedidos han sido clasificados o procesados.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    itemCount: pedidosPendientes.length,
                    itemBuilder: (context, index) {
                      final pedido = pedidosPendientes[index];
                      // Inicializar en el mapa si aún no está
                      if (!_zonasSeleccionadas.containsKey(pedido.id)) {
                        _zonasSeleccionadas[pedido.id] = pedido.zona ?? '';
                      }

                      final String currentSelection = _zonasSeleccionadas[pedido.id]!;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
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
                                    pedido.id,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  _buildPriorityChip(pedido.prioridad),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pedido.cliente,
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
                                      pedido.direccion,
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
                              const Divider(height: 25),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: currentSelection.isEmpty ? null : currentSelection,
                                      hint: const Text('Asignar Zona Geográfica'),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        prefixIcon: const Icon(Icons.public, color: Colors.blueAccent, size: 20),
                                      ),
                                      items: _zonas.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _zonasSeleccionadas[pedido.id] = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (pedidosPendientes.isNotEmpty)
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
                  onPressed: _isLoading ? null : () => _guardarClasificacion(context, pedidosPendientes),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 10),
                            Text(
                              'Guardar Clasificación',
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

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'Alta':
        color = Colors.redAccent;
        break;
      case 'Media':
        color = Colors.amber;
        break;
      case 'Baja':
      default:
        color = Colors.green;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _guardarClasificacion(BuildContext context, List<Pedido> pendientes) async {
    // Validar que se haya modificado o ingresado al menos una zona válida
    bool algunCambio = false;
    List<Pedido> pedidosAActualizar = [];

    for (var pedido in pendientes) {
      final selectedZona = _zonasSeleccionadas[pedido.id];
      if (selectedZona != null && selectedZona.isNotEmpty && selectedZona != pedido.zona) {
        algunCambio = true;
        
        final updatedPedido = Pedido(
          id: pedido.id,
          cliente: pedido.cliente,
          direccion: pedido.direccion,
          prioridad: pedido.prioridad,
          estado: pedido.estado,
          numeroCajas: pedido.numeroCajas,
          zona: selectedZona,
        );
        pedidosAActualizar.add(updatedPedido);
      }
    }

    if (!algunCambio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cambios pendientes por guardar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PedidoProvider>(context, listen: false);

      // Guardar todos de forma masiva esperando a que terminen en Firestore
      await Future.wait(pedidosAActualizar.map((p) => provider.actualizarPedido(p)));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Clasificación geográfica guardada exitosamente.',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
      debugPrint("Error al guardar clasificación geográfica: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la clasificación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
