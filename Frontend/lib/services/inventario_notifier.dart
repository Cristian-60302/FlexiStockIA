import 'package:flutter/foundation.dart';

class InventarioNotifier extends ChangeNotifier {
  void notificarCambio() {
    notifyListeners();
  }
}

final InventarioNotifier inventarioNotifier = InventarioNotifier();
