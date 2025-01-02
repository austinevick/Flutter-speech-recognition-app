class SpeechModel {
  final String prompt;
  SpeechModel({
    required this.prompt,
  });

  Map<String, dynamic> toMap() => {
        'prompt': prompt,
      };
}

class SpeechResponseModel {
  final int status;
  final String message;
  SpeechResponseModel({
    required this.status,
    required this.message,
  });

  factory SpeechResponseModel.fromMap(Map<String, dynamic> map) {
    return SpeechResponseModel(
      status: map['status'] as int,
      message: map['message'] as String,
    );
  }
}
