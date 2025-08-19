import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';

enum QCMDifficulty {
  facile,
  moyen,
  difficile,
  tresDifficile,
}

class QCMModel {
  final String id;
  final String courseId;
  final String title;
  final List<QuestionModel> questions;
  final int minimumSuccessRate;
  final QCMDifficulty difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;

  QCMModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.questions,
    required this.minimumSuccessRate,
    required this.difficulty,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QCMModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QCMModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromMap(q as Map<String, dynamic>))
          .toList(),
      minimumSuccessRate: data['minimumSuccessRate'] ?? 70,
      difficulty: QCMDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => QCMDifficulty.moyen,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'minimumSuccessRate': minimumSuccessRate,
      'difficulty': difficulty.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  QCMModel copyWith({
    String? id,
    String? courseId,
    String? title,
    List<QuestionModel>? questions,
    int? minimumSuccessRate,
    QCMDifficulty? difficulty,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QCMModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      minimumSuccessRate: minimumSuccessRate ?? this.minimumSuccessRate,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper pour obtenir le nom lisible de la difficulté
  String get difficultyDisplayName {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return 'Facile';
      case QCMDifficulty.moyen:
        return 'Moyen';
      case QCMDifficulty.difficile:
        return 'Difficile';
      case QCMDifficulty.tresDifficile:
        return 'Très difficile';
    }
  }

  // Générer l'ID de document formaté pour QCM
  String generateQCMDocumentId() {
    return '$courseId-QCM-${difficulty.name}';
  }
}