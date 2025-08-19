import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_model.dart';
import 'qcm_model.dart';

/// Modèle représentant un groupe de cours (concept/sujet/chapitre)
/// 
/// CONCEPT :
/// Au lieu de favoriser individuellement chaque type de cours,
/// on favorise le SUJET ENTIER avec tous ses types disponibles :
/// - Cours complet
/// - Fiche de révision  
/// - QCM
/// - Exercices
/// 
/// AVANTAGES :
/// - Vision globale du sujet pour les parents
/// - Suivi de progression sur l'ensemble du chapitre
/// - Accès facile à tous les types de contenu
/// - Statistiques complètes (QCM réussis, temps passé, etc.)
class CourseGroupModel {
  final String id;               // ID unique du groupe (ex: "math_fractions_6eme")
  final String title;            // Titre du sujet (ex: "Les fractions")
  final String matiere;          // Matière (ex: "Mathématiques")
  final String niveau;           // Niveau (ex: "6ème")
  final String? description;     // Description du sujet
  final List<String> tags;       // Tags du groupe
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Cours disponibles dans ce groupe
  final CourseModel? coursComplet;     // Cours théorique complet
  final CourseModel? ficheRevision;    // Fiche de révision
  final List<QCMModel> qcms;           // Liste des QCM disponibles
  final List<CourseModel> exercices;   // Exercices pratiques
  
  // Métadonnées de progression
  final Map<String, dynamic> progressionData;  // Données de progression utilisateur
  final bool isPublic;
  final bool isPremium;
  
  CourseGroupModel({
    required this.id,
    required this.title,
    required this.matiere,
    required this.niveau,
    this.description,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.coursComplet,
    this.ficheRevision,
    this.qcms = const [],
    this.exercices = const [],
    this.progressionData = const {},
    this.isPublic = true,
    this.isPremium = false,
  });

  /// Crée un CourseGroupModel depuis Firestore
  factory CourseGroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return CourseGroupModel(
      id: doc.id,
      title: data['title'] ?? '',
      matiere: data['matiere'] ?? '',
      niveau: data['niveau'] ?? '',
      description: data['description'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progressionData: Map<String, dynamic>.from(data['progressionData'] ?? {}),
      isPublic: data['isPublic'] ?? true,
      isPremium: data['isPremium'] ?? false,
    );
  }

