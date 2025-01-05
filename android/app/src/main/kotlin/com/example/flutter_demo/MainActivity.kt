package com.example.flutter_demo

import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), RecognitionListener {
    private var speechToTextEvents: EventChannel.EventSink? = null
    private var speechRecognizerEvents: EventChannel.EventSink? = null
    private var textToSpeechEvents: EventChannel.EventSink? = null

    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    private lateinit var intent: Intent
    private var isListening = false

    private val SPEECHRECOGNITIONCHANNEL = "speech_recognition"
    private val SPEECHTOTEXTEVENTCHANNEL = "speech_to_text_event_channel"
    private val SPEECHRECOGNIZERCHANNEL = "speech_recognizer_channel"
    private val TEXTTOSPEECHCHANNEL = "text_to_speech_channel"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        textToSpeech = TextToSpeech(this@MainActivity) { status ->
            if (status == TextToSpeech.SUCCESS) {
                textToSpeech?.language = Locale.US
            }
        }

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this@MainActivity)
        speechRecognizer?.setRecognitionListener(this@MainActivity)
        intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        intent.putExtra(
            RecognizerIntent.EXTRA_LANGUAGE_MODEL,
            RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
        )
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "en-US")
        intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "Say something")
        intent.putExtra(
            RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, Int.MAX_VALUE
        )

        textToSpeech?.setSpeechRate(0.6f)

        ActivityCompat.requestPermissions(
            this@MainActivity,
            arrayOf(android.Manifest.permission.RECORD_AUDIO),
            1
        )


        EventChannel(flutterEngine.dartExecutor.binaryMessenger, TEXTTOSPEECHCHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    this@MainActivity.textToSpeechEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    this@MainActivity.textToSpeechEvents = null
                }
            }
        )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECHRECOGNIZERCHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    this@MainActivity.speechRecognizerEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    this@MainActivity.speechRecognizerEvents = null
                }
            }
        )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECHTOTEXTEVENTCHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    this@MainActivity.speechToTextEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    this@MainActivity.speechToTextEvents = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECHRECOGNITIONCHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "speechHandler") {
                    handleVoiceCommand()
                    result.success(isListening)
                }
                if (call.method == "textToSpeechHandler") {
                    handleTextToSpeech(call.arguments.toString())
                }
            }
    }

    private fun handleTextToSpeech(speechText: String) {
        if (textToSpeech?.isSpeaking == true) {
            textToSpeech?.stop()
            textToSpeechEvents?.success(false)
        } else {
            textToSpeech?.speak(
                speechText,
                TextToSpeech.QUEUE_FLUSH,
                null,
                null
            )
            textToSpeechEvents?.success(true)
        }
    }

    private fun handleVoiceCommand() {
        if (isListening) {
            speechRecognizer?.stopListening()
            isListening = false
            speechRecognizerEvents?.success(false)
        } else {
            speechRecognizer?.startListening(intent)
            isListening = true
            speechRecognizerEvents?.success(true)
        }
    }

    override fun onReadyForSpeech(params: Bundle?) {
        Log.d("SpeechRecognition", "Ready for speech")
    }

    override fun onBeginningOfSpeech() {
        Log.d("SpeechRecognition", "Beginning of speech")
    }

    override fun onRmsChanged(rmsdB: Float) {
        //Log.d("SpeechRecognition", "RMS changed: $rmsdB")
    }

    override fun onBufferReceived(buffer: ByteArray?) {
        Log.d("SpeechRecognition", "Buffer received")
    }

    override fun onEndOfSpeech() {
        speechRecognizer?.stopListening()
        isListening = false
        speechRecognizerEvents?.success(false)
        Log.d("SpeechRecognition", "End of speech")
    }

    override fun onError(error: Int) {
        Log.d("SpeechRecognition", "Error received: $error")
    }

    override fun onResults(results: Bundle?) {
        val data = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (data != null) {
            for (text in data) {
                speechToTextEvents?.success(text)
                Log.d("SpeechRecognition", text)
            }
        }
    }

    override fun onPartialResults(partialResults: Bundle?) {
        Log.d("PartialResults", partialResults.toString())
    }

    override fun onEvent(eventType: Int, params: Bundle?) {
        Log.d("SpeechRecognition", "Event received: $eventType")
    }

    override fun onDestroy() {
        super.onDestroy()
        speechRecognizer?.destroy()
        textToSpeech?.shutdown()
    }

}
