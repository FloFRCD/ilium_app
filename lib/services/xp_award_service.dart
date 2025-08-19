import '../services/anti_gaming_service.dart';
import '../services/user_progression_service.dart';
import '../utils/logger.dart';

/// Service centralisé pour l'attribution d'XP avec validation anti-gaming
class XPAwardService {
  final UserProgressionService _progressionService = UserProgressionService();
  
  /// Attribue de l'XP après validation anti-gaming
  Future<XPAwardResult> awardXP({
    required String userId,
    required int xpAmount,
    required String activityType,
    required int totalTimeSeconds,
    required int minimumTimeRequired,
    Map<String, dynamic>? additionalData,
    String? reason,
  }) async {
    
    // Validation anti-gaming
    final validation = AntiGamingService.validateActivity(
      activityType: activityType,
      totalTimeSeconds: totalTimeSeconds,
      minimumTimeRequired: minimumTimeRequired,
      additionalData: additionalData,
    );
    
    if (!validation.isValid) {
      Logger.warning('XP refusé pour $activityType - ${validation.primaryReason}');
      return XPAwardResult(
        success: false,
        xpAwarded: 0,
        reason: validation.primaryReason,
        wasValidated: false,
      );
    }
    
    // Attribution de l'XP
    try {
      final success = await _progressionService.addXP(
        userId, 
        xpAmount, 
        reason: reason ?? activityType,
      );
      
      if (success) {
        Logger.info('XP attribué avec succès: +$xpAmount XP pour $activityType (temps: ${totalTimeSeconds}s)');
        return XPAwardResult(
          success: true,
          xpAwarded: xpAmount,
          reason: 'XP attribué avec succès',
          wasValidated: true,
        );
      } else {
        return XPAwardResult(
          success: false,
          xpAwarded: 0,
          reason: 'Erreur lors de l\'attribution XP',
          wasValidated: true,
        );
      }
    } catch (e) {
      Logger.error('Erreur attribution XP', e);
      return XPAwardResult(
        success: false,
        xpAwarded: 0,
        reason: 'Erreur technique: $e',
        wasValidated: true,
      );
    }
  }
  
  /// Attribue de l'XP pour la completion d'un cours
  Future<XPAwardResult> awardCourseCompletionXP({
    required String userId,
    required int baseXP,
    required int readingTimeSeconds,
    required double scrollProgress,
    required int scrollMilestones,
    required bool hasScrolledToEnd,
  }) async {
    return awardXP(
      userId: userId,
      xpAmount: baseXP,
      activityType: 'course_reading',
      totalTimeSeconds: readingTimeSeconds,
      minimumTimeRequired: 60, // 1 minute minimum
      additionalData: {
        'maxScrollProgress': scrollProgress,
        'scrollMilestones': scrollMilestones,
        'hasScrolledToEnd': hasScrolledToEnd,
      },
      reason: 'Completion de cours',
    );
  }
  
  /// Attribue de l'XP pour la réussite d'un QCM
  Future<XPAwardResult> awardQCMCompletionXP({
    required String userId,
    required int baseXP,
    required int totalTimeSeconds,
    required List<int> questionTimesSeconds,
    required double engagementRate,
  }) async {
    return awardXP(
      userId: userId,
      xpAmount: baseXP,
      activityType: 'qcm_completion',
      totalTimeSeconds: totalTimeSeconds,
      minimumTimeRequired: 30, // 30 secondes minimum
      additionalData: {
        'questionTimesSeconds': questionTimesSeconds,
        'engagementRate': engagementRate,
      },
      reason: 'Réussite QCM',
    );
  }
  
  /// Attribue de l'XP pour une connexion quotidienne (avec validation contre le spam)
  Future<XPAwardResult> awardDailyLoginXP({
    required String userId,
    required int sessionTimeSeconds,
    required bool hasPerformedActivity,
  }) async {
    return awardXP(
      userId: userId,
      xpAmount: 10, // XP fixe pour connexion quotidienne
      activityType: 'badge_activity',
      totalTimeSeconds: sessionTimeSeconds,
      minimumTimeRequired: 30, // Au moins 30 secondes de session
      additionalData: {
        'badgeType': 'daily_login',
        'hasRealActivity': hasPerformedActivity,
      },
      reason: 'Connexion quotidienne',
    );
  }
  
  /// Attribue de l'XP pour le maintien d'une série (avec validation)
  Future<XPAwardResult> awardStreakMaintenanceXP({
    required String userId,
    required int streakDays,
    required int sessionTimeSeconds,
    required bool hasPerformedActivity,
  }) async {
    final bonusXP = (streakDays / 7).floor() * 5; // 5 XP bonus par semaine de série
    
    return awardXP(
      userId: userId,
      xpAmount: 15 + bonusXP,
      activityType: 'badge_activity',
      totalTimeSeconds: sessionTimeSeconds,
      minimumTimeRequired: 60, // Au moins 1 minute d'activité
      additionalData: {
        'badgeType': 'streak_maintenance',
        'hasRealActivity': hasPerformedActivity,
        'streakDays': streakDays,
      },
      reason: 'Maintien série ($streakDays jours)',
    );
  }
}

/// Résultat d'une attribution d'XP
class XPAwardResult {
  final bool success;
  final int xpAwarded;
  final String reason;
  final bool wasValidated;
  
  const XPAwardResult({
    required this.success,
    required this.xpAwarded,
    required this.reason,
    required this.wasValidated,
  });
  
  /// Retourne true si l'XP a été attribué avec succès
  bool get wasAwarded => success && xpAwarded > 0;
  
  /// Retourne true si la validation anti-gaming a échoué
  bool get failedValidation => !success && wasValidated;
  
  @override
  String toString() {
    return 'XPAwardResult(success: $success, xpAwarded: $xpAwarded, reason: $reason)';
  }
}