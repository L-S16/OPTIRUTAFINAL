import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'mapa_ruta_admin_screen.dart';

class RutasScreen extends StatelessWidget {
  const RutasScreen({super.key});

  Future<void> _reasignarConductor(
    BuildContext context,
    String rutaId,
    String conductorActual,
    List<String> pedidosIds,
  ) async {
    try {
      final conductoresSnapshot = await FirebaseFirestore.instance
          .collection('conductores')
          .get();

      final List<Map<String, String>> conductoresList = [];
      for (var doc in conductoresSnapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final nombre = data['nombre'] ?? '';
        final apellido = data['apellido'] ?? '';
        final nombreCompleto = '$nombre $apellido'.trim();
        if (nombreCompleto.isNotEmpty) {
          conductoresList.add({'id': id, 'nombre': nombreCompleto});
        }
      }

      if (conductoresList.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay conductores registrados para asignar.')),
        );
        return;
      }

      String? seleccionadoId;
      for (var cond in conductoresList) {
        if (cond['id'] == conductorActual || cond['nombre'] == conductorActual) {
          seleccionadoId = cond['id'];
          break;
        }
      }
      seleccionadoId ??= conductoresList.first['id'];

      if (!context.mounted) return;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          String? tempSelected = seleccionadoId;
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Reasignar Conductor'),
                content: DropdownButtonFormField<String>(
                  initialValue: tempSelected,
                  decoration: const InputDecoration(
                    labelText: 'Selecciona Conductor',
                    border: OutlineInputBorder(),
                  ),
                  items: conductoresList.map((cond) {
                    return DropdownMenuItem<String>(
                      value: cond['id'],
                      child: Text(cond['nombre']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      tempSelected = val;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final nuevoConductorId = tempSelected;
                      final nuevoConductorNombre = conductoresList
                          .firstWhere((c) => c['id'] == nuevoConductorId)['nombre'];

                      if (nuevoConductorId == null) return;

                      try {
                        final batch = FirebaseFirestore.instance.batch();

                        batch.update(
                          FirebaseFirestore.instance.collection('rutas').doc(rutaId),
                          {
                            'conductorId': nuevoConductorId,
                            'nombreConductor': nuevoConductorNombre,
                            'fechaActualizacion': FieldValue.serverTimestamp(),
                          },
                        );

                        for (var pedId in pedidosIds) {
                          batch.update(
                            FirebaseFirestore.instance.collection('entregas').doc('ENT-$pedId'),
                            {
                              'conductorId': nuevoConductorId,
                              'nombreConductor': nuevoConductorNombre,
                            },
                          );
                        }

                        await batch.commit();

                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Conductor reasignado correctamente')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al reasignar: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Reasignar'),
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
        SnackBar(content: Text('Error al cargar conductores: $e')),
      );
    }
  }

  Future<void> _cancelarRuta(
    BuildContext context,
    String rutaId,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar ruta'),
          content: const Text(
            '¿Está seguro de que desea cancelar esta ruta?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('rutas')
          .doc(rutaId)
          .update({
        'estado': 'Cancelada',
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta cancelada correctamente'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar ruta: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Rutas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rutas')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar las rutas'),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final rutas = snapshot.data!.docs;

          if (rutas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No existen rutas registradas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rutas.length,
            itemBuilder: (context, index) {
              final documento = rutas[index];

              final datos =
                  documento.data() as Map<String, dynamic>;

              final conductorId =
                  datos['conductorId']?.toString() ??
                      'Sin conductor';

              final estado =
                  datos['estado']?.toString() ?? 'Activa';

              final pedidos =
                  List<String>.from(datos['pedidos'] ?? []);

              final rutaCancelada =
                  estado.toLowerCase() == 'cancelada';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: rutaCancelada
                              ? Colors.grey
                              : Colors.blue,
                          child: Icon(
                            rutaCancelada
                                ? Icons.route_outlined
                                : Icons.route,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          'Ruta ${documento.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 8),
                          child: Text(
                            'Conductor: $conductorId\n'
                            'Pedidos: ${pedidos.length}\n'
                            'Estado: $estado',
                          ),
                        ),
                        isThreeLine: true,
                      ),
                      const Divider(),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapaRutaAdminScreen(
                                    rutaId: documento.id,
                                    pedidosIds: pedidos,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('Ver Mapa'),
                          ),
                          TextButton.icon(
                            onPressed: rutaCancelada
                                ? null
                                : () {
                                     _reasignarConductor(
                                       context,
                                       documento.id,
                                       conductorId,
                                       pedidos,
                                     );
                                   },
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Reasignar'),
                          ),
                          TextButton.icon(
                            onPressed: rutaCancelada
                                ? null
                                : () {
                                    _cancelarRuta(
                                      context,
                                      documento.id,
                                    );
                                  },
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}