/// Prompt copy for conversational onboarding. Keep this short so STT cost stays
/// inside the 3-minute audio cap.
class ConversationalPrompt {
  const ConversationalPrompt({
    required this.id,
    required this.title,
    required this.hint,
  });

  final String id;
  final String title;
  final String hint;
}

const List<ConversationalPrompt> kConversationalPrompts = [
  ConversationalPrompt(
    id: 'who',
    title: 'Who are you?',
    hint: 'Your name, age, where you are from, and where you live now.',
  ),
  ConversationalPrompt(
    id: 'looking',
    title: 'What are you looking for in Houston?',
    hint:
        'Friendship, dating, community, professional circles — in your words.',
  ),
  ConversationalPrompt(
    id: 'culture',
    title: 'Culture and community',
    hint: 'Heritage, languages, and the events or groups that feel like home.',
  ),
];
