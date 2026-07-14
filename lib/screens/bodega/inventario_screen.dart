import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_provider.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String _searchQuery = '';
  String _selectedZona = 'Todos';

  final List<String> _zonas = [
    'Todos',
    'Norte',
    'Sur',
    'Este',
    'Oeste',
    'Centro',
    'Sin Clasificar'
  ];

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Entregado':
        return Colors.green;
      case 'En Ruta':
        return Colors.blueAccent;
      case 'Asignado':
        return Colors.orange[800]!;
      case 'Pendiente':
      default:
        return Colors.orange;
    }
  }

  void _editarCajasDialog(BuildContext context, Pedido pedido) {
    final controller = TextEditingController(text: pedido.numeroCajas.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Editar Cajas: ${pedido.id}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${pedido.cliente}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de Cajas',
                    prefixIcon: Icon(Icons.inbox),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, ingresa una cantidad';
                    }
                    final n = int.tryParse(value);
                    if (n == null || n <= 0) {
                      return 'Ingresa un número entero mayor a 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final int nuevasCajas = int.parse(controller.text.trim());
                final pedidoActualizado = Pedido(
                  id: pedido.id,
                  cliente: pedido.cliente,
                  direccion: pedido.direccion,
                  prioridad: pedido.prioridad,
                  estado: pedido.estado,
                  numeroCajas: nuevasCajas,
                  zona: pedido.zona,
                );

                try {
                  // Actualizar en Firestore & local Provider
                  await Provider.of<PedidoProvider>(context, listen: false)
                      .actualizarPedido(pedidoActualizado);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cantidad de cajas para ${pedido.id} actualizada a $nuevasCajas.'),
                        backgroundColor: Colors.teal[600],
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar cajas: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneRow(String zona, int boxes, int totalInWarehouse) {
    final double percentage = totalInWarehouse > 0 ? boxes / totalInWarehouse : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              zona,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                color: Colors.purple[400],
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              '$boxes und (${(percentage * 100).toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Inventario de Cajas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent[700],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar inventario de Firestore.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final List<Pedido> todosPedidos = docs
              .map((doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          // Calculate counts
          int totalBodega = 0;
          int pendientes = 0;
          int asignados = 0;
          int enRuta = 0;

          // Zone box distribution
          final Map<String, int> zoneBoxes = {
            'Norte': 0,
            'Sur': 0,
            'Este': 0,
            'Oeste': 0,
            'Centro': 0,
            'Sin Clasificar': 0,
          };

          for (var p in todosPedidos) {
            if (p.estado == 'Pendiente') {
              totalBodega += p.numeroCajas;
              pendientes += p.numeroCajas;
              
              final String z = (p.zona == null || p.zona!.isEmpty) ? 'Sin Clasificar' : p.zona!;
              zoneBoxes[z] = (zoneBoxes[z] ?? 0) + p.numeroCajas;
            } else if (p.estado == 'Asignado') {
              totalBodega += p.numeroCajas;
              asignados += p.numeroCajas;

              final String z = (p.zona == null || p.zona!.isEmpty) ? 'Sin Clasificar' : p.zona!;
              zoneBoxes[z] = (zoneBoxes[z] ?? 0) + p.numeroCajas;
            } else if (p.estado == 'En Ruta') {
              enRuta += p.numeroCajas;
            }
          }

          // Filter warehouse list locally (states: Pendiente and Asignado)
          final filteredWarehouse = todosPedidos.where((p) {
            if (p.estado != 'Pendiente' && p.estado != 'Asignado') return false;

            final matchesSearch = p.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.cliente.toLowerCase().contains(_searchQuery.toLowerCase());

            final bool matchesZona;
            if (_selectedZona == 'Todos') {
              matchesZona = true;
            } else if (_selectedZona == 'Sin Clasificar') {
              matchesZona = p.zona == null || p.zona!.isEmpty;
            } else {
              matchesZona = p.zona == _selectedZona;
            }

            return matchesSearch && matchesZona;
          }).toList();

          return CustomScrollView(
            slivers: [
              // KPIs Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 12),
                  child: Row(
                    children: [
                      _buildKpiCard('Total Bodega', totalBodega, Icons.warehouse, Colors.blueAccent[700]!),
                      _buildKpiCard('Pendiente', pendientes, Icons.assignment_late, Colors.orange),
                      _buildKpiCard('Asignado', asignados, Icons.local_shipping, Colors.amber[800]!),
                      _buildKpiCard('En Ruta', enRuta, Icons.output, Colors.green),
                    ],
                  ),
                ),
              ),

              // Zone Distribution Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.public, color: Colors.purple, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Distribución de Cajas por Zona (En Bodega)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildZoneRow('Zona Norte', zoneBoxes['Norte'] ?? 0, totalBodega),
                          _buildZoneRow('Zona Sur', zoneBoxes['Sur'] ?? 0, totalBodega),
                          _buildZoneRow('Zona Centro', zoneBoxes['Centro'] ?? 0, totalBodega),
                          _buildZoneRow('Zona Este', zoneBoxes['Este'] ?? 0, totalBodega),
                          _buildZoneRow('Zona Oeste', zoneBoxes['Oeste'] ?? 0, totalBodega),
                          _buildZoneRow('Sin Clasificar', zoneBoxes['Sin Clasificar'] ?? 0, totalBodega),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Search & Filter Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pedidos Almacenados en Bodega',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Buscar por ID o Cliente...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedZona,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  items: _zonas.map((z) {
                                    return DropdownMenuItem(value: z, child: Text(z));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedZona = val!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // List of Orders
              filteredWarehouse.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No se encontraron pedidos en bodega.'),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final pedido = filteredWarehouse[index];
                            final stateColor = _getEstadoColor(pedido.estado);

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[50],
                                  child: Icon(Icons.inventory, color: Colors.blueAccent[700]),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      pedido.id,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: stateColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        pedido.estado,
                                        style: TextStyle(
                                          color: stateColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pedido.cliente,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Dir: ${pedido.direccion}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (pedido.zona != null && pedido.zona!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.public, size: 10, color: Colors.purple),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Zona: ${pedido.zona}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.purple,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Text(
                                        '${pedido.numeroCajas} ${pedido.numeroCajas == 1 ? 'caja' : 'cajas'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Toca para editar',
                                      style: TextStyle(fontSize: 8, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                onTap: () => _editarCajasDialog(context, pedido),
                              ),
                            );
                          },
                          childCount: filteredWarehouse.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
