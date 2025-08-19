import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/openai_service.dart';
import '../utils/logger.dart';

class SearchResult {
  final List<CourseModel> courses;
  final bool isGenerated;
  final String? generationMessage;

  SearchResult({
    required this.courses,
    this.isGenerated = false,
    this.generationMessage,
  });
}

class IntelligentSearchService {
  final FirestoreService _firestoreService = FirestoreService();
  final OpenAIService _openAIService = OpenAIService();

  /// Recherche rapide SANS génération - juste pour vérifier ce qui existe
  Future<List<CourseModel>> findExistingCourses({
    required String query,
    String? matiere,
    String? niveau,
    CourseType? type,
    List<String>? options,
  }) async {
    try {
      // Recherche uniquement dans Firebase, pas de génération
      List<CourseModel> existingCourses = await _searchInFirebase(
        query: query,
        matiere: matiere,
        niveau: niveau,
        type: type,
      );
      
      return existingCourses;
    } catch (e) {
      debugPrint('Erreur recherche rapide: $e');
      return [];
    }
  }

  /// Recherche intelligente avec génération automatique
  Future<SearchResult> searchCourses({
    required String query,
    required UserModel user,
    String? matiere,
    String? niveau,
    CourseType? type,
    List<String>? options,
  }) async {
    try {
      // 1. Chercher d'abord dans Firebase (si disponible)
      List<CourseModel> existingCourses = [];
      try {
        existingCourses = await _searchInFirebase(
          query: query,
          matiere: matiere,
          niveau: niveau,
          type: type,
        );
      } catch (e) {
        Logger.warning('Firebase search failed, using mock data: $e');
        // Aucun résultat trouvé en mode hors ligne
        return SearchResult(
          courses: [],
          isGenerated: false,
          generationMessage: 'Aucun cours trouvé - Vérifiez votre connexion internet',
        );
      }

      // Si on trouve des cours, les retourner
      if (existingCourses.isNotEmpty) {
        return SearchResult(
          courses: existingCourses,
          isGenerated: false,
        );
      }

      // 2. Si aucun cours trouvé, générer avec ChatGPT
      CourseModel? generatedCourse = await _generateCourseWithChatGPT(
        query: query,
        matiere: matiere ?? _inferMatiere(query),
        niveau: niveau ?? user.niveau,
        type: type ?? CourseType.cours,
        user: user,
        options: options,
      );

      if (generatedCourse != null) {
        // 3. Sauvegarder le cours généré dans Firebase
        bool saved = await _saveCourseToFirebase(generatedCourse);
        
        if (saved) {
          return SearchResult(
            courses: [generatedCourse],
            isGenerated: true,
            generationMessage: 'Nouveau cours généré spécialement pour vous !',
          );
        }
      }

      // 4. Aucun cours trouvé
      return SearchResult(
        courses: [],
        isGenerated: false,
        generationMessage: 'Aucun cours trouvé pour cette recherche',
      );

    } catch (e) {
      debugPrint('Erreur recherche intelligente: $e');
      // Retourner liste vide en cas d'erreur
      return SearchResult(
        courses: [],
        isGenerated: false,
        generationMessage: 'Erreur de connexion - Réessayez plus tard',
      );
    }
  }

  /// Recherche dans Firebase
  Future<List<CourseModel>> _searchInFirebase({
    required String query,
    String? matiere,
    String? niveau,
    CourseType? type,
  }) async {
    try {
      // Recherche par matière et niveau d'abord
      List<CourseModel> courses = await _firestoreService.getCourses(
        matiere: matiere,
        niveau: niveau,
        type: type,
        limit: 50,
      );

      // Filtrer par requête dans le titre et contenu
      return courses.where((course) {
        String searchableText = '${course.title} ${course.content}'.toLowerCase();
        String searchQuery = query.toLowerCase();
        
        return searchableText.contains(searchQuery) ||
               _isSemanticMatch(course.title, query);
      }).toList();
    } catch (e) {
      debugPrint('Erreur recherche Firebase: $e');
      return [];
    }
  }

