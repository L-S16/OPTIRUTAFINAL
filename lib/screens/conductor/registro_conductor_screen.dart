import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroConductorScreen extends StatefulWidget {
  const RegistroConductorScreen({super.key});

  @override
  State<RegistroConductorScreen> createState() => _RegistroConductorScreenState();
}

class _RegistroConductorScreenState extends State<RegistroConductorScreen> {
  final _correoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _tipoLicencia = 'Tipo B';
  bool _isLoading = false;
  String _errorMessage = '';

  final List<String> _licencias = [
    'Tipo A', 'Tipo B', 'Tipo A1', 'Tipo C', 'Tipo C1', 'Tipo D', 'Tipo E', 'Tipo F', 'Tipo G'
  ];

  Future<void> _registrar() async {
    if (_correoController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa correo y contraseña.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      await userCredential.user?.updateDisplayName(
        '${_nombreController.text.trim()} ${_apellidoController.text.trim()}'.trim()
      );
      
      // Guardar información en Firestore
      await FirebaseFirestore.instance.collection('conductores').doc(userCredential.user!.uid).set({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'tipoLicencia': _tipoLicencia,
        'correo': _correoController.text.trim(),
        'fechaRegistro': DateTime.now().toIso8601String(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conductor registrado exitosamente')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'El correo ya está registrado.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'La contraseña es muy débil (mínimo 6 caracteres).';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'El formato del correo es inválido.';
        } else {
          _errorMessage = 'Error al registrar (Auth): ${e.code}';
        }
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Error de Base de Datos: ${e.code} - ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error exacto: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Conductor'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.person_add,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nuevo Conductor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage.isNotEmpty) ...[
                Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              
              // Dropdown para Tipo de Licencia
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _tipoLicencia,
                    icon: const Icon(Icons.arrow_drop_down),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _tipoLicencia = newValue;
                        });
                      }
                    },
                    items: _licencias.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            const Icon(Icons.card_membership, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(value),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (mínimo 6 caracteres)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registrar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Registrar',
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

