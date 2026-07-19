import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido.dart';

class PedidoProvider with ChangeNotifier {
  final List<Pedido> _pedidos = [];
  bool _isDarkFont = true; // true for dark text (Light Theme), false for white text (Dark Theme)
  double _fontSizeFactor = 1.0; // 1.0 is default size

  List<Pedido> get pedidos => [..._pedidos];
  bool get isDarkFont => _isDarkFont;
  double get fontSizeFactor => _fontSizeFactor;

  void setFontColor(bool isDark) {
    _isDarkFont = isDark;
    notifyListeners();
  }

  void setFontSizeFactor(double factor) {
    _fontSizeFactor = factor;
    notifyListeners();
  }

  PedidoProvider() {
    _cargarPedidos();
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
    // Guardar en Firestore. El Stream listener de _cargarPedidos actualizará la lista local de forma segura y en tiempo real.
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedido.id)
        .set(pedido.toMap());
  }

  Future<void> actualizarPedido(Pedido pedido) async {
    // Guardar en Firestore. El Stream listener de _cargarPedidos actualizará la lista local de forma segura y en tiempo real.
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedido.id)
        .set(pedido.toMap());
  }

  Future<void> eliminarPedido(String id) async {
    // Eliminar en Firestore. El Stream listener de _cargarPedidos actualizará la lista local de forma segura y en tiempo real.
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(id)
        .delete();
  }
}
