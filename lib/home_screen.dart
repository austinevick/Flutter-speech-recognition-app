import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_demo/data/repository.dart';
import 'package:flutter_demo/data/speech_model.dart';
import 'package:flutter_demo/speech_recognition_controller.dart';
import 'package:logger/logger.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final streamController = StreamController<String>.broadcast();
  Stream<String> get stream => streamController.stream;
  final textController = TextEditingController();
  bool isLoading = false;
  bool isListening = false;
  bool isSpeaking = false;

  String message = '';

  Future<void> getSpeech(String prompt) async {
    try {
      setState(() => isLoading = true);
      final model = SpeechModel(prompt: prompt);
      final response = await Repository.getSpeech(model);
      setState(() {
        message = response.message;
        isLoading = false;
      });
      streamController.add(response.message);
    } catch (e) {
      setState(() => isLoading = false);
      print(e);
      rethrow;
    }
  }

  Stream<String> streamSpeechRecognition() =>
      SpeechRecognitionController.eventChannel.map((event) {
        getSpeech(event.toString());
        return event.toString();
      });

  Stream<bool> streamSpeechRecognitionState() {
    return SpeechRecognitionController.speechChannel.map((event) {
      setState(() {
        isListening = event;
      });
      return event;
    });
  }

  Stream<bool> streamTextToSpeechState() {
    return SpeechRecognitionController.textToSpeechChannel.map((event) {
      setState(() {
        isSpeaking = event;
        Logger().d(event);
      });
      return event;
    });
  }

  @override
  void initState() {
    stream.listen((data) {
      Logger().d(data);
    }).onData((data) {
      SpeechRecognitionController.handleTextToSpeech(message);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Hi there 👋',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          minimum: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'I am your AI Assistant you can ask me anything😉',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      Divider(),
                      const SizedBox(height: 20),
                      StreamBuilder(
                        stream: streamSpeechRecognition(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Center(
                              child: Text(
                                snapshot.data!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            );
                          } else {
                            return Center(
                              child: Text(
                                'Your speech will appear here',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black38,
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 70),
                      AvatarGlow(
                        glowRadiusFactor: 0.3,
                        glowColor: Colors.red,
                        child: CircleAvatar(
                          radius: 40,
                          child: IconButton(
                              padding: EdgeInsets.all(16),
                              iconSize: 30,
                              onPressed: () => SpeechRecognitionController
                                  .handleSpeechRecognition(),
                              icon: StreamBuilder(
                                  stream: streamSpeechRecognitionState(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return snapshot.data!
                                          ? Icon(Icons.mic_off)
                                          : Icon(Icons.mic);
                                    } else {
                                      return const Icon(Icons.mic);
                                    }
                                  })),
                        ),
                      ),
                      const SizedBox(height: 50),
                      Center(
                          child: isLoading
                              ? CircularProgressIndicator()
                              : Text(
                                  message,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                )),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: textController,
                    onChanged: (value) => setState(() {}),
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    decoration: InputDecoration(
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'Write something here'),
                  )),
                  IconButton.filled(
                      onPressed: () {
                        if (textController.text.isNotEmpty) {
                          HapticFeedback.vibrate();
                          getSpeech(textController.text.trim());
                          setState(() => textController.text = '');
                        }
                      },
                      icon: Icon(
                        Icons.send,
                        color: textController.text.isEmpty
                            ? Colors.grey
                            : Colors.white,
                      ))
                ],
              ),
            ],
          ),
        ));
  }
}
