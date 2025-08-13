import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget that creates a particle celebration effect
class ParticleCelebration extends StatefulWidget {
  const ParticleCelebration({
    super.key,
    this.particleCount = 50,
    this.duration = const Duration(seconds: 3),
    this.colors = const [
      Colors.yellow,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.green,
    ],
    this.onComplete,
  });

  final int particleCount;
  final Duration duration;
  final List<Color> colors;
  final VoidCallback? onComplete;

  @override
  State<ParticleCelebration> createState() => _ParticleCelebrationState();
}

class _ParticleCelebrationState extends State<ParticleCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _initializeParticles();

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(widget.particleCount, (index) => Particle(
        color: widget.colors[random.nextInt(widget.colors.length)],
        startX: random.nextDouble(),
        startY: random.nextDouble() * 0.2 + 0.4, // Start from middle area
        velocityX: (random.nextDouble() - 0.5) * 4,
        velocityY: -random.nextDouble() * 3 - 1,
        gravity: random.nextDouble() * 0.5 + 0.5,
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 4,
      ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        ),
    );
}

/// Represents a single particle in the celebration
class Particle {
  Particle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.gravity,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double gravity;
  final double size;
  final double rotation;
  final double rotationSpeed;

  Offset getPosition(double progress, Size canvasSize) {
    final time = progress * 3; // 3 seconds of physics simulation
    
    final x = startX * canvasSize.width + velocityX * time * 50;
    final y = startY * canvasSize.height + 
               velocityY * time * 50 + 
               0.5 * gravity * time * time * 50;

    return Offset(x, y);
  }

  double getRotation(double progress) => rotation + rotationSpeed * progress * 3;

  double getOpacity(double progress) {
    // Fade out in the last 30% of the animation
    if (progress > 0.7) {
      return 1.0 - (progress - 0.7) / 0.3;
    }
    return 1;
  }
}

/// Custom painter for drawing particles
class ParticlePainter extends CustomPainter {
  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  final List<Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final position = particle.getPosition(progress, size);
      final opacity = particle.getOpacity(progress);
      final rotation = particle.getRotation(progress);

      // Skip particles that are off-screen or fully transparent
      if (position.dx < -particle.size || 
          position.dx > size.width + particle.size ||
          position.dy > size.height + particle.size ||
          opacity <= 0) {
        continue;
      }

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);

      // Draw different particle shapes
      final shapeType = particle.color.hashCode % 3;
      switch (shapeType) {
        case 0:
          // Circle
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case 1:
          // Square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            ),
            paint,
          );
          break;
        case 2:
          // Triangle
          final path = Path();
          path.moveTo(0, -particle.size / 2);
          path.lineTo(-particle.size / 2, particle.size / 2);
          path.lineTo(particle.size / 2, particle.size / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => oldDelegate.progress != progress;
}

/// Widget that shows confetti falling from the top
class ConfettiCelebration extends StatefulWidget {
  const ConfettiCelebration({
    super.key,
    this.duration = const Duration(seconds: 4),
    this.onComplete,
  });

  final Duration duration;
  final VoidCallback? onComplete;

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiPiece> _confetti;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _initializeConfetti();

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  void _initializeConfetti() {
    final random = math.Random();
    _confetti = List.generate(100, (index) => ConfettiPiece(
        color: HSVColor.fromAHSV(
          1,
          random.nextDouble() * 360,
          0.7 + random.nextDouble() * 0.3,
          0.8 + random.nextDouble() * 0.2,
        ).toColor(),
        startX: random.nextDouble(),
        fallSpeed: random.nextDouble() * 2 + 1,
        swayAmount: random.nextDouble() * 100 + 50,
        swaySpeed: random.nextDouble() * 2 + 1,
        size: random.nextDouble() * 6 + 3,
        rotationSpeed: (random.nextDouble() - 0.5) * 6,
      ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
          painter: ConfettiPainter(
            confetti: _confetti,
            progress: _controller.value,
          ),
          size: Size.infinite,
        ),
    );
}

/// Represents a single piece of confetti
class ConfettiPiece {
  ConfettiPiece({
    required this.color,
    required this.startX,
    required this.fallSpeed,
    required this.swayAmount,
    required this.swaySpeed,
    required this.size,
    required this.rotationSpeed,
  });

  final Color color;
  final double startX;
  final double fallSpeed;
  final double swayAmount;
  final double swaySpeed;
  final double size;
  final double rotationSpeed;

  Offset getPosition(double progress, Size canvasSize) {
    final time = progress * 4; // 4 seconds of falling
    
    final x = startX * canvasSize.width + 
               math.sin(time * swaySpeed) * swayAmount;
    final y = -size + (canvasSize.height + size * 2) * progress * fallSpeed;

    return Offset(x, y);
  }

  double getRotation(double progress) => progress * rotationSpeed * 4;
}

/// Custom painter for confetti
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({
    required this.confetti,
    required this.progress,
  });

  final List<ConfettiPiece> confetti;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confetti) {
      final position = piece.getPosition(progress, size);
      final rotation = piece.getRotation(progress);

      // Skip pieces that are off-screen
      if (position.dx < -piece.size || 
          position.dx > size.width + piece.size ||
          position.dy > size.height + piece.size) {
        continue;
      }

      final paint = Paint()
        ..color = piece.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);

      // Draw rectangle confetti piece
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}