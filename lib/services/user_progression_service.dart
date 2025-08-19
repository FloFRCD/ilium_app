import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/progression_model.dart';
import 'firestore_service.dart';
import 'badge_system_service.dart';
import 'badge_notification_service.dart';
import 'subject_completion_service.dart';
import '../utils/logger.dart';

class UserProgressionService {
  final FirestoreService _firestoreService = FirestoreService();
  final BadgeSystemService _badgeSystemService = BadgeSystemService();
  
  /// Met à jour l'XP de l'utilisateur
  Future<bool> addXP(String uid, int xpToAdd, {String? reason}) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      int newTotalXp = user.progression.totalXp + xpToAdd;
      int newLevel = _calculateLevel(newTotalXp);
      int xpToNextLevel = _calculateXpToNextLevel(newLevel);
      UserTier newTier = _calculateTier(newLevel);
      
      GlobalProgressionModel updatedProgression = user.progression.copyWith(
        totalXp: newTotalXp,
        currentLevel: newLevel,
        xpToNextLevel: xpToNextLevel,
        tier: newTier,
        lastLoginDate: DateTime.now(),
      );
      
      UserModel updatedUser = user.copyWith(
        progression: updatedProgression,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      
      if (reason != null) {
        Logger.info('XP ajouté: +$xpToAdd ($reason) - Total: $newTotalXp');
      }
      
      return true;
    } catch (e) {
      Logger.error('Erreur ajout XP: $e');
      return false;
    }
  }
  
  /// Marque un cours comme complété
  Future<bool> completeCourse(String uid, String matiere, String courseId, {BuildContext? context}) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      // Mise à jour progression générale
      GlobalProgressionModel updatedProgression = user.progression.copyWith(
        totalCoursCompleted: user.progression.totalCoursCompleted + 1,
        lastLoginDate: DateTime.now(),
      );
      
      // Mise à jour progression par matière
      Map<String, SubjectProgressionModel> subjectProgressions = 
          Map.from(user.progression.subjectProgressions);
      
      SubjectProgressionModel? subjectProgression = subjectProgressions[matiere];
      if (subjectProgression != null) {
        // Utiliser SubjectCompletionService pour la mise à jour précise
        subjectProgression = SubjectCompletionService.updateOnCourseCompleted(
          current: subjectProgression,
          courseId: courseId,
        );
        subjectProgressions[matiere] = subjectProgression;
      } else {
        // Créer nouvelle progression avec SubjectCompletionService
        subjectProgression = SubjectCompletionService.initializeProgression(
          matiere: matiere,
          niveau: user.niveau,
        );
        // Marquer le premier cours comme complété
        subjectProgression = SubjectCompletionService.updateOnCourseCompleted(
          current: subjectProgression,
          courseId: courseId,
        );
        subjectProgressions[matiere] = subjectProgression;
      }
      
      updatedProgression = updatedProgression.copyWith(
        subjectProgressions: subjectProgressions,
      );
      
      UserModel updatedUser = user.copyWith(
        progression: updatedProgression,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      
      // Ajouter XP pour le cours complété
      await addXP(uid, 50, reason: 'Cours complété: $matiere');
      
      // Vérifier et attribuer les badges
      final newBadges = await _badgeSystemService.checkAndAwardBadges(updatedUser);
      
      // Ajouter l'XP des nouveaux badges obtenus et afficher les notifications
      for (final badge in newBadges) {
        await addXP(uid, badge.xpReward, reason: 'Badge débloqué: ${badge.name}');
        Logger.info('🏆 Nouveau badge débloqué: ${badge.name} (+${badge.xpReward} XP)');
        
        // Afficher notification si context disponible
        if (context != null && context.mounted) {
          BadgeNotificationService.showBadgeUnlockedNotification(context, badge);
        }
      }
      
      return true;
    } catch (e) {
      Logger.error('Erreur completion cours: $e');
      return false;
    }
  }
  
  /// Enregistre un résultat de QCM final (pour la progression précise)
  Future<bool> recordFinalQCMResult(String uid, String matiere, double score, String qcmId, {BuildContext? context}) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      // Mise à jour avec SubjectCompletionService
      Map<String, SubjectProgressionModel> subjectProgressions = 
          Map.from(user.progression.subjectProgressions);
      
      SubjectProgressionModel? subjectProgression = subjectProgressions[matiere];
      if (subjectProgression != null) {
        // Vérifier si c'est le QCM final pour cette matière/niveau
        final criteria = SubjectCompletionService.getCompletionCriteria(matiere, user.niveau);
        if (criteria['finalQCMId'] == qcmId) {
          // C'est le QCM final, utiliser la méthode spécialisée
          subjectProgression = SubjectCompletionService.updateOnFinalQCMPassed(
            current: subjectProgression,
            score: score,
          );
          subjectProgressions[matiere] = subjectProgression;
          
          // Mise à jour de la progression générale
          GlobalProgressionModel updatedProgression = user.progression.copyWith(
            subjectProgressions: subjectProgressions,
            totalQcmPassed: score >= criteria['minScore'] 
                ? user.progression.totalQcmPassed + 1 
                : user.progression.totalQcmPassed,
            overallAverageScore: _calculateOverallAverage(subjectProgressions),
            lastLoginDate: DateTime.now(),
          );
          
          UserModel updatedUser = user.copyWith(
            progression: updatedProgression,
            updatedAt: DateTime.now(),
          );
          
          await _firestoreService.saveUser(updatedUser);
          
          int xpEarned = _calculateQCMXP(score, score >= criteria['minScore']);
          await addXP(uid, xpEarned, reason: 'QCM final $matiere: $score%');
          
          // Vérifier les badges
          final newBadges = await _badgeSystemService.checkAndAwardBadges(updatedUser);
          for (final badge in newBadges) {
            await addXP(uid, badge.xpReward, reason: 'Badge débloqué: ${badge.name}');
            Logger.info('🏆 Nouveau badge débloqué: ${badge.name} (+${badge.xpReward} XP)');
            
            if (context != null && context.mounted) {
              BadgeNotificationService.showBadgeUnlockedNotification(context, badge);
            }
          }
          
          return true;
        }
      } else {
        // Pas de progression existante - vérifier si c'est le QCM final pour créer directement
        final criteria = SubjectCompletionService.getCompletionCriteria(matiere, user.niveau);
        if (criteria['finalQCMId'] == qcmId && score >= criteria['minScore']) {
          // Créer progression directement via QCM final (maîtrise démontrée sans cours)
          subjectProgression = SubjectCompletionService.createProgressionForDirectQCM(
            matiere: matiere,
            niveau: user.niveau,
            score: score,
          );
          subjectProgressions[matiere] = subjectProgression;
          
          // Mise à jour de la progression générale
          GlobalProgressionModel updatedProgression = user.progression.copyWith(
            subjectProgressions: subjectProgressions,
            totalQcmPassed: user.progression.totalQcmPassed + 1, // QCM réussi
            overallAverageScore: _calculateOverallAverage(subjectProgressions),
            lastLoginDate: DateTime.now(),
          );
          
          UserModel updatedUser = user.copyWith(
            progression: updatedProgression,
            updatedAt: DateTime.now(),
          );
          
          await _firestoreService.saveUser(updatedUser);
          
          // XP bonus pour maîtrise directe déjà inclus dans createProgressionForDirectQCM
          int xpEarned = 300; // XP bonus pour démonstration directe de maîtrise
          await addXP(uid, xpEarned, reason: 'Maîtrise directe $matiere par QCM final: $score%');
          
          // Vérifier les badges
          final newBadges = await _badgeSystemService.checkAndAwardBadges(updatedUser);
          for (final badge in newBadges) {
            await addXP(uid, badge.xpReward, reason: 'Badge débloqué: ${badge.name}');
            Logger.info('🏆 Nouveau badge débloqué: ${badge.name} (+${badge.xpReward} XP)');
            
            if (context != null && context.mounted) {
              BadgeNotificationService.showBadgeUnlockedNotification(context, badge);
            }
          }
          
          return true;
        }
      }
      
      // Si ce n'est pas un QCM final, utiliser la méthode normale
      if (context != null && context.mounted) {
        return recordQCMResult(uid, matiere, score, score >= 60, context: context);
      } else {
        return recordQCMResult(uid, matiere, score, score >= 60);
      }
    } catch (e) {
      Logger.error('Erreur enregistrement QCM final: $e');
      return false;
    }
  }

  /// Enregistre un résultat de QCM
  Future<bool> recordQCMResult(String uid, String matiere, double score, bool passed, {BuildContext? context}) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      int xpEarned = _calculateQCMXP(score, passed);
      
      // Mise à jour progression générale
      GlobalProgressionModel updatedProgression = user.progression.copyWith(
        totalQcmPassed: passed 
            ? user.progression.totalQcmPassed + 1 
            : user.progression.totalQcmPassed,
        lastLoginDate: DateTime.now(),
      );
      
      // Mise à jour progression par matière
      Map<String, SubjectProgressionModel> subjectProgressions = 
          Map.from(user.progression.subjectProgressions);
      
      SubjectProgressionModel? subjectProgression = subjectProgressions[matiere];
      if (subjectProgression != null) {
        int newQcmPassed = passed ? subjectProgression.qcmPassed + 1 : subjectProgression.qcmPassed;
        int newQcmFailed = !passed ? subjectProgression.qcmFailed + 1 : subjectProgression.qcmFailed;
        int newQcmTotal = subjectProgression.qcmTotal + 1;
        
        // Calcul nouveau score moyen
        double newAverageScore = ((subjectProgression.averageScore * subjectProgression.qcmTotal) + score) / newQcmTotal;
        
        subjectProgression = subjectProgression.copyWith(
          qcmPassed: newQcmPassed,
          qcmFailed: newQcmFailed,
          qcmTotal: newQcmTotal,
          averageScore: newAverageScore,
          lastActivity: DateTime.now(),
          totalXp: subjectProgression.totalXp + xpEarned,
        );
        subjectProgressions[matiere] = subjectProgression;
      } else {
        // Créer nouvelle progression normale avec SubjectCompletionService
        // Note: Pour une maîtrise directe par QCM final, utiliser recordFinalQCMResult() à la place
        subjectProgression = SubjectCompletionService.initializeProgression(
          matiere: matiere,
          niveau: user.niveau,
        );
        // Mettre à jour avec le résultat du QCM
        subjectProgression = subjectProgression.copyWith(
          qcmPassed: passed ? 1 : 0,
          qcmFailed: passed ? 0 : 1,
          qcmTotal: 1,
          averageScore: score,
          totalXp: xpEarned,
          lastActivity: DateTime.now(),
        );
        subjectProgressions[matiere] = subjectProgression;
      }
      
      updatedProgression = updatedProgression.copyWith(
        subjectProgressions: subjectProgressions,
        overallAverageScore: _calculateOverallAverage(subjectProgressions),
      );
      
      UserModel updatedUser = user.copyWith(
        progression: updatedProgression,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      
      // Ajouter XP pour le QCM
      await addXP(uid, xpEarned, reason: 'QCM ${passed ? "réussi" : "tenté"}: $matiere ($score%)');
      
      // Vérifier et attribuer les badges
      final newBadges = await _badgeSystemService.checkAndAwardBadges(updatedUser);
      
      // Ajouter l'XP des nouveaux badges obtenus et afficher les notifications
      for (final badge in newBadges) {
        await addXP(uid, badge.xpReward, reason: 'Badge débloqué: ${badge.name}');
        Logger.info('🏆 Nouveau badge débloqué: ${badge.name} (+${badge.xpReward} XP)');
        
        // Afficher notification si context disponible
        if (context != null && context.mounted) {
          BadgeNotificationService.showBadgeUnlockedNotification(context, badge);
        }
      }
      
      return true;
    } catch (e) {
      Logger.error('Erreur enregistrement QCM: $e');
      return false;
    }
  }
  
  /// Met à jour la streak de l'utilisateur
  Future<bool> updateStreak(String uid, {BuildContext? context}) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      DateTime now = DateTime.now();
      DateTime lastLogin = user.progression.lastLoginDate;
      
      // Vérifier si c'est un jour consécutif
      int daysDifference = now.difference(lastLogin).inDays;
      
      int newStreakDays = user.progression.totalStreakDays;
      int newCurrentStreak = user.progression.currentStreak;
      int newMaxStreak = user.progression.maxStreakDays;
      
      if (daysDifference == 0) {
        // Même jour - pas de changement mais s'assurer qu'on a au moins 1
        if (newCurrentStreak == 0) {
          newCurrentStreak = 1;
          newStreakDays = 1;
          if (newCurrentStreak > newMaxStreak) {
            newMaxStreak = newCurrentStreak;
          }
        }
      } else if (daysDifference == 1) {
        // Jour consécutif - augmenter la streak
        newStreakDays += 1;
        newCurrentStreak += 1;
        if (newCurrentStreak > newMaxStreak) {
          newMaxStreak = newCurrentStreak;
        }
      } else if (daysDifference > 1) {
        // Streak cassée - recommencer à 1
        newStreakDays += 1; // On compte quand même ce jour d'activité
        newCurrentStreak = 1; // Mais la série actuelle repart à 1
      }
      
      GlobalProgressionModel updatedProgression = user.progression.copyWith(
        totalStreakDays: newStreakDays,
        currentStreak: newCurrentStreak,
        maxStreakDays: newMaxStreak,
        lastLoginDate: now,
      );
      
      UserModel updatedUser = user.copyWith(
        progression: updatedProgression,
        updatedAt: now,
      );
      
      await _firestoreService.saveUser(updatedUser);
      
      Logger.info('Streak mise à jour: daysDifference=$daysDifference, currentStreak=$newCurrentStreak, totalStreakDays=$newStreakDays');
      
      // Vérifier et attribuer les badges liés aux streaks
      final newBadges = await _badgeSystemService.checkAndAwardBadges(updatedUser);
      
      // Ajouter l'XP des nouveaux badges obtenus et afficher les notifications
      for (final badge in newBadges) {
        await addXP(uid, badge.xpReward, reason: 'Badge débloqué: ${badge.name}');
        Logger.info('🏆 Nouveau badge débloqué: ${badge.name} (+${badge.xpReward} XP)');
        
        // Afficher notification si context disponible
        if (context != null && context.mounted) {
          BadgeNotificationService.showBadgeUnlockedNotification(context, badge);
        }
      }
      
      return true;
    } catch (e) {
      Logger.error('Erreur mise à jour streak: $e');
      return false;
    }
  }
  
  // Méthodes utilitaires privées
  
  int _calculateLevel(int totalXp) {
    return (totalXp / 100).floor() + 1;
  }
  
  int _calculateXpToNextLevel(int currentLevel) {
    return currentLevel * 100;
  }
  
  UserTier _calculateTier(int level) {
    if (level >= 50) return UserTier.diamond;
    if (level >= 30) return UserTier.platinum;
    if (level >= 20) return UserTier.gold;
    if (level >= 10) return UserTier.silver;
    return UserTier.bronze;
  }
  
  int _calculateQCMXP(double score, bool passed) {
    int baseXP = passed ? 30 : 10;
    int bonusXP = (score / 10).floor() * 5; // 5 XP par tranche de 10%
    return baseXP + bonusXP;
  }
  
  double _calculateOverallAverage(Map<String, SubjectProgressionModel> subjectProgressions) {
    if (subjectProgressions.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    int totalQcm = 0;
    
    for (SubjectProgressionModel progression in subjectProgressions.values) {
      totalScore += progression.averageScore * progression.qcmTotal;
      totalQcm += progression.qcmTotal;
    }
    
    return totalQcm > 0 ? totalScore / totalQcm : 0.0;
  }
}