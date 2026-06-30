import 'package:flutter/material.dart';

import '../admin/login_admin_screen.dart';
import '../bodega/login_bodeguero_screen.dart';
import '../conductor/login_conductor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OPTIRUTA"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const Icon(
              Icons.local_shipping,
              size: 80,
              color: Colors.blue,
            ),

            const SizedBox(height: 15),

            const Text(
              "Sistema Inteligente de Distribución",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            _menuCard(
              context,
              icon: Icons.admin_panel_settings,
              titulo: "Administrador",
              descripcion: "Gestiona el sistema",
              pantalla: const LoginAdminScreen(),
            ),

            const SizedBox(height: 20),

            _menuCard(
              context,
              icon: Icons.inventory,
              titulo: "Bodeguero",
              descripcion: "Gestiona pedidos",
              pantalla: const LoginBodegueroScreen(),
            ),

            const SizedBox(height: 20),

            _menuCard(
              context,
              icon: Icons.local_shipping,
              titulo: "Conductor",
              descripcion: "Consulta rutas",
              pantalla: const LoginConductorScreen(),
            ),

          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String descripcion,
    required Widget pantalla,
  }) {
    return Card(
      elevation: 5,
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => pantalla,
            ),
          );
        },
      ),
    );
  }
}