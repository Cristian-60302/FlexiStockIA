import 'dart:convert';

import 'package:flutter/foundation.dart'; // Requerido para kIsWeb
import 'package:http/http.dart' as http;

class ApiService {
  // Ajustado al puerto 3000 de tu Flask
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

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
