import 'package:flutter/material.dart';

import '../admin/login_admin_screen.dart';
import '../bodega/login_bodeguero_screen.dart';
import '../conductor/login_conductor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xff0B2A5B),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "OPTIRUTA",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              const SizedBox(height: 10),

              Image.asset(
                'assets/images/logo_optiruta.png',
                height: 200,
              ),

              const SizedBox(height: 10),

              const Text(
                "Sistema Inteligente de Distribución",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0B2A5B),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                "Seleccione el módulo al que desea ingresar",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              _menuCard(
                context,
                color: const Color(0xff0B2A5B),
                icon: Icons.admin_panel_settings,
                titulo: "Administrador",
                descripcion: "Gestionar usuarios y rutas",
                pantalla: const LoginAdminScreen(),
              ),

              const SizedBox(height: 18),

              _menuCard(
                context,
                color: Colors.orange,
                icon: Icons.inventory_2,
                titulo: "Bodeguero",
                descripcion: "Gestionar pedidos",
                pantalla: const LoginBodegueroScreen(),
              ),

              const SizedBox(height: 18),

              _menuCard(
                context,
                color: Colors.green,
                icon: Icons.local_shipping,
                titulo: "Conductor",
                descripcion: "Consultar rutas asignadas",
                pantalla: const LoginConductorScreen(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String titulo,
    required String descripcion,
    required Widget pantalla,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => pantalla,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [

              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(.15),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      descripcion,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}