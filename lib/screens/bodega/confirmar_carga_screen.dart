import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_provider.dart';

class ConfirmarCargaScreen extends StatefulWidget {
  const ConfirmarCargaScreen({super.key});

  @override
  State<ConfirmarCargaScreen> createState() => _ConfirmarCargaScreenState();
}

class _ConfirmarCargaScreenState extends State<ConfirmarCargaScreen> {
  // Map to store checked boxes status: {pedidoId: [box1_checked, box2_checked, ...]}
  final Map<String, List<bool>> _boxChecks = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Checklist de Carga',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent[700],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .where('estado', isEqualTo: 'Asignado')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar pedidos asignados.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final List<Pedido> pedidosAsignados = docs
              .map((doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          if (pedidosAsignados.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.playlist_add_check,
                      size: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No hay pedidos por cargar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Asigna conductores a los pedidos pendientes para que aparezcan en esta lista.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Initialize box check arrays if they are not already initialized
          for (var pedido in pedidosAsignados) {
            if (!_boxChecks.containsKey(pedido.id) ||
                _boxChecks[pedido.id]!.length != pedido.numeroCajas) {
              _boxChecks[pedido.id] = List.generate(pedido.numeroCajas, (_) => false);
            }
          }

          // Check if at least one order has all its boxes checked
          bool canConfirmCarga = false;
          for (var pedido in pedidosAsignados) {
            final checks = _boxChecks[pedido.id];
            if (checks != null && checks.every((c) => c)) {
              canConfirmCarga = true;
              break;
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.blueAccent[700],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selecciona las cajas preparadas de cada pedido para habilitar la carga.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pedidosAsignados.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidosAsignados[index];
                    final checks = _boxChecks[pedido.id]!;
                    final totalBoxes = pedido.numeroCajas;
                    final checkedCount = checks.where((c) => c).length;
                    final isAllChecked = checkedCount == totalBoxes;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isAllChecked ? Colors.green[300]! : Colors.grey[200]!,
                          width: isAllChecked ? 1.5 : 1,
                        ),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        leading: CircleAvatar(
                          backgroundColor: isAllChecked ? Colors.green[50] : Colors.blue[50],
                          child: Icon(
                            isAllChecked ? Icons.check_circle : Icons.inventory,
                            color: isAllChecked ? Colors.green : Colors.blueAccent[700],
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              pedido.id,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent[700],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAllChecked ? Colors.green[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isAllChecked ? 'Verificado' : 'Pendiente',
                                style: TextStyle(
                                  color: isAllChecked ? Colors.green[700] : Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${pedido.cliente}\nCant. Cajas: $checkedCount/$totalBoxes',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Checklist de cajas:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    final checkVal = !isAllChecked;
                                    _boxChecks[pedido.id] = List.generate(totalBoxes, (_) => checkVal);
                                  });
                                },
                                child: Text(isAllChecked ? 'Desmarcar todos' : 'Marcar todos'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: totalBoxes,
                            itemBuilder: (context, boxIndex) {
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(
                                  'Caja ${boxIndex + 1} de $totalBoxes',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                value: checks[boxIndex],
                                onChanged: (val) {
                                  setState(() {
                                    checks[boxIndex] = val ?? false;
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    onPressed: !canConfirmCarga || _isSaving
                        ? null
                        : () => _confirmarCarga(pedidosAsignados),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_shipping),
                              SizedBox(width: 10),
                              Text(
                                'Confirmar Carga de Pedidos',
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
          );
        },
      ),
    );
  }

  Future<void> _confirmarCarga(List<Pedido> pedidos) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final List<String> pedidosCargadosIds = [];

      for (var pedido in pedidos) {
        final checks = _boxChecks[pedido.id];
        if (checks != null && checks.every((c) => c)) {
          pedidosCargadosIds.add(pedido.id);

          // 1. Actualizar estado del pedido en la colección 'pedidos' a 'En Ruta' y localmente en el Provider
          final pedidoActualizado = Pedido(
            id: pedido.id,
            cliente: pedido.cliente,
            direccion: pedido.direccion,
            prioridad: pedido.prioridad,
            estado: 'En Ruta',
            numeroCajas: pedido.numeroCajas,
            zona: pedido.zona,
          );
          
          await Provider.of<PedidoProvider>(context, listen: false).actualizarPedido(pedidoActualizado);

          // 2. Actualizar estado de la entrega en la colección 'entregas' a 'Pendiente' (así le aparece al conductor)
          final entregaDocId = 'ENT-${pedido.id}';
          await FirebaseFirestore.instance
              .collection('entregas')
              .doc(entregaDocId)
              .update({'estado': 'Pendiente'});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Se confirmó la carga de ${pedidosCargadosIds.length} pedidos. Ahora están En Ruta.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(15),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al confirmar carga: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar carga: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
