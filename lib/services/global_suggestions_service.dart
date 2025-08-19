import 'dart:math' as math;
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../utils/logger.dart';

/// Service global pour gérer les suggestions sans doublons entre toutes les pages
/// 
/// GUIDE DE MIGRATION POUR LES ÉCRANS EXISTANTS :
/// 
/// 1. REMPLACEMENT RAPIDE (migration simple) :
/// 
///    // Ancien code :
///    // List<CourseModel> courses = await _recommendationService.getSuggestedCourses(user, limit: 3);
/// 
///    // Nouveau code :
///    final GlobalSuggestionsService _suggestionsService = GlobalSuggestionsService();
///    List<CourseModel> courses = await _suggestionsService.getSuggestionsForPage(
///      user, 
///      pageId: 'unique_page_identifier', // ⚠️ IMPORTANT: identifier unique par page
///      limit: 3
///    );
/// 
/// 2. UTILISATION AVANCÉE (avec widget réutilisable) :
/// 
///    // Remplacer toute la section de suggestions par :
///    SuggestionsWidget(
///      user: widget.user,
///      pageId: 'my_screen_main', // ⚠️ IMPORTANT: identifier unique
///      limit: 3,
///      title: 'Suggestions pour vous',
///      onSuggestionUsed: () {
///        // Action optionnelle quand suggestion utilisée
///      },
///    )
/// 
/// 3. GESTION DES ACTIONS :
/// 
///    // Quand l'utilisateur interagit avec une suggestion :
///    void _onCourseAction(CourseModel course) {
///      _suggestionsService.markSuggestionAsUsed(widget.user.uid, course.id);
///      // ... autres actions
///    }
/// 
/// 4. RAFRAÎCHISSEMENT :
/// 
///    // Forcer un rafraîchissement complet :
///    await _suggestionsService.refreshUserSuggestions(widget.user);
/// 
/// 5. IDENTIFIANTS DE PAGES UNIQUES :
/// 
///    Chaque écran/section doit avoir un pageId unique :
///    - 'home_modern' : HomeModernScreen
///    - 'home_legacy' : HomeScreen recommendations
///    - 'home_legacy_recent' : HomeScreen recent courses
///    - 'profile_suggestions' : ProfileScreen suggestions
///    - 'courses_related' : CoursesScreen related courses
///    - etc.
/// 
/// ⚠️ IMPORTANT : Plus jamais de doublons entre les pages !
class GlobalSuggestionsService {
  static final GlobalSuggestionsService _instance = GlobalSuggestionsService._internal();
  factory GlobalSuggestionsService() => _instance;
  GlobalSuggestionsService._internal() {
    // Configurer l'injection de dépendance après initialisation
    // _setupDependencyInjection(); // Désactivé car service de recommandation supprimé
  }

  
  /// Configure l'injection de dépendance pour éviter la circularité
  void _setupDependencyInjection() {
    // Service de recommandation supprimé
  }
  
  // Cache des suggestions par utilisateur
  final Map<String, List<CourseModel>> _userSuggestionsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Set<String>> _usedSuggestionsByUser = {}; // Track des suggestions déjà utilisées
  final Map<String, bool> _isLoadingByUser = {}; // Protection contre les appels concurrents
  
  // Durée de validité du cache (30 minutes)
  static const Duration _cacheValidityDuration = Duration(minutes: 30);
  
  /// Efface le cache des suggestions pour un utilisateur
  void clearUserCache(String userId) {
    _userSuggestionsCache.remove(userId);
    _cacheTimestamps.remove(userId);
    _usedSuggestionsByUser.remove(userId);
    Logger.info('Cache suggestions vidé pour utilisateur: $userId');
  }
  
  /// Vérifie si le cache est valide pour un utilisateur
  bool _isCacheValid(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;
    
    final isValid = DateTime.now().difference(timestamp) < _cacheValidityDuration;
    if (!isValid) {
      Logger.info('Cache expiré pour utilisateur: $userId');
    }
    return isValid;
  }
  
