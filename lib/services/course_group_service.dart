import 'dart:math' as math;
import '../models/course_group_model.dart';
import '../models/course_model.dart';
import '../models/qcm_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import '../utils/logger.dart';

/// Service pour gérer les groupes de cours (concept/sujet avec tous ses types)
/// 
/// FONCTIONNALITÉS :
/// - Regroupement automatique des cours par sujet/chapitre
/// - Recherche et récupération des groupes complets
/// - Assemblage des différents types de contenu (cours, fiche, QCM)
/// - Gestion de la progression sur l'ensemble du groupe
class CourseGroupService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Crée un groupe de cours à partir de cours individuels existants
  Future<CourseGroupModel> createCourseGroup({
    required String title,
    required String matiere,
    required String niveau,
    String? description,
    List<String> tags = const [],
  }) async {
    try {
      // Chercher tous les cours correspondant au titre/matière/niveau
      List<CourseModel> relatedCourses = await _findRelatedCourses(title, matiere, niveau);
      
      // Chercher les QCM correspondants
      List<QCMModel> relatedQCMs = await _findRelatedQCMs(title, matiere, niveau);
      
      // Assembler le groupe
      CourseGroupModel group = _assembleCourseGroup(
        title: title,
        matiere: matiere,
        niveau: niveau,
        description: description,
        tags: tags,
        courses: relatedCourses,
        qcms: relatedQCMs,
      );
      
      Logger.info('Groupe créé: ${group.title} avec ${group.totalContentCount} contenus');
      return group;
      
    } catch (e) {
      Logger.error('Erreur création groupe de cours: $e');
      rethrow;
    }
  }

  /// Récupère un groupe de cours complet par ID
  Future<CourseGroupModel?> getCourseGroup(String groupId) async {
    try {
      // En attendant une vraie collection de groupes, on reconstruit depuis les cours
      List<CourseModel> allCourses = await _firestoreService.getCourses();
      
      // Trouver les cours qui pourraient appartenir à ce groupe
      for (CourseModel course in allCourses) {
        String potentialGroupId = CourseGroupModel.generateGroupId(
          course.title, 
          course.matiere, 
          course.niveau
        );
        
        if (potentialGroupId == groupId) {
          return await createCourseGroup(
            title: course.title,
            matiere: course.matiere,
            niveau: course.niveau,
            description: course.description,
            tags: course.tags,
          );
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('Erreur récupération groupe: $e');
      return null;
    }
  }

  /// Récupère tous les groupes de cours pour un niveau donné
  Future<List<CourseGroupModel>> getCourseGroupsByLevel(String niveau, {int limit = 20}) async {
    try {
      List<CourseModel> courses = await _firestoreService.getCourses(niveau: niveau);
      
      // Grouper les cours par titre similaire
      Map<String, List<CourseModel>> groupedCourses = _groupCoursesByTitle(courses);
      
      List<CourseGroupModel> groups = [];
      
      for (String title in groupedCourses.keys.take(limit)) {
        List<CourseModel> coursesInGroup = groupedCourses[title]!;
        if (coursesInGroup.isNotEmpty) {
          CourseModel representative = coursesInGroup.first;
          
          // Chercher les QCM pour ce groupe
          List<QCMModel> qcms = await _findRelatedQCMs(title, representative.matiere, niveau);
          
          CourseGroupModel group = _assembleCourseGroup(
            title: title,
            matiere: representative.matiere,
            niveau: niveau,
            description: representative.description,
            tags: representative.tags,
            courses: coursesInGroup,
            qcms: qcms,
          );
          
          groups.add(group);
        }
      }
      
      Logger.info('${groups.length} groupes trouvés pour $niveau');
      return groups;
      
    } catch (e) {
      Logger.error('Erreur récupération groupes par niveau: $e');
      return [];
    }
  }

  /// Récupère les groupes recommandés pour un utilisateur
  Future<List<CourseGroupModel>> getRecommendedGroups(UserModel user, {int limit = 10}) async {
    try {
      List<String> favoriteSubjects = List<String>.from(user.preferences['favoriteSubjects'] ?? []);
      
      List<CourseGroupModel> allGroups = [];
      
      // Récupérer des groupes pour chaque matière favorite
      for (String subject in favoriteSubjects) {
        List<CourseGroupModel> subjectGroups = await getCourseGroupsBySubject(subject, user.niveau);
        allGroups.addAll(subjectGroups);
      }
      
      // Si pas de matières favorites, récupérer par niveau
      if (allGroups.isEmpty) {
        allGroups = await getCourseGroupsByLevel(user.niveau);
      }
      
      // Trier par pertinence (nombre de contenus, récence, etc.)
      allGroups.sort((a, b) {
        double scoreA = _calculateGroupRelevanceScore(a, user);
        double scoreB = _calculateGroupRelevanceScore(b, user);
        return scoreB.compareTo(scoreA);
      });
      
      return allGroups.take(limit).toList();
      
    } catch (e) {
      Logger.error('Erreur récupération groupes recommandés: $e');
      return [];
    }
  }

  /// Récupère les groupes par matière
  Future<List<CourseGroupModel>> getCourseGroupsBySubject(String matiere, String niveau) async {
    try {
      List<CourseModel> courses = await _firestoreService.getCoursesBySubject(matiere, niveau);
      
      Map<String, List<CourseModel>> groupedCourses = _groupCoursesByTitle(courses);
      List<CourseGroupModel> groups = [];
      
      for (String title in groupedCourses.keys) {
        List<CourseModel> coursesInGroup = groupedCourses[title]!;
        if (coursesInGroup.isNotEmpty) {
          CourseModel representative = coursesInGroup.first;
          
          List<QCMModel> qcms = await _findRelatedQCMs(title, matiere, niveau);
          
          CourseGroupModel group = _assembleCourseGroup(
            title: title,
            matiere: matiere,
            niveau: niveau,
            description: representative.description,
            tags: representative.tags,
            courses: coursesInGroup,
            qcms: qcms,
          );
          
          groups.add(group);
        }
      }
      
      return groups;
      
    } catch (e) {
      Logger.error('Erreur récupération groupes par matière: $e');
      return [];
    }
  }

  /// Trouve les cours liés à un titre/matière/niveau
  Future<List<CourseModel>> _findRelatedCourses(String title, String matiere, String niveau) async {
    try {
      List<CourseModel> allCourses = await _firestoreService.getCourses(niveau: niveau);
      
      // Filtrer par correspondance de titre et matière
      List<CourseModel> relatedCourses = allCourses.where((course) {
        return course.matiere.toLowerCase() == matiere.toLowerCase() &&
               _areTitlesSimilar(course.title, title);
      }).toList();
      
      return relatedCourses;
    } catch (e) {
      Logger.error('Erreur recherche cours liés: $e');
      return [];
    }
  }

  /// Trouve les QCM liés à un titre/matière/niveau
  Future<List<QCMModel>> _findRelatedQCMs(String title, String matiere, String niveau) async {
    try {
      // TODO: Implémenter la recherche de QCM quand le service sera disponible
      // List<QCMModel> allQCMs = await _qcmService.getQCMsByLevel(niveau);
      // return allQCMs.where((qcm) => qcm.matiere == matiere && _areTitlesSimilar(qcm.title, title)).toList();
      
      return []; // Pour l'instant, retourner une liste vide
    } catch (e) {
      Logger.error('Erreur recherche QCM liés: $e');
      return [];
    }
  }

  /// Assemble un groupe de cours à partir des éléments trouvés
  CourseGroupModel _assembleCourseGroup({
    required String title,
    required String matiere,
    required String niveau,
    String? description,
    List<String> tags = const [],
    required List<CourseModel> courses,
    required List<QCMModel> qcms,
  }) {
    CourseModel? coursComplet;
    CourseModel? ficheRevision;
    List<CourseModel> exercices = [];
    
    // Séparer les cours par type
    for (CourseModel course in courses) {
      switch (course.type) {
        case CourseType.cours:
          coursComplet = course;
          break;
        case CourseType.fiche:
          ficheRevision = course;
          break;
        case CourseType.vulgarise:
          exercices.add(course);
          break;
      }
    }
    
    return CourseGroupModel(
      id: CourseGroupModel.generateGroupId(title, matiere, niveau),
      title: title,
      matiere: matiere,
      niveau: niveau,
      description: description,
      tags: tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      coursComplet: coursComplet,
      ficheRevision: ficheRevision,
      qcms: qcms,
      exercices: exercices,
    );
  }

  /// Groupe les cours par titre similaire
  Map<String, List<CourseModel>> _groupCoursesByTitle(List<CourseModel> courses) {
    Map<String, List<CourseModel>> grouped = {};
    
    for (CourseModel course in courses) {
      String normalizedTitle = _normalizeTitle(course.title);
      
      // Chercher un groupe existant avec un titre similaire
      String? existingKey;
      for (String key in grouped.keys) {
        if (_areTitlesSimilar(key, normalizedTitle)) {
          existingKey = key;
          break;
        }
      }
      
      if (existingKey != null) {
        grouped[existingKey]!.add(course);
      } else {
        grouped[normalizedTitle] = [course];
      }
    }
    
    return grouped;
  }

  /// Normalise un titre pour le regroupement
  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Vérifie si deux titres sont similaires
  bool _areTitlesSimilar(String title1, String title2) {
    String norm1 = _normalizeTitle(title1);
    String norm2 = _normalizeTitle(title2);
    
    // Correspondance exacte
    if (norm1 == norm2) return true;
    
    // Correspondance partielle (l'un contient l'autre)
    if (norm1.contains(norm2) || norm2.contains(norm1)) return true;
    
    // Correspondance par mots-clés (au moins 60% de mots en commun)
    List<String> words1 = norm1.split(' ');
    List<String> words2 = norm2.split(' ');
    
    int commonWords = 0;
    for (String word in words1) {
      if (words2.contains(word) && word.length > 2) {
        commonWords++;
      }
    }
    
    double similarity = commonWords / math.max(words1.length, words2.length);
    return similarity >= 0.6;
  }

  /// Calcule un score de pertinence pour un groupe
  double _calculateGroupRelevanceScore(CourseGroupModel group, UserModel user) {
    double score = 0.0;
    
    // Score basé sur le nombre de contenus disponibles
    score += group.totalContentCount * 2.0;
    
    // Score basé sur la matière favorite
    List<String> favoriteSubjects = List<String>.from(user.preferences['favoriteSubjects'] ?? []);
    if (favoriteSubjects.contains(group.matiere)) {
      score += 10.0;
    }
    
    // Score basé sur la récence
    int daysSinceCreated = DateTime.now().difference(group.createdAt).inDays;
    if (daysSinceCreated < 30) {
      score += 3.0;
    }
    
    // Score basé sur la progression existante
    double progression = group.calculateProgressPercentage(user.uid);
    if (progression > 0 && progression < 100) {
      score += 5.0; // Bonus pour les cours en cours
    }
    
    return score;
  }
}