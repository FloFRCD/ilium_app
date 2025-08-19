import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import 'favorites_service.dart';
import '../utils/logger.dart';

/// Service global pour gérer l'état des favoris de manière centralisée
/// 
/// PROBLÈME RÉSOLU :
/// - Synchronisation des états favoris entre toutes les pages
/// - Mise à jour en temps réel via StreamController
/// - Cache en mémoire pour éviter les requêtes répétées
/// - Pattern singleton pour un état partagé
/// 
/// MIGRATION DES ÉCRANS :
/// 
/// 1. REMPLACEMENT SIMPLE :
/// ```dart
/// // Ancien code :
/// final FavoritesService _favoritesService = FavoritesService();
/// 
/// // Nouveau code :
/// final GlobalFavoritesService _favoritesService = GlobalFavoritesService();
/// ```
/// 
/// 2. ÉCOUTE DES CHANGEMENTS :
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   // Écouter les changements de favoris
///   _favoritesService.favoritesStream.listen((favorites) {
///     if (mounted) {
///       setState(() {
///         // Actualiser l'état local si nécessaire
///       });
///     }
///   });
/// }
/// ```
/// 
/// 3. VÉRIFICATION DE STATUT :
/// ```dart
/// // Plus besoin d'appel async pour vérifier
/// bool isFavorite = _favoritesService.isFavoriteInCache(courseId);
/// 
/// // Ou pour forcer le reload depuis Firebase :
/// bool isFavorite = await _favoritesService.isFavorite(userId: userId, courseId: courseId);
/// ```
class GlobalFavoritesService extends ChangeNotifier {
  static final GlobalFavoritesService _instance = GlobalFavoritesService._internal();
  factory GlobalFavoritesService() => _instance;
  GlobalFavoritesService._internal();

  final FavoritesService _backendService = FavoritesService();
  
  // Cache en mémoire des favoris par utilisateur
  final Map<String, Set<String>> _userFavoritesCache = {};
  final Map<String, List<CourseModel>> _userFavoriteCoursesCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Stream pour notifier les changements
  final StreamController<Map<String, Set<String>>> _favoritesStreamController = 
      StreamController<Map<String, Set<String>>>.broadcast();
  
  // Durée de validité du cache (5 minutes)
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  
  /// Stream des changements de favoris pour écoute en temps réel
  Stream<Map<String, Set<String>>> get favoritesStream => _favoritesStreamController.stream;
  
  /// Obtient les favoris d'un utilisateur depuis le cache ou Firebase
  Future<Set<String>> getUserFavorites(String userId, {bool forceRefresh = false}) async {
    // Vérifier le cache si pas de force refresh
    if (!forceRefresh && _isCacheValid(userId)) {
      Logger.debug('Favoris récupérés depuis le cache pour: $userId');
      return _userFavoritesCache[userId] ?? <String>{};
    }
    
    try {
      Logger.info('Rechargement favoris depuis Firebase pour: $userId');
      
      // Récupérer depuis Firebase
      List<CourseModel> courses = await _backendService.getFavoriteCourses(
        userId: userId,
        limit: 200, // Plus grande limite pour avoir tous les favoris
      );
      
      // Extraire les IDs
      Set<String> favoriteIds = courses.map((course) => course.id).toSet();
      
      // Mettre à jour le cache
      _userFavoritesCache[userId] = favoriteIds;
      _userFavoriteCoursesCache[userId] = courses;
      _cacheTimestamps[userId] = DateTime.now();
      
      Logger.info('${favoriteIds.length} favoris chargés pour $userId');
      
      // Notifier les listeners
      _favoritesStreamController.add(_userFavoritesCache);
      notifyListeners();
      
      return favoriteIds;
    } catch (e) {
      Logger.error('Erreur rechargement favoris pour $userId: $e');
      return _userFavoritesCache[userId] ?? <String>{};
    }
  }
  
