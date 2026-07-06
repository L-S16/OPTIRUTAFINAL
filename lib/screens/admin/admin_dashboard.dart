import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Administrador'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: const [

            DashboardCard(
              titulo: 'Pedidos',
              valor: '15',
              icono: Icons.inventory,
            ),

            DashboardCard(
              titulo: 'Conductores',
              valor: '6',
              icono: Icons.person,
            ),

            DashboardCard(
              titulo: 'Rutas',
              valor: '4',
              icono: Icons.route,
            ),

            DashboardCard(
              titulo: 'Entregas',
              valor: '12',
              icono: Icons.local_shipping,
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

  const DashboardCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
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
    );
  }
}