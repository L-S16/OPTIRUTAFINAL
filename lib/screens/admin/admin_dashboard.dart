import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../welcome_screen.dart';
import 'rutas_screen.dart';
import 'usuarios_screen.dart';
import 'conductores_screen.dart';
import 'reportes_screen.dart';
import '../../providers/pedido_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _mostrarConfiguracionLetra(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<PedidoProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: const Text('Configuración Visual'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Configura el estilo de letra y tema de la aplicación:'),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: const Text('Tema Oscuro (Letra Blanca)'),
                    value: !provider.isDarkFont,
                    onChanged: (value) {
                      provider.setFontColor(!value);
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tamaño de Letra:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<double>(
                    initialValue: provider.fontSizeFactor,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 0.85,
                        child: Text('Pequeño (Pantalla Chica)'),
                      ),
                      DropdownMenuItem(
                        value: 1.0,
                        child: Text('Normal (Defecto)'),
                      ),
                      DropdownMenuItem(
                        value: 1.25,
                        child: Text('Grande (Fácil Lectura)'),
                      ),
                    ],
                    onChanged: (double? value) {
                      if (value != null) {
                        provider.setFontSizeFactor(value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarConfirmacionSalir(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Confirmar Salida',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas salir?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (e) {
                  debugPrint("Error signing out: $e");
                }
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Sí, Salir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Administrador'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración Visual',
            onPressed: () => _mostrarConfiguracionLetra(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
            onPressed: () => _mostrarConfirmacionSalir(context),
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
              builder: (context, snapshot) {
                final valor = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
                return DashboardCard(
                  titulo: 'Pedidos',
                  valor: valor,
                  icono: Icons.inventory,
                  onTap: () {
                    // Navega a reportes (vista general de pedidos)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportesScreen(initialTab: 1),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('conductores').snapshots(),
              builder: (context, snapshot) {
                final valor = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
                return DashboardCard(
                  titulo: 'Conductores',
                  valor: valor,
                  icono: Icons.person,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConductoresScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('rutas').snapshots(),
              builder: (context, snapshot) {
                final valor = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
                return DashboardCard(
                  titulo: 'Rutas',
                  valor: valor,
                  icono: Icons.route,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RutasScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .where('estado', isEqualTo: 'Entregado')
                  .snapshots(),
              builder: (context, snapshot) {
                final valor = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
                return DashboardCard(
                  titulo: 'Entregas',
                  valor: valor,
                  icono: Icons.local_shipping,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportesScreen(initialTab: 0),
                      ),
                    );
                  },
                );
              },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icono,
                      size: 32,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}