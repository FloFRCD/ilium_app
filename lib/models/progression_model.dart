import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectProgressionModel {
  final String matiere;
  final String niveau;
  final int coursCompleted;
  final int coursInProgress;
  final int coursTotal;
  final int qcmPassed;
  final int qcmFailed;
  final int qcmTotal;
  final double averageScore;
  final int totalXp;
  final int streakDays;
  final DateTime lastActivity;
  final Map<String, double> skillLevels; // Ex: {'algebra': 85.5, 'geometry': 72.0}
  final List<String> unlockedBadges;
  
  // Nouveaux champs pour progression précise
  final int requiredCoursesForCompletion; // Nombre de cours requis pour 100%
  final bool hasPassedFinalQCM; // A réussi le QCM le plus difficile
  final double finalQCMScore; // Score du QCM final (0 si pas encore passé)
  final List<String> completedCourseIds; // IDs des cours terminés
  final String? finalQCMId; // ID du QCM final requis

  SubjectProgressionModel({
    required this.matiere,
    required this.niveau,
    required this.coursCompleted,
    required this.coursInProgress,
    required this.coursTotal,
    required this.qcmPassed,
    required this.qcmFailed,
    required this.qcmTotal,
    required this.averageScore,
    required this.totalXp,
    required this.streakDays,
    required this.lastActivity,
    required this.skillLevels,
    required this.unlockedBadges,
    // Nouveaux paramètres
    this.requiredCoursesForCompletion = 0,
    this.hasPassedFinalQCM = false,
    this.finalQCMScore = 0.0,
    this.completedCourseIds = const [],
    this.finalQCMId,
  });

  factory SubjectProgressionModel.fromMap(Map<String, dynamic> map) {
    return SubjectProgressionModel(
      matiere: map['matiere'] ?? '',
      niveau: map['niveau'] ?? '',
      coursCompleted: map['coursCompleted'] ?? 0,
      coursInProgress: map['coursInProgress'] ?? 0,
      coursTotal: map['coursTotal'] ?? 0,
      qcmPassed: map['qcmPassed'] ?? 0,
      qcmFailed: map['qcmFailed'] ?? 0,
      qcmTotal: map['qcmTotal'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      totalXp: map['totalXp'] ?? 0,
      streakDays: map['streakDays'] ?? 0,
      lastActivity: map['lastActivity'] != null
          ? (map['lastActivity'] as Timestamp).toDate()
          : DateTime.now(),
      skillLevels: Map<String, double>.from(map['skillLevels'] ?? {}),
      unlockedBadges: List<String>.from(map['unlockedBadges'] ?? []),
      // Nouveaux champs
      requiredCoursesForCompletion: map['requiredCoursesForCompletion'] ?? 0,
      hasPassedFinalQCM: map['hasPassedFinalQCM'] ?? false,
      finalQCMScore: (map['finalQCMScore'] ?? 0.0).toDouble(),
      completedCourseIds: List<String>.from(map['completedCourseIds'] ?? []),
      finalQCMId: map['finalQCMId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matiere': matiere,
      'niveau': niveau,
      'coursCompleted': coursCompleted,
      'coursInProgress': coursInProgress,
      'coursTotal': coursTotal,
      'qcmPassed': qcmPassed,
      'qcmFailed': qcmFailed,
      'qcmTotal': qcmTotal,
      'averageScore': averageScore,
      'totalXp': totalXp,
      'streakDays': streakDays,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'skillLevels': skillLevels,
      'unlockedBadges': unlockedBadges,
      // Nouveaux champs
      'requiredCoursesForCompletion': requiredCoursesForCompletion,
      'hasPassedFinalQCM': hasPassedFinalQCM,
      'finalQCMScore': finalQCMScore,
      'completedCourseIds': completedCourseIds,
      'finalQCMId': finalQCMId,
    };
  }

  // Méthodes utiles
  double get completionPercentage {
    if (coursTotal == 0) return 0.0;
    return (coursCompleted / coursTotal) * 100;
  }

  /// Calcul de progression précise selon les nouveaux critères
  /// 100% = Tous les cours requis + QCM final réussi OU QCM final réussi seul (maîtrise démontrée)
  double get preciseCompletionPercentage {
    if (requiredCoursesForCompletion == 0) {
      // Fallback vers l'ancien calcul si pas configuré
      return completionPercentage;
    }
    
    // Cas spécial: Si le QCM final est réussi sans avoir fait de cours,
    // cela démontre une maîtrise complète = 100%
    if (hasPassedFinalQCM && completedCourseIds.isEmpty) {
      return 100.0;
    }
    
    double courseProgress = (completedCourseIds.length / requiredCoursesForCompletion) * 80; // 80% pour les cours
    double qcmProgress = hasPassedFinalQCM ? 20.0 : 0.0; // 20% pour le QCM final
    
    return (courseProgress + qcmProgress).clamp(0.0, 100.0);
  }

  /// Indique si la matière est complètement maîtrisée (100%)
  bool get isCompletelyMastered {
    // Maîtrise complète si QCM final réussi (peu importe les cours)
    // OU tous les cours + QCM final réussis
    return hasPassedFinalQCM && 
           (completedCourseIds.isEmpty || completedCourseIds.length >= requiredCoursesForCompletion);
  }

  /// Retourne ce qu'il manque pour atteindre 100%
  Map<String, dynamic> get completionRequirements {
    // Si QCM final réussi sans cours, alors 100% atteint
    if (hasPassedFinalQCM && completedCourseIds.isEmpty) {
      return {
        'missingCourses': 0,
        'needsFinalQCM': false,
        'finalQCMRequired': finalQCMId != null,
        'coursesProgress': 'Maîtrise démontrée par QCM final',
        'overallProgress': preciseCompletionPercentage,
        'masteredByQCMOnly': true,
      };
    }
    
    int missingCourses = (requiredCoursesForCompletion - completedCourseIds.length).clamp(0, requiredCoursesForCompletion);
    
    return {
      'missingCourses': missingCourses,
      'needsFinalQCM': !hasPassedFinalQCM,
      'finalQCMRequired': finalQCMId != null,
      'coursesProgress': '${completedCourseIds.length}/$requiredCoursesForCompletion',
      'overallProgress': preciseCompletionPercentage,
      'masteredByQCMOnly': false,
    };
  }

  double get qcmSuccessRate {
    if (qcmTotal == 0) return 0.0;
    return (qcmPassed / qcmTotal) * 100;
  }

  int get totalCoursAttempted => coursCompleted + coursInProgress;

  String get progressionStatus {
    if (completionPercentage >= 90) return 'Expert';
    if (completionPercentage >= 75) return 'Avancé';
    if (completionPercentage >= 50) return 'Intermédiaire';
    if (completionPercentage >= 25) return 'Débutant';
    return 'Novice';
  }

  SubjectProgressionModel copyWith({
    String? matiere,
    String? niveau,
    int? coursCompleted,
    int? coursInProgress,
    int? coursTotal,
    int? qcmPassed,
    int? qcmFailed,
    int? qcmTotal,
    double? averageScore,
    int? totalXp,
    int? streakDays,
    DateTime? lastActivity,
    Map<String, double>? skillLevels,
    List<String>? unlockedBadges,
    // Nouveaux paramètres
    int? requiredCoursesForCompletion,
    bool? hasPassedFinalQCM,
    double? finalQCMScore,
    List<String>? completedCourseIds,
    String? finalQCMId,
  }) {
    return SubjectProgressionModel(
      matiere: matiere ?? this.matiere,
      niveau: niveau ?? this.niveau,
      coursCompleted: coursCompleted ?? this.coursCompleted,
      coursInProgress: coursInProgress ?? this.coursInProgress,
      coursTotal: coursTotal ?? this.coursTotal,
      qcmPassed: qcmPassed ?? this.qcmPassed,
      qcmFailed: qcmFailed ?? this.qcmFailed,
      qcmTotal: qcmTotal ?? this.qcmTotal,
      averageScore: averageScore ?? this.averageScore,
      totalXp: totalXp ?? this.totalXp,
      streakDays: streakDays ?? this.streakDays,
      lastActivity: lastActivity ?? this.lastActivity,
      skillLevels: skillLevels ?? this.skillLevels,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      // Nouveaux champs
      requiredCoursesForCompletion: requiredCoursesForCompletion ?? this.requiredCoursesForCompletion,
      hasPassedFinalQCM: hasPassedFinalQCM ?? this.hasPassedFinalQCM,
      finalQCMScore: finalQCMScore ?? this.finalQCMScore,
      completedCourseIds: completedCourseIds ?? this.completedCourseIds,
      finalQCMId: finalQCMId ?? this.finalQCMId,
    );
  }
}

enum UserTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

class GlobalProgressionModel {
  final int totalXp;
  final int currentLevel;
  final int xpToNextLevel;
  final UserTier tier;
  final int totalCoursCompleted;
  final int totalQcmPassed;
  final int totalStreakDays;
  final int maxStreakDays;
  final int currentStreak;
  final DateTime memberSince;
  final DateTime lastLoginDate;
  final Map<String, SubjectProgressionModel> subjectProgressions;
  final List<String> achievements;
  final double overallAverageScore;

  GlobalProgressionModel({
    required this.totalXp,
    required this.currentLevel,
    required this.xpToNextLevel,
    required this.tier,
    required this.totalCoursCompleted,
    required this.totalQcmPassed,
    required this.totalStreakDays,
    required this.maxStreakDays,
    required this.currentStreak,
    required this.memberSince,
    required this.lastLoginDate,
    required this.subjectProgressions,
    required this.achievements,
    required this.overallAverageScore,
  });

  factory GlobalProgressionModel.fromMap(Map<String, dynamic> map) {
    return GlobalProgressionModel(
      totalXp: map['totalXp'] ?? 0,
      currentLevel: map['currentLevel'] ?? 1,
      xpToNextLevel: map['xpToNextLevel'] ?? 100,
      tier: UserTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => UserTier.bronze,
      ),
      totalCoursCompleted: map['totalCoursCompleted'] ?? 0,
      totalQcmPassed: map['totalQcmPassed'] ?? 0,
      totalStreakDays: map['totalStreakDays'] ?? 0,
      maxStreakDays: map['maxStreakDays'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      memberSince: map['memberSince'] != null
          ? (map['memberSince'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginDate: map['lastLoginDate'] != null
          ? (map['lastLoginDate'] as Timestamp).toDate()
          : DateTime.now(),
      subjectProgressions: (map['subjectProgressions'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(
                key,
                SubjectProgressionModel.fromMap(value as Map<String, dynamic>),
              )),
      achievements: List<String>.from(map['achievements'] ?? []),
      overallAverageScore: (map['overallAverageScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalXp': totalXp,
      'currentLevel': currentLevel,
      'xpToNextLevel': xpToNextLevel,
      'tier': tier.name,
      'totalCoursCompleted': totalCoursCompleted,
      'totalQcmPassed': totalQcmPassed,
      'totalStreakDays': totalStreakDays,
      'maxStreakDays': maxStreakDays,
      'currentStreak': currentStreak,
      'memberSince': Timestamp.fromDate(memberSince),
      'lastLoginDate': Timestamp.fromDate(lastLoginDate),
      'subjectProgressions': subjectProgressions.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'achievements': achievements,
      'overallAverageScore': overallAverageScore,
    };
  }

  // Méthodes utiles
  double get levelProgress {
    // Calcul correct : progression dans le niveau actuel
    // Chaque niveau nécessite 100 XP, on calcule le progrès dans le niveau actuel
    int xpInCurrentLevel = totalXp % 100;
    return xpInCurrentLevel / 100.0;
  }

  String get tierName {
    switch (tier) {
      case UserTier.bronze:
        return 'Bronze';
      case UserTier.silver:
        return 'Argent';
      case UserTier.gold:
        return 'Or';
      case UserTier.platinum:
        return 'Platine';
      case UserTier.diamond:
        return 'Diamant';
    }
  }

  String get tierColor {
    switch (tier) {
      case UserTier.bronze:
        return '#CD7F32';
      case UserTier.silver:
        return '#C0C0C0';
      case UserTier.gold:
        return '#FFD700';
      case UserTier.platinum:
        return '#E5E4E2';
      case UserTier.diamond:
        return '#B9F2FF';
    }
  }

  SubjectProgressionModel? getSubjectProgression(String matiere) {
    return subjectProgressions[matiere];
  }

  List<SubjectProgressionModel> get topSubjects {
    return subjectProgressions.values
        .toList()
        ..sort((a, b) => b.preciseCompletionPercentage.compareTo(a.preciseCompletionPercentage));
  }

  GlobalProgressionModel copyWith({
    int? totalXp,
    int? currentLevel,
    int? xpToNextLevel,
    UserTier? tier,
    int? totalCoursCompleted,
    int? totalQcmPassed,
    int? totalStreakDays,
    int? maxStreakDays,
    int? currentStreak,
    DateTime? memberSince,
    DateTime? lastLoginDate,
    Map<String, SubjectProgressionModel>? subjectProgressions,
    List<String>? achievements,
    double? overallAverageScore,
  }) {
    return GlobalProgressionModel(
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      tier: tier ?? this.tier,
      totalCoursCompleted: totalCoursCompleted ?? this.totalCoursCompleted,
      totalQcmPassed: totalQcmPassed ?? this.totalQcmPassed,
      totalStreakDays: totalStreakDays ?? this.totalStreakDays,
      maxStreakDays: maxStreakDays ?? this.maxStreakDays,
      currentStreak: currentStreak ?? this.currentStreak,
      memberSince: memberSince ?? this.memberSince,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      subjectProgressions: subjectProgressions ?? this.subjectProgressions,
      achievements: achievements ?? this.achievements,
      overallAverageScore: overallAverageScore ?? this.overallAverageScore,
    );
  }
}