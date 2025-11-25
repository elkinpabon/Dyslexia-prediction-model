import 'package:flutter/material.dart';
import 'screening_test_screen.dart';

/// Pantalla de bienvenida que aparece ANTES de iniciar el screening test
/// Incluye instrucciones detalladas con pasos, iconos y audio automático
class ScreeningWelcomeScreen extends StatefulWidget {
  final String userId;
  final String childId;

  const ScreeningWelcomeScreen({
    super.key,
    required this.userId,
    required this.childId,
  });

  @override
  State<ScreeningWelcomeScreen> createState() => _ScreeningWelcomeScreenState();
}

class _ScreeningWelcomeScreenState extends State<ScreeningWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Solo animar, sin reproducir audio
      // El audio se reproducirá cuando se abra el modal de bienvenida en screening_test_screen
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _continueToTest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScreeningTestScreen(userId: widget.userId, childId: widget.childId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2E5090).withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Icono principal animado
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2E5090),
                            const Color(0xFF4CAF50),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E5090).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.celebration,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.2, 0.6),
                      ),
                    ),
                    child: Text(
                      '¡Bienvenido!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                            color: const Color(0xFF2E5090),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtítulo
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.3, 0.7),
                      ),
                    ),
                    child: Text(
                      'Evaluación de habilidades de lectura y audición',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Pasos con iconos
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.4, 0.8),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInstructionStep(
                          icon: Icons.timer,
                          title: '48 Actividades',
                          description: 'Aproximadamente 15-20 minutos',
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionStep(
                          icon: Icons.check_circle,
                          title: 'Sin presión',
                          description:
                              'No hay respuestas correctas o incorrectas',
                          color: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionStep(
                          icon: Icons.volume_up,
                          title: 'Escucha disponible',
                          description:
                              'Puedes repetir las instrucciones cuando quieras',
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionStep(
                          icon: Icons.favorite,
                          title: 'Haz tu mejor esfuerzo',
                          description:
                              'Cada respuesta cuenta, así que tómate tu tiempo',
                          color: Colors.pink,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Información adicional
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.5, 0.9),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Asegúrate de tener el volumen activado para escuchar mejor',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botón continuar
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.6, 1.0),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _continueToTest,
                        icon: const Icon(Icons.arrow_forward, size: 24),
                        label: const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 8,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5090),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
