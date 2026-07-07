import 'package:flutter/material.dart';
import 'login_admin_screen.dart';

import 'rutas_screen.dart';
import 'usuarios_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Administrador'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginAdminScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            const DashboardCard(
              titulo: 'Pedidos',
              valor: '15',
              icono: Icons.inventory,
            ),
            const DashboardCard(
              titulo: 'Conductores',
              valor: '6',
              icono: Icons.person,
            ),
            DashboardCard(
              titulo: 'Rutas',
              valor: 'Gestionar',
              icono: Icons.route,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RutasScreen(),
                  ),
                );
              },
            ),
            const DashboardCard(
              titulo: 'Entregas',
              valor: '12',
              icono: Icons.local_shipping,
            ),
            DashboardCard(
              titulo: 'Usuarios',
              valor: 'Gestionar',
              icono: Icons.manage_accounts,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UsuariosScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 50,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}