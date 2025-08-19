enum QuestionType {
  multipleChoice,
  trueFalse,
  fillInTheBlank,
  ordering,
}

enum QuestionDifficulty {
  facile,
  moyen,
  difficile,
}

class QuestionModel {
  final String id;
  final String question;
  final List<String> options; // Garde pour compatibilité
  final List<String> answers; // Alias pour options
  final int correctAnswer;
  final List<int> correctAnswers; // Pour les questions à choix multiples
  final String explanation;
  final QuestionType questionType;
  final int points;
  final QuestionDifficulty difficulty;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  QuestionModel({
    required this.id,
    required this.question,
    List<String>? options,
    List<String>? answers,
    required this.correctAnswer,
    this.correctAnswers = const [],
    this.explanation = '',
    this.questionType = QuestionType.multipleChoice,
    this.points = 1,
    this.difficulty = QuestionDifficulty.moyen,
    this.tags = const [],
    this.metadata,
  }) : options = options ?? answers ?? [],
       answers = answers ?? options ?? [];

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? map['answers'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 0,
      correctAnswers: List<int>.from(map['correctAnswers'] ?? []),
      explanation: map['explanation'] ?? '',
      questionType: QuestionType.values.firstWhere(
        (e) => e.name == map['questionType'],
        orElse: () => QuestionType.multipleChoice,
      ),
      points: map['points'] ?? 1,
      difficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => QuestionDifficulty.moyen,
      ),
      tags: List<String>.from(map['tags'] ?? []),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'answers': answers,
      'correctAnswer': correctAnswer,
      'correctAnswers': correctAnswers,
      'explanation': explanation,
      'questionType': questionType.name,
      'points': points,
      'difficulty': difficulty.name,
      'tags': tags,
      'metadata': metadata,
    };
  }

  QuestionModel copyWith({
    String? id,
    String? question,
    List<String>? options,
    List<String>? answers,
    int? correctAnswer,
    List<int>? correctAnswers,
    String? explanation,
    QuestionType? questionType,
    int? points,
    QuestionDifficulty? difficulty,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      answers: answers ?? this.answers,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      explanation: explanation ?? this.explanation,
      questionType: questionType ?? this.questionType,
      points: points ?? this.points,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}