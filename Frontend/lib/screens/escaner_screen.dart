import 'package:flutter/material.dart';

class EscanerScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const EscanerScreen({super.key, required this.usuario});
  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Prueba de Escáner',
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
    );
  }
}
