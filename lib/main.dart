import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/pedido_provider.dart';
import 'screens/admin/login_admin_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PedidoProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginAdminScreen(),
    );
  }
}