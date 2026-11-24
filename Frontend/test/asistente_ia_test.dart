// Este archivo contiene las pruebas unitarias y de widgets para el Módulo de
// Inteligencia Artificial (FlexiStock IA) en el frontend Flutter.
// Evalúa tres aspectos clave sin consumir cuota externa de la API de Gemini:
// 1) Renderizado inicial de AsistenteIAScreen: verifica que la vista muestre el
//    encabezado 'FlexiStock IA', genere el saludo contextual con el nombre del
//    usuario autenticado y despliegue los chips de consultas rápidas.
// 2) Validación de entrada e interacción en el chat: comprueba que el sistema
//    ignore envíos con el campo vacío y que, al redactar una consulta real,
//    registre de inmediato la burbuja del usuario en el historial visual.
// 3) Integración de navegación desde MainNavigationScreen: valida que al pulsar
//    el acceso directo 'IA' en la barra superior (AppBar), la aplicación
//    navegue correctamente hacia AsistenteIAScreen conservando el contexto.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/asistente_ia_screen.dart';
import 'package:frontend/screens/main_navigation_screen.dart';

void main() {
  const usuarioPrueba = {
    'id_usuario': 1,
    'nombre': 'Cristian',
    'correo': 'cristian@flexistock.com',
    'id_empresa': 1,
    'empresa': 'Ferretería Central',
  };

  group('Pruebas del Módulo IA - AsistenteIAScreen y Navegación', () {
    testWidgets(
      'Renderiza saludo personalizado, panel de insights y sugerencias rápidas',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: AsistenteIAScreen(usuario: usuarioPrueba)),
        );

        await tester.pump();

        expect(find.text('FlexiStock IA'), findsOneWidget);
        expect(find.textContaining('Hola Cristian'), findsOneWidget);
        expect(find.text('Más vendidos'), findsOneWidget);
        expect(find.text('Estado inventario'), findsOneWidget);
        expect(find.text('Ideas de promoción'), findsOneWidget);
      },
    );

    testWidgets(
      'No envía mensajes vacíos y muestra en pantalla la pregunta escrita por el usuario',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: AsistenteIAScreen(usuario: usuarioPrueba)),
        );

        await tester.pump();

        // Intentar enviar con el TextField vacío
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump();

        expect(find.textContaining('Hola Cristian'), findsOneWidget);

        // Escribir una pregunta real y enviarla
        const pregunta = '¿Cuál es mi producto estrella este mes?';
        await tester.enterText(find.byType(TextField), pregunta);
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump();

        expect(find.text(pregunta), findsOneWidget);
      },
    );

    testWidgets(
      'Navega desde MainNavigationScreen hacia AsistenteIAScreen al pulsar botón IA',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: MainNavigationScreen(usuario: usuarioPrueba)),
        );

        await tester.pump();

        final botonIA = find.byKey(const Key('btn_abrir_ia'));
        expect(botonIA, findsOneWidget);

        await tester.tap(botonIA);
        await tester.pumpAndSettle();

        expect(find.byType(AsistenteIAScreen), findsOneWidget);
        expect(find.text('FlexiStock IA'), findsOneWidget);
      },
    );
  });
}
