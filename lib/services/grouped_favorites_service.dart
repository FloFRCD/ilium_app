import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_group_model.dart';
import '../models/course_model.dart';
import 'course_group_service.dart';
import 'course_status_service.dart';
import '../utils/logger.dart';

/// Service pour gérer les favoris groupés par sujet/chapitre
/// 
/// CONCEPT RÉVOLUTIONNAIRE :
/// Au lieu de favoriser individuellement chaque type de cours,
/// on favorise le SUJET ENTIER avec tous ses contenus :
/// 
/// AVANT : 
/// - Favori : "Les fractions - Cours complet"
/// - Favori : "Les fractions - Fiche de révision"  
/// - Favori : "Les fractions - QCM"
/// 
/// APRÈS :
/// - Favori : "Les fractions" (avec cours complet + fiche + QCM + progression)
/// 
/// AVANTAGES POUR LES PARENTS :
/// - Vision globale du sujet étudié
/// - Progression visible sur l'ensemble du chapitre
/// - Statistiques complètes (QCM réussis, temps passé)
/// - Accès facile à tous les types de contenu
/// - Suivi pédagogique simplifié
class GroupedFavoritesService extends ChangeNotifier {
  static final GroupedFavoritesService _instance = GroupedFavoritesService._internal();
  factory GroupedFavoritesService() => _instance;
  GroupedFavoritesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CourseGroupService _groupService = CourseGroupService();
  final CourseStatusService _statusService = CourseStatusService();
  
  // Cache des favoris groupés par utilisateur
  final Map<String, List<CourseGroupModel>> _userFavoriteGroupsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Stream pour notifier les changements
  final StreamController<Map<String, List<CourseGroupModel>>> _favoritesStreamController = 
      StreamController<Map<String, List<CourseGroupModel>>>.broadcast();
  
  // Durée de validité du cache (5 minutes)
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  
  /// Stream des changements de favoris groupés
  Stream<Map<String, List<CourseGroupModel>>> get favoritesStream => _favoritesStreamController.stream;

  /// Ajoute un groupe de cours aux favoris
  Future<bool> addGroupToFavorites({
    required String userId,
    required CourseGroupModel group,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_groups')
          .doc(group.id)
          .set({
        'groupId': group.id,
        'title': group.title,
        'matiere': group.matiere,
        'niveau': group.niveau,
        'addedAt': FieldValue.serverTimestamp(),
        'totalContent': group.totalContentCount,
        'availableContent': group.availableContentDescription,
      });
      
      // Marquer tous les cours du groupe comme "en cours" automatiquement
      await _markGroupCoursesAsInProgress(userId, group);
      
      // Invalider le cache pour forcer le refresh
      invalidateUserCache(userId);
      
      // Notifier les listeners et le stream
      notifyListeners();
      await _broadcastFavoritesChanges();
      
      Logger.info('Groupe ajouté aux favoris: ${group.title} pour $userId');
      return true;
      
    } catch (e) {
      Logger.error('Erreur ajout groupe aux favoris: $e');
      return false;
    }
  }

  /// Ajoute un cours individuel aux favoris (en créant/trouvant son groupe)
  Future<bool> addCourseToFavorites({
    required String userId,
    required CourseModel course,
  }) async {
    try {
      // Créer ou trouver le groupe pour ce cours
      CourseGroupModel group = await _groupService.createCourseGroup(
        title: course.title,
        matiere: course.matiere,
        niveau: course.niveau,
        description: course.description,
        tags: course.tags,
      );
      
      // Ajouter le groupe aux favoris
      return await addGroupToFavorites(userId: userId, group: group);
      
    } catch (e) {
      Logger.error('Erreur ajout cours aux favoris groupés: $e');
      return false;
    }
  }

  /// Retire un groupe des favoris
  Future<bool> removeGroupFromFavorites({
    required String userId,
    required String groupId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_groups')
          .doc(groupId)
          .delete();
      
      // Invalider le cache pour forcer le refresh
      invalidateUserCache(userId);
      
      // Notifier les listeners et le stream
      notifyListeners();
      await _broadcastFavoritesChanges();
      
      Logger.info('Groupe retiré des favoris: $groupId pour $userId');
      return true;
      
    } catch (e) {
      Logger.error('Erreur suppression groupe des favoris: $e');
      return false;
    }
  }

  /// Toggle favori pour un cours (gère le groupe automatiquement)
  Future<bool> toggleCourseFavorite({
    required String userId,
    required CourseModel course,
  }) async {
    try {
      // Générer l'ID du groupe pour ce cours
      String groupId = CourseGroupModel.generateGroupId(
        course.title, 
        course.matiere, 
        course.niveau
      );
      
      Logger.debug('🔄 Toggle favori pour cours "${course.title}" -> groupId: $groupId');
      
      bool isCurrentlyFavorite = await isGroupFavorite(userId: userId, groupId: groupId);
      
      Logger.debug('📊 État actuel favori: $isCurrentlyFavorite');
      
      if (isCurrentlyFavorite) {
        Logger.debug('➖ Suppression du groupe des favoris');
        bool result = await removeGroupFromFavorites(userId: userId, groupId: groupId);
        Logger.debug('✅ Résultat suppression: $result');
        return result;
      } else {
        Logger.debug('➕ Ajout du cours aux favoris');
        bool result = await addCourseToFavorites(userId: userId, course: course);
        Logger.debug('✅ Résultat ajout: $result');
        return result;
      }
      
    } catch (e) {
      Logger.error('Erreur toggle favori cours: $e');
      return false;
    }
  }

