// Este archivo contiene pruebas de integración y flujo funcional simulado en Flutter.
// Evalúa la interacción conjunta entre tres componentes: un repositorio simulado
// (FakeInventarioService) que emula las respuestas HTTP del backend Python, la
// interfaz interactiva de despacho donde el usuario selecciona y confirma la venta
// de una unidad disponible, y el bus reactivo InventarioNotifier encargado de
// propagar la actualización hacia otras vistas suscritas (como Inicio o Reportes).
// Permite validar el ciclo completo de negocio en un entorno controlado y sin
// depender de red externa ni modificar datos reales en NeonDB.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/inventario_notifier.dart';

/// Servicio simulado (Fake) que emula el contrato JSON del backend Python
/// para listar inventario disponible y registrar una salida por venta.
class FakeInventarioService {
  final List<Map<String, dynamic>> _unidades = [
    {
      'id_objeto': 501,
      'id_producto': 10,
      'producto': 'Taladro Percutor 1/2"',
      'codigo': 'TAL-501',
      'estado': 'Disponible',
    },
    {
      'id_objeto': 502,
      'id_producto': 11,
      'producto': 'Juego de Destornilladores',
      'codigo': 'DES-502',
      'estado': 'Disponible',
    },
  ];

  Future<List<Map<String, dynamic>>> obtenerDisponibles() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _unidades.where((u) => u['estado'] == 'Disponible').toList();
  }

  Future<Map<String, dynamic>> confirmarVenta(List<int> idsObjetos) async {
    await Future.delayed(const Duration(milliseconds: 10));
    for (final unidad in _unidades) {
      if (idsObjetos.contains(unidad['id_objeto'])) {
        unidad['estado'] = 'Vendido';
      }
    }
    return {'statusCode': 200, 'mensaje': 'Venta registrada correctamente'};
  }
}

/// Widget integrado que conecta el servicio de inventario, la selección de
/// despacho y la notificación global mediante InventarioNotifier.
class FlujoVentaIntegradoWidget extends StatefulWidget {
  final FakeInventarioService service;
  final InventarioNotifier notifier;

  const FlujoVentaIntegradoWidget({
    super.key,
    required this.service,
    required this.notifier,
  });

  @override
  State<FlujoVentaIntegradoWidget> createState() =>
      _FlujoVentaIntegradoWidgetState();
}

class _FlujoVentaIntegradoWidgetState extends State<FlujoVentaIntegradoWidget> {
  List<Map<String, dynamic>> _disponibles = [];
  final List<Map<String, dynamic>> _carrito = [];
  int _recargasExternas = 0;
  String _estadoMensaje = 'Listo para vender';

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onInventarioActualizado);
    _cargar();
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onInventarioActualizado);
    super.dispose();
  }

  void _onInventarioActualizado() {
    setState(() {
      _recargasExternas++;
    });
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await widget.service.obtenerDisponibles();
    if (!mounted) return;
    setState(() {
      _disponibles = lista;
    });
  }

  Future<void> _procesarVenta() async {
    if (_carrito.isEmpty) return;
    final ids = _carrito.map((e) => e['id_objeto'] as int).toList();
    final res = await widget.service.confirmarVenta(ids);

    if (res['statusCode'] == 200) {
      setState(() {
        _carrito.clear();
        _estadoMensaje = res['mensaje'];
      });
      widget.notifier.notificarCambio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_estadoMensaje, key: const Key('lbl_estado')),
          Text(
            'Recargas notificador: $_recargasExternas',
            key: const Key('lbl_recargas'),
          ),
          Text('En carrito: ${_carrito.length}', key: const Key('lbl_carrito')),
          Expanded(
            child: ListView.builder(
              itemCount: _disponibles.length,
              itemBuilder: (_, index) {
                final item = _disponibles[index];
                return ListTile(
                  title: Text(item['producto']),
                  subtitle: Text(item['codigo']),
                  trailing: IconButton(
                    key: Key('btn_agregar_${item['codigo']}'),
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        if (!_carrito.any(
                          (c) => c['id_objeto'] == item['id_objeto'],
                        )) {
                          _carrito.add(item);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            key: const Key('btn_confirmar_venta'),
            onPressed: _procesarVenta,
            child: const Text('Confirmar Venta'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Pruebas de Integración y Flujo Funcional - Venta + Notifier', () {
    testWidgets(
      'Flujo completo: carga disponibles, agrega al carrito, confirma venta y propaga actualización',
      (WidgetTester tester) async {
        final fakeService = FakeInventarioService();
        final notifier = InventarioNotifier();

        await tester.pumpWidget(
          MaterialApp(
            home: FlujoVentaIntegradoWidget(
              service: fakeService,
              notifier: notifier,
            ),
          ),
        );

        // Esperar a que termine la carga inicial simulada
        await tester.pumpAndSettle();

        // 1. Verificar que los 2 productos disponibles se cargaron en pantalla
        expect(find.text('Taladro Percutor 1/2"'), findsOneWidget);
        expect(find.text('Juego de Destornilladores'), findsOneWidget);
        expect(find.text('En carrito: 0'), findsOneWidget);

        // 2. El usuario agrega el taladro (TAL-501) al carrito
        await tester.tap(find.byKey(const Key('btn_agregar_TAL-501')));
        await tester.pump();
        expect(find.text('En carrito: 1'), findsOneWidget);

        // 3. El usuario confirma la venta
        await tester.tap(find.byKey(const Key('btn_confirmar_venta')));
        await tester.pumpAndSettle();

        // 4. Verificar respuesta de negocio, limpieza de carrito, notificación y actualización de stock
        expect(find.text('Venta registrada correctamente'), findsOneWidget);
        expect(find.text('En carrito: 0'), findsOneWidget);
        expect(find.text('Recargas notificador: 1'), findsOneWidget);
        expect(find.text('Taladro Percutor 1/2"'), findsNothing);
        expect(find.text('Juego de Destornilladores'), findsOneWidget);

        notifier.dispose();
      },
    );
  });
}
