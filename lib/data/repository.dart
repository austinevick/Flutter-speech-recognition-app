import 'dart:convert';

import 'package:flutter_demo/data/speech_model.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';

class Repository {
  static Future<SpeechResponseModel> getSpeech(SpeechModel model) async {
    final response = await Client().post(
        Uri.parse('http://localhost:3000/api/speech'),
        body: model.toMap());
    final json = jsonDecode(response.body);
    Logger().d(json);
    return SpeechResponseModel.fromMap(json);
  }
}
