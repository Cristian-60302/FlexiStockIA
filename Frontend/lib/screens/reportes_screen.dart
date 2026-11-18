import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class ReportesScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const ReportesScreen({super.key, required this.usuario});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  int _tabSeleccionada = 0; // 0: Unidades Físicas, 1: Movimientos

  List<dynamic> _inventario = [];
  List<dynamic> _recomendaciones = [];
  String _filtroEstado = 'Todos';

  final List<String> _estadosFiltro = [
    'Todos',
    'Disponible',
    'Vendido',
    'Dañado',
    'Prestado',
  ];

  List<dynamic> _movimientos = [];
  List<dynamic> _productos = [];
  String _filtroTipoMov = 'Todos';

  final List<String> _tiposMovimiento = [
    'Todos',
    'ENTRADA',
    'SALIDA',
    'AJUSTE',
  ];

  int get _idEmpresa =>
      int.tryParse(widget.usuario['id_empresa']?.toString() ?? '1') ?? 1;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final resultados = await Future.wait([
      ApiService.obtenerInventario(_idEmpresa),
      ApiService.recomendacionesCompra(_idEmpresa),
      ApiService.obtenerMovimientos(idEmpresa: _idEmpresa),
      ApiService.obtenerProductos(_idEmpresa),
    ]);

    if (!mounted) return;

    final resInventario = resultados[0];
    final resRec = resultados[1];
    final resMov = resultados[2];
    final resProd = resultados[3];

    if (resInventario['statusCode'] == 200) {
      setState(() {
        _inventario = resInventario['data']['inventario'] ?? [];
        if (resRec['statusCode'] == 200) {
          _recomendaciones = resRec['data']['recomendaciones'] ?? [];
        }
        if (resMov['statusCode'] == 200) {
          _movimientos = resMov['data']['movimientos'] ?? [];
        }
        if (resProd['statusCode'] == 200) {
          _productos = resProd['data']['productos'] ?? [];
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            resInventario['data']['error'] ?? 'Error al cargar el inventario';
        _isLoading = false;
      });
    }
  }

  // =========================================================================
  // CONSULTAR DETALLE (GET /inventario/<id>) Y ACTUALIZAR (PUT /inventario/<id>)
  // =========================================================================
  Future<void> _abrirDetalleYEdicionUnidad(int idObjeto) async {
    final resDetalle = await ApiService.obtenerObjetoInventario(
      idObjeto: idObjeto,
    );
    if (!mounted) return;

    if (resDetalle['statusCode'] != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resDetalle['data']['error'] ?? 'No se pudo consultar la unidad',
          ),
        ),
      );
      return;
    }

    final Map<String, dynamic> objeto = resDetalle['data']['objeto'];
    String estadoSeleccionado = objeto['estado'] ?? 'Disponible';
    final ubicacionCtrl = TextEditingController(
      text: objeto['ubicacion'] ?? '',
    );

    final estadosValidos = ['Disponible', 'Vendido', 'Dañado', 'Prestado'];
    if (!estadosValidos.contains(estadoSeleccionado)) {
      estadosValidos.add(estadoSeleccionado);
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            objeto['producto'] ?? 'Detalle de Unidad',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código: ${objeto['codigo']}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Marca: ${objeto['marca'] ?? 'N/A'}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
                if (objeto['descripcion'] != null &&
                    objeto['descripcion'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    objeto['descripcion'],
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                    ),
                  ),
                ],
                const Divider(color: Color(0xFF334155), height: 24),
                DropdownButtonFormField<String>(
                  value: estadoSeleccionado,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Estado físico',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  items: estadosValidos.map((est) {
                    return DropdownMenuItem<String>(
                      value: est,
                      child: Text(est),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() => estadoSeleccionado = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ubicacionCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ubicación en bodega',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);

                final resUpdate = await ApiService.actualizarObjeto(
                  idObjeto,
                  estadoSeleccionado,
                  ubicacion: ubicacionCtrl.text.trim(),
                );

                if (!mounted) return;

                if (resUpdate['statusCode'] == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unidad actualizada correctamente'),
                    ),
                  );
                  _cargarDatos();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        resUpdate['data']['error'] ?? 'Error al actualizar',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Guardar cambios',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // REGISTRAR MOVIMIENTO MANUAL (POST /movimientos)
  // =========================================================================
  Future<void> _abrirFormularioMovimiento() async {
    if (_productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay productos registrados para asociar el movimiento',
          ),
        ),
      );
      return;
    }

    int productoSeleccionado = _productos.first['id_producto'];
    String tipoSeleccionado = 'ENTRADA';
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Registrar Movimiento',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nota: Registra un historial contable por cantidad; no modifica unidades escaneadas.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: productoSeleccionado,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Producto *',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  items: _productos.map((prod) {
                    return DropdownMenuItem<int>(
                      value: prod['id_producto'],
                      child: Text(
                        prod['nombre'] ?? 'Producto',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() => productoSeleccionado = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimiento *',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ENTRADA', child: Text('ENTRADA')),
                    DropdownMenuItem(value: 'SALIDA', child: Text('SALIDA')),
                    DropdownMenuItem(value: 'AJUSTE', child: Text('AJUSTE')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() => tipoSeleccionado = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad (entero mayor a 0) *',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivoCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (opcional)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              onPressed: () async {
                final int? cantidad = int.tryParse(cantidadCtrl.text.trim());
                if (cantidad == null || cantidad <= 0) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa una cantidad entera mayor a 0'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogCtx);

                final String motivo = motivoCtrl.text.trim();
                final res = await ApiService.registrarMovimiento(
                  idProducto: productoSeleccionado,
                  tipo: tipoSeleccionado,
                  cantidad: cantidad,
                  motivo: motivo.isEmpty ? null : motivo,
                );

                if (!mounted) return;

                if (res['statusCode'] == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Movimiento registrado correctamente'),
                    ),
                  );
                  _cargarDatos();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        res['data']['error'] ?? 'Error al registrar movimiento',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorPorEstado(String? estado) {
    switch (estado) {
      case 'Disponible':
        return Colors.greenAccent;
      case 'Vendido':
        return const Color(0xFF60A5FA);
      case 'Dañado':
        return Colors.redAccent;
      case 'Prestado':
        return Colors.orangeAccent;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Color _colorPorTipoMovimiento(String? tipo) {
    switch (tipo) {
      case 'ENTRADA':
        return Colors.greenAccent;
      case 'SALIDA':
        return Colors.redAccent;
      case 'AJUSTE':
        return Colors.orangeAccent;
      default:
        return const Color(0xFF94A3B8);
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
              onPressed: _cargarDatos,
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

    return SafeArea(
      child: Column(
        children: [
          // 1. Tarjeta dinámica de Recomendación de Compra (Endpoint 19)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _recomendaciones.isEmpty
                          ? 'Inventario saludable: ningún producto requiere reposición urgente.'
                          : 'Sugerencia: "${_recomendaciones.first['producto']}" tiene ${_recomendaciones.first['unidades_disponibles']} unds. Se recomienda pedir ${_recomendaciones.first['cantidad_recomendada']} unds.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Selector de pestañas: Unidades Físicas / Movimientos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton(
                    index: 0,
                    label: 'Unidades (${_inventario.length})',
                    icon: Icons.qr_code_2_rounded,
                  ),
                  _buildTabButton(
                    index: 1,
                    label: 'Movimientos (${_movimientos.length})',
                    icon: Icons.swap_horiz_rounded,
                  ),
                ],
              ),
            ),
          ),

          // 3. Contenido según pestaña activa
          Expanded(
            child: _tabSeleccionada == 0
                ? _buildVistaUnidades()
                : _buildVistaMovimientos(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _tabSeleccionada == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabSeleccionada = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVistaUnidades() {
    final listaFiltrada = _filtroEstado == 'Todos'
        ? _inventario
        : _inventario.where((item) => item['estado'] == _filtroEstado).toList();

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _estadosFiltro.length,
            itemBuilder: (context, index) {
              final estado = _estadosFiltro[index];
              final seleccionado = _filtroEstado == estado;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(estado),
                  selected: seleccionado,
                  onSelected: (_) => setState(() => _filtroEstado = estado),
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: TextStyle(
                    color: seleccionado
                        ? Colors.white
                        : const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarDatos,
            child: listaFiltrada.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'No hay unidades físicas con este estado.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) {
                      final item = listaFiltrada[index];
                      final colorEstado = _colorPorEstado(item['estado']);
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
                            'Cód: ${item['codigo']} • Ubic: ${item['ubicacion'] ?? 'Sin asignar'}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['estado'] ?? 'N/A',
                              style: TextStyle(
                                color: colorEstado,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () =>
                              _abrirDetalleYEdicionUnidad(item['id_objeto']),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVistaMovimientos() {
    final movFiltrados = _filtroTipoMov == 'Todos'
        ? _movimientos
        : _movimientos.where((m) => m['tipo'] == _filtroTipoMov).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tiposMovimiento.length,
                    itemBuilder: (context, index) {
                      final tipo = _tiposMovimiento[index];
                      final seleccionado = _filtroTipoMov == tipo;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(tipo),
                          selected: seleccionado,
                          onSelected: (_) =>
                              setState(() => _filtroTipoMov = tipo),
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: const Color(0xFF1E293B),
                          labelStyle: TextStyle(
                            color: seleccionado
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _abrirFormularioMovimiento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text(
                  'Nuevo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarDatos,
            child: movFiltrados.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'No hay movimientos registrados.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: movFiltrados.length,
                    itemBuilder: (context, index) {
                      final mov = movFiltrados[index];
                      final colorTipo = _colorPorTipoMovimiento(mov['tipo']);
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            mov['nombre_producto'] ?? 'Producto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (mov['motivo'] != null &&
                                    mov['motivo'].toString().isNotEmpty)
                                  Text(
                                    'Motivo: ${mov['motivo']}',
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  'Fecha: ${mov['fecha'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorTipo.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  mov['tipo'] ?? '',
                                  style: TextStyle(
                                    color: colorTipo,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${mov['cantidad']} unds',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
