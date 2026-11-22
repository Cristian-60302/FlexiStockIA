// Prueba Funcional y de Sistemas End-to-End (E2E) para el flujo real de Venta.
// Ejecuta la aplicación completa contra el backend Python y Neon PostgreSQL:
// 1) Inicia sesión con una cuenta existente con inventario disponible.
// 2) Navega a la pestaña "Venta" del BottomNavigationBar.
// 3) Abre el selector manual ("Elegir de lista") y verifica si existen
//    unidades disponibles; selecciona la primera unidad disponible.
// 4) Verifica que el contador pase a "1 unds" y pulsa "Confirmar Venta".
// 5) Valida la confirmación real en pantalla ("1 unidad(es) despachadas como Vendidas")
//    y el reinicio del carrito a "0 unds".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;
import 'package:frontend/screens/main_navigation_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Prueba Funcional y de Sistemas E2E - Flujo Real de Venta', () {
    testWidgets(
      'Inicia sesión, selecciona una unidad disponible y confirma venta en servidor real',
      (WidgetTester tester) async {
        // IMPORTANTE: Usa credenciales de un usuario existente en tu BD
        // que tenga al menos 1 unidad con estado "Disponible".
        const correoValido = 'crfegoro@gmail.com';
        const passwordValida = '123456';

        app.main();
        await tester.pumpAndSettle();

        // 1. Iniciar sesión en LoginScreen
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Correo electrónico'),
          correoValido,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña'),
          passwordValida,
        );

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
        await tester.pumpAndSettle(const Duration(seconds: 4));

        expect(find.byType(MainNavigationScreen), findsOneWidget);

        // 2. Ir a la pestaña "Venta" en el BottomNavigationBar
        // 2. Ir a la pestaña "Venta" en el BottomNavigationBar
        await tester.tap(
          find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.text('Venta'),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Venta Rápida'), findsOneWidget);
        expect(find.text('0 unds'), findsOneWidget);

        // 3. Pulsar "Elegir de lista" para abrir el modal de disponibles
        await tester.tap(find.text('Elegir de lista'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verificar que se abrió el modal con unidades disponibles
        expect(find.text('Seleccionar Unidad Disponible'), findsOneWidget);

        // Seleccionar la primera unidad disponible de la lista
        final primeraUnidad = find.byIcon(Icons.add_circle_outline).first;
        await tester.tap(primeraUnidad);
        await tester.pumpAndSettle();

        // 4. Confirmar que el contador subió a "1 unds" y despachar venta
        expect(find.text('1 unds'), findsOneWidget);

        await tester.tap(find.text('Confirmar Venta'));
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // 5. Verificar confirmación real del servidor y reinicio del carrito
        expect(
          find.text('1 unidad(es) despachadas como Vendidas'),
          findsOneWidget,
        );
        expect(find.text('0 unds'), findsOneWidget);
      },
    );
  });
}
