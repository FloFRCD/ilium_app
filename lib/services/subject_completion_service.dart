import '../models/progression_model.dart';

/// Service pour gérer la progression précise par matière et niveau
class SubjectCompletionService {
  
  /// Récupère les critères de completion pour Mathématiques Terminale par exemple
  static Map<String, dynamic> getCompletionCriteria(String matiere, String niveau) {
    // Configuration par matière et niveau
    final configs = {
      'Mathématiques': {
        'Terminale': {'requiredCourses': 25, 'finalQCMId': 'maths_terminale_final', 'minScore': 75.0},
        'Première': {'requiredCourses': 20, 'finalQCMId': 'maths_premiere_final', 'minScore': 70.0},
        'Seconde': {'requiredCourses': 18, 'finalQCMId': 'maths_seconde_final', 'minScore': 65.0},
      },
      'Physique-Chimie': {
        'Terminale': {'requiredCourses': 22, 'finalQCMId': 'physique_terminale_final', 'minScore': 75.0},
        'Première': {'requiredCourses': 18, 'finalQCMId': 'physique_premiere_final', 'minScore': 70.0},
      },
      'SVT': {
        'Terminale': {'requiredCourses': 20, 'finalQCMId': 'svt_terminale_final', 'minScore': 70.0},
        'Première': {'requiredCourses': 16, 'finalQCMId': 'svt_premiere_final', 'minScore': 65.0},
      },
      'Histoire-Géographie': {
        'Terminale': {'requiredCourses': 24, 'finalQCMId': 'histgeo_terminale_final', 'minScore': 70.0},
        'Première': {'requiredCourses': 20, 'finalQCMId': 'histgeo_premiere_final', 'minScore': 65.0},
      },
      'Philosophie': {
        'Terminale': {'requiredCourses': 15, 'finalQCMId': 'philo_terminale_final', 'minScore': 60.0},
      },
      'Français': {
        'Première': {'requiredCourses': 18, 'finalQCMId': 'francais_premiere_final', 'minScore': 70.0},
        'Seconde': {'requiredCourses': 15, 'finalQCMId': 'francais_seconde_final', 'minScore': 65.0},
      },
    };

    return configs[matiere]?[niveau] ?? {'requiredCourses': 0, 'finalQCMId': null, 'minScore': 60.0};
  }

  /// Initialise une progression avec les critères appropriés
  static SubjectProgressionModel initializeProgression({
    required String matiere,
    required String niveau,
  }) {
    final criteria = getCompletionCriteria(matiere, niveau);
    
    return SubjectProgressionModel(
      matiere: matiere,
      niveau: niveau,
      coursCompleted: 0,
      coursInProgress: 0,
      coursTotal: criteria['requiredCourses'] ?? 0,
      qcmPassed: 0,
      qcmFailed: 0,
      qcmTotal: 0,
      averageScore: 0.0,
      totalXp: 0,
      streakDays: 1,
      lastActivity: DateTime.now(),
      skillLevels: {},
      unlockedBadges: [],
      // Nouveaux critères précis
      requiredCoursesForCompletion: criteria['requiredCourses'] ?? 0,
      hasPassedFinalQCM: false,
      finalQCMScore: 0.0,
      completedCourseIds: [],
      finalQCMId: criteria['finalQCMId'],
    );
  }

  /// Met à jour la progression lors de la completion d'un cours
  static SubjectProgressionModel updateOnCourseCompleted({
    required SubjectProgressionModel current,
    required String courseId,
  }) {
    List<String> updatedIds = List.from(current.completedCourseIds);
    if (!updatedIds.contains(courseId)) {
      updatedIds.add(courseId);
    }

    return current.copyWith(
      coursCompleted: current.coursCompleted + 1,
      coursInProgress: (current.coursInProgress > 0) ? current.coursInProgress - 1 : 0,
      totalXp: current.totalXp + 50,
      lastActivity: DateTime.now(),
      completedCourseIds: updatedIds,
    );
  }

  /// Met à jour lors de la réussite du QCM final
  static SubjectProgressionModel updateOnFinalQCMPassed({
    required SubjectProgressionModel current,
    required double score,
  }) {
    final criteria = getCompletionCriteria(current.matiere, current.niveau);
    final minScore = criteria['minScore'] ?? 60.0;
    final hasPassed = score >= minScore;

    // Bonus XP si l'utilisateur réussit le QCM final sans faire de cours (maîtrise démontrée)
    int bonusXp = 0;
    if (hasPassed && current.completedCourseIds.isEmpty) {
      bonusXp = 200; // Bonus pour démontrer la maîtrise directement
    }

    return current.copyWith(
      qcmPassed: hasPassed ? current.qcmPassed + 1 : current.qcmPassed,
      qcmFailed: hasPassed ? current.qcmFailed : current.qcmFailed + 1,
      qcmTotal: current.qcmTotal + 1,
      averageScore: _calculateNewAverage(current.averageScore, current.qcmTotal, score),
      totalXp: current.totalXp + (hasPassed ? 100 : 50) + bonusXp,
      lastActivity: DateTime.now(),
      hasPassedFinalQCM: hasPassed || current.hasPassedFinalQCM,
      finalQCMScore: hasPassed ? score : current.finalQCMScore,
    );
  }

  /// Calcule la nouvelle moyenne après un QCM
  static double _calculateNewAverage(double currentAverage, int totalQCM, double newScore) {
    if (totalQCM == 0) return newScore;
    return ((currentAverage * totalQCM) + newScore) / (totalQCM + 1);
  }

  /// Démarre directement avec le QCM final (sans cours)
  /// Utilisé quand l'utilisateur veut prouver sa maîtrise directement
  static SubjectProgressionModel createProgressionForDirectQCM({
    required String matiere,
    required String niveau,
    required double score,
  }) {
    final criteria = getCompletionCriteria(matiere, niveau);
    final minScore = criteria['minScore'] ?? 60.0;
    final hasPassed = score >= minScore;

    // XP bonus pour démonstration directe de maîtrise
    int baseXp = hasPassed ? 300 : 100; // Plus d'XP car c'est plus difficile

    return SubjectProgressionModel(
      matiere: matiere,
      niveau: niveau,
      coursCompleted: 0,
      coursInProgress: 0,
      coursTotal: criteria['requiredCourses'] ?? 0,
      qcmPassed: hasPassed ? 1 : 0,
      qcmFailed: hasPassed ? 0 : 1,
      qcmTotal: 1,
      averageScore: score,
      totalXp: baseXp,
      streakDays: 1,
      lastActivity: DateTime.now(),
      skillLevels: {},
      unlockedBadges: [],
      // Critères précis
      requiredCoursesForCompletion: criteria['requiredCourses'] ?? 0,
      hasPassedFinalQCM: hasPassed,
      finalQCMScore: hasPassed ? score : 0.0,
      completedCourseIds: [], // Vide = maîtrise par QCM uniquement
      finalQCMId: criteria['finalQCMId'],
    );
  }

  /// Retourne les matières disponibles pour un niveau
  static List<String> getAvailableSubjects(String niveau) {
    final allConfigs = {
      'Mathématiques': ['Terminale', 'Première', 'Seconde'],
      'Physique-Chimie': ['Terminale', 'Première'],
      'SVT': ['Terminale', 'Première'],
      'Histoire-Géographie': ['Terminale', 'Première'],
      'Philosophie': ['Terminale'],
      'Français': ['Première', 'Seconde'],
    };
    
    return allConfigs.entries
        .where((entry) => entry.value.contains(niveau))
        .map((entry) => entry.key)
        .toList()..sort();
  }
}