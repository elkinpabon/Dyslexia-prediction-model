import 'package:flutter/material.dart';
import '../models/activity_result.dart';
import 'custom_button.dart';

/// Diálogo profesional para mostrar resultados de actividades
class ResultDialog extends StatefulWidget {
  final ActivityResult result;
  final VoidCallback? onRepeat;
  final VoidCallback? onClose;

  const ResultDialog({
    super.key,
    required this.result,
    this.onRepeat,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required ActivityResult result,
    VoidCallback? onRepeat,
    VoidCallback? onClose,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Result Dialog',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ResultDialog(
          result: result,
          onRepeat: onRepeat,
          onClose: onClose,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _resultColor => widget.result.result == "SÍ"
      ? const Color(0xFFE57373)
      : const Color(0xFF81C784);

  IconData get _resultIcon => widget.result.result == "SÍ"
      ? Icons.warning_amber_rounded
      : Icons.check_circle_outline;

  String get _resultTitle => widget.result.result == "SÍ"
      ? "Indicadores Detectados"
      : "Sin Indicadores";

  String get _resultMessage => widget.result.result == "SÍ"
      ? "Se detectaron posibles indicadores de dislexia. Se recomienda consultar con un especialista."
      : "No se detectaron indicadores significativos. ¡Excelente desempeño!";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 16,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, _resultColor.withOpacity(0.1)],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono animado
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _resultColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _resultIcon,
                            size: 48,
                            color: _resultColor,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Título
                        Text(
                          _resultTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _resultColor,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Actividad
                        Text(
                          widget.result.activityName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Estadísticas
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildStatRow(
                                "Probabilidad",
                                "${(widget.result.probability * 100).toStringAsFixed(1)}%",
                                Icons.analytics_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildStatRow(
                                "Confianza",
                                "${(widget.result.confidence * 100).toStringAsFixed(1)}%",
                                Icons.verified_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildStatRow(
                                "Nivel de Riesgo",
                                widget.result.riskLevel,
                                Icons.speed,
                              ),
                              const SizedBox(height: 12),
                              _buildStatRow(
                                "Duración",
                                "${widget.result.duration.inSeconds}s",
                                Icons.timer_outlined,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Mensaje
                        Text(
                          _resultMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Botones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (widget.onRepeat != null)
                              Expanded(
                                child: CustomButton(
                                  text: "Repetir",
                                  icon: Icons.refresh,
                                  isOutlined: true,
                                  color: _resultColor,
                                  textColor: _resultColor,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.onRepeat?.call();
                                  },
                                ),
                              ),
                            if (widget.onRepeat != null)
                              const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: "Cerrar",
                                icon: Icons.home,
                                color: _resultColor,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onClose?.call();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _resultColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: _resultColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