  /// Ajouter un cours aux favoris avec mise à jour temps réel
  Future<bool> addToFavorites({
    required String userId,
    required String courseId,
  }) async {
    try {
      // 1. Ajouter à Firebase
      bool success = await _backendService.addToFavorites(
        userId: userId,
        courseId: courseId,
      );
      
      if (success) {
        // 2. Mettre à jour le cache immédiatement
        Set<String> userFavorites = _userFavoritesCache[userId] ?? <String>{};
        userFavorites.add(courseId);
        _userFavoritesCache[userId] = userFavorites;
        
        Logger.info('Favori ajouté et cache mis à jour: $courseId pour $userId');
        
        // 3. Notifier tous les listeners
        _favoritesStreamController.add(_userFavoritesCache);
        notifyListeners();
        
        // 4. Invalider le cache des cours pour forcer le reload
        _userFavoriteCoursesCache.remove(userId);
        
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Erreur ajout favori: $e');
      return false;
    }
  }
  
  /// Retirer un cours des favoris avec mise à jour temps réel
  Future<bool> removeFromFavorites({
    required String userId,
    required String courseId,
  }) async {
    try {
      // 1. Retirer de Firebase
      bool success = await _backendService.removeFromFavorites(
        userId: userId,
        courseId: courseId,
      );
      
      if (success) {
        // 2. Mettre à jour le cache immédiatement
        Set<String> userFavorites = _userFavoritesCache[userId] ?? <String>{};
        userFavorites.remove(courseId);
        _userFavoritesCache[userId] = userFavorites;
        
        Logger.info('Favori retiré et cache mis à jour: $courseId pour $userId');
        
        // 3. Notifier tous les listeners
        _favoritesStreamController.add(_userFavoritesCache);
        notifyListeners();
        
        // 4. Invalider le cache des cours pour forcer le reload
        _userFavoriteCoursesCache.remove(userId);
        
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Erreur suppression favori: $e');
      return false;
    }
  }
  
  /// Toggle favori avec mise à jour temps réel
  Future<bool> toggleFavorite({
    required String userId,
    required String courseId,
  }) async {
    // Vérifier l'état actuel depuis le cache
    Set<String> userFavorites = _userFavoritesCache[userId] ?? <String>{};
    bool isCurrentlyFavorite = userFavorites.contains(courseId);
    
    if (isCurrentlyFavorite) {
      return await removeFromFavorites(userId: userId, courseId: courseId);
    } else {
      return await addToFavorites(userId: userId, courseId: courseId);
    }
  }
  
  /// Vérifier si un cours est favori (depuis le cache)
  bool isFavoriteInCache(String userId, String courseId) {
    Set<String> userFavorites = _userFavoritesCache[userId] ?? <String>{};
    return userFavorites.contains(courseId);
  }
  
  /// Vérifier si un cours est favori (depuis Firebase si nécessaire)
  Future<bool> isFavorite({
    required String userId,
    required String courseId,
    bool forceRefresh = false,
  }) async {
    // Si cache valide, utiliser le cache
    if (!forceRefresh && _isCacheValid(userId)) {
      return isFavoriteInCache(userId, courseId);
    }
    
    // Sinon, recharger depuis Firebase
    Set<String> favorites = await getUserFavorites(userId, forceRefresh: true);
    return favorites.contains(courseId);
  }
  
  /// Obtenir les cours favoris complets
  Future<List<CourseModel>> getFavoriteCourses({
    required String userId,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    // Vérifier le cache des cours
    if (!forceRefresh && 
        _isCacheValid(userId) && 
        _userFavoriteCoursesCache.containsKey(userId)) {
      Logger.debug('Cours favoris récupérés depuis le cache pour: $userId');
      List<CourseModel> cached = _userFavoriteCoursesCache[userId]!;
      return cached.take(limit).toList();
    }
    
    try {
      // Recharger depuis Firebase
      List<CourseModel> courses = await _backendService.getFavoriteCourses(
        userId: userId,
        limit: limit,
      );
      
      // Mettre à jour les caches
      _userFavoriteCoursesCache[userId] = courses;
      _userFavoritesCache[userId] = courses.map((c) => c.id).toSet();
      _cacheTimestamps[userId] = DateTime.now();
      
      Logger.info('${courses.length} cours favoris rechargés pour $userId');
      
      return courses;
    } catch (e) {
      Logger.error('Erreur récupération cours favoris: $e');
      return _userFavoriteCoursesCache[userId] ?? [];
    }
  }
  
  /// Stream des cours favoris en temps réel
  Stream<List<CourseModel>> getFavoritesStream({
    required String userId,
    int limit = 50,
  }) {
    return _backendService.getFavoritesStream(userId: userId, limit: limit);
  }
  
  /// Obtenir le nombre de favoris
  Future<int> getFavoritesCount({required String userId}) async {
    Set<String> favorites = await getUserFavorites(userId);
    return favorites.length;
  }
  
  /// Vérifier si le cache est valide pour un utilisateur
  bool _isCacheValid(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;
    
    final isValid = DateTime.now().difference(timestamp) < _cacheValidityDuration;
    if (!isValid) {
      Logger.debug('Cache favoris expiré pour: $userId');
    }
    return isValid;
  }
  
  /// Invalider le cache d'un utilisateur
  void invalidateUserCache(String userId) {
    _userFavoritesCache.remove(userId);
    _userFavoriteCoursesCache.remove(userId);
    _cacheTimestamps.remove(userId);
    Logger.info('Cache favoris invalidé pour: $userId');
  }
  
  /// Nettoyer tous les caches expirés
  void cleanExpiredCaches() {
    final now = DateTime.now();
    List<String> expiredUsers = [];
    
    _cacheTimestamps.forEach((userId, timestamp) {
      if (now.difference(timestamp) > _cacheValidityDuration) {
        expiredUsers.add(userId);
      }
    });
    
    for (String userId in expiredUsers) {
      invalidateUserCache(userId);
    }
    
    if (expiredUsers.isNotEmpty) {
      Logger.info('Cache favoris nettoyé pour ${expiredUsers.length} utilisateurs');
    }
  }
  
  /// Pré-charger les favoris d'un utilisateur
  Future<void> preloadUserFavorites(String userId) async {
    Logger.info('Pré-chargement des favoris pour: $userId');
    await getUserFavorites(userId, forceRefresh: true);
  }
  
  /// Obtenir les statistiques du cache
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_users': _userFavoritesCache.keys.length,
      'total_cached_favorites': _userFavoritesCache.values
          .map((set) => set.length)
          .fold(0, (a, b) => a + b),
      'cached_courses': _userFavoriteCoursesCache.values
          .map((list) => list.length)
          .fold(0, (a, b) => a + b),
      'cache_timestamps': _cacheTimestamps.length,
    };
  }
  
  @override
  void dispose() {
    _favoritesStreamController.close();
    super.dispose();
  }
}