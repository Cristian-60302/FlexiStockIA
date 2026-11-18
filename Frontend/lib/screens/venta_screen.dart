import 'package:flutter/material.dart';
import 'package:frontend/screens/scanner_screen.dart';
import 'package:frontend/services/api_service.dart';

class VentaScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const VentaScreen({super.key, required this.usuario});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> {
  final List<Map<String, dynamic>> _carrito = [];
  List<dynamic> _disponibles = [];
  bool _cargandoInventario = false;
  bool _procesandoVenta = false;

  int get _idEmpresa =>
      int.tryParse(widget.usuario['id_empresa']?.toString() ?? '1') ?? 1;

  @override
  void initState() {
    super.initState();
    _cargarDisponibles();
  }

  Future<void> _cargarDisponibles() async {
    setState(() => _cargandoInventario = true);
    final res = await ApiService.obtenerInventario(_idEmpresa);
    if (!mounted) return;

    setState(() {
      if (res['statusCode'] == 200) {
        final List<dynamic> todo = res['data']['inventario'] ?? [];
        _disponibles = todo
            .where((item) => item['estado'] == 'Disponible')
            .toList();
      }
      _cargandoInventario = false;
    });
  }

  Future<void> _agregarPorEscaner() async {
    final codigoEscaneado = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ScannerScreen(usuario: widget.usuario, modoSeleccion: true),
      ),
    );

    if (codigoEscaneado == null || !mounted) return;

    await _cargarDisponibles();
    if (!mounted) return;

    final encontrado = _disponibles
        .where(
          (item) =>
              item['codigo']?.toString().trim().toLowerCase() ==
              codigoEscaneado.trim().toLowerCase(),
        )
        .firstOrNull;

    if (encontrado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El código "$codigoEscaneado" no está disponible en inventario.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _agregarUnidadAlCarrito(Map<String, dynamic>.from(encontrado));
  }

  void _agregarUnidadAlCarrito(Map<String, dynamic> unidad) {
    final yaEnCarrito = _carrito.any(
      (item) => item['id_objeto'] == unidad['id_objeto'],
    );
    if (yaEnCarrito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta unidad ya está en la lista')),
      );
      return;
    }

    setState(() => _carrito.add(unidad));
  }

  Future<void> _abrirSelectorManual() async {
    await _cargarDisponibles();
    if (!mounted) return;

    final candidatos = _disponibles
        .where((u) => !_carrito.any((c) => c['id_objeto'] == u['id_objeto']))
        .toList();

    if (candidatos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay más unidades disponibles para agregar'),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Seleccionar Unidad Disponible',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: candidatos.length,
              itemBuilder: (context, index) {
                final item = candidatos[index];
                return ListTile(
                  title: Text(
                    item['producto'] ?? 'Producto',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Cód: ${item['codigo']} • Ubic: ${item['ubicacion'] ?? 'N/A'}',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  trailing: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF10B981),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _agregarUnidadAlCarrito(Map<String, dynamic>.from(item));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarVenta() async {
    if (_carrito.isEmpty || _procesandoVenta) return;

    setState(() => _procesandoVenta = true);

    int exitosos = 0;
    final Map<int, int> conteoPorProducto = {};

    for (final item in _carrito) {
      final res = await ApiService.actualizarObjeto(
        item['id_objeto'],
        'Vendido',
      );
      if (res['statusCode'] == 200) {
        exitosos++;
        final int? idProd = int.tryParse(item['id_producto']?.toString() ?? '');
        if (idProd != null) {
          conteoPorProducto[idProd] = (conteoPorProducto[idProd] ?? 0) + 1;
        }
      }
    }

    for (final entry in conteoPorProducto.entries) {
      await ApiService.registrarMovimiento(
        idProducto: entry.key,
        tipo: 'SALIDA',
        cantidad: entry.value,
        motivo: 'Despacho desde Venta Rápida',
      );
    }

    if (!mounted) return;

    setState(() {
      _procesandoVenta = false;
      _carrito.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$exitosos unidad(es) despachadas como Vendidas'),
        backgroundColor: Colors.green,
      ),
    );

    _cargarDisponibles();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Venta Rápida',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _cargandoInventario
                            ? null
                            : _abrirSelectorManual,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.list_alt_rounded,
                          size: 18,
                          color: Color(0xFF60A5FA),
                        ),
                        label: const Text(
                          'Elegir de lista',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _agregarPorEscaner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Escanear',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _carrito.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Escanea un código de barras o selecciona unidades disponibles de la lista para despacharlas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      final item = _carrito[index];
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            item['producto'] ?? 'Producto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Cód: ${item['codigo']} • Ubic: ${item['ubicacion'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() => _carrito.removeAt(index));
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
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
                      'Unidades a despachar:',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                    ),
                    Text(
                      '${_carrito.length} unds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: (_carrito.isEmpty || _procesandoVenta)
                      ? null
                      : _confirmarVenta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.point_of_sale, color: Colors.white),
                  label: _procesandoVenta
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Confirmar Venta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
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
