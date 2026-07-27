import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_provider.dart';
import 'registrar_pedido.dart';
import 'editar_pedido.dart';
import 'clasificar_pedidos.dart';
import 'asignar_conductor_screen.dart';
import 'confirmar_carga_screen.dart';
import 'inventario_screen.dart';
import '../welcome_screen.dart';

class BodegueroDashboard extends StatefulWidget {
  const BodegueroDashboard({super.key});

  @override
  State<BodegueroDashboard> createState() => _BodegueroDashboardState();
}

class _BodegueroDashboardState extends State<BodegueroDashboard> {
  String _searchQuery = '';
  String _selectedEstado = 'Todos';
  String _selectedPrioridad = 'Todos';
  String _selectedZona = 'Todos';

  final List<String> _estados = ['Todos', 'Pendiente', 'Asignado', 'En Ruta', 'Entregado'];
  final List<String> _prioridades = ['Todos', 'Alta', 'Media', 'Baja'];
  final List<String> _zonas = ['Todos', 'Norte', 'Sur', 'Este', 'Oeste', 'Centro', 'Sin Clasificar'];

  bool _esReciente(dynamic p) {
    DateTime? dt;
    if (p.fechaCreacion != null && (p.fechaCreacion as String).isNotEmpty) {
      dt = DateTime.tryParse(p.fechaCreacion as String);
    }
    if (dt == null && (p.id as String).startsWith('PED-')) {
      final msStr = (p.id as String).replaceFirst('PED-', '');
      final ms = int.tryParse(msStr);
      if (ms != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    if (dt == null) return false;
    final diff = DateTime.now().difference(dt);
    return diff.inHours < 24 && !diff.isNegative;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Alta':
        return Colors.redAccent;
      case 'Media':
        return Colors.amber[700]!;
      case 'Baja':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _mostrarConfirmacionEliminar(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este pedido? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<PedidoProvider>(context, listen: false).eliminarPedido(id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pedido $id eliminado exitosamente'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 13, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildZonaChip(String zona) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purple[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.public, size: 10, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            zona,
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Dashboard Bodeguero',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Configuración Visual',
              onPressed: () => PedidoProvider.mostrarConfiguracionLetra(context),
            ),
          Consumer<PedidoProvider>(
            builder: (context, provider, child) {
              final asignadosCount = provider.pedidos.where((p) => p.estado == 'Asignado').length;
              return Badge(
                label: Text(
                  '$asignadosCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                isLabelVisible: asignadosCount > 0,
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.playlist_add_check),
                  tooltip: 'Checklist de Carga ($asignadosCount pendientes)',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfirmarCargaScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Clasificar por Zona',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClasificarPedidosScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2),
            tooltip: 'Ver Inventario',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InventarioScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
            onPressed: () => _mostrarConfirmacionSalir(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Buscar por ID o Cliente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                        }),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          // Banner de Notificación Instantánea de Carga Pendiente
          Consumer<PedidoProvider>(
            builder: (context, provider, _) {
              final asignadosCount = provider.pedidos.where((p) => p.estado == 'Asignado').length;
              if (asignadosCount == 0) return const SizedBox.shrink();

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConfirmarCargaScreen(),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[800]!, Colors.amber[700]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔔 ¡TIENES $asignadosCount PEDIDO${asignadosCount > 1 ? 'S' : ''} PENDIENTES DE CARGAR!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Toca aquí para ir al Checklist y cargar las cajas al camión al instante.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          // Fila de Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    value: _selectedEstado,
                    items: _estados,
                    label: 'Estado',
                    icon: Icons.info_outline,
                    onChanged: (val) => setState(() => _selectedEstado = val!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterDropdown(
                    value: _selectedPrioridad,
                    items: _prioridades,
                    label: 'Prioridad',
                    icon: Icons.flag_outlined,
                    onChanged: (val) => setState(() => _selectedPrioridad = val!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterDropdown(
                    value: _selectedZona,
                    items: _zonas,
                    label: 'Zona',
                    icon: Icons.public_outlined,
                    onChanged: (val) => setState(() => _selectedZona = val!),
                  ),
                ),
              ],
            ),
          ),
          // Listado de Pedidos
          Expanded(
            child: Consumer<PedidoProvider>(
              builder: (context, provider, child) {
                final pedidos = provider.pedidos;

                if (pedidos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_late_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No hay pedidos registrados',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Presiona el botón "Registrar Pedido" para ingresar una nueva orden de despacho.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Filtrar localmente
                final filteredPedidos = pedidos.where((pedido) {
                  final matchesSearch = pedido.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      pedido.cliente.toLowerCase().contains(_searchQuery.toLowerCase());

                  final matchesEstado = _selectedEstado == 'Todos' || pedido.estado == _selectedEstado;

                  final matchesPrioridad = _selectedPrioridad == 'Todos' || pedido.prioridad == _selectedPrioridad;

                  final bool matchesZona;
                  if (_selectedZona == 'Todos') {
                    matchesZona = true;
                  } else if (_selectedZona == 'Sin Clasificar') {
                    matchesZona = pedido.zona == null || pedido.zona!.isEmpty;
                  } else {
                    matchesZona = pedido.zona == _selectedZona;
                  }

                  return matchesSearch && matchesEstado && matchesPrioridad && matchesZona;
                }).toList();

                final pedidosRecientes = <Pedido>[];
                final pedidosAntiguos = <Pedido>[];

                for (var p in filteredPedidos) {
                  if (_esReciente(p)) {
                    pedidosRecientes.add(p);
                  } else {
                    pedidosAntiguos.add(p);
                  }
                }

                int compareDesc(Pedido a, Pedido b) {
                  if (a.fechaCreacion != null && b.fechaCreacion != null) {
                    return b.fechaCreacion!.compareTo(a.fechaCreacion!);
                  }
                  return b.id.compareTo(a.id);
                }

                pedidosRecientes.sort(compareDesc);
                pedidosAntiguos.sort(compareDesc);

                final listItems = <dynamic>[];

                if (pedidosRecientes.isNotEmpty) {
                  listItems.add(_SectionHeaderData(
                    title: 'Recientes',
                    icon: Icons.access_time_filled,
                    color: Colors.green[700]!,
                    count: pedidosRecientes.length,
                  ));
                  listItems.addAll(pedidosRecientes);
                }

                if (pedidosAntiguos.isNotEmpty) {
                  listItems.add(_SectionHeaderData(
                    title: 'Antiguos',
                    icon: Icons.history,
                    color: Colors.blueGrey[700]!,
                    count: pedidosAntiguos.length,
                  ));
                  listItems.addAll(pedidosAntiguos);
                }

                if (listItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 70,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Sin resultados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Prueba ajustando los filtros o la búsqueda.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 84),
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    final item = listItems[index];

                    if (item is _SectionHeaderData) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 10.0, left: 4.0, right: 4.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item.icon, size: 16, color: item.color),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${item.count}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: item.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final pedido = item as Pedido;
                    final priorityColor = _getPriorityColor(pedido.prioridad);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Indicador lateral de prioridad
                            Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: priorityColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Fila de ID, Estado y Menú de Opciones
                                    Row(
                                      children: [
                                        Text(
                                          pedido.id,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: pedido.estado == 'Entregado'
                                                ? Colors.green[50]
                                                : pedido.estado == 'En Ruta'
                                                    ? Colors.blue[50]
                                                    : pedido.estado == 'Asignado'
                                                        ? Colors.orange[50]
                                                        : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            pedido.estado,
                                            style: TextStyle(
                                              color: pedido.estado == 'Entregado'
                                                  ? Colors.green[700]
                                                  : pedido.estado == 'En Ruta'
                                                      ? Colors.blue[700]
                                                      : pedido.estado == 'Asignado'
                                                          ? Colors.orange[800]
                                                          : Colors.grey[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onSelected: (value) {
                                            if (value == 'editar') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditarPedidoScreen(pedido: pedido),
                                                ),
                                              );
                                            } else if (value == 'eliminar') {
                                              _mostrarConfirmacionEliminar(pedido.id);
                                            } else if (value == 'asignar') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AsignarConductorScreen(pedido: pedido),
                                                ),
                                              );
                                            } else if (value == 'confirmar_carga') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const ConfirmarCargaScreen(),
                                                ),
                                              );
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => [
                                            const PopupMenuItem(
                                              value: 'editar',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                                                  SizedBox(width: 8),
                                                  Text('Editar'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'eliminar',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                                  SizedBox(width: 8),
                                                  Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                                                ],
                                              ),
                                            ),
                                            if (pedido.estado == 'Pendiente')
                                              const PopupMenuItem(
                                                value: 'asignar',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.local_shipping, size: 18, color: Colors.teal),
                                                    SizedBox(width: 8),
                                                    Text('Asignar Conductor'),
                                                  ],
                                                ),
                                              ),
                                            if (pedido.estado == 'Asignado')
                                              const PopupMenuItem(
                                                value: 'confirmar_carga',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.playlist_add_check, size: 18, color: Colors.orange),
                                                    SizedBox(width: 8),
                                                    Text('Confirmar Carga'),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Cliente
                                    Text(
                                      pedido.cliente,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // Dirección
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            pedido.direccion,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Fila inferior: cajas, prioridad y zona
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Cajas
                                        Row(
                                          children: [
                                            const Icon(Icons.inbox, size: 18, color: Colors.blueAccent),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${pedido.numeroCajas} ${pedido.numeroCajas == 1 ? 'caja' : 'cajas'}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Prioridad & Zona Chips
                                        Flexible(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: priorityColor.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: priorityColor.withValues(alpha: 0.5),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          color: priorityColor,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Prioridad ${pedido.prioridad}',
                                                        style: TextStyle(
                                                          color: priorityColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (pedido.zona != null && pedido.zona!.isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  _buildZonaChip(pedido.zona!),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                     if (pedido.estado == 'Asignado') ...[
                                       const SizedBox(height: 14),
                                       Container(
                                         width: double.infinity,
                                         decoration: BoxDecoration(
                                           gradient: LinearGradient(
                                             colors: [Colors.orange[800]!, Colors.amber[700]!],
                                           ),
                                           borderRadius: BorderRadius.circular(12),
                                           boxShadow: [
                                             BoxShadow(
                                               color: Colors.orange.withValues(alpha: 0.3),
                                               blurRadius: 6,
                                               offset: const Offset(0, 3),
                                             ),
                                           ],
                                         ),
                                         child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const ConfirmarCargaScreen(),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.inventory_2, size: 20, color: Colors.white),
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'Cargar Cajas Ahora',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Colors.white,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrarPedidoScreen(),
            ),
          );
        },
        backgroundColor: Colors.blueAccent[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Registrar Pedido',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}
}

class _SectionHeaderData {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  _SectionHeaderData({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });
}

