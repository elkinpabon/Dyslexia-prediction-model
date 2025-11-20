import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'activities/visual_discrimination_activity_screen.dart';
import 'activities/sequence_rounds_activity_screen.dart';
import 'activities/speed_rounds_activity_screen.dart';
import 'activities/memory_rounds_activity_screen.dart';
import 'activities/text_rounds_activity_screen.dart';

/// Menú de juegos educativos (5 actividades de práctica)
class GamesMenuScreen extends StatelessWidget {
  final String userId;
  final String childId;

  const GamesMenuScreen({
    super.key,
    required this.userId,
    required this.childId,
  });

  @override
  Widget build(BuildContext context) {
    final activities = [
      _ActivityItem(
        title: 'Discriminación Visual',
        subtitle: 'Letras confundibles',
        description: '10 rondas • Identifica diferencias entre b/d/p/q',
        icon: Icons.visibility,
        color: Colors.indigo,
        screen: VisualDiscriminationActivityScreen(
          userId: userId,
          childId: childId,
        ),
      ),
      _ActivityItem(
        title: 'Sonido-Letra',
        subtitle: 'Correspondencia auditiva',
        description: '10 rondas • Escucha y selecciona la letra correcta',
        icon: Icons.hearing,
        color: Colors.blue,
        screen: SequenceRoundsActivityScreen(userId: userId, childId: childId),
      ),
      _ActivityItem(
        title: 'Memoria Secuencial',
        subtitle: 'Secuencias de letras',
        description: '10 rondas • Memoriza y reproduce el orden',
        icon: Icons.memory,
        color: Colors.pink,
        screen: MemoryRoundsActivityScreen(userId: userId, childId: childId),
      ),
      _ActivityItem(
        title: 'Dictado Auditivo',
        subtitle: 'Escucha y escribe',
        description: '10 rondas • Transcribe las palabras correctamente',
        icon: Icons.keyboard,
        color: Colors.teal,
        screen: TextRoundsActivityScreen(userId: userId, childId: childId),
      ),
      _ActivityItem(
        title: 'Errores Ortográficos',
        subtitle: 'Detección de errores',
        description: '10 rondas • Encuentra palabras mal escritas',
        icon: Icons.spellcheck,
        color: Colors.orange,
        screen: SpeedRoundsActivityScreen(userId: userId, childId: childId),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Juegos Educativos'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selecciona una actividad para practicar. Los juegos NO generan predicción de dislexia.',
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
            const SizedBox(height: 24),

            // Lista de actividades
            ...activities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildActivityCard(context, activity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, _ActivityItem activity) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => activity.screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [activity.color.withOpacity(0.8), activity.color],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: activity.color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => activity.screen),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(activity.icon, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
