import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/inventario_notifier.dart';

class AsistenteIAScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const AsistenteIAScreen({super.key, required this.usuario});

  @override
  State<AsistenteIAScreen> createState() => _AsistenteIAScreenState();
}

class _AsistenteIAScreenState extends State<AsistenteIAScreen> {
  final TextEditingController _preguntaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Historial en el formato exacto que espera POST /asistente/chat:
  // [{"rol": "user" | "model", "contenido": "..."}]
  List<Map<String, String>> _historial = [];

  bool _enviando = false;
  bool _cargandoInsights = false;
  bool _mostrarPanelInsights = true;

  List<dynamic> _alertasStock = [];
  List<dynamic> _recomendacionesCompra = [];

  int get _idUsuario =>
      int.tryParse(widget.usuario['id_usuario']?.toString() ?? '0') ?? 0;

  int get _idEmpresa =>
      int.tryParse(widget.usuario['id_empresa']?.toString() ?? '1') ?? 1;

  static const List<Map<String, String>> _sugerenciasRapidas = [
    {
      'titulo': 'Más vendidos',
      'prompt': '¿Cuáles son los productos más vendidos de mi empresa y cómo se distribuyen las ventas?',
    },
    {
      'titulo': 'Estado inventario',
      'prompt': 'Dame un diagnóstico actual de mi inventario por estado (disponibles, vendidos, dañados o prestados).',
    },
    {
      'titulo': 'Ideas de promoción',
      'prompt': 'Con base en mis productos con menos ventas, sugíereme 3 estrategias de promoción concretas para rotar ese inventario.',
    },
    {
      'titulo': 'Plan de reposición',
      'prompt': 'Analiza el ritmo de salida de mis productos y recomiéndame qué prioridades debería tener al reabastecer.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mensajeBienvenida();
    _cargarInsightsRapidos();
    inventarioNotifier.addListener(_cargarInsightsRapidos);
  }

  @override
  void dispose() {
    inventarioNotifier.removeListener(_cargarInsightsRapidos);
    _preguntaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _mensajeBienvenida() {
    final nombre = widget.usuario['nombre'] ?? 'Administrador';
    _historial = [
      {
        'rol': 'model',
        'contenido':
            'Hola $nombre. Soy FlexiStock IA.\n\n'
            'Tengo acceso en tiempo real a los movimientos y existencias de tu negocio. '
            'Puedes preguntarme por rendimiento de productos, rotación, alertas de stock o ideas de promoción.',
      },
    ];
  }

  Future<void> _cargarInsightsRapidos() async {
    setState(() => _cargandoInsights = true);

    final resultados = await Future.wait([
      ApiService.alertasStockBajo(_idEmpresa, limite: 5),
      ApiService.recomendacionesCompra(
        _idEmpresa,
        stockMinimo: 5,
        stockObjetivo: 10,
      ),
    ]);

    if (!mounted) return;

    setState(() {
      if (resultados[0]['statusCode'] == 200) {
        _alertasStock = resultados[0]['data']['alertas'] ?? [];
      }
      if (resultados[1]['statusCode'] == 200) {
        _recomendacionesCompra = resultados[1]['data']['recomendaciones'] ?? [];
      }
      _cargandoInsights = false;
    });
  }

  Future<void> _enviarPregunta([String? textoPredefinido]) async {
    final texto = (textoPredefinido ?? _preguntaController.text).trim();
    if (texto.isEmpty || _enviando) return;

    if (textoPredefinido == null) {
      _preguntaController.clear();
    }

    // Construimos el historial limpio sin el mensaje inicial local de bienvenida
    final historialParaBackend = _historial
        .skip(1)
        .map((m) => {'rol': m['rol']!, 'contenido': m['contenido']!})
        .toList();

    setState(() {
      _historial.add({'rol': 'user', 'contenido': texto});
      _enviando = true;
    });
    _desplazarAlFinal();

    final res = await ApiService.consultarAsistenteIA(
      idUsuario: _idUsuario,
      idEmpresa: _idEmpresa,
      pregunta: texto,
      historial: historialParaBackend,
    );

    if (!mounted) return;

    if (res['statusCode'] == 200) {
      final respuestaIA =
          res['data']['respuesta']?.toString() ??
          'No se recibió texto de respuesta.';
      setState(() {
        _historial.add({'rol': 'model', 'contenido': respuestaIA});
        _enviando = false;
      });
    } else {
      final errorMsg =
          res['data']['error']?.toString() ??
          'Error al comunicarse con el asistente IA.';
      setState(() {
        _historial.add({
          'rol': 'model',
          'contenido': '⚠️ No pude completar la consulta: $errorMsg',
        });
        _enviando = false;
      });
    }

    _desplazarAlFinal();
  }

  void _analizarAlertasConIA() {
    if (_alertasStock.isEmpty) {
      _enviarPregunta(
        'Actualmente no tengo productos por debajo del límite de 5 unidades disponibles. ¿Qué me recomiendas para optimizar la rotación del inventario actual?',
      );
      return;
    }

    final detalle = _alertasStock
        .take(5)
        .map(
          (a) =>
              '${a['producto']} (${a['unidades_disponibles']} disponibles de ${a['total_objetos']} totales)',
        )
        .join(', ');

    _enviarPregunta(
      'Tengo alertas de stock bajo en estos productos: $detalle. '
      'Cruza esto con mi historial de ventas y dame un plan prioritario de compra.',
    );
  }

  void _reiniciarChat() {
    setState(() {
      _mensajeBienvenida();
    });
  }

  void _desplazarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 22),
            SizedBox(width: 10),
            Text(
              'FlexiStock IA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _mostrarPanelInsights
                ? 'Ocultar alertas rápidas'
                : 'Mostrar alertas rápidas',
            icon: Icon(
              _mostrarPanelInsights
                  ? Icons.analytics
                  : Icons.analytics_outlined,
              color: const Color(0xFF60A5FA),
            ),
            onPressed: () {
              setState(() => _mostrarPanelInsights = !_mostrarPanelInsights);
            },
          ),
          IconButton(
            tooltip: 'Nueva conversación',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
            onPressed: _enviando ? null : _reiniciarChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Panel colapsable de Alertas y Recomendaciones reales
          if (_mostrarPanelInsights) _buildPanelInsights(),

          // 2. Lista de mensajes del chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _historial.length + (_enviando ? 1 : 0),
              itemBuilder: (context, index) {
                if (_enviando && index == _historial.length) {
                  return _buildIndicadorEscribiendo();
                }
                final msg = _historial[index];
                final esUsuario = msg['rol'] == 'user';
                return _buildBurbujaMensaje(
                  contenido: msg['contenido'] ?? '',
                  esUsuario: esUsuario,
                );
              },
            ),
          ),