  /// Génère un cours avec ChatGPT
  Future<CourseModel?> _generateCourseWithChatGPT({
    required String query,
    required String matiere,
    required String niveau,
    required CourseType type,
    required UserModel user,
    List<String>? options,
  }) async {
    try {
      CourseModel? course = await _openAIService.generateCourse(
        sujet: query,
        matiere: matiere,
        niveau: niveau,
        type: type,
        authorId: 'ia_assistant',
        authorName: 'Assistant Ilium',
        options: options,
      );

      if (course != null) {
        // Générer l'ID formaté et les tags appropriés
        return course.copyWith(
          id: '', // L'ID sera généré par la méthode generateDocumentId
          description: 'Cours généré automatiquement pour "$query"',
          isPremium: false,
          isPublic: true,
          tags: course.typeBasedTags, // Utilise les nouveaux tags basés sur le type
          rating: {'ia': 4.5}, // Note par défaut pour les cours IA
          viewsCount: 0,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Erreur génération ChatGPT: $e');
      return null;
    }
  }

  /// Sauvegarde dans Firebase
  Future<bool> _saveCourseToFirebase(CourseModel course) async {
    try {
      return await _firestoreService.saveCourse(course);
    } catch (e) {
      debugPrint('Erreur sauvegarde Firebase: $e');
      return false;
    }
  }

  /// Inférer la matière à partir de la requête
  String _inferMatiere(String query) {
    Map<String, List<String>> matiereKeywords = {
      'Mathématiques': ['math', 'equation', 'calcul', 'geometrie', 'algebre', 'fonction'],
      'Français': ['francais', 'grammaire', 'litterature', 'orthographe', 'expression'],
      'Histoire-Géographie': ['histoire', 'geographie', 'guerre', 'revolution', 'pays'],
      'Sciences': ['physique', 'chimie', 'biologie', 'svt', 'experience'],
      'Anglais': ['anglais', 'english', 'grammaire anglaise'],
      'Philosophie': ['philosophie', 'ethique', 'morale', 'pensee'],
    };

    String queryLower = query.toLowerCase();
    
    for (String matiere in matiereKeywords.keys) {
      List<String> keywords = matiereKeywords[matiere]!;
      for (String keyword in keywords) {
        if (queryLower.contains(keyword)) {
          return matiere;
        }
      }
    }
    
    return 'Sciences'; // Matière par défaut
  }

  /// Vérification de correspondance sémantique simple
  bool _isSemanticMatch(String title, String query) {
    List<String> titleWords = title.toLowerCase().split(' ');
    List<String> queryWords = query.toLowerCase().split(' ');
    
    int matchCount = 0;
    for (String queryWord in queryWords) {
      if (queryWord.length > 3) { // Ignorer les mots trop courts
        for (String titleWord in titleWords) {
          if (titleWord.contains(queryWord) || queryWord.contains(titleWord)) {
            matchCount++;
            break;
          }
        }
      }
    }
    
    return matchCount >= (queryWords.length * 0.6); // 60% de correspondance
  }

  /// Recherche rapide pour suggestions
  Future<List<String>> getSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];
    
    try {
      Set<String> suggestions = {};
      
      // Essayer Firebase d'abord
      try {
        List<CourseModel> recentCourses = await _firestoreService.getCourses(limit: 100);
        
        for (CourseModel course in recentCourses) {
          if (course.title.toLowerCase().contains(partialQuery.toLowerCase())) {
            suggestions.add(course.title);
          }
        }
      } catch (e) {
        // Aucune suggestion en cas d'erreur Firebase
        debugPrint('Erreur récupération suggestions: $e');
      }
      
      // Ajouter des suggestions basées sur des sujets communs
      List<String> commonTopics = [
        'Les fractions',
        'La révolution française',
        'Le système solaire',
        'Les temps du passé',
        'L\'équation du second degré',
        'La photosynthèse',
        'Le présent en anglais',
        'Les probabilités',
      ];
      
      for (String topic in commonTopics) {
        if (topic.toLowerCase().contains(partialQuery.toLowerCase())) {
          suggestions.add(topic);
        }
      }
      
      return suggestions.take(5).toList();
    } catch (e) {
      return [];
    }
  }
}