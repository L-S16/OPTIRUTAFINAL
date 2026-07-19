import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'mapa_ruta_admin_screen.dart';

class RutasScreen extends StatelessWidget {
  const RutasScreen({super.key});

  Future<void> _reasignarConductor(
    BuildContext context,
    String rutaId,
    String conductorActual,
  ) async {
    final controller = TextEditingController(text: conductorActual);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reasignar conductor'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'ID del nuevo conductor',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final nuevoConductor = controller.text.trim();

                if (nuevoConductor.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ingrese el ID del conductor',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('rutas')
                      .doc(rutaId)
                      .update({
                    'conductorId': nuevoConductor,
                    'fechaActualizacion':
                        FieldValue.serverTimestamp(),
                  });

                  if (!context.mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Conductor reasignado correctamente',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al reasignar conductor: $e',
                      ),
                    ),
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

    controller.dispose();
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
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
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
                          const SizedBox(width: 10),
                          TextButton.icon(
                            onPressed: rutaCancelada
                                ? null
                                : () {
                                    _reasignarConductor(
                                      context,
                                      documento.id,
                                      conductorId,
                                    );
                                  },
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Reasignar'),
                          ),
                          const SizedBox(width: 10),
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