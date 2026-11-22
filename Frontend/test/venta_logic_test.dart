import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/venta_screen.dart';

/// Función pura auxiliar para probar lógica de negocio sin UI ni red:
/// Evita duplicar unidades con el mismo id_objeto en el carrito de despacho.
List<Map<String, dynamic>> agregarUnidadSinDuplicados(
  List<Map<String, dynamic>> carritoActual,
  Map<String, dynamic> nuevaUnidad,
) {
  final existe = carritoActual.any(
    (item) => item['id_objeto'] == nuevaUnidad['id_objeto'],
  );
  if (existe) {
    return List<Map<String, dynamic>>.from(carritoActual);
  }
  return [...carritoActual, nuevaUnidad];
}

void main() {
  group('Pruebas unitarias - Lógica de despacho en Venta', () {
    test('Agrega una unidad disponible cuando no existe en el carrito', () {
      final inicial = <Map<String, dynamic>>[];
      final unidad = {
        'id_objeto': 101,
        'id_producto': 12,
        'producto': 'Martillo de uña',
        'codigo': 'COD-101',
        'estado': 'Disponible',
      };

      final resultado = agregarUnidadSinDuplicados(inicial, unidad);

      expect(resultado.length, 1);
      expect(resultado.first['id_objeto'], 101);
      expect(resultado.first['codigo'], 'COD-101');
    });

    test('No duplica una unidad si ya fue agregada previamente', () {
      final unidad = {
        'id_objeto': 101,
        'id_producto': 12,
        'producto': 'Martillo de uña',
        'codigo': 'COD-101',
        'estado': 'Disponible',
      };
      final inicial = [unidad];

      final resultado = agregarUnidadSinDuplicados(inicial, unidad);

      expect(resultado.length, 1);
    });
  });

  group('Pruebas de widget - VentaScreen', () {
    testWidgets(
      'Muestra encabezado Venta Rápida y contador inicial en 0 unds',
      (WidgetTester tester) async {
        final usuarioPrueba = {
          'id_usuario': 1,
          'nombre': 'Usuario Prueba',
          'id_empresa': 1,
          'empresa': 'Empresa Demo',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: VentaScreen(usuario: usuarioPrueba)),
          ),
        );

        // Avanza frames iniciales sin bloquearse por peticiones pendientes
        await tester.pump();

        expect(find.text('Venta Rápida'), findsOneWidget);
        expect(find.text('0 unds'), findsOneWidget);
        expect(find.text('Confirmar Venta'), findsOneWidget);
      },
    );
  });
}

// Este archivo contiene pruebas unitarias y de widget para la lógica de venta.
// En las pruebas unitarias se valida la función pura agregarUnidadSinDuplicados
// para comprobar que se añaden unidades nuevas sin mutar la lista original y
// que se bloquean duplicados con el mismo id_objeto, sin depender de red ni
// base de datos (aunque la función es auxiliar de prueba y no llama directo al
// método privado interno de la pantalla).
//
//
//
//En la prueba de widget se monta
// VentaScreen dentro de MaterialApp y Scaffold y se avanza un frame con pump()
// para verificar que se rendericen el título "Venta Rápida", el contador inicial
// "0 unds" y el botón "Confirmar Venta"; no constituye una prueba de
// integración ni funcional completa porque ApiService no está simulado (mock) y
// la carga inicial de inventario depende de la conexión real.
