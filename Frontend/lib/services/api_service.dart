import 'dart:convert';

import 'package:frontend/config/constants.dart';
// Requerido para kIsWeb
import 'package:http/http.dart' as http;

class ApiService {
  // Ajustado al puerto 3000 de tu Flask
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> login(
    String correo,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'), // Apunta directamente a /login
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo, // Mapeado como 'correo' para coincidir con Flask
          'password': password,
        }),
      );

      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error de conexión con el servidor'},
      };
    }
  }

  static Future<Map<String, dynamic>> obtenerProductos(int idEmpresa) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/productos?id_empresa=$idEmpresa'),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error consultando productos'},
      };
    }
  }

  static Future<Map<String, dynamic>> obtenerCategorias(int idEmpresa) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categorias?id_empresa=$idEmpresa'),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error consultando categorías'},
      };
    }
  }

  static Future<Map<String, dynamic>> resumenInventario(int idEmpresa) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inventario/resumen?id_empresa=$idEmpresa'),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error consultando resumen del inventario'},
      };
    }
  }

  static Future<Map<String, dynamic>> alertasStockBajo(
    int idEmpresa, {
    int limite = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/alertas/stock-bajo?id_empresa=$idEmpresa&limite=$limite',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error consultando alertas de stock'},
      };
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String correo,
    String password,
  ) async {
    try {
      // Como aún no tienes endpoint /registro en main.py, enviamos la petición estructurada
      final response = await http.post(
        Uri.parse('$baseUrl/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': name,
          'correo': correo,
          'password': password,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error de conexión con el servidor'},
      };
    }
  }
  // ==============================================
  // GESTIÓN DE INVENTARIO FÍSICO (ESCANEO)
  // ==============================================

  static Future<Map<String, dynamic>> obtenerInventario(int idEmpresa) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inventario?id_empresa=$idEmpresa'),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error consultando el inventario'},
      };
    }
  }

  static Future<Map<String, dynamic>> actualizarObjeto(
    int idObjeto,
    String? estado, {
    String? ubicacion,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (estado != null) body['estado'] = estado;
      if (ubicacion != null) body['ubicacion'] = ubicacion;

      final response = await http.put(
        Uri.parse('$baseUrl/inventario/$idObjeto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error actualizando el objeto'},
      };
    }
  }

  static Future<Map<String, dynamic>> agregarInventario({
    required int idProducto,
    required String codigo,
    String estado = 'Disponible',
    String? ubicacion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inventario'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_producto': idProducto,
          'codigo': codigo,
          'estado': estado,
          'ubicacion': ubicacion,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error agregando objeto al inventario'},
      };
    }
  }
  // ==============================================
  // GESTIÓN DE PRODUCTOS (CRUD RESTANTE)
  // ==============================================

  // Endpoint 6: POST /productos
  static Future<Map<String, dynamic>> crearProducto({
    required int idEmpresa,
    required String nombre,
    String? descripcion,
    String? marca,
    int? idCategoria,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/productos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_empresa': idEmpresa,
          'nombre': nombre,
          'descripcion': descripcion,
          'marca': marca,
          'id_categoria': idCategoria,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error creando el producto'},
      };
    }
  }

  // Endpoint 9: GET /productos/<id_producto>
  static Future<Map<String, dynamic>> obtenerProductoPorId({
    required int idProducto,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/productos/$idProducto'),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error consultando el producto'},
      };
    }
  }

  // Endpoint 10: PUT /productos/<id_producto>
  static Future<Map<String, dynamic>> actualizarProducto(
    int idProducto, {
    String? nombre,
    String? descripcion,
    String? marca,
    int? idCategoria,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (nombre != null) body['nombre'] = nombre;
      if (descripcion != null) body['descripcion'] = descripcion;
      if (marca != null) body['marca'] = marca;
      if (idCategoria != null) body['id_categoria'] = idCategoria;

      final response = await http.put(
        Uri.parse('$baseUrl/productos/$idProducto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error actualizando el producto'},
      };
    }
  }

  // ==============================================
  // GESTIÓN DE CATEGORÍAS (CRUD RESTANTE)
  // ==============================================

  // Endpoint 7: POST /categorias
  static Future<Map<String, dynamic>> crearCategoria({
    required int idEmpresa,
    required String nombre,
    String? descripcion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categorias'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_empresa': idEmpresa,
          'nombre': nombre,
          'descripcion': descripcion,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error creando la categoría'},
      };
    }
  }

  // Endpoint 12: GET /categorias/<id_categoria>
  static Future<Map<String, dynamic>> obtenerCategoriaPorId({
    required int idCategoria,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categorias/$idCategoria'),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error consultando la categoría'},
      };
    }
  }

  // Endpoint 13: PUT /categorias/<id_categoria>
  static Future<Map<String, dynamic>> actualizarCategoria(
    categoria, {
    required int idCategoria,
    String? nombre,
    String? descripcion,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (nombre != null) body['nombre'] = nombre;
      if (descripcion != null) body['descripcion'] = descripcion;

      final response = await http.put(
        Uri.parse('$baseUrl/categorias/$idCategoria'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error actualizando la categoría'},
      };
    }
  }

  // ==============================================
  // INVENTARIO DETALLADO, MOVIMIENTOS Y COMPRAS
  // ==============================================

  // Endpoint 15: GET /inventario/<id_objeto>
  static Future<Map<String, dynamic>> obtenerObjetoInventario({
    required int idObjeto,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inventario/$idObjeto'),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error consultando el objeto del inventario'},
      };
    }
  }

  // Endpoint 16: POST /movimientos
  static Future<Map<String, dynamic>> registrarMovimiento({
    required int idProducto,
    required String tipo, // 'ENTRADA', 'SALIDA' o 'AJUSTE'
    required int cantidad,
    String? motivo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/movimientos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'producto_id': idProducto, // Flask espera 'producto_id' aquí
          'tipo': tipo.toUpperCase(),
          'cantidad': cantidad,
          'motivo': motivo,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error registrando el movimiento'},
      };
    }
  }

  // Endpoint 17: GET /movimientos?id_empresa=1
  static Future<Map<String, dynamic>> obtenerMovimientos({
    required int idEmpresa,
    int? idProducto,
    String? tipo,
  }) async {
    try {
      String query = 'id_empresa=$idEmpresa';
      if (idProducto != null) query += '&id_producto=$idProducto';
      if (tipo != null) query += '&tipo=${tipo.toUpperCase()}';

      final response = await http.get(
        Uri.parse('$baseUrl/movimientos?$query'),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error consultando movimientos'},
      };
    }
  }

  // Endpoint 19: GET /recomendaciones/compra
  static Future<Map<String, dynamic>> recomendacionesCompra(
    int idEmpresa, {
    int stockMinimo = 5,
    int stockObjetivo = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/recomendaciones/compra?id_empresa=$idEmpresa&stock_minimo=$stockMinimo&stock_objetivo=$stockObjetivo',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error generando recomendaciones de compra'},
      };
    }
  }

  static Future<Map<String, dynamic>> registrarInventario({
    required int idProducto,
    required String codigo,
    String estado = 'Disponible',
    String? ubicacion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inventario'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_producto': idProducto,
          'codigo': codigo,
          'estado': estado,
          'ubicacion': ubicacion,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'error': 'Error registrando unidad en inventario'},
      };
    }
  }
}
