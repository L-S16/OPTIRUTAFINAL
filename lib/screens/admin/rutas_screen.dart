import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RutasScreen extends StatelessWidget {
  const RutasScreen({super.key});

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

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.route),
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
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Conductor: $conductorId\n'
                      'Pedidos: ${pedidos.length}\n'
                      'Estado: $estado',
                    ),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
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