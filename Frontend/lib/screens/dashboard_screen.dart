import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const DashboardScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FlexiStock - ${usuario['empresa'] ?? 'Mi Negocio'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola, ${usuario['nombre']}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Correo: ${usuario['correo']}',
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.inventory, size: 80, color: Color(0xFF2563EB)),
                    SizedBox(height: 16),
                    Text(
                      'Módulo de Inventario en construcción',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
