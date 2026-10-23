import 'package:flutter/material.dart';

class VentaScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const VentaScreen({super.key, required this.usuario});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> {
  // Datos de prueba para el carrito
  final List<Map<String, dynamic>> _carrito = [
    {'nombre': 'Llave Ajustable 12 Pulgadas', 'precio': 25000.0, 'cantidad': 1},
    {
      'nombre': 'Rollo Cable Cobre THHN N° 12',
      'precio': 120000.0,
      'cantidad': 2,
    },
  ];

  double get _calcularTotal {
    return _carrito.fold(
      0,
      (suma, item) => suma + (item['precio'] * item['cantidad']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Encabezado
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Venta Rápida',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Lista de productos en el carrito
          Expanded(
            child: _carrito.isEmpty
                ? const Center(
                    child: Text(
                      'El carrito está vacío',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      final item = _carrito[index];
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            item['nombre'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '\$${item['precio']} x ${item['cantidad']}',
                            style: const TextStyle(color: Color(0xFF94A3B8)),
                          ),
                          trailing: Text(
                            '\$${item['precio'] * item['cantidad']}',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Panel inferior de cobro
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a cobrar:',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 18),
                    ),
                    Text(
                      '\$${_calcularTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Procesando pago...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF10B981,
                    ), // Verde para ventas
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.point_of_sale, color: Colors.white),
                  label: const Text(
                    'Cobrar Venta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
