import 'dart:convert';

import 'package:frontend/config/constants.dart';
import 'package:flutter/foundation.dart'; // Requerido para kIsWeb
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
}
