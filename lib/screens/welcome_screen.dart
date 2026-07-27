import 'package:flutter/material.dart';
import 'admin/login_admin_screen.dart';
import 'bodega/login_bodeguero_screen.dart';
import 'conductor/login_conductor_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // 0: Admin, 1: Bodeguero, 2: Conductor
  int _selectedProfile = 1; // Bodeguero predeterminado

  void _onNext() {
    Widget nextScreen;
    switch (_selectedProfile) {
      case 0:
        nextScreen = const LoginAdminScreen();
        break;
      case 1:
        nextScreen = const LoginBodegueroScreen();
        break;
      case 2:
        nextScreen = const LoginConductorScreen();
        break;
      default:
        return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }



  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E3A8A); // Azul oscuro premium
    final screenSize = MediaQuery.of(context).size;
    final isShortScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: isShortScreen ? 20 : 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo_optiruta.png',
                  height: isShortScreen ? 90 : 140,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: isShortScreen ? 8 : 12),
                // Bienvenido
                const Text(
                  '¡Bienvenido a OPTIRUTA!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Por favor, selecciona tu perfil para comenzar:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: isShortScreen ? 20 : 30),

                // Perfiles Row / Column
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 650;

                    Widget buildCard(int index, String title, String description, IconData icon) {
                      return _buildProfileCard(
                        index: index,
                        title: title,
                        description: description,
                        icon: icon,
                        isDesktop: isDesktop,
                        width: isDesktop ? null : double.infinity,
                        color: primaryColor,
                      );
                    }

                    if (isDesktop) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: buildCard(0, 'SUPER ADMINISTRADOR', 'Gestión global, reportes y configuración.', Icons.assignment_ind_outlined)),
                          const SizedBox(width: 16),
                          Expanded(child: buildCard(1, 'BODEGUERO', 'Control de inventario y preparación.', Icons.inventory_2_outlined)),
                          const SizedBox(width: 16),
                          Expanded(child: buildCard(2, 'CONDUCTOR', 'Rutas, entregas y confirmación.', Icons.local_shipping_outlined)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          buildCard(0, 'SUPER ADMINISTRADOR', 'Gestión global, reportes y configuración.', Icons.assignment_ind_outlined),
                          const SizedBox(height: 12),
                          buildCard(1, 'BODEGUERO', 'Control de inventario y preparación.', Icons.inventory_2_outlined),
                          const SizedBox(height: 12),
                          buildCard(2, 'CONDUCTOR', 'Rutas, entregas y confirmación.', Icons.local_shipping_outlined),
                        ],
                      );
                    }
                  },
                ),

                SizedBox(height: isShortScreen ? 25 : 35),

                // Botón Siguiente
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // Azul vibrante
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _onNext,
                    child: const Text(
                      'Siguiente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required int index,
    required String title,
    required String description,
    required IconData icon,
    required bool isDesktop,
    double? width,
    required Color color,
  }) {
    final bool isSelected = _selectedProfile == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProfile = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        constraints: BoxConstraints(
          minHeight: isDesktop ? 160 : 75,
        ),
        padding: isDesktop
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 18)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: isDesktop
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 36,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
