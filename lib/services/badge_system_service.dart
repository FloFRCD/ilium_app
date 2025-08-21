import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../utils/logger.dart';

/// Service pour le système de badges basé sur les vrais accomplissements
class BadgeSystemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Collection Firebase pour les badges utilisateur
  static const String _userBadgesCollection = 'user_badges';
  
  /// Vérifie et attribue automatiquement les badges mérités
  Future<List<BadgeModel>> checkAndAwardBadges(UserModel user) async {
    try {
      List<BadgeModel> newBadges = [];
      
      // Récupérer les badges déjà attribués à l'utilisateur
      Set<String> existingBadgeIds = await _getUserBadgeIds(user.uid);
      
      // Vérifier chaque type de badge
      List<BadgeModel> achievementBadges = await _checkAchievementBadges(user, existingBadgeIds);
      List<BadgeModel> progressionBadges = await _checkProgressionBadges(user, existingBadgeIds);
      List<BadgeModel> socialBadges = await _checkSocialBadges(user, existingBadgeIds);
      List<BadgeModel> specialBadges = await _checkSpecialBadges(user, existingBadgeIds);
      
      newBadges.addAll(achievementBadges);
      newBadges.addAll(progressionBadges);
      newBadges.addAll(socialBadges);
      newBadges.addAll(specialBadges);
      
      // Sauvegarder les nouveaux badges
      for (BadgeModel badge in newBadges) {
        await _awardBadgeToUser(user.uid, badge);
      }
      
      return newBadges;
    } catch (e) {
      return [];
    }
  }
  
  /// Vérifie les badges d'accomplissement (basés sur les actions)
  Future<List<BadgeModel>> _checkAchievementBadges(UserModel user, Set<String> existingBadges) async {
    List<BadgeModel> newBadges = [];
    
    // Badge "Premier Pas" - Premier cours complété
    if (!existingBadges.contains('first_course') && 
        user.progression.totalCoursCompleted >= 1) {
      newBadges.add(BadgeModel(
        id: 'first_course',
        name: 'Premier Pas',
        description: 'Premier cours complété',
        icon: 'school',
        type: BadgeType.achievement,
        rarity: BadgeRarity.common,
        requirements: {'description': 'Compléter votre premier cours'},
        unlockedAt: DateTime.now(),
        isUnlocked: true,
        xpReward: 50,
      ));
    }
    
    // Badge "Explorateur" - 5 cours complétés
    if (!existingBadges.contains('explorer') && 
        user.progression.totalCoursCompleted >= 5) {
      newBadges.add(BadgeModel(
        id: 'explorer',
        name: 'Explorateur',
        description: '5 cours complétés',
        icon: 'explore',
        type: BadgeType.achievement,
        rarity: BadgeRarity.uncommon,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Compléter 5 cours différents'},
        isUnlocked: true,
        xpReward: 100,
      ));
    }

    // Badge "Érudit" - 20 cours complétés
    if (!existingBadges.contains('scholar') && 
        user.progression.totalCoursCompleted >= 20) {
      newBadges.add(BadgeModel(
        id: 'scholar',
        name: 'Érudit',
        description: '20 cours complétés',
        icon: 'menu_book',
        type: BadgeType.achievement,
        rarity: BadgeRarity.rare,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Compléter 20 cours'},
        isUnlocked: true,
        xpReward: 200,
      ));
    }

    // Badge "Maître QCM" - 10 QCM réussis
    if (!existingBadges.contains('qcm_master') && 
        user.progression.totalQcmPassed >= 10) {
      newBadges.add(BadgeModel(
        id: 'qcm_master',
        name: 'Maître QCM',
        description: '10 QCM réussis',
        icon: 'quiz',
        type: BadgeType.achievement,
        rarity: BadgeRarity.uncommon,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Réussir 10 QCM'},
        isUnlocked: true,
        xpReward: 150,
      ));
    }

    // Badge "Perfectionniste" - Score moyen > 90%
    if (!existingBadges.contains('perfectionist') && 
        user.progression.overallAverageScore >= 90.0) {
      newBadges.add(BadgeModel(
        id: 'perfectionist',
        name: 'Perfectionniste',
        description: 'Score moyen supérieur à 90%',
        icon: 'star',
        type: BadgeType.achievement,
        rarity: BadgeRarity.epic,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Maintenir un score moyen de 90%+'},
        isUnlocked: true,
        xpReward: 300,
      ));
    }
    
    return newBadges;
  }
  
  /// Vérifie les badges de progression (basés sur l'XP et les niveaux)
  Future<List<BadgeModel>> _checkProgressionBadges(UserModel user, Set<String> existingBadges) async {
    List<BadgeModel> newBadges = [];
    
    int currentLevel = user.progression.currentLevel;
    
    // Badge "Apprenti" - Niveau 5
    if (!existingBadges.contains('apprentice') && currentLevel >= 5) {
      newBadges.add(BadgeModel(
        id: 'apprentice',
        name: 'Apprenti',
        description: 'Atteindre le niveau 5',
        icon: 'trending_up',
        type: BadgeType.progression,
        rarity: BadgeRarity.common,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Atteindre le niveau 5'},
        isUnlocked: true,
        xpReward: 150,
      ));
    }

    // Badge "Expert" - Niveau 10  
    if (!existingBadges.contains('expert') && currentLevel >= 10) {
      newBadges.add(BadgeModel(
        id: 'expert',
        name: 'Expert',
        description: 'Atteindre le niveau 10',
        icon: 'workspace_premium',
        type: BadgeType.progression,
        rarity: BadgeRarity.uncommon,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Atteindre le niveau 10'},
        isUnlocked: true,
        xpReward: 200,
      ));
    }

    // Badge "Maître" - Niveau 25
    if (!existingBadges.contains('master') && currentLevel >= 25) {
      newBadges.add(BadgeModel(
        id: 'master',
        name: 'Maître',
        description: 'Atteindre le niveau 25',
        icon: 'military_tech',
        type: BadgeType.progression,
        rarity: BadgeRarity.rare,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Atteindre le niveau 25'},
        isUnlocked: true,
        xpReward: 400,
      ));
    }

    // Badge "Légende" - Niveau 50
    if (!existingBadges.contains('legend') && currentLevel >= 50) {
      newBadges.add(BadgeModel(
        id: 'legend',
        name: 'Légende',
        description: 'Atteindre le niveau 50',
        icon: 'emoji_events',
        type: BadgeType.progression,
        rarity: BadgeRarity.legendary,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Atteindre le niveau 50'},
        isUnlocked: true,
        xpReward: 1000,
      ));
    }
    
    return newBadges;
  }
  
  /// Vérifie les badges sociaux (partage, favoris, etc.)
  Future<List<BadgeModel>> _checkSocialBadges(UserModel user, Set<String> existingBadges) async {
    List<BadgeModel> newBadges = [];
    
    // Badge "Généreux" - Premier partage
    bool hasShared = await _hasUserSharedCourse(user.uid);
    if (!existingBadges.contains('generous') && hasShared) {
      newBadges.add(BadgeModel(
        id: 'generous',
        name: 'Généreux',
        description: 'Premier cours partagé',
        icon: 'share',
        type: BadgeType.achievement,
        rarity: BadgeRarity.common,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Partager votre premier cours'},
        isUnlocked: true,
        xpReward: 75,
      ));
    }
    
    return newBadges;
  }
  
  /// Vérifie les badges spéciaux (basés sur des conditions uniques)
  Future<List<BadgeModel>> _checkSpecialBadges(UserModel user, Set<String> existingBadges) async {
    List<BadgeModel> newBadges = [];
    
    // Badge "Pionnier" - Utilisateur précoce
    if (!existingBadges.contains('pioneer') && 
        user.createdAt.isBefore(DateTime(2024, 12, 31))) {
      newBadges.add(BadgeModel(
        id: 'pioneer',
        name: 'Pionnier',
        description: 'Utilisateur précoce d\'Ilium',
        icon: 'flag',
        type: BadgeType.special,
        rarity: BadgeRarity.legendary,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Rejoindre Ilium avant 2025'},
        isUnlocked: true,
        xpReward: 200,
      ));
    }
    
    // Badge "Assidu" - Streak de 7 jours
    if (!existingBadges.contains('dedicated') && 
        user.progression.totalStreakDays >= 7) {
      newBadges.add(BadgeModel(
        id: 'dedicated',
        name: 'Assidu',
        description: '7 jours consécutifs d\'activité',
        icon: 'local_fire_department',
        type: BadgeType.streak,
        rarity: BadgeRarity.rare,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Maintenir une série de 7 jours'},
        isUnlocked: true,
        xpReward: 250,
      ));
    }

    // Badge "Persévérant" - Streak de 30 jours
    if (!existingBadges.contains('persistent') && 
        user.progression.totalStreakDays >= 30) {
      newBadges.add(BadgeModel(
        id: 'persistent',
        name: 'Persévérant',
        description: '30 jours consécutifs d\'activité',
        icon: 'local_fire_department',
        type: BadgeType.streak,
        rarity: BadgeRarity.epic,
        unlockedAt: DateTime.now(),
        requirements: {'description': 'Maintenir une série de 30 jours'},
        isUnlocked: true,
        xpReward: 500,
      ));
    }
    
    return newBadges;
  }
  
  /// Récupère les IDs des badges déjà attribués à un utilisateur
  Future<Set<String>> _getUserBadgeIds(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_userBadgesCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['badgeId'] as String)
          .toSet();
    } catch (e) {
      return <String>{};
    }
  }
  
  /// Attribue un badge à un utilisateur ET synchronise avec UserModel
  Future<bool> _awardBadgeToUser(String userId, BadgeModel badge) async {
    try {
      // 1. Ajouter dans user_badges
      await _firestore
          .collection(_userBadgesCollection)
          .add({
        'userId': userId,
        'badgeId': badge.id,
        'badgeName': badge.name,
        'badgeDescription': badge.description,
        'badgeIcon': badge.icon,
        'type': badge.type.name,
        'rarity': badge.rarity.name,
        'unlockedAt': Timestamp.fromDate(badge.unlockedAt ?? DateTime.now()),
        'requirements': badge.requirements,
        'xpReward': badge.xpReward,
      });
      
      // 2. CRITIQUE: Synchroniser avec UserModel.badges
      await _synchronizeUserBadges(userId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Synchronise les badges de user_badges avec UserModel.badges
  Future<void> _synchronizeUserBadges(String userId) async {
    try {
      // Récupérer tous les badges de l'utilisateur
      final userBadges = await getUserBadges(userId);
      
      // Mettre à jour UserModel avec les badges synchronisés
      await _firestore.collection('users').doc(userId).update({
        'badges': userBadges.map((badge) => badge.toMap()).toList(),
      });
      
      Logger.info('✅ Badges synchronisés pour utilisateur $userId: ${userBadges.length} badges');
    } catch (e) {
      Logger.error('❌ Erreur synchronisation badges: $e');
    }
  }
  
  /// Récupère tous les badges d'un utilisateur
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_userBadgesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('unlockedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return BadgeModel(
          id: data['badgeId'] ?? '',
          name: data['badgeName'] ?? '',
          description: data['badgeDescription'] ?? '',
          icon: data['badgeIcon'] ?? 'star',
          type: BadgeType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => BadgeType.achievement,
          ),
          rarity: BadgeRarity.values.firstWhere(
            (e) => e.name == data['rarity'],
            orElse: () => BadgeRarity.common,
          ),
          unlockedAt: (data['unlockedAt'] as Timestamp).toDate(),
          requirements: Map<String, dynamic>.from(data['requirements'] ?? {}),
          isUnlocked: true,
          xpReward: data['xpReward'] ?? 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Vérifie si l'utilisateur a partagé au moins un cours
  Future<bool> _hasUserSharedCourse(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('shared_courses')
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}