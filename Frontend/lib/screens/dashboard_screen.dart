import 'package:flutter/material.dart';

import '../services/api_service.dart'; // Asegúrate de que la ruta coincida con la tuya

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario;

  const DashboardScreen({super.key, required this.usuario});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _alertas = [];
  int _totalUnidades = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    // Extraemos el id_empresa del usuario (por defecto 1 si falla)
    final int idEmpresa = widget.usuario?['id_empresa'] ?? 1;

    // Ejecutamos ambas peticiones al mismo tiempo
    final resultados = await Future.wait([
      ApiService.alertasStockBajo(idEmpresa),
      ApiService.resumenInventario(idEmpresa),
    ]);

    final resAlertas = resultados[0];
    final resResumen = resultados[1];

    int unidades = 0;
    List<dynamic> alertasObtenidas = [];

    // Procesamos el resumen para calcular el total de unidades físicas
    if (resResumen['statusCode'] == 200) {
      final resumen = resResumen['data']['resumen'] as List<dynamic>? ?? [];
      for (var item in resumen) {
        unidades += (item['disponibles'] as int? ?? 0);
      }
    }

    // Procesamos las alertas
    if (resAlertas['statusCode'] == 200) {
      alertasObtenidas = resAlertas['data']['alertas'] as List<dynamic>? ?? [];
    }

    setState(() {
      _totalUnidades = unidades;
      _alertas = alertasObtenidas;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user = widget.usuario ?? {};
    final String nombre = user['nombre']?.toString() ?? 'Usuario';
    final String correo = user['correo']?.toString() ?? 'Sin correo asignado';

    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Saludo e información del usuario
                    Text(
                      '¡Hola, $nombre!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Correo: $correo',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Botones de Acción Rápida
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.point_of_sale_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              'Venta',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.move_to_inbox_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            label: const Text(
                              'Recepción',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. Tarjeta Principal: Inventario Total
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Inventario total',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '\$ 45.800.000', // Próximamente se calculará multiplicando stock * precio
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Tarjetas Secundarias
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Ventas hoy',
                            value: '\$ 1.250.000',
                            valueColor: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Productos',
                            value: '$_totalUnidades unds', // Variable dinámica
                            valueColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 5. Alertas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Alertas de stock',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Generación dinámica de alertas
                    if (_alertas.isEmpty)
                      const Text(
                        'Todo el inventario está en niveles óptimos.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      )
                    else
                      ..._alertas.map((alerta) {
                        final disponibles = alerta['unidades_disponibles'] ?? 0;
                        final isCritical =
                            disponibles <= 2; // Lógica para marcar crítico

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildAlertCard(
                            title: alerta['producto'],
                            subtitle: isCritical
                                ? 'Crítico: $disponibles unds'
                                : 'Por agotar: $disponibles unds',
                            isCritical: isCritical,
                            onPedirPressed: () {
                              // Lógica para pedir más unidades
                            },
                          ),
                        );
                      }).toList(),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String subtitle,
    required bool isCritical,
    required VoidCallback onPedirPressed,
  }) {
    final borderColor = isCritical ? Colors.redAccent : Colors.amber;
    final backgroundColor = isCritical
        ? const Color(0xFF450A0A)
        : const Color(0xFF422006);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.warning_rounded : Icons.info_outline_rounded,
            color: borderColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onPedirPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: borderColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Pedir',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
