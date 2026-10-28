import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DetalleProductoScreen extends StatefulWidget {
  final Map<String, dynamic> producto;

  const DetalleProductoScreen({super.key, required this.producto});

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  String _estadoSeleccionado = 'Disponible';
  bool _isSubmitting = false;
  static const String _baseUrl = 'http://172.41.131.147:3000';

  Future<void> _agregarUnidadAlInventario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/inventario'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_producto': widget.producto['id_producto'],
              'codigo': _codigoController.text.trim(),
              'estado': _estadoSeleccionado,
              'ubicacion': _ubicacionController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unidad agregada al inventario'),
            backgroundColor: Colors.green,
          ),
        );
        _codigoController.clear();
        _ubicacionController.clear();
      } else {
        _mostrarError(data['error'] ?? 'Error al agregar unidad');
      }
    } catch (e) {
      _mostrarError('Error de conexión con el servidor.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.producto['nombre'] ?? 'Producto';
    final marca = widget.producto['marca'] ?? 'Sin marca';

    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info del producto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marca: $marca',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.producto['descripcion'] ?? '',
                    style: const TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Ingresar nueva unidad física',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Formulario de inventario
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _codigoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Código de Barras / Serial',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: const Icon(
                        Icons.qr_code_scanner,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingresa un código' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _ubicacionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Ubicación (Ej: Pasillo 3, Estante B)',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _estadoSeleccionado,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['Disponible', 'Prestado', 'Dañado'].map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text(estado),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _estadoSeleccionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : _agregarUnidadAlInventario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Registrar Unidad',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
