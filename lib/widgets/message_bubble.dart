import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isJarvis) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(child: _buildBubble()),
          const SizedBox(width: 8),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF001A33),
        border: Border.all(
            color: const Color(0xFF00D4FF).withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Center(
        child: Text('J',
            style: TextStyle(
                color: Color(0xFF00D4FF),
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A2E),
        border: Border.all(color: Colors.white12),
      ),
      child: const Icon(Icons.person, color: Colors.white38, size: 16),
    );
  }

  Widget _buildBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.isUser
            ? const Color(0xFF0A1F3D)
            : const Color(0xFF071420),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.isUser ? 16 : 4),
          bottomRight: Radius.circular(message.isUser ? 4 : 16),
        ),
        border: Border.all(
          color: message.isUser
              ? const Color(0xFF0066FF).withOpacity(0.3)
              : const Color(0xFF00D4FF).withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: (message.isUser
                    ? const Color(0xFF0066FF)
                    : const Color(0xFF00D4FF))
                .withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                message.imageData!,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          if (message.hasImage) const SizedBox(height: 8),
          Text(
            message.text,
            style: TextStyle(
              color: message.isUser ? Colors.white70 : Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
