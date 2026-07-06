import 'package:flutter/material.dart';
import 'screens/conductor/login_conductor_screen.dart';

void main() {
  runApp(const MyAppTest());
}

class MyAppTest extends StatelessWidget {
  const MyAppTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prueba Conductor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginConductorScreen(),
    );
  }
}
