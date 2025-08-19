import '../models/user_model.dart';
import 'global_favorites_service.dart';
import '../utils/logger.dart';

/// Service pour initialiser les favoris au démarrage de l'app
/// 
/// UTILISATION :
/// 
/// Dans le widget principal après connexion utilisateur :
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   if (user != null) {
///     FavoritesInitializationService.initializeUserFavorites(user);
///   }
/// }
/// ```
class FavoritesInitializationService {
  static final GlobalFavoritesService _globalFavoritesService = GlobalFavoritesService();
  static final Set<String> _initializedUsers = <String>{};

  /// Initialise les favoris d'un utilisateur au premier lancement
  static Future<void> initializeUserFavorites(UserModel user) async {
    // Éviter les initialisations multiples pour le même utilisateur
    if (_initializedUsers.contains(user.uid)) {
      Logger.debug('Favoris déjà initialisés pour: ${user.uid}');
      return;
    }

    try {
      Logger.info('Initialisation des favoris pour: ${user.uid}');
      
      // Pré-charger les favoris en arrière-plan
      await _globalFavoritesService.preloadUserFavorites(user.uid);
      
      // Marquer comme initialisé
      _initializedUsers.add(user.uid);
      
      Logger.info('Favoris initialisés avec succès pour: ${user.uid}');
    } catch (e) {
      Logger.error('Erreur initialisation favoris pour ${user.uid}: $e');
    }
  }

  /// Nettoie les données d'initialisation (lors de déconnexion)
  static void clearInitializationData(String userId) {
    _initializedUsers.remove(userId);
    _globalFavoritesService.invalidateUserCache(userId);
    Logger.info('Données favoris nettoyées pour: $userId');
  }

  /// Force la réinitialisation pour un utilisateur
  static Future<void> reinitializeUserFavorites(UserModel user) async {
    clearInitializationData(user.uid);
    await initializeUserFavorites(user);
  }

  /// Obtient les statistiques d'initialisation
  static Map<String, dynamic> getInitializationStats() {
    return {
      'initialized_users_count': _initializedUsers.length,
      'initialized_users': _initializedUsers.toList(),
      'cache_stats': _globalFavoritesService.getCacheStats(),
    };
  }
}