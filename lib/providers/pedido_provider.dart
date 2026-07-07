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

    // 2. Intentar guardar en Firestore (seguro contra fallos de inicialización)
    try {
      await FirebaseFirestore.instance.collection('pedidos').doc(pedido.id).set(pedido.toMap());
      debugPrint("Pedido guardado exitosamente en Firestore.");
    } catch (e) {
      debugPrint("Aviso: No se pudo guardar en Firestore ($e). El pedido se conserva en la sesión local.");
    }
  }
}
