import 'package:flutter/material.dart';

/// Widget animado de micrófono para reconocimiento de voz
class AnimatedMicrophone extends StatefulWidget {
  final bool isListening;
  final VoidCallback? onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedMicrophone({
    super.key,
    required this.isListening,
    this.onTap,
    this.size = 80,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<AnimatedMicrophone> createState() => _AnimatedMicrophoneState();
}

class _AnimatedMicrophoneState extends State<AnimatedMicrophone>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedMicrophone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
      } else {
        _pulseController.stop();
        _waveController.stop();
        _pulseController.reset();
        _waveController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.red;
    final inactiveColor = widget.inactiveColor ?? Colors.blue;
    final currentColor = widget.isListening ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ondas de sonido animadas
          if (widget.isListening)
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size * 2, widget.size * 2),
                  painter: SoundWavePainter(
                    animation: _waveController.value,
                    color: activeColor,
                  ),
                );
              },
            ),

          // Círculo pulsante
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentColor.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withOpacity(0.4),
                        blurRadius: widget.isListening ? 20 : 10,
                        spreadRadius: widget.isListening ? 5 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isListening ? Icons.mic : Icons.mic_none,
                    size: widget.size * 0.5,
                    color: currentColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Painter personalizado para ondas de sonido
class SoundWavePainter extends CustomPainter {
  final double animation;
  final Color color;

  SoundWavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);

    // Dibujar 3 ondas concéntricas
    for (int i = 1; i <= 3; i++) {
      final radius = (size.width / 2) * (animation + (i * 0.2));
      final opacity = (1 - animation) * (1 - (i * 0.2));

      if (radius < size.width / 2) {
        paint.color = color.withOpacity(opacity * 0.3);
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SoundWavePainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}

/// Widget de visualización de nivel de audio
class AudioLevelIndicator extends StatelessWidget {
  final double level; // 0.0 a 1.0
  final Color? color;
  final int barCount;

  const AudioLevelIndicator({
    super.key,
    required this.level,
    this.color,
    this.barCount = 20,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? Theme.of(context).primaryColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (index) {
        final barHeight = ((index + 1) / barCount) * 100;
        final isActive = (index / barCount) <= level;

        return Container(
          width: 4,
          height: isActive ? barHeight : 20,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? barColor : barColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
