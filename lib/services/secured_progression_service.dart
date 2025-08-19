import '../services/user_progression_service.dart';
import '../services/xp_award_service.dart';
import '../utils/logger.dart';

/// Service de progression sécurisé avec validation anti-gaming intégrée
/// Remplace les appels directs au UserProgressionService pour garantir la validation
class SecuredProgressionService {
  final UserProgressionService _baseService = UserProgressionService();
  final XPAwardService _xpService = XPAwardService();
  
  /// Enregistrer un résultat de QCM avec validation anti-gaming
  Future<bool> recordSecuredQCMResult({
    required String userId,
    required String matiere,
    required double score,
    required bool passed,
    required int totalTimeSeconds,
    required List<int> questionTimesSeconds,
    required double engagementRate,
  }) async {
    try {
      // Calculer l'XP normalement
      int baseXP = _calculateQCMXP(score, passed);
      
      if (passed && baseXP > 0) {
        // Utiliser le service XP sécurisé pour validation
        final result = await _xpService.awardQCMCompletionXP(
          userId: userId,
          baseXP: baseXP,
          totalTimeSeconds: totalTimeSeconds,
          questionTimesSeconds: questionTimesSeconds,
          engagementRate: engagementRate,
        );
        
        if (!result.wasAwarded) {
          Logger.warning('QCM réussi mais XP refusé: ${result.reason}');
          // Enregistrer quand même le résultat sans XP
          return await _baseService.recordQCMResult(userId, matiere, score, false);
        }
      }
      
      // Enregistrer le résultat normalement (avec ou sans XP selon validation)
      return await _baseService.recordQCMResult(userId, matiere, score, passed);
    } catch (e) {
      Logger.error('Erreur enregistrement QCM sécurisé', e);
      return false;
    }
  }
  
  /// Marque un cours comme complété avec validation anti-gaming
  Future<bool> completeSecuredCourse({
    required String userId,
    required String courseId,
    required String matiere,
    required int readingTimeSeconds,
    required double scrollProgress,
    required int scrollMilestones,
    required bool hasScrolledToEnd,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Calculer l'XP normalement
      int baseXP = _calculateCourseXP();
      
      // Utiliser le service XP sécurisé pour validation
      final result = await _xpService.awardCourseCompletionXP(
        userId: userId,
        baseXP: baseXP,
        readingTimeSeconds: readingTimeSeconds,
        scrollProgress: scrollProgress,
        scrollMilestones: scrollMilestones,
        hasScrolledToEnd: hasScrolledToEnd,
      );
      
      if (!result.wasAwarded) {
        Logger.warning('Cours terminé mais XP refusé: ${result.reason}');
        // Enregistrer la completion sans accorder l'XP
        return await _baseService.completeCourse(userId, matiere, courseId);
      }
      
      // Enregistrer normalement si validation OK
      return await _baseService.completeCourse(userId, matiere, courseId);
    } catch (e) {
      Logger.error('Erreur completion cours sécurisé', e);
      return false;
    }
  }
  
  /// Enregistre une connexion quotidienne avec validation anti-gaming
  Future<bool> recordSecuredDailyLogin({
    required String userId,
    required int sessionTimeSeconds,
    required bool hasPerformedActivity,
  }) async {
    try {
      final result = await _xpService.awardDailyLoginXP(
        userId: userId,
        sessionTimeSeconds: sessionTimeSeconds,
        hasPerformedActivity: hasPerformedActivity,
      );
      
      if (!result.wasAwarded) {
        Logger.info('Connexion quotidienne sans XP: ${result.reason}');
      }
      
      // Mettre à jour la streak même si XP refusé
      return await _baseService.updateStreak(userId);
    } catch (e) {
      Logger.error('Erreur connexion quotidienne sécurisée', e);
      return false;
    }
  }
  
  /// Met à jour une série avec validation anti-gaming
  Future<bool> updateSecuredStreak({
    required String userId,
    required int streakDays,
    required int sessionTimeSeconds,
    required bool hasPerformedActivity,
  }) async {
    try {
      // Attribuer XP bonus pour maintien de série
      if (streakDays > 0 && streakDays % 7 == 0) {
        // XP bonus chaque semaine de série
        final result = await _xpService.awardStreakMaintenanceXP(
          userId: userId,
          streakDays: streakDays,
          sessionTimeSeconds: sessionTimeSeconds,
          hasPerformedActivity: hasPerformedActivity,
        );
        
        if (!result.wasAwarded) {
          Logger.info('Série maintenue mais XP bonus refusé: ${result.reason}');
        }
      }
      
      // Mettre à jour la série dans tous les cas
      return await _baseService.updateStreak(userId);
    } catch (e) {
      Logger.error('Erreur mise à jour série sécurisée', e);
      return false;
    }
  }
  
  /// Délègue les autres méthodes au service de base (sans validation nécessaire)
  Future<bool> addXP(String userId, int xp, {String? reason}) =>
      _baseService.addXP(userId, xp, reason: reason);
  
  Future<bool> recordQCMResult(String uid, String matiere, double score, bool passed) =>
      _baseService.recordQCMResult(uid, matiere, score, passed);
  
  Future<bool> completeCourse(String userId, String matiere, String courseId) =>
      _baseService.completeCourse(userId, matiere, courseId);
  
  Future<bool> updateStreak(String userId) =>
      _baseService.updateStreak(userId);
  
  /// Calcule l'XP pour un QCM (copié du service original)
  int _calculateQCMXP(double score, bool passed) {
    if (!passed) return 0;
    
    // XP basé sur le score
    if (score >= 90) return 50;
    if (score >= 80) return 40;
    if (score >= 70) return 30;
    return 20;
  }
  
  /// Calcule l'XP pour un cours (copié du service original)
  int _calculateCourseXP() {
    return 100; // XP fixe pour completion de cours
  }
}