  /// Vérifie si un groupe est en favoris
  Future<bool> isGroupFavorite({
    required String userId,
    required String groupId,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_groups')
          .doc(groupId)
          .get();
      
      Logger.debug('🔎 Vérification document favori: users/$userId/favorite_groups/$groupId -> exists: ${doc.exists}');
      
      return doc.exists;
    } catch (e) {
      Logger.error('Erreur vérification favori groupe: $e');
      return false;
    }
  }

  /// Vérifie si un cours fait partie d'un groupe favorisé
  Future<bool> isCourseInFavoriteGroup({
    required String userId,
    required CourseModel course,
  }) async {
    String groupId = CourseGroupModel.generateGroupId(
      course.title, 
      course.matiere, 
      course.niveau
    );
    
    Logger.debug('🔍 Vérification favori pour cours "${course.title}" -> groupId: $groupId');
    
    bool isFavorite = await isGroupFavorite(userId: userId, groupId: groupId);
    
    Logger.debug('📖 Résultat favori pour groupId $groupId: $isFavorite');
    
    return isFavorite;
  }

  /// Récupère tous les groupes favoris d'un utilisateur
  Future<List<CourseGroupModel>> getFavoriteGroups({
    required String userId,
    bool forceRefresh = false,
  }) async {
    // Vérifier le cache
    if (!forceRefresh && _isCacheValid(userId)) {
      return _userFavoriteGroupsCache[userId] ?? [];
    }
    
    return await _refreshUserFavoriteGroups(userId);
  }

