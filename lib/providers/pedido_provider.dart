import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido.dart';

class PedidoProvider with ChangeNotifier {
  final List<Pedido> _pedidos = [];

  List<Pedido> get pedidos => [..._pedidos];

  Future<void> registrarPedido(Pedido pedido) async {
    // 1. Guardar localmente para respuesta inmediata de la UI
    _pedidos.add(pedido);
    notifyListeners();

    // 2. Intentar guardar en Firestore de forma asíncrona sin bloquear la UI
    FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedido.id)
        .set(pedido.toMap())
        .then((_) {
      debugPrint("Pedido guardado exitosamente en Firestore.");
    }).catchError((e) {
      debugPrint("Aviso: No se pudo guardar en Firestore ($e). El pedido se conserva en la sesión local.");
    });
  }

  void actualizarPedido(Pedido pedido) {
    // 1. Actualizar localmente
    final index = _pedidos.indexWhere((p) => p.id == pedido.id);
    if (index != -1) {
      _pedidos[index] = pedido;
      notifyListeners();
    }

    // 2. Actualizar en Firestore de forma asíncrona sin bloquear la UI
    FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedido.id)
        .set(pedido.toMap())
        .then((_) {
      debugPrint("Pedido actualizado exitosamente en Firestore.");
    }).catchError((e) {
      debugPrint("Aviso: No se pudo actualizar en Firestore ($e).");
    });
  }

  void eliminarPedido(String id) {
    // 1. Eliminar localmente
    _pedidos.removeWhere((p) => p.id == id);
    notifyListeners();

    // 2. Eliminar en Firestore de forma asíncrona sin bloquear la UI
    FirebaseFirestore.instance
        .collection('pedidos')
        .doc(id)
        .delete()
        .then((_) {
      debugPrint("Pedido eliminado exitosamente en Firestore.");
    }).catchError((e) {
      debugPrint("Aviso: No se pudo eliminar en Firestore ($e).");
    });
  }
}
