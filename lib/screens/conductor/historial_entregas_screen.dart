import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialEntregasScreen extends StatelessWidget {
  const HistorialEntregasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Entregas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entregas')
            .where('estado', isEqualTo: 'Entregado')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el historial.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No hay entregas completadas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final numRuta = data['numeroRuta'] ?? 'Desconocida';
              final observaciones = data['observaciones'] ?? '';
              final firmaBase64 = data['firmaBase64'];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ruta #$numRuta',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Chip(
                            label: Text('Entregado', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (observaciones.isNotEmpty)
                        Text('Observaciones: $observaciones'),
                      const SizedBox(height: 12),
                      if (firmaBase64 != null && firmaBase64.isNotEmpty) ...[
                        const Text('Firma del cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade100,
                          ),
                          child: Image.memory(
                            base64Decode(firmaBase64),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                      ] else ...[
                        const Text('No se adjuntó firma.', style: TextStyle(fontStyle: FontStyle.italic)),
                      ]
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
