import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class OfertasEmpleoScreen extends StatelessWidget {
  const OfertasEmpleoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas de Empleo / Servicios'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entregas')
            .where('necesitaServicio', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar solicitudes.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay ofertas de empleo o servicios solicitados.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final pedidoId = data['pedidoId'] ?? data['numeroRuta'] ?? doc.id;
              final destino = data['destino'] ?? 'Desconocido';
              final estado = data['estado'] ?? 'Pendiente';
              final descripcion = data['descripcionServicio'] ?? 'Sin descripción adicional';
              
              final cliente = data['cliente'] ?? 'Cliente';
              final telefono = data['telefono'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Pedido: $pedidoId',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estado,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (cliente != 'Cliente') ...[
                        Text(
                          'Cliente: $cliente',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text('Destino: $destino', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.work, size: 16, color: Colors.orange),
                                SizedBox(width: 6),
                                Text(
                                  'Servicio Solicitado:',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              descripcion.toString().trim().isNotEmpty ? descripcion : 'El cliente solicita servicio externo sin detalles.',
                              style: TextStyle(fontSize: 14, color: Colors.orange.shade900),
                            ),
                          ],
                        ),
                      ),
                      if (telefono.toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Contacto: $telefono',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_in_talk, color: Colors.green),
                              onPressed: () async {
                                final Uri launchUri = Uri(scheme: 'tel', path: telefono.toString());
                                if (await canLaunchUrl(launchUri)) {
                                  await launchUrl(launchUri);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
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