  /// Recharge complètement les suggestions pour un utilisateur
  Future<void> _reloadUserSuggestions(UserModel user) async {
    // Protection contre les appels concurrents pour le même utilisateur
    if (_isLoadingByUser[user.uid] == true) {
      Logger.debug('Rechargement déjà en cours pour: ${user.uid}');
      return;
    }
    
    _isLoadingByUser[user.uid] = true;
    
    try {
      Logger.info('Rechargement complet des suggestions pour: ${user.uid}');
      
      // Service de recommandation supprimé - retourner liste vide
      List<CourseModel> allSuggestions = [];
      
      // Sauvegarder dans le cache
      _userSuggestionsCache[user.uid] = allSuggestions;
      _cacheTimestamps[user.uid] = DateTime.now();
      _usedSuggestionsByUser[user.uid] = <String>{}; // Reset des suggestions utilisées
      
      Logger.info('${allSuggestions.length} suggestions uniques chargées pour ${user.uid}');
      
    } catch (e) {
      Logger.error('Erreur rechargement suggestions pour ${user.uid}: $e');
      _userSuggestionsCache[user.uid] = [];
      _cacheTimestamps[user.uid] = DateTime.now();
      _usedSuggestionsByUser[user.uid] = <String>{};
    } finally {
      _isLoadingByUser[user.uid] = false;
    }
  }
  
  /// Obtient des suggestions uniques pour une page spécifique
  Future<List<CourseModel>> getSuggestionsForPage(
    UserModel user, {
    required String pageId, // 'home', 'courses', 'profile', etc.
    required int limit,
    bool forceRefresh = false,
  }) async {
    
    // Vérifier si on doit recharger le cache
    if (forceRefresh || 
        !_isCacheValid(user.uid) || 
        !_userSuggestionsCache.containsKey(user.uid) ||
        _userSuggestionsCache[user.uid]!.isEmpty) {
      await _reloadUserSuggestions(user);
    }
    
    List<CourseModel> availableSuggestions = _userSuggestionsCache[user.uid] ?? [];
    Set<String> usedSuggestions = _usedSuggestionsByUser[user.uid] ?? <String>{};
    
    if (availableSuggestions.isEmpty) {
      Logger.warning('Aucune suggestion disponible pour ${user.uid}');
      return [];
    }
    
    // Filtrer les suggestions non encore utilisées
    List<CourseModel> unusedSuggestions = availableSuggestions
        .where((course) => !usedSuggestions.contains(course.id))
        .toList();
    
    // Si pas assez de suggestions non utilisées, réinitialiser et mélanger
    if (unusedSuggestions.length < limit) {
      Logger.info('Réinitialisation des suggestions utilisées pour ${user.uid} (page: $pageId)');
      usedSuggestions.clear();
      _usedSuggestionsByUser[user.uid] = usedSuggestions;
      unusedSuggestions = availableSuggestions.toList();
      unusedSuggestions.shuffle(math.Random());
    }
    
    // Prendre les suggestions demandées
    List<CourseModel> selectedSuggestions = unusedSuggestions.take(limit).toList();
    
    // Marquer ces suggestions comme utilisées
    for (CourseModel course in selectedSuggestions) {
      usedSuggestions.add(course.id);
    }
    
    Logger.info('${selectedSuggestions.length} suggestions fournies pour page "$pageId" (utilisateur: ${user.uid})');
    
    return selectedSuggestions;
  }
  
  /// Marque qu'une suggestion a été utilisée (ex: mise en favoris, vue, etc.)
  void markSuggestionAsUsed(String userId, String courseId) {
    Set<String> usedSuggestions = _usedSuggestionsByUser[userId] ?? <String>{};
    usedSuggestions.add(courseId);
    _usedSuggestionsByUser[userId] = usedSuggestions;
    Logger.debug('Suggestion marquée comme utilisée: $courseId pour $userId');
  }
  
  /// Force un rafraîchissement des suggestions pour un utilisateur
  Future<void> refreshUserSuggestions(UserModel user) async {
    Logger.info('Rafraîchissement forcé des suggestions pour: ${user.uid}');
    await _reloadUserSuggestions(user);
  }
  
