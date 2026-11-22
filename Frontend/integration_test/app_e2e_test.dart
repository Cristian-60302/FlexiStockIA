// Prueba Funcional y de Sistemas End-to-End (E2E) para FlexiStock IA.
// Ejecuta la aplicación completa sobre un dispositivo o emulador real conectado
// al backend Python y a Neon PostgreSQL. Simula la interacción real de un usuario:
// 1) Verifica el renderizado inicial de LoginScreen.
// 2) Navega a RegisterScreen, diligencia el formulario con un correo único y
//    registra una cuenta nueva en la base de datos real (HTTP 201).
// 3) Regresa automáticamente a LoginScreen, ingresa las credenciales recién
//    creadas e inicia sesión (HTTP 200).
// 4) Verifica la transición exitosa hacia MainNavigationScreen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;
import 'package:frontend/screens/main_navigation_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Prueba Funcional y de Sistemas E2E - Registro e Inicio de Sesión', () {
    testWidgets(
      'Flujo completo: registrar usuario nuevo en servidor real e iniciar sesión',
      (WidgetTester tester) async {
        // Inicia la aplicación real
        app.main();
        await tester.pumpAndSettle();

        // 1. Verificar pantalla inicial de Login
        expect(find.text('FlexiStock IA'), findsOneWidget);
        expect(find.text('Iniciar Sesión'), findsOneWidget);

        // 2. Ir a la pantalla de Registro pulsando "Regístrate"
        final botonIrRegistro = find.text('Regístrate');
        expect(botonIrRegistro, findsOneWidget);
        await tester.tap(botonIrRegistro);
        await tester.pumpAndSettle();

        expect(find.text('Crear Cuenta'), findsOneWidget);

        // Generar datos únicos por marca de tiempo para evitar duplicados en NeonDB
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final correoPrueba = 'test_e2e_$timestamp@flexistock.com';
        const passwordPrueba = 'ClaveTest2026';

        // 3. Diligenciar campos de RegisterScreen
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre Completo'),
          'Usuario Prueba E2E',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Correo Electrónico'),
          correoPrueba,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña'),
          passwordPrueba,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmar Contraseña'),
          passwordPrueba,
        );

        // Ocultar teclado si está abierto y pulsar "Registrarse"
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarse'));

        // Esperar respuesta real del servidor Python / NeonDB
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // 4. Confirmar que regresó a LoginScreen tras el registro exitoso (HTTP 201)
        expect(find.text('FlexiStock IA'), findsOneWidget);

        // 5. Diligenciar credenciales en LoginScreen e iniciar sesión
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Correo electrónico'),
          correoPrueba,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña'),
          passwordPrueba,
        );

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));

        // Esperar autenticación y carga de MainNavigationScreen
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // 6. Verificar que ingresó a la pantalla principal del sistema
        expect(find.byType(MainNavigationScreen), findsOneWidget);
      },
    );
  });
}
