import 'package:flutter/services.dart';

class SpeechRecognitionController {
  static final methodChannel = MethodChannel('speech_recognition');
  static final eventChannel =
      EventChannel('speech_to_text_event_channel').receiveBroadcastStream();
  static final speechChannel =
      EventChannel('speech_recognizer_channel').receiveBroadcastStream();

  static final textToSpeechChannel =
      EventChannel('text_to_speech_channel').receiveBroadcastStream();

  static void handleTextToSpeech(String message) async =>
      await methodChannel.invokeMethod('textToSpeechHandler', message);

  static void handleSpeechRecognition() async =>
      await methodChannel.invokeMethod('speechHandler');
}
