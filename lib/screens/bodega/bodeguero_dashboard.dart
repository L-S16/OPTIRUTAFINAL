import 'package:flutter/material.dart';

class BodegueroDashboard extends StatelessWidget {
  const BodegueroDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Bodeguero'),
      ),
      body: const Center(
        child: Text(
          'Bienvenido Bodeguero',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
