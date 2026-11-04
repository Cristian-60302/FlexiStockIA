import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const ScannerScreen({super.key, required this.usuario});

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Producto'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          // Botón para encender/apagar la linterna
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state == TorchState.on ? Colors.amber : Colors.white,
                );
              },
            ),
            onPressed: () async {
              final codigoEscaneado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScannerScreen(usuario: widget.usuario),
                ),
              );

              if (codigoEscaneado != null) {
                // Aquí es donde consultaremos el backend para ver qué producto es
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Código escaneado: $codigoEscaneado')),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned)
                return; // Evita que lea el mismo código 10 veces en un segundo

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                setState(() => _isScanned = true);

                final String codigo = barcodes.first.rawValue!;

                // Devuelve el código escaneado a la pantalla anterior
                Navigator.pop(context, codigo);
              }
            },
          ),
          // Un marco visual simple para guiar al usuario
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
        ],
      ),
    );
  }
}
