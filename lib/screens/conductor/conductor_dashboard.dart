import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ver_ruta_asignada_screen.dart';
import 'historial_entregas_screen.dart';

class ConductorDashboard extends StatelessWidget {
  const ConductorDashboard({super.key});


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName ?? 'Conductor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Conductor'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de Entregas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistorialEntregasScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Bienvenido $nombre',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text('Tus rutas activas:', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('entregas')
                  .where('conductorId', isEqualTo: user?.uid)
                  .where('estado', whereIn: ['Pendiente', 'Reprogramado', 'En Ruta'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar rutas.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('No tienes rutas activas asignadas.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final routeId = docs[index].id;
                    final numRuta = data['numeroRuta'] ?? 'Desconocida';
                    final estado = data['estado'] ?? 'Pendiente';

                    return Card(
                      color: Colors.blue.shade50,
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active, color: Colors.blue, size: 40),
                        title: Text('Ruta #$numRuta'),
                        subtitle: Text('Estado: $estado\nToca aquí para ver los detalles'),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerRutaAsignadaScreen(
                                routeId: routeId,
                                routeData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

    );
  }
}
