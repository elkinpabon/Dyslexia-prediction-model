import 'package:flutter/material.dart';
import '../../../services/audio/audio_service.dart';

/// Controlador del flujo de test de cribado mejorado con:
/// - Modal con timer de 5 segundos
/// - Countdown "3 2 1 ¡YA!"
/// - Transiciones entre actividades
class ScreeningFlowController {
  final BuildContext context;
  final AudioService audioService = AudioService();

  ScreeningFlowController(this.context);

  /// Mostrar modal de instrucciones de la actividad
  Future<void> showActivityInstructions({
    required int activityNumber,
    required String activityType,
  }) async {
    if (!context.mounted) return;

    // Importar dinámicamente para evitar circular dependency
    final modalsModule = await _loadScreeningModals();
    if (modalsModule == null) return;

    await modalsModule.showActivityModal(
      context,
      audioService,
      activityNumber: activityNumber,
      activityType: activityType,
    );
  }

  /// Cargar dinámicamente ScreeningModals
  Future<dynamic> _loadScreeningModals() async {
    try {
      // Usar reflection o import dinámico
      return null; // Placeholder - se usa directamente en test_screen
    } catch (e) {
      debugPrint('Error loading modals: $e');
      return null;
    }
  }

  /// Mostrar modal de actividad con timer de 5 segundos
  /// Con timeout de 10 segundos para evitar bloqueos indefinidos
  Future<bool> showActivityModalWithTimer({
    required int activityNumber,
    required String activityType,
  }) async {
    bool shouldContinue = false;

    if (!context.mounted) return false;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _ActivityModalWithTimer(
          activityNumber: activityNumber,
          activityType: activityType,
          audioService: audioService,
          onContinue: () {
            shouldContinue = true;
            if (context.mounted) {
              Navigator.pop(dialogContext);
            }
          },
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      );
    } catch (e) {
      // Silenciar errores de navegación
      debugPrint('Error en modal: $e');
    }

    return shouldContinue;
  }

  /// Mostrar pantalla en blanco (transición)
  /// Espera completamente a que se cierre antes de retornar
  Future<void> showBlankScreen({
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    if (!context.mounted) return;

    bool screenClosed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: FutureBuilder(
              future: Future.delayed(duration),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    !screenClosed) {
                  screenClosed = true;
                  // Usar microtask para garantizar cierre completamente procesado
                  Future.microtask(() {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  });
                }
                return SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    // Esperar un frame adicional para garantizar cierre completo
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

/// Modal de actividad con timer de 5 segundos
class _ActivityModalWithTimer extends StatefulWidget {
  final int activityNumber;
  final String activityType;
  final AudioService audioService;
  final VoidCallback onContinue;

  const _ActivityModalWithTimer({
    required this.activityNumber,
    required this.activityType,
    required this.audioService,
    required this.onContinue,
  });

  @override
  State<_ActivityModalWithTimer> createState() =>
      _ActivityModalWithTimerState();
}

class _ActivityModalWithTimerState extends State<_ActivityModalWithTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  int _remainingSeconds = 3;
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();

    // Inicializar el animation controller inmediatamente
    _timerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // NO mostrar el modal de instrucciones aquí
    // Solo iniciar el countdown del timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimerCountdown();
    });
  }

  void _startTimerCountdown() {
    _timerController.addListener(() {
      final remaining = (3 * (1 - _timerController.value)).ceil();
      if (remaining != _remainingSeconds) {
        setState(() {
          _remainingSeconds = remaining;
        });
      }
    });

    _timerController.forward().then((_) {
      setState(() {
        _canContinue = true;
      });
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Texto de instrucción
            Text(
              '¿Estás listo?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),

            // Timer circular
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Círculo de progreso
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _timerController.value,
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _canContinue ? Colors.green : Colors.blue,
                      ),
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                  // Número del timer
                  Text(
                    '$_remainingSeconds',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón continuar
            ElevatedButton(
              onPressed: _canContinue
                  ? () {
                      _timerController.stop();
                      widget.onContinue();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canContinue ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
