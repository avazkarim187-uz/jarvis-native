import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/camera_service.dart';
import '../widgets/orb_widget.dart';
import '../widgets/message_bubble.dart';
import '../widgets/status_bar_widget.dart';

class JarvisScreen extends StatefulWidget {
  const JarvisScreen({super.key});

  @override
  State<JarvisScreen> createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen>
    with TickerProviderStateMixin {
  
  // Services
  final GeminiService _gemini = GeminiService();
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();
  final CameraService _camera = CameraService();

  // State
  final List<ChatMessage> _messages = [];
  String _partialText = '';
  ListeningState _listeningState = ListeningState.idle;
  bool _cameraVisible = false;
  bool _isInitialized = false;
  String _statusText = 'Initializing...';

  // Scroll
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _orbController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Ruxsatlarni so'rash
    await _requestPermissions();
    
    // TTS
    await _tts.initialize();
    _tts.onSpeakingCompleted = _onTtsDone;
    
    // Speech
    final speechOk = await _speech.initialize();
    _speech.onWakeWordDetected = _onWakeWordDetected;
    _speech.onSpeechResult = _onSpeechResult;
    _speech.onPartialResult = _onPartialResult;
    _speech.onStateChanged = _onStateChanged;
    
    // Camera
    await _camera.initialize();
    
    setState(() {
      _isInitialized = true;
      _statusText = 'Listening for "Jarvis"...';
    });
    
    // Wake word tinglashni boshlash
    if (speechOk) {
      await _speech.startWakeWordListening();
      await _tts.speak('Jarvis tayyor. Meni chaqiring.');
    } else {
      setState(() => _statusText = 'Mikrofon ruxsati kerak');
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();
  }

  // Wake word aniqlandi
  void _onWakeWordDetected(String word) {
    HapticFeedback.mediumImpact();
    Vibration.vibrate(duration: 100);
    _pulseController.forward(from: 0);
    setState(() => _statusText = 'Listening...');
  }

  // To'liq savol olindi
  void _onSpeechResult(String text) async {
    if (text.isEmpty) {
      _speech.startWakeWordListening();
      return;
    }
    
    setState(() {
      _partialText = '';
      _statusText = 'Thinking...';
    });
    
    _speech.setProcessing();
    _tts.stop();

    // Kamera fotosi olinadimi?
    Uint8List? imageData;
    final bool needsCamera = _detectNeedsCamera(text);
    
    if (needsCamera && _camera.isInitialized) {
      imageData = await _camera.captureImage();
      setState(() => _cameraVisible = true);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _cameraVisible = false);
    }

    // User xabarini qo'shish
    _addMessage(ChatMessage(
      role: MessageRole.user,
      text: text,
      imageData: imageData,
      type: imageData != null ? MessageType.image : MessageType.text,
    ));

    // AI ga yuborish
    String response;
    if (imageData != null) {
      response = await _gemini.sendMessageWithImage(text, imageData);
    } else {
      response = await _gemini.sendMessage(text);
    }

    // Jarvis javobi
    _addMessage(ChatMessage(
      role: MessageRole.jarvis,
      text: response,
    ));

    setState(() => _statusText = 'Speaking...');
    await _tts.speak(response);
  }

  bool _detectNeedsCamera(String text) {
    final lowerText = text.toLowerCase();
    final cameraKeywords = [
      'ko\'r', 'nima bor', 'ko\'ryapsan', 'tasvir', 'rasm',
      'посмотри', 'видишь', 'что здесь', 'покажи',
      'look', 'see', 'what is this', 'what do you see', 'camera',
    ];
    return cameraKeywords.any((kw) => lowerText.contains(kw));
  }

  // Partial natija (real-time)
  void _onPartialResult(String text) {
    setState(() => _partialText = text);
  }

  // State o'zgardi
  void _onStateChanged(ListeningState state) {
    setState(() {
      _listeningState = state;
      switch (state) {
        case ListeningState.idle:
          _statusText = 'Idle';
          break;
        case ListeningState.wakeWord:
          _statusText = 'Say "Jarvis"...';
          break;
        case ListeningState.listening:
          _statusText = 'Listening...';
          break;
        case ListeningState.processing:
          _statusText = 'Processing...';
          break;
      }
    });
  }

  // TTS tugadi — wake word ga qaytish
  void _onTtsDone() {
    if (mounted) {
      _speech.startWakeWordListening();
      setState(() => _statusText = 'Say "Jarvis"...');
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() => _messages.add(message));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Manual tugma
  Future<void> _onManualPress() async {
    if (_listeningState == ListeningState.processing) return;
    
    HapticFeedback.lightImpact();
    await _tts.stop();
    await _speech.startManualListening();
  }

  // Kamerani ko'rsatish toggle
  void _toggleCamera() {
    setState(() => _cameraVisible = !_cameraVisible);
  }

  // Chat tozalash
  void _clearChat() {
    _gemini.resetChat();
    setState(() => _messages.clear());
  }

  @override
  void dispose() {
    _speech.dispose();
    _tts.stop();
    _camera.dispose();
    _orbController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A0F),
      body: Stack(
        children: [
          // Background grid
          _buildBackground(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Camera preview (optional)
                if (_cameraVisible && _camera.isInitialized)
                  _buildCameraPreview(),
                
                // Messages
                Expanded(
                  child: _buildMessageList(),
                ),
                
                // Partial text
                if (_partialText.isNotEmpty)
                  _buildPartialText(),
                
                // Orb & controls
                _buildOrbSection(),
                
                // Status
                StatusBarWidget(
                  status: _statusText,
                  state: _listeningState,
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _GridPainter(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'JARVIS',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
          // Actions
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _cameraVisible ? Icons.camera_alt : Icons.camera_alt_outlined,
                  color: _cameraVisible
                      ? const Color(0xFF00D4FF)
                      : Colors.white38,
                  size: 20,
                ),
                onPressed: _toggleCamera,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white38, size: 20),
                onPressed: _clearChat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _camera.controller != null
          ? CameraPreview(_camera.controller!)
          : const Center(
              child: Text('Camera unavailable',
                  style: TextStyle(color: Colors.white38)),
            ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none,
                color: Colors.white12, size: 48),
            const SizedBox(height: 12),
            const Text(
              '"Jarvis" deb chaqiring',
              style: TextStyle(color: Colors.white24, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildPartialText() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00D4FF).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF00D4FF).withOpacity(0.2)),
      ),
      child: Text(
        _partialText,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOrbSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera switch
          if (_camera.hasMultipleCameras)
            _buildCircleButton(
              icon: Icons.flip_camera_android,
              onTap: () => _camera.switchCamera(),
            ),
          
          const SizedBox(width: 24),
          
          // Main ORB
          GestureDetector(
            onTap: _onManualPress,
            child: OrbWidget(
              state: _listeningState,
              controller: _orbController,
              pulseController: _pulseController,
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Stop button
          _buildCircleButton(
            icon: Icons.stop,
            onTap: () async {
              await _tts.stop();
              await _speech.startWakeWordListening();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white38, size: 20),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Gradient overlay
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 0.8,
        colors: [
          const Color(0xFF001830).withOpacity(0.0),
          const Color(0xFF050A0F).withOpacity(0.6),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
