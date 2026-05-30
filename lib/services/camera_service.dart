import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  int _currentCameraIndex = 0;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      
      await _initController(_cameras[_currentCameraIndex]);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    _controller?.dispose();
    
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      debugPrint('Camera controller error: $e');
    }
  }

  // Foto olish
  Future<Uint8List?> captureImage() async {
    if (!_isInitialized || _controller == null) return null;
    
    try {
      final XFile file = await _controller!.takePicture();
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  // Kamerani almashtirish (old/orqa)
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    _isInitialized = false;
    await _initController(_cameras[_currentCameraIndex]);
  }

  // Orqa kameraga o'tish
  Future<void> useBackCamera() async {
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.back) {
        _currentCameraIndex = i;
        await _initController(_cameras[i]);
        return;
      }
    }
  }

  // Old kameraga o'tish
  Future<void> useFrontCamera() async {
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        _currentCameraIndex = i;
        await _initController(_cameras[i]);
        return;
      }
    }
  }

  bool get hasMultipleCameras => _cameras.length > 1;

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
