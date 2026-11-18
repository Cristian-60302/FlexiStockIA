import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final bool modoSeleccion;

  const ScannerScreen({
    super.key,
    required this.usuario,
    this.modoSeleccion = false,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _isScanned = false;
  bool _consultando = false;

  int get _idEmpresa =>
      int.tryParse(widget.usuario['id_empresa']?.toString() ?? '1') ?? 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _procesarCodigoEnModoTab(String codigo) async {
    setState(() => _consultando = true);

    final res = await ApiService.obtenerInventario(_idEmpresa);
    if (!mounted) return;

    setState(() => _consultando = false);

    if (res['statusCode'] != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['data']['error'] ??
                'Error al consultar el código en inventario',
          ),
        ),
      );
      setState(() => _isScanned = false);
      return;
    }

    final List<dynamic> inventario = res['data']['inventario'] ?? [];
    final encontrado = inventario
        .where(
          (item) =>
              item['codigo']?.toString().trim().toLowerCase() ==
              codigo.trim().toLowerCase(),
        )
        .firstOrNull;

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          encontrado != null
              ? (encontrado['producto'] ?? 'Unidad encontrada')
              : 'Código no registrado',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: encontrado != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código: ${encontrado['codigo']}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estado actual: ${encontrado['estado']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ubicación: ${encontrado['ubicacion'] ?? 'Sin asignar'}',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              )
            : Text(
                'El código "$codigo" no existe en el inventario físico de tu empresa.',
                style: const TextStyle(color: Color(0xFFCBD5E1)),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          if (encontrado != null && encontrado['estado'] == 'Disponible')
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final resUpd = await ApiService.actualizarObjeto(
                  encontrado['id_objeto'],
                  'Vendido',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      resUpd['statusCode'] == 200
                          ? 'Unidad marcada como Vendida'
                          : (resUpd['data']['error'] ?? 'Error al actualizar'),
                    ),
                  ),
                );
              },
              child: const Text(
                'Marcar Vendido',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );

    if (mounted) {
      setState(() => _isScanned = false);
    }
  }

  Widget _buildBotonLinterna() {
    return IconButton(
      icon: ValueListenableBuilder(
        valueListenable: _controller.torchState,
        builder: (context, state, child) {
          return Icon(
            state == TorchState.on ? Icons.flash_on : Icons.flash_off,
            color: state == TorchState.on ? Colors.amber : Colors.white,
          );
        },
      ),
      onPressed: () => _controller.toggleTorch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esModal = widget.modoSeleccion || Navigator.of(context).canPop();

    final contenidoCamara = Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_isScanned || _consultando) return;

            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              setState(() => _isScanned = true);
              final String codigo = barcodes.first.rawValue!;

              if (esModal) {
                Navigator.pop(context, codigo);
              } else {
                _procesarCodigoEnModoTab(codigo);
              }
            }
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (!esModal)
          Positioned(
            top: 16,
            right: 16,
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1E293B).withOpacity(0.85),
              child: _buildBotonLinterna(),
            ),
          ),
        if (_consultando)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          ),
      ],
    );

    if (!esModal) {
      return SafeArea(child: contenidoCamara);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Producto'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [_buildBotonLinterna()],
      ),
      body: contenidoCamara,
    );
  }
}
