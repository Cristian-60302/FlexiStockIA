import 'dart:convert';

import 'detalle_producto_screen.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CatalogoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const CatalogoScreen({super.key, required this.usuario});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  List<dynamic> _productos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  static const String _baseUrl = 'http://192.168.1.5:3000';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Extrae el id_empresa del usuario, si no existe usa '1' por defecto
    final idEmpresa = widget.usuario['id_empresa']?.toString() ?? '1';

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/productos?id_empresa=$idEmpresa'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _productos = data['productos'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar productos (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión. Revisa que el backend esté activo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarProductos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_productos.isEmpty) {
      return const Center(
        child: Text(
          'No hay productos registrados en esta empresa.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _productos.length,
      itemBuilder: (context, index) {
        final p = _productos[index];
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
            title: Text(
              p['nombre'] ?? 'Producto sin nombre',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marca: ${p['marca'] ?? 'N/A'} • Cat: ${p['categoria'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['descripcion'] ?? 'Sin descripción',
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF475569),
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleProductoScreen(producto: p),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
