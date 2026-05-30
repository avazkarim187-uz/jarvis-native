import 'package:flutter/material.dart';
import '../services/speech_service.dart';

class StatusBarWidget extends StatelessWidget {
  final String status;
  final ListeningState state;

  const StatusBarWidget({
    super.key,
    required this.status,
    required this.state,
  });

  Color get _dotColor {
    switch (state) {
      case ListeningState.idle:
        return Colors.white24;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dotColor,
              boxShadow: [
                BoxShadow(
                  color: _dotColor.withOpacity(0.8),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              status,
              key: ValueKey(status),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
