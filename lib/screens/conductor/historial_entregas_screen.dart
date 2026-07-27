import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialEntregasScreen extends StatefulWidget {
  const HistorialEntregasScreen({super.key});

  @override
  State<HistorialEntregasScreen> createState() => _HistorialEntregasScreenState();
}

class _HistorialEntregasScreenState extends State<HistorialEntregasScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final dateString = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial - $dateString'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Buscar por fecha',
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entregas')
            .where('conductorId', isEqualTo: currentUser?.uid)
            .where('estado', whereIn: ['Entregado', 'No entregado'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el historial.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          
          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Usar fechaActualizacion si existe, de lo contrario fechaCreacion
            final timestamp = data['fechaActualizacion'] as Timestamp? ?? data['fechaCreacion'] as Timestamp?;
            if (timestamp == null) return false;
            // Convertir la fecha local del dispositivo comparada con el timestamp
            final date = timestamp.toDate().toLocal();
            return date.year == _selectedDate.year &&
                   date.month == _selectedDate.month &&
                   date.day == _selectedDate.day;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No hay entregas completadas en esta fecha.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final numRuta = data['numeroRuta'] ?? 'Desconocida';
              final observaciones = data['observaciones'] ?? '';
              final firmaBase64 = data['firmaBase64'];
              final fotoBase64 = data['fotoBase64'];
              final estado = data['estado'] ?? 'Entregado';
              final cajasDevueltas = data['cajasDevueltas'] ?? 0;

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
                          Expanded(
                            child: Text(
                              'Ruta #$numRuta',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(data['estado'] ?? 'Entregado', style: const TextStyle(color: Colors.white)),
                            backgroundColor: data['estado'] == 'No entregado' ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (observaciones.isNotEmpty)
                        Text('Observaciones: $observaciones'),
                      if (estado == 'No entregado') ...[
                        const SizedBox(height: 8),
                        Text('Cajas Devueltas: $cajasDevueltas', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                      const SizedBox(height: 12),
                      
                      if (fotoBase64 != null && fotoBase64.isNotEmpty) ...[
                        const Text('Evidencia fotográfica:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade100,
                          ),
                          child: Image.memory(
                            base64Decode(fotoBase64),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

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
                        Text(
                          estado == 'No entregado' ? 'No se adjuntó foto ni firma por ser No Entregado.' : 'No se adjuntó firma.', 
                          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)
                        ),
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
