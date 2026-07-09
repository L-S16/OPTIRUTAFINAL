import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConductoresScreen extends StatefulWidget {
  const ConductoresScreen({super.key});

  @override
  State<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends State<ConductoresScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Conductores',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent[700],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar conductor...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
              builder: (context, usuariosSnapshot) {
                // Crear un mapeo de estados de usuarios (Activo / Inactivo) por correo electrónico
                final Map<String, bool> estadosPorCorreo = {};
                if (usuariosSnapshot.hasData) {
                  for (var doc in usuariosSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final correo = data['correo']?.toString().toLowerCase().trim() ?? '';
                    final estado = data['estado'] as bool? ?? true;
                    if (correo.isNotEmpty) {
                      estadosPorCorreo[correo] = estado;
                    }
                  }
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('conductores').snapshots(),
                  builder: (context, conductoresSnapshot) {
                    if (conductoresSnapshot.hasError) {
                      return const Center(child: Text('Error al cargar la información de conductores.'));
                    }
                    
                    if (conductoresSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final list = conductoresSnapshot.data?.docs ?? [];
                    
                    // Filtrar localmente según búsqueda
                    final filteredList = list.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                      final apellido = (data['apellido'] ?? '').toString().toLowerCase();
                      final correo = (data['correo'] ?? '').toString().toLowerCase();
                      final nombreCompleto = '$nombre $apellido';
                      
                      return nombreCompleto.contains(_searchQuery) || correo.contains(_searchQuery);
                    }).toList();

                    if (filteredList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 70, color: Colors.grey[400]),
                            const SizedBox(height: 15),
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'No hay conductores registrados' 
                                  : 'No se encontraron resultados',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final doc = filteredList[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        final nombre = data['nombre'] ?? '';
                        final apellido = data['apellido'] ?? '';
                        final nombreCompleto = '$nombre $apellido'.trim();
                        final correo = data['correo'] ?? 'Sin correo';
                        final telefono = data['telefono'] ?? 'Sin teléfono';
                        final tipoLicencia = data['tipoLicencia'] ?? 'Sin licencia';
                        
                        // Validar estado cruzando correos (por defecto true si no está registrado en usuarios)
                        final bool activo = estadosPorCorreo[correo.toString().toLowerCase().trim()] ?? true;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Avatar lateral con color de estado
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: activo ? Colors.green[50] : Colors.grey[100],
                                  child: Icon(
                                    Icons.local_shipping,
                                    color: activo ? Colors.green[700] : Colors.grey[600],
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Detalles
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombreCompleto.isNotEmpty ? nombreCompleto : 'Conductor sin nombre',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: activo ? Colors.black87 : Colors.grey[600],
                                          decoration: activo ? null : TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.email, size: 14, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              correo,
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                            telefono,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.badge, size: 14, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Licencia: $tipoLicencia',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Indicador de estado visual
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: activo ? Colors.green[50] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    activo ? 'Activo' : 'Inactivo',
                                    style: TextStyle(
                                      color: activo ? Colors.green[700] : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
