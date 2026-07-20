import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      _fontSizeFactor = prefs.getDouble('fontSizeFactor') ?? 1.0;
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
}
