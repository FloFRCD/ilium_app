import '../models/course_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import '../utils/logger.dart';

/// Service pour gérer le catalogue de cours existants basé sur les tags et préférences
/// 
/// FONCTIONNALITÉS :
/// - Récupération de cours par tags correspondants
/// - Filtrage par niveau et matières favorites
/// - Suggestion basée sur les préférences utilisateur
/// - Pas de génération automatique - seulement des cours existants
class CourseCatalogService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Récupère des cours existants basés sur les tags correspondant aux préférences utilisateur
  Future<List<CourseModel>> getCoursesByUserPreferences(UserModel user, {int limit = 20}) async {
    try {
      Logger.info('Récupération cours pour utilisateur: ${user.uid}');
      
      // 1. Récupérer les matières favorites de l'utilisateur
      List<String> favoriteSubjects = List<String>.from(user.preferences['favoriteSubjects'] ?? []);
      
      // 2. Si pas de matières favorites, utiliser les matières standard pour le niveau
      if (favoriteSubjects.isEmpty) {
        favoriteSubjects = _getDefaultSubjectsForLevel(user.niveau);
      }
      
      List<CourseModel> allCourses = [];
      
      // 3. Récupérer des cours pour chaque matière favorite en parallèle
      List<Future<List<CourseModel>>> subjectFutures = favoriteSubjects.map((subject) =>
        _firestoreService.getCoursesBySubject(subject, user.niveau)
      ).toList();
      
      // 4. Récupérer aussi des cours avec des tags intéressants en parallèle
      List<String> userInterestTags = _generateInterestTags(user);
      Future<List<CourseModel>> taggedCoursesFuture = _getCoursesByTags(userInterestTags, user.niveau, limit: 10);
      
      // Exécuter toutes les requêtes en parallèle
      List<dynamic> results = await Future.wait([
        ...subjectFutures,
        taggedCoursesFuture,
      ]);
      
      // Ajouter tous les résultats
      for (int i = 0; i < results.length; i++) {
        allCourses.addAll(results[i] as List<CourseModel>);
      }
      
      // 5. Déduplication et tri par pertinence
      List<CourseModel> uniqueCourses = _removeDuplicates(allCourses);
      List<CourseModel> rankedCourses = _rankCoursesByRelevance(uniqueCourses, user);
      
      Logger.info('${rankedCourses.length} cours trouvés pour ${user.uid}');
      
      return rankedCourses.take(limit).toList();
      
    } catch (e) {
      Logger.error('Erreur récupération cours par préférences: $e');
      return [];
    }
  }

  /// Récupère des cours par tags spécifiques
  Future<List<CourseModel>> getCoursesByTags(List<String> tags, String niveau, {int limit = 10}) async {
    return await _getCoursesByTags(tags, niveau, limit: limit);
  }
  
  /// Recherche de cours existants par matière et niveau (sans génération)
  Future<List<CourseModel>> searchExistingCourses({
    String? matiere,
    String? niveau,
    CourseType? type,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      List<CourseModel> courses = [];
      
      // 1. Recherche par matière et niveau
      if (matiere != null && niveau != null) {
        courses = await _firestoreService.getCoursesBySubject(matiere, niveau);
      } else if (niveau != null) {
        // Récupérer tous les cours pour le niveau
        courses = await _firestoreService.getCourses(niveau: niveau);
      } else {
        // Récupérer tous les cours disponibles
        courses = await _firestoreService.getCourses();
      }
      
      // 2. Filtrer par type si spécifié
      if (type != null) {
        courses = courses.where((course) => course.type == type).toList();
      }
      
      // 3. Filtrer par tags si spécifiés
      if (tags != null && tags.isNotEmpty) {
        courses = courses.where((course) {
          return tags.any((tag) => course.tags.any((courseTag) => 
            courseTag.toLowerCase().contains(tag.toLowerCase()) ||
            tag.toLowerCase().contains(courseTag.toLowerCase())
          ));
        }).toList();
      }
      
      Logger.info('Recherche existante: ${courses.length} cours trouvés');
      return courses;
      
    } catch (e) {
      Logger.error('Erreur recherche cours existants: $e');
      return [];
    }
  }

  /// Récupère des cours populaires pour un niveau donné
  Future<List<CourseModel>> getPopularCourses(String niveau, {int limit = 15}) async {
    try {
      List<CourseModel> courses = await _firestoreService.getCourses(niveau: niveau);
      
      // Trier par popularité (nombre de votes, vues, etc.)
      courses.sort((a, b) {
        double scoreA = _calculatePopularityScore(a);
        double scoreB = _calculatePopularityScore(b);
        return scoreB.compareTo(scoreA);
      });
      
      Logger.info('${courses.length} cours populaires pour $niveau');
      return courses.take(limit).toList();
      
    } catch (e) {
      Logger.error('Erreur récupération cours populaires: $e');
      return [];
    }
  }

  /// Récupère des cours récents ajoutés à la base
  Future<List<CourseModel>> getRecentCourses(String niveau, {int limit = 10}) async {
    try {
      List<CourseModel> courses = await _firestoreService.getCourses(niveau: niveau);
      
      // Trier par date de création (plus récents en premier)
      courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      Logger.info('${courses.length} cours récents pour $niveau');
      return courses.take(limit).toList();
      
    } catch (e) {
      Logger.error('Erreur récupération cours récents: $e');
      return [];
    }
  }

  /// Vérifie s'il y a des cours disponibles pour un utilisateur
  Future<bool> hasAvailableCourses(UserModel user) async {
    try {
      List<CourseModel> courses = await getCoursesByUserPreferences(user, limit: 1);
      return courses.isNotEmpty;
    } catch (e) {
      Logger.error('Erreur vérification cours disponibles: $e');
      return false;
    }
  }

  /// Récupère des cours par tags
  Future<List<CourseModel>> _getCoursesByTags(List<String> tags, String niveau, {int limit = 10}) async {
    try {
      if (tags.isEmpty) return [];
      
      List<CourseModel> allCourses = await _firestoreService.getCourses(niveau: niveau);
      
      // Filtrer par tags
      List<CourseModel> matchingCourses = allCourses.where((course) {
        return tags.any((tag) => course.tags.any((courseTag) => 
          courseTag.toLowerCase().contains(tag.toLowerCase()) ||
          tag.toLowerCase().contains(courseTag.toLowerCase()) ||
          course.title.toLowerCase().contains(tag.toLowerCase()) ||
          course.matiere.toLowerCase().contains(tag.toLowerCase())
        ));
      }).toList();
      
      return matchingCourses.take(limit).toList();
      
    } catch (e) {
      Logger.error('Erreur récupération cours par tags: $e');
      return [];
    }
  }

  /// Génère des tags d'intérêt basés sur le profil utilisateur
  List<String> _generateInterestTags(UserModel user) {
    List<String> tags = [];
    
    // Tags basés sur les matières favorites
    List<String> favoriteSubjects = List<String>.from(user.preferences['favoriteSubjects'] ?? []);
    tags.addAll(favoriteSubjects.map((subject) => subject.toLowerCase()));
    
    // Tags basés sur le niveau
    tags.add(user.niveau.toLowerCase());
    
    // Tags basés sur les difficultés préférées
    String preferredDifficulty = user.preferences['preferredDifficulty'] ?? 'moyen';
    tags.add(preferredDifficulty.toLowerCase());
    
    // Tags basés sur les options
    if (user.options.isNotEmpty) {
      tags.addAll(user.options.map((option) => option.toLowerCase()));
    }
    
    // Tags génériques utiles
    tags.addAll(['révision', 'exercice', 'cours', 'fiche']);
    
    return tags.toSet().toList(); // Supprimer les doublons
  }

  /// Supprime les cours en doublon
  List<CourseModel> _removeDuplicates(List<CourseModel> courses) {
    Map<String, CourseModel> uniqueCoursesMap = {};
    
    for (CourseModel course in courses) {
      if (!uniqueCoursesMap.containsKey(course.id)) {
        uniqueCoursesMap[course.id] = course;
      }
    }
    
    return uniqueCoursesMap.values.toList();
  }

  /// Classe les cours par pertinence pour l'utilisateur
  List<CourseModel> _rankCoursesByRelevance(List<CourseModel> courses, UserModel user) {
    courses.sort((a, b) {
      double scoreA = _calculateRelevanceScore(a, user);
      double scoreB = _calculateRelevanceScore(b, user);
      return scoreB.compareTo(scoreA);
    });
    
    return courses;
  }

  /// Calcule un score de pertinence pour un cours
  double _calculateRelevanceScore(CourseModel course, UserModel user) {
    double score = 0.0;
    
    // Score basé sur le niveau (exact = +10, proche = +5)
    if (course.niveau == user.niveau) {
      score += 10.0;
    } else if (_isLevelClose(course.niveau, user.niveau)) {
      score += 5.0;
    }
    
    // Score basé sur les matières favorites
    List<String> favoriteSubjects = List<String>.from(user.preferences['favoriteSubjects'] ?? []);
    if (favoriteSubjects.contains(course.matiere)) {
      score += 8.0;
    }
    
    // Score basé sur la popularité
    score += _calculatePopularityScore(course) * 0.1;
    
    // Score basé sur la récence
    int daysSinceCreated = DateTime.now().difference(course.createdAt).inDays;
    if (daysSinceCreated < 30) {
      score += 2.0; // Bonus pour les cours récents
    }
    
    return score;
  }

  /// Calcule un score de popularité
  double _calculatePopularityScore(CourseModel course) {
    double score = 0.0;
    
    // Score basé sur les votes
    int totalVotes = course.votes.values.length;
    int positiveVotes = course.votes.values.where((vote) => vote > 0).length;
    
    if (totalVotes > 0) {
      score += (positiveVotes / totalVotes) * 5.0;
      score += totalVotes * 0.1; // Bonus pour beaucoup de votes
    }
    
    // Score basé sur la popularité générale
    score += course.popularity;
    
    return score;
  }

  /// Vérifie si deux niveaux sont proches
  bool _isLevelClose(String level1, String level2) {
    List<String> levels = [
      'CP', 'CE1', 'CE2', 'CM1', 'CM2',
      '6ème', '5ème', '4ème', '3ème',
      '2nde', '1ère', 'Terminale'
    ];
    
    int index1 = levels.indexOf(level1);
    int index2 = levels.indexOf(level2);
    
    if (index1 == -1 || index2 == -1) return false;
    
    return (index1 - index2).abs() <= 1; // Niveaux adjacents
  }

  /// Retourne les matières par défaut pour un niveau
  List<String> _getDefaultSubjectsForLevel(String niveau) {
    Map<String, List<String>> subjectsByLevel = {
      'CP': ['Mathématiques', 'Français', 'Découverte du monde'],
      'CE1': ['Mathématiques', 'Français', 'Découverte du monde', 'Arts'],
      'CE2': ['Mathématiques', 'Français', 'Histoire-Géographie', 'Sciences'],
      'CM1': ['Mathématiques', 'Français', 'Histoire-Géographie', 'Sciences', 'Arts'],
      'CM2': ['Mathématiques', 'Français', 'Histoire-Géographie', 'Sciences', 'Arts'],
      '6ème': ['Mathématiques', 'Français', 'Histoire-Géographie', 'SVT', 'Anglais'],
      '5ème': ['Mathématiques', 'Français', 'Histoire-Géographie', 'SVT', 'Anglais', 'Physique-Chimie'],
      '4ème': ['Mathématiques', 'Français', 'Histoire-Géographie', 'SVT', 'Anglais', 'Physique-Chimie'],
      '3ème': ['Mathématiques', 'Français', 'Histoire-Géographie', 'SVT', 'Anglais', 'Physique-Chimie'],
      '2nde': ['Mathématiques', 'Français', 'Histoire-Géographie', 'SVT', 'Anglais', 'Physique-Chimie', 'SES'],
      '1ère': ['Mathématiques', 'Français', 'Histoire-Géographie', 'Philosophie', 'Anglais'],
      'Terminale': ['Mathématiques', 'Français', 'Histoire-Géographie', 'Philosophie', 'Anglais'],
    };
    
    return subjectsByLevel[niveau] ?? ['Mathématiques', 'Français', 'Histoire-Géographie'];
  }
}