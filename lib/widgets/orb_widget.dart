import 'dart:math';
import 'package:flutter/material.dart';
import '../services/speech_service.dart';

class OrbWidget extends StatelessWidget {
  final ListeningState state;
  final AnimationController controller;
  final AnimationController pulseController;

  const OrbWidget({
    super.key,
    required this.state,
    required this.controller,
    required this.pulseController,
  });

  Color get _primaryColor {
    switch (state) {
      case ListeningState.idle:
        return const Color(0xFF1A3A5C);
      case ListeningState.wakeWord:
        return const Color(0xFF0066FF);
      case ListeningState.listening:
        return const Color(0xFF00D4FF);
      case ListeningState.processing:
        return const Color(0xFF7B2FFF);
    }
  }

  Color get _glowColor {
    switch (state) {
      case ListeningState.idle:
        return const Color(0xFF0066FF);
      case ListeningState.wakeWord:
        return const Color(0xFF0066FF);
      case ListeningState.listening:
        return const Color(0xFF00D4FF);
      case ListeningState.processing:
        return const Color(0xFF7B2FFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, pulseController]),
      builder: (context, child) {
        final t = controller.value;
        final pulse = pulseController.value;
        
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring 1
              if (state == ListeningState.listening ||
                  state == ListeningState.processing)
                _buildRing(60 + pulse * 20, _glowColor, 0.1 - pulse * 0.1),
              
              // Outer ring 2
              _buildRing(56, _glowColor, 0.15),
              
              // Rotating dashes
              Transform.rotate(
                angle: t * 2 * pi,
                child: _buildDashedRing(50, _glowColor, 0.4),
              ),
              
              // Counter rotate
              Transform.rotate(
                angle: -t * 2 * pi * 0.7,
                child: _buildDashedRing(44, _glowColor, 0.25),
              ),
              
              // Main orb
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primaryColor.withOpacity(0.9),
                      _primaryColor.withOpacity(0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _glowColor.withOpacity(0.6),
                      blurRadius: 20 + pulse * 10,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _glowColor.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: _buildIcon(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    switch (state) {
      case ListeningState.idle:
        return const Icon(Icons.mic_none, color: Colors.white38, size: 28);
      case ListeningState.wakeWord:
        return const Icon(Icons.hearing, color: Colors.white60, size: 28);
      case ListeningState.listening:
        return const Icon(Icons.mic, color: Colors.white, size: 30);
      case ListeningState.processing:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withOpacity(0.8),
          ),
        );
    }
  }

  Widget _buildRing(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(opacity),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildDashedRing(double size, Color color, double opacity) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DashedCirclePainter(color.withOpacity(opacity)),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  
  _DashedCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 16;
    const dashAngle = 2 * pi / dashCount;
    const dashLength = dashAngle * 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashLength,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
