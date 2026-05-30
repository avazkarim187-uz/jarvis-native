import 'dart:typed_data';

enum MessageRole { user, jarvis }
enum MessageType { text, image, screenAnalysis }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final Uint8List? imageData;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    this.imageData,
    this.type = MessageType.text,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isJarvis => role == MessageRole.jarvis;
  bool get hasImage => imageData != null;
}
