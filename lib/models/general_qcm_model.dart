import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';
import 'qcm_model.dart';

/// Modèle pour un QCM général adaptatif basé sur le profil utilisateur
class GeneralQCMModel {
  final String id;
  final String titre;
  final String niveau;
  final List<String> matieres; // Matières incluses
  final List<String>? options; // Options spécialisées (si applicable)
  final List<QuestionModel> questions;
  final QCMDifficulty difficulty;
  final int minimumSuccessRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  GeneralQCMModel({
    required this.id,
    required this.titre,
    required this.niveau,
    required this.matieres,
    this.options,
    required this.questions,
    required this.difficulty,
    required this.minimumSuccessRate,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory GeneralQCMModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GeneralQCMModel(
      id: doc.id,
      titre: data['titre'] ?? '',
      niveau: data['niveau'] ?? '',
      matieres: List<String>.from(data['matieres'] ?? []),
      options: data['options'] != null ? List<String>.from(data['options']) : null,
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromMap(q as Map<String, dynamic>))
          .toList(),
      difficulty: QCMDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => QCMDifficulty.moyen,
      ),
      minimumSuccessRate: data['minimumSuccessRate'] ?? 70,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titre': titre,
      'niveau': niveau,
      'matieres': matieres,
      'options': options,
      'questions': questions.map((q) => q.toMap()).toList(),
      'difficulty': difficulty.name,
      'minimumSuccessRate': minimumSuccessRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  GeneralQCMModel copyWith({
    String? id,
    String? titre,
    String? niveau,
    List<String>? matieres,
    List<String>? options,
    List<QuestionModel>? questions,
    QCMDifficulty? difficulty,
    int? minimumSuccessRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return GeneralQCMModel(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      niveau: niveau ?? this.niveau,
      matieres: matieres ?? this.matieres,
      options: options ?? this.options,
      questions: questions ?? this.questions,
      difficulty: difficulty ?? this.difficulty,
      minimumSuccessRate: minimumSuccessRate ?? this.minimumSuccessRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Génère un ID unique pour le QCM général
  String generateGeneralQCMId() {
    String optionsStr = options != null && options!.isNotEmpty 
        ? '_${options!.join('_')}'
        : '';
    String matieresStr = matieres.take(3).join('_');
    return 'GENERAL_${niveau}_${matieresStr}${optionsStr}_${difficulty.name}';
  }

  /// Description des matières pour l'affichage
  String get matieresDescription {
    if (matieres.length == 1) {
      return matieres.first;
    } else if (matieres.length <= 3) {
      return matieres.join(', ');
    } else {
      return '${matieres.take(2).join(', ')} et ${matieres.length - 2} autres';
    }
  }

  /// Description des options pour l'affichage
  String? get optionsDescription {
    if (options == null || options!.isEmpty) return null;
    if (options!.length == 1) {
      return options!.first;
    } else {
      return options!.join(', ');
    }
  }

  /// Titre complet avec niveau et matières
  String get fullTitle {
    String title = '$titre - $niveau';
    if (options != null && options!.isNotEmpty) {
      title += ' ($optionsDescription)';
    }
    return title;
  }

  /// Convertir en QCMModel standard pour compatibilité
  QCMModel toQCMModel() {
    return QCMModel(
      id: id,
      courseId: 'general_qcm', // ID spécial pour QCM général
      title: fullTitle,
      questions: questions,
      minimumSuccessRate: minimumSuccessRate,
      difficulty: difficulty,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Vérifie si ce QCM correspond au profil utilisateur
  bool matchesUserProfile({
    required String userLevel,
    required List<String> userMatieres,
    List<String>? userOptions,
  }) {
    // Vérifier le niveau
    if (niveau != userLevel) return false;

    // Vérifier qu'au moins une matière correspond
    bool hasCommonSubject = matieres.any((matiere) => userMatieres.contains(matiere));
    if (!hasCommonSubject) return false;

    // Si le QCM a des options spécifiques, vérifier la correspondance
    if (options != null && options!.isNotEmpty) {
      if (userOptions == null || userOptions.isEmpty) return false;
      bool hasCommonOption = options!.any((option) => userOptions.contains(option));
      return hasCommonOption;
    }

    return true;
  }

  /// Score de pertinence pour le tri des QCM recommandés
  int getRelevanceScore({
    required String userLevel,
    required List<String> userMatieres,
    List<String>? userOptions,
  }) {
    if (!matchesUserProfile(userLevel: userLevel, userMatieres: userMatieres, userOptions: userOptions)) {
      return 0;
    }

    int score = 0;

    // Points pour les matières communes
    int commonSubjects = matieres.where((m) => userMatieres.contains(m)).length;
    score += commonSubjects * 10;

    // Points pour les options communes
    if (options != null && userOptions != null) {
      int commonOptions = options!.where((o) => userOptions.contains(o)).length;
      score += commonOptions * 5;
    }

    // Bonus si toutes les matières du QCM correspondent
    if (matieres.every((m) => userMatieres.contains(m))) {
      score += 15;
    }

    return score;
  }
}