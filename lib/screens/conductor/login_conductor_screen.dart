import 'package:flutter/material.dart';
import 'conductor_dashboard.dart';
import 'registro_conductor_screen.dart';

class LoginConductorScreen extends StatelessWidget {
  const LoginConductorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Conductor'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo OPTIRUTA
              const Icon(
                Icons.local_shipping,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'OPTIRUTA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 48),

              // Campo Correo
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Contraseña
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 32),

              // Botón Iniciar Sesión
              ElevatedButton(
                onPressed: () {
                  // Acción de inicio de sesión
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConductorDashboard(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              // Botón Nuevo Usuario
              OutlinedButton(
                onPressed: () {
                  // Navegar a la pantalla de registro
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistroConductorScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Nuevo Usuario',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
