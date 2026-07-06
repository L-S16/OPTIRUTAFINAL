import 'package:flutter/material.dart';
import 'ver_ruta_asignada_screen.dart';

class ConductorDashboard extends StatelessWidget {
  const ConductorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Conductor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido Conductor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            // Simulación de Notificación de Ruta Asignada
            Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: ListTile(
                leading: const Icon(Icons.notifications_active, color: Colors.blue, size: 40),
                title: const Text('¡Tienes una nueva ruta asignada!'),
                subtitle: const Text('Toca aquí para ver los detalles'),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VerRutaAsignadaScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
