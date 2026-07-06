import 'package:flutter/material.dart';

class ConductorDashboard extends StatelessWidget {
  const ConductorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Conductor'),
      ),
      body: const Center(
        child: Text(
          'Bienvenido Conductor',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