          // 3. Chips de preguntas rápidas
          _buildBarraSugerencias(),

          // 4. Caja de entrada de texto
          _buildInputMensaje(),
        ],
      ),
    );
  }

  Widget _buildPanelInsights() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: _cargandoInsights
          ? const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF60A5FA),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Sincronizando alertas de inventario...',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _alertasStock.isNotEmpty
                        ? Colors.amber.withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _alertasStock.isNotEmpty
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: _alertasStock.isNotEmpty
                        ? Colors.amberAccent
                        : const Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _alertasStock.isNotEmpty
                            ? '${_alertasStock.length} producto(s) con stock bajo'
                            : 'Niveles de stock saludables',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _recomendacionesCompra.isNotEmpty
                            ? '${_recomendacionesCompra.length} sugerencia(s) de compra lista(s)'
                            : 'Sin reposiciones urgentes pendientes',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _enviando ? null : _analizarAlertasConIA,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB)
                        .withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Analizar IA',
                    style: TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBurbujaMensaje({
    required String contenido,
    required bool esUsuario,
  }) {
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: esUsuario ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esUsuario ? 16 : 4),
            bottomRight: Radius.circular(esUsuario ? 4 : 16),
          ),
          border: esUsuario
              ? null
              : Border.all(color: const Color(0xFF334155), width: 1),
        ),
        child: SelectableText.rich(_formatearTextoMarkdown(contenido)),
      ),
    );
  }

  TextSpan _formatearTextoMarkdown(String texto) {
    const estiloBase = TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.4,
    );
    const estiloNegrita = TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.bold,
    );

    final List<TextSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*', dotAll: true);
    int ultimoIndice = 0;

    for (final match in regex.allMatches(texto)) {
      if (match.start > ultimoIndice) {
        spans.add(
          TextSpan(
            text: texto.substring(ultimoIndice, match.start),
            style: estiloBase,
          ),
        );
      }
      spans.add(TextSpan(text: match.group(1), style: estiloNegrita));
      ultimoIndice = match.end;
    }

    if (ultimoIndice < texto.length) {
      spans.add(
        TextSpan(text: texto.substring(ultimoIndice), style: estiloBase),
      );
    }

    return TextSpan(style: estiloBase, children: spans);
  }

  Widget _buildIndicadorEscribiendo() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF60A5FA),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'FlexiStock IA está analizando...',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraSugerencias() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _sugerenciasRapidas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _sugerenciasRapidas[index];
          return ActionChip(
            backgroundColor: const Color(0xFF1E293B),
            side: const BorderSide(color: Color(0xFF334155)),
            label: Text(
              item['titulo']!,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
            onPressed: _enviando
                ? null
                : () => _enviarPregunta(item['prompt']!),
          );
        },
      ),
    );
  }

  Widget _buildInputMensaje() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Color(0xFF334155))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _preguntaController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviarPregunta(),
                decoration: InputDecoration(
                  hintText: 'Pregúntale a FlexiStock IA...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: _enviando
                  ? const Color(0xFF334155)
                  : const Color(0xFF2563EB),
              radius: 22,
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _enviando ? null : () => _enviarPregunta(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
