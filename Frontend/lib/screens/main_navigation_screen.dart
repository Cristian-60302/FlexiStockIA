import 'package:flutter/material.dart';

import 'reportes_screen.dart';
import 'venta_screen.dart';
import 'escaner_screen.dart';
import 'crear_producto_screen.dart';
import 'dashboard_screen.dart';
import 'catalogo_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const MainNavigationScreen({super.key, required this.usuario});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(usuario: widget.usuario),
      CatalogoScreen(usuario: widget.usuario), // Reemplaza el Center de texto
      VentaScreen(usuario: widget.usuario),
      EscanerScreen(usuario: widget.usuario),
      ReportesScreen(usuario: widget.usuario),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FlexiStock - ${widget.usuario['empresa'] ?? 'Mi Negocio'}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CrearProductoScreen(usuario: widget.usuario),
                  ),
                );

                // Si se creó el producto exitosamente, podrías recargar la vista actual aquí
                if (result == true) {
                  setState(() {});
                }
              },
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nuevo', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_rounded),
            label: 'Venta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Escáner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
