import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

enum ListeningState {
  idle,          // Hech narsa qilmayapti
  wakeWord,      // "Jarvis" so'zini kutmoqda
  listening,     // Savol tinglayapti
  processing,    // AI javob bermoqda
}

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  
  ListeningState _state = ListeningState.idle;
  ListeningState get state => _state;

  // Callbacks
  Function(String)? onWakeWordDetected;
  Function(String)? onSpeechResult;
  Function(String)? onPartialResult;
  Function(ListeningState)? onStateChanged;

  static const List<String> wakeWords = [
    'jarvis', 'жарвис', 'жавис', 'harvey', 'java'
  ];

  Future<bool> initialize() async {
    _isInitialized = await _speech.initialize(
      onError: (error) => _handleError(error.errorMsg),
      onStatus: (status) => _handleStatus(status),
    );
    return _isInitialized;
  }

  void _setState(ListeningState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }

  // Wake word uchun doim tinglash
  Future<void> startWakeWordListening() async {
    if (!_isInitialized) await initialize();
    _setState(ListeningState.wakeWord);
    await _listenForWakeWord();
  }

  Future<void> _listenForWakeWord() async {
    if (_state != ListeningState.wakeWord) return;
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords.toLowerCase();
          // Wake word aniqlash
          for (final word in wakeWords) {
            if (text.contains(word)) {
              onWakeWordDetected?.call(word);
              _startCommandListening();
              return;
            }
          }
          // Wake word topilmasa, davom etish
          if (_state == ListeningState.wakeWord) {
            Future.delayed(const Duration(milliseconds: 300), _listenForWakeWord);
          }
        }
      },
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
      localeId: 'uz_UZ', // O'zbek tili
      cancelOnError: false,
    );
  }

  Future<void> _startCommandListening() async {
    _setState(ListeningState.listening);
    String finalText = '';
    
    await _speech.listen(
      onResult: (result) {
        onPartialResult?.call(result.recognizedWords);
        if (result.finalResult) {
          finalText = result.recognizedWords;
          if (finalText.isNotEmpty) {
            onSpeechResult?.call(finalText);
          } else {
            // Bo'sh natija — yana wake word tinglash
            startWakeWordListening();
          }
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      localeId: _detectLocale(),
      cancelOnError: false,
    );
  }

  // Manual trigger (tugma bosish bilan)
  Future<void> startManualListening() async {
    if (!_isInitialized) await initialize();
    _setState(ListeningState.listening);
    
    await _speech.listen(
      onResult: (result) {
        onPartialResult?.call(result.recognizedWords);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          onSpeechResult?.call(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      localeId: _detectLocale(),
    );
  }

  String _detectLocale() {
    // Availble locales dan birinchi mosini oladi
    return 'ru_RU'; // Rus tili yaxshi ishlaydi, o'zgartirishingiz mumkin
  }

  void setProcessing() {
    _speech.stop();
    _setState(ListeningState.processing);
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _setState(ListeningState.idle);
  }

  Future<void> resumeWakeWord() async {
    if (_state != ListeningState.wakeWord) {
      await startWakeWordListening();
    }
  }

  void _handleError(String error) {
    if (_state == ListeningState.wakeWord) {
      Future.delayed(const Duration(seconds: 1), _listenForWakeWord);
    }
  }

  void _handleStatus(String status) {
    if (status == 'done' && _state == ListeningState.wakeWord) {
      Future.delayed(const Duration(milliseconds: 500), _listenForWakeWord);
    }
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;

  void dispose() {
    _speech.stop();
    _speech.cancel();
  }
}
