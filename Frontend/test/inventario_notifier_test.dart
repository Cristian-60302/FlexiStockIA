import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/inventario_notifier.dart';

void main() {
  group('Pruebas unitarias - InventarioNotifier', () {
    test('Notifica a un listener registrado cuando ocurre un cambio', () {
      final notifier = InventarioNotifier();
      var llamadas = 0;

      void callback() {
        llamadas++;
      }

      notifier.addListener(callback);
      notifier.notificarCambio();

      expect(llamadas, 1);

      notifier.removeListener(callback);
      notifier.dispose();
    });

    test('Notifica a múltiples listeners suscritos de forma independiente', () {
      final notifier = InventarioNotifier();
      var llamadasVistaA = 0;
      var llamadasVistaB = 0;

      void listenerA() => llamadasVistaA++;
      void listenerB() => llamadasVistaB++;

      notifier.addListener(listenerA);
      notifier.addListener(listenerB);

      notifier.notificarCambio();
      notifier.notificarCambio();

      expect(llamadasVistaA, 2);
      expect(llamadasVistaB, 2);

      notifier.removeListener(listenerA);
      notifier.removeListener(listenerB);
      notifier.dispose();
    });

    test('Deja de notificar a un listener después de removerlo', () {
      final notifier = InventarioNotifier();
      var llamadas = 0;

      void callback() => llamadas++;

      notifier.addListener(callback);
      notifier.notificarCambio();
      expect(llamadas, 1);

      notifier.removeListener(callback);
      notifier.notificarCambio();

      expect(llamadas, 1);
      notifier.dispose();
    });
  });
}

// Este archivo contiene pruebas unitarias sobre InventarioNotifier, el mecanismo
// centralizado de notificación de cambios del módulo de inventario en Flutter.
// Verifica que los suscriptores registrados reciban exactamente una señal cada
// vez que se ejecuta notificarCambio(), que múltiples vistas o callbacks puedan
// suscribirse de forma independiente y que al remover un listener mediante
// removeListener() deje de ejecutarse en notificaciones posteriores, evitando
// invocaciones innecesarias o sobre widgets desmontados. Es una prueba unitaria
// local y determinista que no requiere red, servidor Flask ni base de datos.
