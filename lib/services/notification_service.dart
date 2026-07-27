import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/conductor/ver_ruta_asignada_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  StreamSubscription<QuerySnapshot>? _deliveriesSubscription;
  bool _isInitialized = false;
  
  // Guardamos un set de las rutas que el conductor ya conoce para no duplicar alertas
  final Set<String> _knownRouteIds = {};

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. Solicitar permisos de notificación
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!context.mounted) return;

      debugPrint('User granted notification permission: ${settings.authorizationStatus}');

      // 2. Obtener FCM Token y guardarlo en Firestore
      await updateFcmToken();
      if (!context.mounted) return;

      // 3. Configurar listeners de mensajes de primer plano (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (!context.mounted) return;
        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification?.title}');
          _showInAppNotification(
            context,
            message.notification?.title ?? 'Notificación',
            message.notification?.body ?? '',
            routeId: message.data['routeId'],
            routeData: message.data,
          );
        }
      });

      // 4. Configurar listener de cuando abren la app desde una notificación (Background/Terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Message clicked!');
        if (!context.mounted) return;
        _navigateNotification(context, message.data['routeId'], message.data);
      });

      // 5. Verificar si la app se abrió desde una notificación terminada
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (!context.mounted) return;
      if (initialMessage != null) {
        _navigateNotification(context, initialMessage.data['routeId'], initialMessage.data);
      }

      // 6. Iniciar el listener en tiempo real de Firestore para notificaciones en vivo
      _startLiveRouteListener(context);

    } catch (e) {
      debugPrint("Error initializing NotificationService: $e");
    }
  }

  Future<void> updateFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        // Guardar token en 'usuarios' y 'conductores'
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }).catchError((_) {});

        await FirebaseFirestore.instance.collection('conductores').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }
    } catch (e) {
      debugPrint("Error updating FCM token in Firestore: $e");
    }
  }

  void _startLiveRouteListener(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _deliveriesSubscription?.cancel();

    // Consultamos las rutas activas asignadas a este conductor
    _deliveriesSubscription = FirebaseFirestore.instance
        .collection('entregas')
        .where('conductorId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      
      // La primera vez que carga, solo guardamos las rutas existentes en el set de conocidas
      bool isFirstLoad = _knownRouteIds.isEmpty && snapshot.docs.isNotEmpty;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final routeId = doc.id;
        final estado = data['estado'] ?? 'Pendiente';
        final numRuta = data['numeroRuta'] ?? 'Desconocida';

        if (isFirstLoad) {
          _knownRouteIds.add(routeId);
          continue;
        }

        // Si es una ruta nueva o cambió a un estado activo y no la teníamos registrada
        if (!_knownRouteIds.contains(routeId) && (estado == 'Pendiente' || estado == 'Reprogramado' || estado == 'En Ruta')) {
          _knownRouteIds.add(routeId);
          
          if (!context.mounted) return;
          // Lanzar la notificación local
          _showInAppNotification(
            context,
            '¡Nueva Ruta Asignada!',
            'Se te ha asignado la Ruta #$numRuta. Toca para ver los detalles.',
            routeId: routeId,
            routeData: data,
          );
        }
      }
    });
  }

  void _showInAppNotification(
    BuildContext context,
    String title,
    String body, {
    String? routeId,
    Map<String, dynamic>? routeData,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            if (routeId != null) {
              _navigateNotification(context, routeId, routeData);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A), // Azul oscuro premium
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 7),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateNotification(BuildContext context, String? routeId, Map<String, dynamic>? routeData) {
    if (routeId == null) return;
    
    // Si no se proporcionaron datos de la ruta, los consultamos de Firestore antes de navegar
    if (routeData == null || routeData.isEmpty) {
      FirebaseFirestore.instance.collection('entregas').doc(routeId).get().then((doc) {
        if (!context.mounted) return;
        if (doc.exists && doc.data() != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerRutaAsignadaScreen(
                routeId: routeId,
                routeData: doc.data()!,
              ),
            ),
          );
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerRutaAsignadaScreen(
            routeId: routeId,
            routeData: routeData,
          ),
        ),
      );
    }
  }

  void dispose() {
    _deliveriesSubscription?.cancel();
    _isInitialized = false;
    _knownRouteIds.clear();
  }
}