  /// Stream des groupes favoris en temps réel
  Stream<List<CourseGroupModel>> getFavoriteGroupsStream({
    required String userId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorite_groups')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <CourseGroupModel>[];
      }

      List<CourseGroupModel> favoriteGroups = [];
      
      for (DocumentSnapshot doc in snapshot.docs) {
        String groupId = doc['groupId'];
        
        // Récupérer le groupe complet avec tous ses contenus
        CourseGroupModel? group = await _groupService.getCourseGroup(groupId);
        if (group != null) {
          favoriteGroups.add(group);
        }
      }

      return favoriteGroups;
    });
  }

  /// Récupère les groupes avec leur progression détaillée
  Future<List<Map<String, dynamic>>> getFavoriteGroupsWithProgress({
    required String userId,
  }) async {
    try {
      List<CourseGroupModel> groups = await getFavoriteGroups(userId: userId);
      
      List<Map<String, dynamic>> groupsWithProgress = [];
      
      for (CourseGroupModel group in groups) {
        double progressPercentage = group.calculateProgressPercentage(userId);
        Map<String, int> qcmSummary = group.getQCMSummary(userId);
        
        groupsWithProgress.add({
          'group': group,
          'progressPercentage': progressPercentage,
          'qcmSummary': qcmSummary,
          'totalContent': group.totalContentCount,
          'availableContent': group.availableContentDescription,
          'hasCoursComplet': group.hasCoursComplet,
          'hasFicheRevision': group.hasFicheRevision,
          'hasQCMs': group.hasQCMs,
          'qcmCount': group.qcms.length,
        });
      }
      
      return groupsWithProgress;
      
    } catch (e) {
      Logger.error('Erreur récupération favoris avec progression: $e');
      return [];
    }
  }

  /// Met à jour la progression d'un utilisateur sur un groupe
  Future<bool> updateGroupProgress({
    required String userId,
    required String groupId,
    required String contentType,
    required String contentId,
    required bool completed,
  }) async {
    try {
      // Récupérer le groupe actuel
      CourseGroupModel? group = await _groupService.getCourseGroup(groupId);
      if (group == null) return false;
      
      // Mettre à jour la progression
      CourseGroupModel updatedGroup = group.updateUserProgress(
        userId, 
        contentType, 
        contentId, 
        completed
      );
      
      // Sauvegarder dans Firestore (pour l'instant on garde la progression dans le groupe)
      // TODO: Implémenter la sauvegarde de progression dans une collection dédiée
      
      Logger.info('Progression mise à jour: $contentType/$contentId = $completed pour $userId');
      return true;
      
    } catch (e) {
      Logger.error('Erreur mise à jour progression: $e');
      return false;
    }
  }

  /// Rafraîchit le cache des favoris pour un utilisateur
  Future<List<CourseGroupModel>> _refreshUserFavoriteGroups(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_groups')
          .orderBy('addedAt', descending: true)
          .get();

      List<CourseGroupModel> favoriteGroups = [];
      
      for (DocumentSnapshot doc in snapshot.docs) {
        String groupId = doc['groupId'];
        
        // Récupérer le groupe complet
        CourseGroupModel? group = await _groupService.getCourseGroup(groupId);
        if (group != null) {
          favoriteGroups.add(group);
        }
      }

      // Mettre à jour le cache
      _userFavoriteGroupsCache[userId] = favoriteGroups;
      _cacheTimestamps[userId] = DateTime.now();
      
      // Notifier les listeners
      _favoritesStreamController.add(_userFavoriteGroupsCache);
      notifyListeners();
      
      Logger.info('${favoriteGroups.length} groupes favoris chargés pour $userId');
      return favoriteGroups;
      
    } catch (e) {
      Logger.error('Erreur rafraîchissement favoris groupés: $e');
      return [];
    }
  }

  /// Vérifie si le cache est valide
  bool _isCacheValid(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;
    
    final isValid = DateTime.now().difference(timestamp) < _cacheValidityDuration;
    if (!isValid) {
      Logger.debug('Cache favoris groupés expiré pour: $userId');
    }
    return isValid;
  }

  /// Invalide le cache d'un utilisateur
  void invalidateUserCache(String userId) {
    _userFavoriteGroupsCache.remove(userId);
    _cacheTimestamps.remove(userId);
    Logger.info('Cache favoris groupés invalidé pour: $userId');
  }

  /// Diffuse les changements de favoris via le stream
  Future<void> _broadcastFavoritesChanges() async {
    try {
      // Recreer la map avec tous les favoris mis à jour
      Map<String, List<CourseGroupModel>> allFavorites = {};
      
      // Pour chaque utilisateur dans le cache, recharger ses favoris
      for (String userId in _userFavoriteGroupsCache.keys.toList()) {
        allFavorites[userId] = await getFavoriteGroups(userId: userId, forceRefresh: true);
      }
      
      // Diffuser via le stream
      _favoritesStreamController.add(allFavorites);
      Logger.debug('🔄 Favoris diffusés via stream pour ${allFavorites.length} utilisateurs');
      
    } catch (e) {
      Logger.error('Erreur diffusion favoris: $e');
    }
  }

  /// Obtient les statistiques globales des favoris
  Future<Map<String, dynamic>> getFavoritesStats(String userId) async {
    try {
      List<Map<String, dynamic>> groupsWithProgress = await getFavoriteGroupsWithProgress(userId: userId);
      
      int totalGroups = groupsWithProgress.length;
      int totalContent = groupsWithProgress.fold(0, (sum, item) => sum + (item['totalContent'] as int));
      
      double averageProgress = totalGroups > 0 
          ? groupsWithProgress.fold(0.0, (sum, item) => sum + (item['progressPercentage'] as double)) / totalGroups
          : 0.0;
      
      int totalQCMs = groupsWithProgress.fold(0, (sum, item) => sum + (item['qcmCount'] as int));
      int successfulQCMs = groupsWithProgress.fold(0, (sum, item) {
        Map<String, int> qcmSummary = item['qcmSummary'] as Map<String, int>;
        return sum + qcmSummary['reussis']!;
      });
      
      return {
        'totalFavoriteGroups': totalGroups,
        'totalContent': totalContent,
        'averageProgress': averageProgress,
        'totalQCMs': totalQCMs,
        'successfulQCMs': successfulQCMs,
        'qcmSuccessRate': totalQCMs > 0 ? (successfulQCMs / totalQCMs) * 100 : 0.0,
      };
      
    } catch (e) {
      Logger.error('Erreur statistiques favoris: $e');
      return {};
    }
  }

  /// Marque tous les cours d'un groupe comme "en cours" automatiquement
  /// quand le groupe est ajouté aux favoris
  Future<void> _markGroupCoursesAsInProgress(String userId, CourseGroupModel group) async {
    try {
      // Marquer le cours complet comme en cours s'il existe
      if (group.hasCoursComplet && group.coursComplet != null) {
        await _statusService.startCourse(
          userId: userId,
          courseId: group.coursComplet!.id,
          metadata: {
            'source': 'favorite_group',
            'groupId': group.id,
            'groupTitle': group.title,
          },
        );
      }
      
      // Marquer la fiche de révision comme en cours si elle existe
      if (group.hasFicheRevision && group.ficheRevision != null) {
        await _statusService.startCourse(
          userId: userId,
          courseId: group.ficheRevision!.id,
          metadata: {
            'source': 'favorite_group',
            'groupId': group.id,
            'groupTitle': group.title,
          },
        );
      }
      
      // Marquer les exercices comme en cours s'ils existent
      for (final exercice in group.exercices) {
        await _statusService.startCourse(
          userId: userId,
          courseId: exercice.id,
          metadata: {
            'source': 'favorite_group',
            'groupId': group.id,
            'groupTitle': group.title,
          },
        );
      }
      
      Logger.info('Cours du groupe ${group.title} marqués comme "en cours" pour $userId');
      
    } catch (e) {
      Logger.error('Erreur marquage cours comme en cours: $e');
      // Ne pas faire échouer l'ajout aux favoris si le marquage échoue
    }
  }

  @override
  void dispose() {
    _favoritesStreamController.close();
    super.dispose();
  }
}