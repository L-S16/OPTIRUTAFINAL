import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'admin_dashboard.dart';
import '../bodega/login_bodeguero_screen.dart';
import '../conductor/login_conductor_screen.dart';
import '../welcome_screen.dart';
import '../../providers/pedido_provider.dart';

class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({super.key});

  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu correo y contraseña.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Autenticar con Firebase
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // 2. Validar rol Administrador en Firestore
        final querySnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('correo', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          final String? rol = userData['rol'];
          if (rol != 'Administrador') {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Acceso denegado. No tienes permisos de Administrador.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          // Si es el primer acceso y no existe en Firestore, registramos el perfil por defecto
          await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
            'nombre': 'Administrador',
            'correo': email,
            'rol': 'Administrador',
            'estado': true,
            'fechaRegistro': FieldValue.serverTimestamp(),
          });
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensajeError = 'Ocurrió un error al iniciar sesión.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensajeError = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'invalid-email') {
        mensajeError = 'El formato del correo es inválido.';
      } else if (e.code == 'user-disabled') {
        mensajeError = 'Este usuario ha sido deshabilitado.';
      } else if (e.code == 'network-request-failed') {
        mensajeError = 'Error de conexión. Verifica tu internet.';
      } else {
        mensajeError = 'Error al iniciar sesión: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPTIRUTA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver a Selección de Perfil',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración Visual',
            onPressed: () => _mostrarConfiguracionLetra(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Image.asset(
                'assets/images/logo_optiruta.png',
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 25),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Text(
                          'Login Super Administrador',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _iniciarSesion,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Iniciar Sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginBodegueroScreen(),
                          ),
                        );
                      },
                child: const Text(
                  '¿Eres Bodeguero? Iniciar sesión aquí',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginConductorScreen(),
                          ),
                        );
                      },
                child: const Text(
                  '¿Eres Conductor? Iniciar sesión aquí',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}