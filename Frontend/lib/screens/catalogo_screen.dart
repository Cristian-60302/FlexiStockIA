import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

import 'detalle_producto_screen.dart';

class CatalogoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const CatalogoScreen({super.key, required this.usuario});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  List<dynamic> _productos = [];
  List<dynamic> _categorias = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _tabSeleccionada = 0; // 0: Productos, 1: Categorías

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

    final int idEmpresa =
        int.tryParse(widget.usuario['id_empresa']?.toString() ?? '1') ?? 1;

    // Consultamos productos y categorías en paralelo
    final resultados = await Future.wait([
      ApiService.obtenerProductos(idEmpresa),
      ApiService.obtenerCategorias(idEmpresa),
    ]);

    if (!mounted) return;

    final resProductos = resultados[0];
    final resCategorias = resultados[1];

    if (resProductos['statusCode'] == 200 &&
        resCategorias['statusCode'] == 200) {
      setState(() {
        _productos = resProductos['data']['productos'] ?? [];
        _categorias = resCategorias['data']['categorias'] ?? [];
        _isLoading = false;
      });
    } else {
      final errorProd = resProductos['data']['error'];
      final errorCat = resCategorias['data']['error'];
      setState(() {
        _errorMessage =
            errorProd ?? errorCat ?? 'Error al cargar el catálogo del servidor';
        _isLoading = false;
      });
    }
  }

  // Se implementará en el Paso 2
  Future<void> _abrirFormularioCategoria({
    Map<String, dynamic>? categoria,
  }) async {
    final bool esEdicion = categoria != null;
    final nombreCtrl = TextEditingController(text: categoria?['nombre'] ?? '');
    final descCtrl = TextEditingController(
      text: categoria?['descripcion'] ?? '',
    );
    final int idEmpresa =
        int.tryParse(widget.usuario['id_empresa']?.toString() ?? '1') ?? 1;

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          esEdicion ? 'Editar Categoría' : 'Nueva Categoría',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF475569)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF475569)),
                ),
              ),
            ),
          ],
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
              final nombre = nombreCtrl.text.trim();
              if (nombre.isEmpty) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
                return;
              }

              Navigator.pop(dialogCtx);

              final String desc = descCtrl.text.trim();
              final Map<String, dynamic> res;

              if (esEdicion) {
                res = await ApiService.actualizarCategoria(
                  categoria,
                  nombre: nombre,
                  descripcion: desc,
                  idCategoria: categoria.id,
                );
              } else {
                res = await ApiService.crearCategoria(
                  idEmpresa: idEmpresa,
                  nombre: nombre,
                  descripcion: desc.isEmpty ? null : desc,
                );
              }

              if (!mounted) return;

              if (res['statusCode'] == 200 || res['statusCode'] == 201) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      esEdicion
                          ? 'Categoría actualizada correctamente'
                          : 'Categoría creada correctamente',
                    ),
                  ),
                );
                _cargarDatos();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res['data']['error'] ?? 'Error al guardar la categoría',
                    ),
                  ),
                );
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Se implementará en el Paso 3
  Future<void> _abrirFormularioProducto({
    Map<String, dynamic>? producto,
  }) async {
    if (_categorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes crear al menos una categoría antes de agregar productos',
          ),
        ),
      );
      return;
    }

    final bool esEdicion = producto != null;
    final nombreCtrl = TextEditingController(text: producto?['nombre'] ?? '');
    final marcaCtrl = TextEditingController(text: producto?['marca'] ?? '');
    final descCtrl = TextEditingController(
      text: producto?['descripcion'] ?? '',
    );
    final int idEmpresa =
        int.tryParse(widget.usuario['id_empresa']?.toString() ?? '1') ?? 1;

    // Resolvemos el id_categoria inicial (GET /productos devuelve el nombre, no el ID)
    int? categoriaSeleccionada;
    if (esEdicion) {
      final catEncontrada = _categorias
          .where((c) => c['nombre'] == producto['categoria'])
          .firstOrNull;
      categoriaSeleccionada =
          catEncontrada?['id_categoria'] ?? _categorias.first['id_categoria'];
    } else {
      categoriaSeleccionada = _categorias.first['id_categoria'];
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
            esEdicion ? 'Editar Producto' : 'Nuevo Producto',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto *',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF475569)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: marcaCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Marca (opcional)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF475569)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: categoriaSeleccionada,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF475569)),
                    ),
                  ),
                  items: _categorias.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat['id_categoria'],
                      child: Text(
                        cat['nombre'] ?? 'Sin nombre',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() => categoriaSeleccionada = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF475569)),
                    ),
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
                final nombre = nombreCtrl.text.trim();
                if (nombre.isEmpty || categoriaSeleccionada == null) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(
                      content: Text('Nombre y categoría son obligatorios'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogCtx);

                final String marca = marcaCtrl.text.trim();
                final String desc = descCtrl.text.trim();
                final Map<String, dynamic> res;

                if (esEdicion) {
                  res = await ApiService.actualizarProducto(
                    producto['id_producto'],
                    nombre: nombre,
                    marca: marca,
                    descripcion: desc,
                    idCategoria: categoriaSeleccionada,
                  );
                } else {
                  res = await ApiService.crearProducto(
                    idEmpresa: idEmpresa,
                    nombre: nombre,
                    marca: marca.isEmpty ? null : marca,
                    descripcion: desc.isEmpty ? null : desc,
                    idCategoria: categoriaSeleccionada,
                  );
                }

                if (!mounted) return;

                if (res['statusCode'] == 200 || res['statusCode'] == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        esEdicion
                            ? 'Producto actualizado correctamente'
                            : 'Producto creado correctamente',
                      ),
                    ),
                  );
                  _cargarDatos();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        res['data']['error'] ?? 'Error al guardar el producto',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
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
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // 1. Selector de pestañas (Productos / Categorías)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    label: 'Productos (${_productos.length})',
                    icon: Icons.inventory_2_rounded,
                  ),
                  _buildTabButton(
                    index: 1,
                    label: 'Categorías (${_categorias.length})',
                    icon: Icons.category_rounded,
                  ),
                ],
              ),
            ),
          ),

          // 2. Encabezado contextual con botón de creación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tabSeleccionada == 0
                      ? 'Listado de productos'
                      : 'Categorías registradas',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_tabSeleccionada == 0) {
                      _abrirFormularioProducto();
                    } else {
                      _abrirFormularioCategoria();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: Text(
                    _tabSeleccionada == 0 ? 'Producto' : 'Categoría',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Contenido dinámico según la pestaña activa
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarDatos,
              child: _tabSeleccionada == 0
                  ? _buildListaProductos()
                  : _buildListaCategorias(),
            ),
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

  Widget _buildListaProductos() {
    if (_productos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No hay productos registrados en esta empresa.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleProductoScreen(producto: p),
                ),
              );
              _cargarDatos();
            },
          ),
        );
      },
    );
  }

  Widget _buildListaCategorias() {
    if (_categorias.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No hay categorías registradas en esta empresa.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final cat = _categorias[index];
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
                Icons.category_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
            title: Text(
              cat['nombre'] ?? 'Categoría sin nombre',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                cat['descripcion'] ?? 'Sin descripción',
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: Color(0xFF60A5FA),
                size: 20,
              ),
              onPressed: () => _abrirFormularioCategoria(categoria: cat),
            ),
          ),
        );
      },
    );
  }
}

extension on Map<String, dynamic> {
  int get id => this['id'] ?? 0;
}
