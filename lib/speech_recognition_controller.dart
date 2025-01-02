import 'package:flutter/services.dart';

class SpeechRecognitionController {
  static final methodChannel = MethodChannel('speech_recognition');
  static final eventChannel =
      EventChannel('speech_recognition_stream').receiveBroadcastStream();
  static final speechChannel =
      EventChannel('speech_listener').receiveBroadcastStream();

  static final textToSpeechChannel =
      EventChannel('text_to_speech').receiveBroadcastStream();

  static void handleTextToSpeech(String message) async =>
      await methodChannel.invokeMethod('textToSpeechHandler', message);

  static void handleSpeechRecognition() async =>
      await methodChannel.invokeMethod('speechHandler');
}
