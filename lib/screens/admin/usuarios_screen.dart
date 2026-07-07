import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _correoController = TextEditingController();

  final List<String> _roles = [
    'Administrador',
    'Bodeguero',
    'Conductor',
  ];

  String _rolSeleccionado = 'Conductor';

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'rol': _rolSeleccionado,
        'estado': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario registrado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar usuario: $e'),
        ),
      );
    }
  }

  Future<void> _editarUsuario(String id) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(id).update({
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'rol': _rolSeleccionado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario actualizado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar usuario: $e'),
        ),
      );
    }
  }

  Future<void> _cambiarEstadoUsuario({
    required String id,
    required bool nuevoEstado,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(id).update({
        'estado': nuevoEstado,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      final mensaje = nuevoEstado
          ? 'Usuario activado correctamente'
          : 'Usuario desactivado correctamente';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
        ),
      );
    }
  }

  void _mostrarFormularioCrear() {
    _nombreController.clear();
    _correoController.clear();
    _rolSeleccionado = 'Conductor';

    _mostrarFormulario(
      titulo: 'Crear usuario',
      textoBoton: 'Guardar',
      iconoBoton: Icons.save,
      accion: _guardarUsuario,
    );
  }

  void _mostrarFormularioEditar({
    required String id,
    required String nombre,
    required String correo,
    required String rol,
  }) {
    _nombreController.text = nombre;
    _correoController.text = correo;

    if (_roles.contains(rol)) {
      _rolSeleccionado = rol;
    } else {
      _rolSeleccionado = 'Conductor';
    }

    _mostrarFormulario(
      titulo: 'Editar usuario',
      textoBoton: 'Actualizar',
      iconoBoton: Icons.edit,
      accion: () => _editarUsuario(id),
    );
  }

  void _mostrarFormulario({
    required String titulo,
    required String textoBoton,
    required IconData iconoBoton,
    required Future<void> Function() accion,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(titulo),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el nombre';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el correo';
                          }

                          if (!value.contains('@')) {
                            return 'Ingrese un correo válido';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _rolSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                        ),
                        items: _roles.map((rol) {
                          return DropdownMenuItem<String>(
                            value: rol,
                            child: Text(rol),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              _rolSeleccionado = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: accion,
                  icon: Icon(iconoBoton),
                  label: Text(textoBoton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _construirListaUsuarios() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error al cargar los usuarios'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final usuarios = snapshot.data!.docs;

        if (usuarios.isEmpty) {
          return const Center(
            child: Text(
              'No existen usuarios registrados',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final documento = usuarios[index];

            final datos = documento.data() as Map<String, dynamic>;

            final nombre = datos['nombre']?.toString() ?? 'Sin nombre';

            final correo = datos['correo']?.toString() ?? 'Sin correo';

            final rol = datos['rol']?.toString() ?? 'Sin rol';

            final bool estado = datos['estado'] as bool? ?? true;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: estado ? Colors.green : Colors.grey,
                  child: Icon(
                    estado ? Icons.person : Icons.person_off,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: estado ? Colors.black : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  '$correo\n'
                  'Rol: $rol\n'
                  'Estado: ${estado ? 'Activo' : 'Inactivo'}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: estado,
                      onChanged: (nuevoEstado) {
                        _cambiarEstadoUsuario(
                          id: documento.id,
                          nuevoEstado: nuevoEstado,
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Editar usuario',
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _mostrarFormularioEditar(
                          id: documento.id,
                          nombre: nombre,
                          correo: correo,
                          rol: rol,
                        );
                      },
                    ),
                  ],
                ),
              ),
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
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _construirListaUsuarios(),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioCrear,
        tooltip: 'Crear usuario',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
