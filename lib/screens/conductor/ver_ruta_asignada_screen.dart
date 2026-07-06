import 'package:flutter/material.dart';

class VerRutaAsignadaScreen extends StatelessWidget {
  const VerRutaAsignadaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta Asignada'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Ruta #001', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Origen: Almacén Central', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Destino: Sucursal Norte', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Estado: Pendiente', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Conductor: Juan Pérez', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
