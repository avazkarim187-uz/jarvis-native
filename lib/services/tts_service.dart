import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  
  Function()? onSpeakingStarted;
  Function()? onSpeakingCompleted;

  Future<void> initialize() async {
    await _tts.setLanguage('ru-RU');
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.9); // Biroz past ton — erkakcha ovoz
    
    _tts.setStartHandler(() {
      _isSpeaking = true;
      onSpeakingStarted?.call();
    });
    
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onSpeakingCompleted?.call();
    });
    
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      onSpeakingCompleted?.call();
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    await stop();
    
    // Tilni aniqlash (sodda usul)
    final lang = _detectLanguage(text);
    await _tts.setLanguage(lang);
    
    await _tts.speak(text);
  }

  String _detectLanguage(String text) {
    // Kirill harflari bormi?
    final cyrillicRegex = RegExp(r'[а-яёА-ЯЁ]');
    final uzbekCyrillicRegex = RegExp(r'[ўқғҳ]', caseSensitive: false);
    
    if (uzbekCyrillicRegex.hasMatch(text)) {
      return 'uz-UZ';
    } else if (cyrillicRegex.hasMatch(text)) {
      return 'ru-RU';
    }
    return 'en-US';
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }

  bool get isSpeaking => _isSpeaking;
}
