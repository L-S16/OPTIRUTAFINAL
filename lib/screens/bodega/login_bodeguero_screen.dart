import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bodeguero_dashboard.dart';
import 'registrar_bodeguero_screen.dart';
import '../admin/login_admin_screen.dart';
import '../welcome_screen.dart';
import '../../providers/pedido_provider.dart';

class LoginBodegueroScreen extends StatefulWidget {
  const LoginBodegueroScreen({super.key});

  @override
  State<LoginBodegueroScreen> createState() => _LoginBodegueroScreenState();
}

class _LoginBodegueroScreenState extends State<LoginBodegueroScreen> {
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
      // 1. Verificar si el usuario está activo en Firestore
      final userQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('correo', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final bool estado = userData['estado'] as bool? ?? true;
        if (!estado) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Esta cuenta ha sido desactivada por el administrador.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef = FirebaseFirestore.instance.collection('bodegueros').doc(user.uid);
        final docSnap = await docRef.get();
        if (!docSnap.exists) {
          final localPart = email.split('@')[0];
          final nameParts = localPart.split('.');
          final formattedName = nameParts
              .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
              .join(' ');
          
          await docRef.set({
            'nombre': formattedName.isNotEmpty ? formattedName : 'Bodeguero',
            'correo': email,
            'fechaRegistro': DateTime.now().toIso8601String(),
            'ultimoAcceso': DateTime.now().toIso8601String(),
          });
        } else {
          await docRef.update({
            'ultimoAcceso': DateTime.now().toIso8601String(),
          });
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BodegueroDashboard(),
        ),
      );
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
            onPressed: () => PedidoProvider.mostrarConfiguracionLetra(context),
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
                          'Login Bodeguero',
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
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => _mostrarRecuperarContrasena(context),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrarBodegueroScreen(),
                          ),
                        );
                      },
                child: const Text(
                  '¿No tienes cuenta? Regístrate como Bodeguero aquí',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginAdminScreen(),
                            ),
                          );
                        }
                      },
                child: const Text(
                  '¿Eres Administrador? Iniciar sesión aquí',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarRecuperarContrasena(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        return AlertDialog(
          title: const Text('Recuperar Contraseña'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final mail = emailController.text.trim();
                if (mail.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: mail);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Correo de recuperación enviado exitosamente.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }
}
