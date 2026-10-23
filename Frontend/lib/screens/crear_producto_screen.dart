import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CrearProductoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const CrearProductoScreen({super.key, required this.usuario});

  @override
  State<CrearProductoScreen> createState() => _CrearProductoScreenState();
}

class _CrearProductoScreenState extends State<CrearProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _idCategoriaController = TextEditingController(
    text: '1',
  );

  bool _isSubmitting = false;
  static const String _baseUrl = 'http://192.168.1.5:3000';

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final idEmpresa = widget.usuario['id_empresa'] ?? 1;

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/productos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_empresa': idEmpresa,
              'nombre': _nombreController.text.trim(),
              'descripcion': _descripcionController.text.trim(),
              'marca': _marcaController.text.trim(),
              'id_categoria': int.tryParse(_idCategoriaController.text) ?? 1,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para avisar que se guardó
      } else {
        _mostrarError(data['error'] ?? 'Error al guardar el producto');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Producto'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre del producto',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _marcaController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Marca',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _idCategoriaController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'ID Categoría',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Ingresa un ID válido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _guardarProducto,
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
                        'Guardar Producto',
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
      ),
    );
  }
}