  /// Nettoie le cache expiré pour tous les utilisateurs
  void cleanExpiredCache() {
    final now = DateTime.now();
    List<String> expiredUsers = [];
    
    _cacheTimestamps.forEach((userId, timestamp) {
      if (now.difference(timestamp) > _cacheValidityDuration) {
        expiredUsers.add(userId);
      }
    });
    
    for (String userId in expiredUsers) {
      _userSuggestionsCache.remove(userId);
      _cacheTimestamps.remove(userId);
      _usedSuggestionsByUser.remove(userId);
    }
    
    if (expiredUsers.isNotEmpty) {
      Logger.info('Cache expiré nettoyé pour ${expiredUsers.length} utilisateurs');
    }
  }
  
  /// Supprime les doublons d'une liste de cours
  List<CourseModel> _removeDuplicates(List<CourseModel> courses) {
    Map<String, CourseModel> uniqueCoursesMap = {};
    Set<String> seenTitleMatiereCombo = {};
    
    for (CourseModel course in courses) {
      // 1. Vérifier d'abord par ID (évite les vrais doublons)
      if (uniqueCoursesMap.containsKey(course.id)) {
        continue;
      }
      
      // 2. Créer une clé unique basée sur titre + matière + niveau
      String titleMatiereKey = '${course.title.toLowerCase().trim()}_${course.matiere.toLowerCase()}_${course.niveau}';
      
      // 3. Si même titre/matière/niveau, ne garder que si les tags sont différents
      if (seenTitleMatiereCombo.contains(titleMatiereKey)) {
        // Comparer les tags avec le cours déjà présent
        CourseModel? existingCourse = uniqueCoursesMap.values.firstWhere(
          (c) => '${c.title.toLowerCase().trim()}_${c.matiere.toLowerCase()}_${c.niveau}' == titleMatiereKey,
          orElse: () => course, // Si pas trouvé, utiliser le cours actuel
        );
        
        if (existingCourse != course) {
          Set<String> existingTags = Set.from(existingCourse.tags.map((t) => t.toLowerCase()));
          Set<String> currentTags = Set.from(course.tags.map((t) => t.toLowerCase()));
          
          // Ne garder que si les tags sont vraiment différents
          if (existingTags.difference(currentTags).isNotEmpty || currentTags.difference(existingTags).isNotEmpty) {
            // Tags différents, on peut garder les deux
            Logger.debug('Cours avec tags différents gardé: "${course.title}" - Tags: ${course.tags}');
          } else {
            // Tags identiques ou très similaires, ignorer ce cours
            Logger.debug('Cours doublon ignoré: "${course.title}" - Tags identiques');
            continue;
          }
        }
      }
      
      // 4. Ajouter le cours si toutes les vérifications passent
      uniqueCoursesMap[course.id] = course;
      seenTitleMatiereCombo.add(titleMatiereKey);
    }
    
    List<CourseModel> result = uniqueCoursesMap.values.toList();
    Logger.debug('Déduplication globale: ${courses.length} cours → ${result.length} cours uniques');
    
    return result;
  }
  
  /// Obtient les statistiques du cache pour debug
  Map<String, dynamic> getCacheStats(String userId) {
    return {
      'hasCachedSuggestions': _userSuggestionsCache.containsKey(userId),
      'suggestionsCount': _userSuggestionsCache[userId]?.length ?? 0,
      'usedSuggestionsCount': _usedSuggestionsByUser[userId]?.length ?? 0,
      'cacheTimestamp': _cacheTimestamps[userId]?.toString(),
      'cacheValid': _isCacheValid(userId),
    };
  }
  
  /// Méthode utilitaire pour migrer facilement les écrans existants
  /// Remplace directement les anciens appels getSuggestedCourses()
  Future<List<CourseModel>> getUniqueSuggestedCourses(UserModel user, {int limit = 3}) async {
    return await getSuggestionsForPage(
      user,
      pageId: 'legacy_migration_${DateTime.now().microsecondsSinceEpoch}',
      limit: limit,
    );
  }
}