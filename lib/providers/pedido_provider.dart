import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido.dart';

class PedidoProvider with ChangeNotifier {
  final List<Pedido> _pedidos = [];

  List<Pedido> get pedidos => [..._pedidos];

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
    // Intentar guardar en Firestore primero. Si falla, el error se propaga.
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedido.id)
        .set(pedido.toMap());
    
    // Guardar localmente
    _pedidos.add(pedido);
    notifyListeners();
  }

  Future<void> actualizarPedido(Pedido pedido) async {
    // Intentar guardar en Firestore primero. Si falla, el error se propaga.
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedido.id)
        .set(pedido.toMap());

    // Actualizar localmente
    final index = _pedidos.indexWhere((p) => p.id == pedido.id);
    if (index != -1) {
      _pedidos[index] = pedido;
      notifyListeners();
    }
  }

  Future<void> eliminarPedido(String id) async {
    // Intentar eliminar en Firestore primero. Si falla, el error se propaga.
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(id)
        .delete();

    // Eliminar localmente
    _pedidos.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
