import 'package:flutter/material.dart';
import 'screening_welcome_screen.dart';

/// Pantalla de carga simulada (SIN consumir API)
class ScreeningTestLoadingScreen extends StatefulWidget {
  final String userId;
  final String childId;

  const ScreeningTestLoadingScreen({
    super.key,
    required this.userId,
    required this.childId,
  });

  @override
  State<ScreeningTestLoadingScreen> createState() =>
      _ScreeningTestLoadingScreenState();
}

class _ScreeningTestLoadingScreenState
    extends State<ScreeningTestLoadingScreen> {
  late Future<void> _loadingFuture;
  int _progressSteps = 0;
  final int _totalSteps = 8; // 7 actividades + bienvenida

  @override
  void initState() {
    super.initState();
    // Carga simulada rápida (SIN API)
    _loadingFuture = _simulateLoading();
  }

  /// Simula carga rápida sin consumir API
  Future<void> _simulateLoading() async {
    try {
      // Actividades de "carga" - SIMULADAS sin acceso a API
      final loadingSteps = [
        'Inicializando recursos...',
        'Cargando instrucciones...',
        'Preparando actividades...',
        'Configurando audio...',
        'Optimizando interfaz...',
        'Sincronizando datos...',
        'Finalizando setup...',
        'Listo!',
      ];

      // Simular progreso
      for (int i = 0; i < loadingSteps.length; i++) {
        if (!mounted) return;

        // Actualizar progreso
        setState(() {
          _progressSteps = i + 1;
        });

        // Simular tiempo de carga (más rápido que OpenAI)
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Pausa final breve
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('Error during simulated load: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E5090),
      body: FutureBuilder<void>(
        future: _loadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono animado
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.psychology,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Título
                    const Text(
                      'Preparando Prueba',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Estamos cargando todas las actividades para una experiencia sin interrupciones...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Barra de progreso
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: _progressSteps / _totalSteps,
                              minHeight: 12,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.greenAccent.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$_progressSteps de $_totalSteps actividades cargadas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Puntos animados
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            // Si hay error, mostrar botón para reintentar
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Error al cargar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadingFuture = _simulateLoading();
                        _progressSteps = 0;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      foregroundColor: const Color(0xFF2E5090),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Carga completada, ir a la prueba
            return _NavigateToTest(
              userId: widget.userId,
              childId: widget.childId,
            );
          }
        },
      ),
    );
  }
}

class _NavigateToTest extends StatefulWidget {
  final String userId;
  final String childId;

  const _NavigateToTest({required this.userId, required this.childId});

  @override
  State<_NavigateToTest> createState() => _NavigateToTestState();
}

class _NavigateToTestState extends State<_NavigateToTest> {
  @override
  void initState() {
    super.initState();
    // Navegar automáticamente a la pantalla de bienvenida después de un pequeño delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ScreeningWelcomeScreen(
              userId: widget.userId,
              childId: widget.childId,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2E5090),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
