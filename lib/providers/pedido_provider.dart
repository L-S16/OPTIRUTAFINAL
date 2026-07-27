import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/pedido.dart';

class PedidoProvider with ChangeNotifier {
  final List<Pedido> _pedidos = [];
  bool _isDarkFont = true; // true for dark text (Light Theme), false for white text (Dark Theme)
  double _fontSizeFactor = 1.0; // 1.0 is default size

  List<Pedido> get pedidos => [..._pedidos];
  bool get isDarkFont => _isDarkFont;
  double get fontSizeFactor => _fontSizeFactor;

  PedidoProvider() {
    _cargarPreferencias();
    _cargarPedidos();
  }

  Future<void> _cargarPreferencias() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkFont = prefs.getBool('isDarkFont') ?? true;
      double factor = prefs.getDouble('fontSizeFactor') ?? 1.0;
      if (factor > 1.75) {
        factor = 1.75;
      }
      _fontSizeFactor = factor;
      notifyListeners();
    } catch (e) {
      debugPrint("Error al cargar preferencias: $e");
    }
  }

  Future<void> setFontColor(bool isDark) async {
    _isDarkFont = isDark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkFont', isDark);
    } catch (e) {
      debugPrint("Error al guardar tema: $e");
    }
  }

  Future<void> setFontSizeFactor(double factor) async {
    _fontSizeFactor = factor;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontSizeFactor', factor);
    } catch (e) {
      debugPrint("Error al guardar escala tipográfica: $e");
    }
  }

  void _cargarPedidos() {
    FirebaseFirestore.instance
        .collection('pedidos')
        .snapshots()
        .listen((snapshot) {
      _pedidos.clear();
      for (var doc in snapshot.docs) {
        _pedidos.add(Pedido.fromMap(doc.data()));
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error al escuchar pedidos de Firestore: $e");
    });
  }

  Future<void> registrarPedido(Pedido pedido) async {
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedido.id)
        .set(pedido.toMap());
  }

  Future<void> actualizarPedido(Pedido pedido) async {
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedido.id)
        .set(pedido.toMap());
  }

  Future<void> eliminarPedido(String id) async {
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(id)
        .delete();
  }

  static void mostrarConfiguracionLetra(BuildContext context) {
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
                    child: Text('Tamaño de Letra e Iconos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<double>(
                    value: provider.fontSizeFactor > 1.75 ? 1.75 : provider.fontSizeFactor,
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
                      DropdownMenuItem(
                        value: 1.5,
                        child: Text('Muy Grande'),
                      ),
                      DropdownMenuItem(
                        value: 1.75,
                        child: Text('Extra Grande'),
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
}
