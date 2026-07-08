/// Une question/réponse du centre d'aide (servie par GET /help/faq).
class FaqEntry {
  const FaqEntry({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  final String id;
  final String category;
  final String question;
  final String answer;

  factory FaqEntry.fromJson(Map<String, dynamic> json) {
    return FaqEntry(
      id: json['id'] as String,
      category: json['category'] as String? ?? '',
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}
