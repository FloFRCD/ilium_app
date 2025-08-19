import '../utils/logger.dart';

/// Service centralisé pour la validation anti-gaming
/// Empêche les utilisateurs de tricher pour obtenir de l'XP
class AntiGamingService {
  
  /// Valide une session d'activité pour s'assurer qu'elle est légitime
  static AntiGamingValidation validateActivity({
    required String activityType,
    required int totalTimeSeconds,
    required int minimumTimeRequired,
    Map<String, dynamic>? additionalData,
  }) {
    
    List<String> violations = [];
    
    // Validation 1: Temps minimum
    if (totalTimeSeconds < minimumTimeRequired) {
      violations.add('Temps insuffisant: ${totalTimeSeconds}s / ${minimumTimeRequired}s requis');
    }
    
    // Validation 2: Détection de patterns suspects selon le type d'activité
    switch (activityType) {
      case 'course_reading':
        violations.addAll(_validateCourseReading(totalTimeSeconds, additionalData));
        break;
      case 'qcm_completion':
        violations.addAll(_validateQCMCompletion(totalTimeSeconds, additionalData));
        break;
      case 'badge_activity':
        violations.addAll(_validateBadgeActivity(totalTimeSeconds, additionalData));
        break;
    }
    
    bool isValid = violations.isEmpty;
    
    if (!isValid) {
      Logger.warning('Validation anti-gaming échouée pour $activityType - Violations: $violations - Temps: ${totalTimeSeconds}s');
    }
    
    return AntiGamingValidation(
      isValid: isValid,
      violations: violations,
      activityType: activityType,
      totalTimeSeconds: totalTimeSeconds,
    );
  }
  
  /// Valide la lecture d'un cours
  static List<String> _validateCourseReading(int totalTime, Map<String, dynamic>? data) {
    List<String> violations = [];
    
    if (data != null) {
      // Validation scrolling
      double? maxScrollProgress = data['maxScrollProgress'] as double?;
      if (maxScrollProgress != null && maxScrollProgress < 0.8) {
        violations.add('Contenu insuffisamment lu: ${(maxScrollProgress * 100).toInt()}% / 80% requis');
      }
      
      // Validation pauses de lecture
      int? scrollMilestones = data['scrollMilestones'] as int?;
      if (scrollMilestones != null && scrollMilestones < 3) {
        violations.add('Attention insuffisante: $scrollMilestones pauses / 3 requis');
      }
      
      // Validation lecture jusqu'à la fin
      bool? hasScrolledToEnd = data['hasScrolledToEnd'] as bool?;
      if (hasScrolledToEnd != null && !hasScrolledToEnd) {
        violations.add('Cours non lu jusqu\'à la fin');
      }
    }
    
    return violations;
  }
  
  /// Valide la completion d'un QCM
  static List<String> _validateQCMCompletion(int totalTime, Map<String, dynamic>? data) {
    List<String> violations = [];
    
    if (data != null) {
      // Validation temps par question
      List<int>? questionTimes = data['questionTimesSeconds'] as List<int>?;
      if (questionTimes != null) {
        int questionsWithMinTime = questionTimes.where((time) => time >= 10).length;
        int requiredQuestions = (questionTimes.length * 0.5).ceil();
        
        if (questionsWithMinTime < requiredQuestions) {
          violations.add('Questions traitées trop rapidement: $questionsWithMinTime / $requiredQuestions');
        }
      }
      
      // Validation taux d'engagement
      double? engagementRate = data['engagementRate'] as double?;
      if (engagementRate != null && engagementRate < 0.6) {
        violations.add('Taux d\'engagement trop faible: ${(engagementRate * 100).toInt()}% / 60% requis');
      }
    }
    
    return violations;
  }
  
  /// Valide une activité de badge
  static List<String> _validateBadgeActivity(int totalTime, Map<String, dynamic>? data) {
    List<String> violations = [];
    
    // Validation spécifique aux badges
    if (data != null) {
      String? badgeType = data['badgeType'] as String?;
      
      switch (badgeType) {
        case 'daily_login':
          // Vérifier que la connexion n'est pas trop rapide
          if (totalTime < 30) {
            violations.add('Connexion journalière trop rapide');
          }
          break;
        case 'streak_maintenance':
          // Vérifier l'activité réelle
          bool? hasRealActivity = data['hasRealActivity'] as bool?;
          if (hasRealActivity != null && !hasRealActivity) {
            violations.add('Aucune activité réelle détectée');
          }
          break;
      }
    }
    
    return violations;
  }
  
  /// Crée un objet de métadonnées pour les logs
  static Map<String, dynamic> createMetadata({
    required bool validated,
    required String activityType,
    required int totalTimeSeconds,
    List<String>? violations,
    Map<String, dynamic>? customData,
  }) {
    return {
      'validated': validated,
      'activityType': activityType,
      'totalTimeSeconds': totalTimeSeconds,
      'violations': violations ?? [],
      'timestamp': DateTime.now().toIso8601String(),
      ...?customData,
    };
  }
}

/// Résultat d'une validation anti-gaming
class AntiGamingValidation {
  final bool isValid;
  final List<String> violations;
  final String activityType;
  final int totalTimeSeconds;
  
  const AntiGamingValidation({
    required this.isValid,
    required this.violations,
    required this.activityType,
    required this.totalTimeSeconds,
  });
  
  /// Message principal expliquant pourquoi la validation a échoué
  String get primaryReason {
    return violations.isNotEmpty ? violations.first : '';
  }
  
  /// Message détaillé avec toutes les violations
  String get detailedReason {
    return violations.join('\n');
  }
  
  /// Crée les métadonnées pour les logs
  Map<String, dynamic> toMetadata() {
    return AntiGamingService.createMetadata(
      validated: isValid,
      activityType: activityType,
      totalTimeSeconds: totalTimeSeconds,
      violations: violations,
    );
  }
}