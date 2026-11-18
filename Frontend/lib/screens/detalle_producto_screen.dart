import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

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

  late Map<String, dynamic> _productoActual;
  String _estadoSeleccionado = 'Disponible';
  bool _isLoadingDetalle = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _productoActual = Map<String, dynamic>.from(widget.producto);
    _cargarDetalleProducto();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarDetalleProducto() async {
    final int? idProducto = int.tryParse(
      _productoActual['id_producto']?.toString() ?? '',
    );
    if (idProducto == null) {
      setState(() => _isLoadingDetalle = false);
      return;
    }

    final res = await ApiService.obtenerProductoPorId(idProducto: idProducto);
    if (!mounted) return;

    setState(() {
      if (res['statusCode'] == 200 && res['data']['producto'] != null) {
        _productoActual = Map<String, dynamic>.from(res['data']['producto']);
      }
      _isLoadingDetalle = false;
    });
  }

  Future<void> _agregarUnidadAlInventario() async {
    if (!_formKey.currentState!.validate()) return;

    final int? idProducto = int.tryParse(
      _productoActual['id_producto']?.toString() ?? '',
    );
    if (idProducto == null) {
      _mostrarError('ID de producto inválido.');
      return;
    }

    setState(() => _isSubmitting = true);

    final String ubicacion = _ubicacionController.text.trim();
    final res = await ApiService.registrarInventario(
      idProducto: idProducto,
      codigo: _codigoController.text.trim(),
      estado: _estadoSeleccionado,
      ubicacion: ubicacion.isEmpty ? null : ubicacion,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (res['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unidad agregada al inventario'),
          backgroundColor: Colors.green,
        ),
      );
      _codigoController.clear();
      _ubicacionController.clear();
      _cargarDetalleProducto();
    } else {
      _mostrarError(res['data']['error'] ?? 'Error al agregar unidad');
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
    final nombre = _productoActual['nombre'] ?? 'Producto';
    final marca = _productoActual['marca'] ?? 'Sin marca';
    final categoria = _productoActual['categoria'] ?? 'Sin categoría';
    final descripcion = _productoActual['descripcion']?.toString() ?? '';
    final unidadesDisponibles = _productoActual['unidades_disponibles'];

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
            // Ficha del producto (GET /productos/<id_producto>)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Marca: $marca • Cat: $categoria',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isLoadingDetalle)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (unidadesDisponibles != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$unidadesDisponibles disp.',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (descripcion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      descripcion,
                      style: const TextStyle(color: Color(0xFFCBD5E1)),
                    ),
                  ],
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

            // Formulario de inventario (POST /inventario)
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
                        (value == null || value.trim().isEmpty)
                        ? 'Ingresa un código'
                        : null,
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
                      if (value != null) {
                        setState(() => _estadoSeleccionado = value);
                      }
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
