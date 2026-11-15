import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../onboarding_theme.dart';
import 'conversational_prompts.dart';

class PromptAnswerDraft {
  PromptAnswerDraft({this.text = '', this.audioPath, this.durationMs = 0});

  String text;
  String? audioPath;
  int durationMs;

  bool get hasContent =>
      text.trim().isNotEmpty || (audioPath != null && durationMs > 0);
}

class ConversationalPromptsPage extends StatefulWidget {
  const ConversationalPromptsPage({
    required this.onContinue,
    required this.onSkipToForms,
    super.key,
  });
  final void Function(List<PromptAnswerDraft> answers) onContinue;
  final VoidCallback onSkipToForms;

  @override
  State<ConversationalPromptsPage> createState() =>
      _ConversationalPromptsPageState();
}

class _ConversationalPromptsPageState extends State<ConversationalPromptsPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final Map<String, TextEditingController> _controllers = {
    for (final prompt in kConversationalPrompts)
      prompt.id: TextEditingController(),
  };
  final Map<String, PromptAnswerDraft> _answers = {
    for (final prompt in kConversationalPrompts) prompt.id: PromptAnswerDraft(),
  };

  String? _recordingPromptId;
  DateTime? _recordingStartedAt;
  Timer? _ticker;
  Duration _usedAudio = Duration.zero;

  static const Duration _maxAudio = Duration(minutes: 3);

  Duration get _remaining => _maxAudio - _usedAudio;

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_recorder.dispose());
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleRecord(ConversationalPrompt prompt) async {
    if (_recordingPromptId == prompt.id) {
      await _stopRecording();
      return;
    }
    if (_recordingPromptId != null) {
      await _stopRecording();
    }
    if (_remaining.inSeconds <= 0) {
      _showMessage('Voice answers are capped at 3 minutes. Type the rest.');
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showMessage('Microphone access is optional. You can type instead.');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/onboarding_${prompt.id}.m4a';
    await _recorder.start(
      const RecordConfig(),
      path: path,
    );
    setState(() {
      _recordingPromptId = prompt.id;
      _recordingStartedAt = DateTime.now();
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _recordingStartedAt == null) return;
      final elapsed = DateTime.now().difference(_recordingStartedAt!);
      if (_usedAudio + elapsed >= _maxAudio) {
        await _stopRecording();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    final promptId = _recordingPromptId;
    final started = _recordingStartedAt;
    final path = await _recorder.stop();
    if (promptId == null || started == null) {
      setState(() {
        _recordingPromptId = null;
        _recordingStartedAt = null;
      });
      return;
    }
    final elapsed = DateTime.now().difference(started);
    setState(() {
      _usedAudio += elapsed;
      _answers[promptId] = PromptAnswerDraft(
        text: _controllers[promptId]?.text ?? '',
        audioPath: path,
        durationMs: elapsed.inMilliseconds,
      );
      _recordingPromptId = null;
      _recordingStartedAt = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    final drafts = <PromptAnswerDraft>[];
    for (final prompt in kConversationalPrompts) {
      final draft = _answers[prompt.id] ?? PromptAnswerDraft();
      draft.text = _controllers[prompt.id]?.text ?? '';
      drafts.add(draft);
    }
    if (!drafts.any((d) => d.hasContent)) {
      _showMessage('Tell us a bit about yourself, or skip to the form.');
      return;
    }
    widget.onContinue(drafts);
  }

  @override
  Widget build(BuildContext context) {
    final remainingLabel =
        '${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')} voice left';
    return OnboardingTheme.constrainedContent(
      child: SingleChildScrollView(
        padding: OnboardingTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tell us about you', style: OnboardingTheme.titleStyle),
            const SizedBox(height: OnboardingTheme.titleToSubtitle),
            Text(
              'Talk or type. We draft a profile from your words and do not keep the recording.',
              style: OnboardingTheme.subtitleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              remainingLabel,
              style: OnboardingTheme.helperStyle.copyWith(
                color: OnboardingTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: OnboardingTheme.subtitleToField),
            for (final prompt in kConversationalPrompts) ...[
              _PromptCard(
                prompt: prompt,
                controller: _controllers[prompt.id]!,
                isRecording: _recordingPromptId == prompt.id,
                hasAudio: _answers[prompt.id]?.audioPath != null,
                onRecord: () => unawaited(_toggleRecord(prompt)),
                onTextChanged: (value) {
                  _answers[prompt.id]?.text = value;
                },
              ),
              const SizedBox(height: OnboardingTheme.fieldToSection),
            ],
            SizedBox(
              width: double.infinity,
              height: OnboardingTheme.buttonHeight,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: OnboardingTheme.buttonGradient,
                  borderRadius: BorderRadius.all(
                    Radius.circular(OnboardingTheme.buttonRadius),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        OnboardingTheme.buttonRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    'Create my draft',
                    style: OnboardingTheme.buttonTextStyle,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onSkipToForms,
              child: Text(
                'Fill it in myself',
                style: GoogleFonts.montserrat(
                  color: OnboardingTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: math.max(24, MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.controller,
    required this.isRecording,
    required this.hasAudio,
    required this.onRecord,
    required this.onTextChanged,
  });

  final ConversationalPrompt prompt;
  final TextEditingController controller;
  final bool isRecording;
  final bool hasAudio;
  final VoidCallback onRecord;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt.title, style: OnboardingTheme.sectionLabelStyle),
          const SizedBox(height: OnboardingTheme.labelToField),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            style: OnboardingTheme.fieldTextStyle,
            decoration: OnboardingTheme.fieldDecoration(hint: prompt.hint),
            onChanged: onTextChanged,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRecord,
              icon: Icon(
                isRecording ? Icons.stop_circle : Icons.mic_none,
                color: isRecording
                    ? Colors.redAccent
                    : OnboardingTheme.primaryGreen,
              ),
              label: Text(
                isRecording
                    ? 'Stop'
                    : hasAudio
                        ? 'Re-record'
                        : 'Record',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: OnboardingTheme.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      );
}

Future<List<Map<String, dynamic>>> encodePromptAnswers(
  List<PromptAnswerDraft> drafts,
) async {
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < kConversationalPrompts.length; i++) {
    final prompt = kConversationalPrompts[i];
    final draft = drafts[i];
    String? audioBase64;
    if (draft.audioPath != null && draft.durationMs > 0) {
      final file = File(draft.audioPath!);
      try {
        audioBase64 = base64Encode(await file.readAsBytes());
        await file.delete();
      } on FileSystemException {
        audioBase64 = null;
      } on Object {
        audioBase64 = null;
      }
    }
    if (draft.text.trim().isEmpty && audioBase64 == null) {
      continue;
    }
    out.add({
      'promptId': prompt.id,
      if (draft.text.trim().isNotEmpty) 'text': draft.text.trim(),
      if (audioBase64 != null) 'audioBase64': audioBase64,
      if (audioBase64 != null) 'mimeType': 'audio/mp4',
      if (audioBase64 != null) 'durationMs': draft.durationMs,
    });
  }
  return out;
}
