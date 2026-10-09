import 'package:cloud_functions/cloud_functions.dart';

/// One prompted answer sent to [extractOnboardingProfile].
class OnboardingAnswerPayload {
  const OnboardingAnswerPayload({
    required this.promptId,
    this.text,
    this.audioBase64,
    this.mimeType,
    this.durationMs,
  });

  final String promptId;
  final String? text;
  final String? audioBase64;
  final String? mimeType;
  final int? durationMs;

  Map<String, dynamic> toJson() => {
        'promptId': promptId,
        if (text != null && text!.trim().isNotEmpty) 'text': text!.trim(),
        if (audioBase64 != null && audioBase64!.isNotEmpty)
          'audioBase64': audioBase64,
        if (mimeType != null) 'mimeType': mimeType,
        if (durationMs != null) 'durationMs': durationMs,
      };
}

class OnboardingExtractResult {
  const OnboardingExtractResult({
    required this.fields,
    required this.confidence,
    required this.source,
  });

  final Map<String, dynamic> fields;
  final Map<String, dynamic> confidence;
  final String source;
}

class OnboardingExtractException implements Exception {
  const OnboardingExtractException(this.code, this.message);

  final String code;
  final String message;

  bool get shouldFallBackToForms =>
      code == 'resource-exhausted' ||
      code == 'failed-precondition' ||
      code == 'unavailable' ||
      code == 'internal';

  @override
  String toString() => 'OnboardingExtractException($code): $message';
}

/// Calls [extractOnboardingProfile] in us-central1.
class OnboardingProfileFunctionsService {
  OnboardingProfileFunctionsService({
    FirebaseFunctions? functions,
  }) : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<OnboardingExtractResult> extract({
    required List<OnboardingAnswerPayload> answers,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'extractOnboardingProfile',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'answers': answers.map((a) => a.toJson()).toList(),
      });
      final data = Map<String, dynamic>.from(result.data);
      return OnboardingExtractResult(
        fields: _asStringKeyedMap(data['fields']),
        confidence: _asStringKeyedMap(data['confidence']),
        source: data['source']?.toString() ?? 'model',
      );
    } on FirebaseFunctionsException catch (e) {
      throw OnboardingExtractException(
        e.code,
        e.message ?? 'Could not draft your profile',
      );
    }
  }

  Map<String, dynamic> _asStringKeyedMap(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }
}
