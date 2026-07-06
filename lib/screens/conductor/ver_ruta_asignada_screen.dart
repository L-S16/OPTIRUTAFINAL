import 'package:flutter/material.dart';
import 'mapa_ruta_screen.dart';

class VerRutaAsignadaScreen extends StatelessWidget {
  const VerRutaAsignadaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta Asignada'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ruta #001', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Chip(
                      label: const Text('Pendiente', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.orange.shade400,
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 1),
                const ListTile(
                  leading: Icon(Icons.location_on, color: Colors.blue),
                  title: Text('Origen'),
                  subtitle: Text('Ubicación Actual', style: TextStyle(fontSize: 16)),
                  contentPadding: EdgeInsets.zero,
                ),
                const ListTile(
                  leading: Icon(Icons.flag, color: Colors.red),
                  title: Text('Destino'),
                  subtitle: Text('Latacunga', style: TextStyle(fontSize: 16)),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                const ListTile(
                  leading: Icon(Icons.person, color: Colors.blueGrey),
                  title: Text('Conductor Asignado'),
                  subtitle: Text('Juan Pérez', style: TextStyle(fontSize: 16)),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapaRutaScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Iniciar Ruta', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