  /// Convertit vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'matiere': matiere,
      'niveau': niveau,
      'description': description,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'progressionData': progressionData,
      'isPublic': isPublic,
      'isPremium': isPremium,
    };
  }

  /// Crée un groupe depuis un cours existant
  factory CourseGroupModel.fromSingleCourse(CourseModel course) {
    return CourseGroupModel(
      id: generateGroupId(course.title, course.matiere, course.niveau),
      title: course.title,
      matiere: course.matiere,
      niveau: course.niveau,
      description: course.description,
      tags: course.tags,
      createdAt: course.createdAt,
      updatedAt: course.updatedAt,
      coursComplet: course.type == CourseType.cours ? course : null,
      ficheRevision: course.type == CourseType.fiche ? course : null,
      isPublic: course.isPublic,
      isPremium: course.isPremium,
    );
  }

  /// Génère un ID unique pour le groupe basé sur le contenu
  static String generateGroupId(String title, String matiere, String niveau) {
    String normalized = '${matiere.toLowerCase()}_${title.toLowerCase().replaceAll(' ', '_')}_${niveau.toLowerCase()}';
    return normalized.replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Vérifie si le groupe a un cours complet
  bool get hasCoursComplet => coursComplet != null;

  /// Vérifie si le groupe a une fiche de révision
  bool get hasFicheRevision => ficheRevision != null;

  /// Vérifie si le groupe a des QCM
  bool get hasQCMs => qcms.isNotEmpty;

  /// Vérifie si le groupe a des exercices
  bool get hasExercices => exercices.isNotEmpty;

  /// Retourne le nombre total de contenus disponibles
  int get totalContentCount {
    int count = 0;
    if (hasCoursComplet) count++;
    if (hasFicheRevision) count++;
    count += qcms.length;
    count += exercices.length;
    return count;
  }

  /// Retourne une description des contenus disponibles
  String get availableContentDescription {
    List<String> contents = [];
    if (hasCoursComplet) contents.add('Cours complet');
    if (hasFicheRevision) contents.add('Fiche de révision');
    if (hasQCMs) contents.add('${qcms.length} QCM${qcms.length > 1 ? 's' : ''}');
    if (hasExercices) contents.add('${exercices.length} exercice${exercices.length > 1 ? 's' : ''}');
    
    if (contents.isEmpty) return 'Aucun contenu disponible';
    if (contents.length == 1) return contents.first;
    if (contents.length == 2) return '${contents.first} et ${contents.last}';
    
    return '${contents.sublist(0, contents.length - 1).join(', ')} et ${contents.last}';
  }

  /// Calcule le pourcentage de progression sur ce groupe
  double calculateProgressPercentage(String userId) {
    if (totalContentCount == 0) return 0.0;
    
    int completedCount = 0;
    Map<String, dynamic> userProgress = progressionData[userId] ?? {};
    
    // Cours complet
    if (hasCoursComplet && (userProgress['cours_completed'] == true)) {
      completedCount++;
    }
    
    // Fiche de révision
    if (hasFicheRevision && (userProgress['fiche_completed'] == true)) {
      completedCount++;
    }
    
    // QCMs
    Map<String, bool> qcmResults = Map<String, bool>.from(userProgress['qcm_results'] ?? {});
    for (QCMModel qcm in qcms) {
      if (qcmResults[qcm.id] == true) {
        completedCount++;
      }
    }
    
    // Exercices
    Map<String, bool> exerciceResults = Map<String, bool>.from(userProgress['exercice_results'] ?? {});
    for (CourseModel exercice in exercices) {
      if (exerciceResults[exercice.id] == true) {
        completedCount++;
      }
    }
    
    return (completedCount / totalContentCount) * 100;
  }

  /// Retourne un résumé des QCM (réussis/total)
  Map<String, int> getQCMSummary(String userId) {
    Map<String, bool> qcmResults = Map<String, bool>.from(
      progressionData[userId]?['qcm_results'] ?? {}
    );
    
    int total = qcms.length;
    int reussis = qcmResults.values.where((result) => result == true).length;
    
    return {
      'total': total,
      'reussis': reussis,
      'echecs': total - reussis,
    };
  }

  /// Met à jour la progression pour un utilisateur
  CourseGroupModel updateUserProgress(String userId, String contentType, String contentId, bool completed) {
    Map<String, dynamic> newProgressionData = Map.from(progressionData);
    Map<String, dynamic> userProgress = Map.from(newProgressionData[userId] ?? {});
    
    switch (contentType) {
      case 'cours':
        userProgress['cours_completed'] = completed;
        break;
      case 'fiche':
        userProgress['fiche_completed'] = completed;
        break;
      case 'qcm':
        Map<String, bool> qcmResults = Map<String, bool>.from(userProgress['qcm_results'] ?? {});
        qcmResults[contentId] = completed;
        userProgress['qcm_results'] = qcmResults;
        break;
      case 'exercice':
        Map<String, bool> exerciceResults = Map<String, bool>.from(userProgress['exercice_results'] ?? {});
        exerciceResults[contentId] = completed;
        userProgress['exercice_results'] = exerciceResults;
        break;
    }
    
    // Mettre à jour la date de dernière activité
    userProgress['last_activity'] = DateTime.now().toIso8601String();
    newProgressionData[userId] = userProgress;
    
    return CourseGroupModel(
      id: id,
      title: title,
      matiere: matiere,
      niveau: niveau,
      description: description,
      tags: tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      coursComplet: coursComplet,
      ficheRevision: ficheRevision,
      qcms: qcms,
      exercices: exercices,
      progressionData: newProgressionData,
      isPublic: isPublic,
      isPremium: isPremium,
    );
  }

  /// Copie avec modifications
  CourseGroupModel copyWith({
    String? id,
    String? title,
    String? matiere,
    String? niveau,
    String? description,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    CourseModel? coursComplet,
    CourseModel? ficheRevision,
    List<QCMModel>? qcms,
    List<CourseModel>? exercices,
    Map<String, dynamic>? progressionData,
    bool? isPublic,
    bool? isPremium,
  }) {
    return CourseGroupModel(
      id: id ?? this.id,
      title: title ?? this.title,
      matiere: matiere ?? this.matiere,
      niveau: niveau ?? this.niveau,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coursComplet: coursComplet ?? this.coursComplet,
      ficheRevision: ficheRevision ?? this.ficheRevision,
      qcms: qcms ?? this.qcms,
      exercices: exercices ?? this.exercices,
      progressionData: progressionData ?? this.progressionData,
      isPublic: isPublic ?? this.isPublic,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  String toString() {
    return 'CourseGroupModel(id: $id, title: $title, matiere: $matiere, niveau: $niveau, totalContent: $totalContentCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseGroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}