import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'YOUR_GEMINI_API_KEY'; // <-- O'zgartiring
  
  late final GenerativeModel _textModel;
  late final GenerativeModel _visionModel;
  late ChatSession _chatSession;

  GeminiService() {
    _textModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        '''Sen JARVIS — shaxsiy AI yordamchisan. 
        Qisqa, aniq va foydali javob ber. 
        O'zbek, Rus yoki Ingliz tilida gapir — foydalanuvchi qaysi tilda so'rasa, shunda javob ber.
        Agar kamera tasviri yuborilsa, uni tahlil qil va savol bilan bog'la.'''
      ),
    );
    
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    
    _chatSession = _textModel.startChat();
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chatSession.sendMessage(
        Content.text(message),
      );
      return response.text ?? 'Javob olishda xatolik yuz berdi.';
    } catch (e) {
      return 'Xatolik: ${e.toString()}';
    }
  }

  Future<String> sendMessageWithImage(String message, Uint8List imageBytes) async {
    try {
      final response = await _visionModel.generateContent([
        Content.multi([
          TextPart(message.isEmpty ? 'Bu tasvirda nima ko\'ryapsan?' : message),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);
      return response.text ?? 'Javob olishda xatolik yuz berdi.';
    } catch (e) {
      return 'Xatolik: ${e.toString()}';
    }
  }

  Future<String> analyzeScreen(Uint8List screenshotBytes, String question) async {
    try {
      final prompt = question.isEmpty
          ? 'Ekranda nima ko\'ryapsan? Qisqacha tahlil qil.'
          : 'Ekran tasviri: $question';
          
      final response = await _visionModel.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/png', screenshotBytes),
        ])
      ]);
      return response.text ?? 'Javob olishda xatolik yuz berdi.';
    } catch (e) {
      return 'Xatolik: ${e.toString()}';
    }
  }

  void resetChat() {
    _chatSession = _textModel.startChat();
  }
}
