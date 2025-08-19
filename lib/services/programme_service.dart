import '../models/programme_model.dart';
import '../services/openai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../utils/text_normalizer.dart';

/// Service pour gérer les programmes scolaires
class ProgrammeService {
  final OpenAIService _openAIService = OpenAIService();
  
  /// Collection Firebase pour les programmes
  static const String _collection = 'programme';
  
  /// Récupère un programme existant ou le génère si nécessaire
  Future<ProgrammeModel?> getProgramme({
    required String matiere,
    required String niveau,
    List<String>? options,
    int? annee,
  }) async {
    annee ??= DateTime.now().year; // Année courante par défaut
    final searchOptions = options ?? [];
    
    // NORMALISER les entrées pour éviter les doublons
    final normalizedMatiere = TextNormalizer.normalizeMatiere(matiere);
    final normalizedNiveau = TextNormalizer.normalizeNiveau(niveau);
    
    try {
      // 1. Chercher un programme existant dans Firebase avec les mêmes options
      final programmeId = ProgrammeModel.generateId(normalizedMatiere, normalizedNiveau, annee, options: searchOptions);
      final existingProgramme = await _getProgrammeFromFirestore(programmeId);
      
      if (existingProgramme != null) {
        Logger.info('Programme trouvé dans Firebase: $programmeId');
        return existingProgramme;
      }
      
      // 2. Aucun programme trouvé, générer avec ChatGPT
      Logger.info('Génération nouveau programme: $normalizedMatiere - $normalizedNiveau - $annee - options: $searchOptions');
      return await _generateProgramme(normalizedMatiere, normalizedNiveau, annee, searchOptions);
      
    } catch (e) {
      Logger.error('Erreur récupération programme: $e');
      return null;
    }
  }
  
  /// Récupère un programme depuis Firestore
  Future<ProgrammeModel?> _getProgrammeFromFirestore(String programmeId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(programmeId)
          .get();
      
      if (doc.exists) {
        return ProgrammeModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Erreur lecture Firestore: $e');
      return null;
    }
  }
  
  /// Génère un programme avec ChatGPT et le sauvegarde
  Future<ProgrammeModel?> _generateProgramme(String matiere, String niveau, int annee, List<String> options) async {
    try {
      Logger.info('_generateProgramme appelé avec: $matiere, $niveau, $annee, ${options.join(',')}');
      // Créer le prompt pour ChatGPT (les options sont uniquement pour le contexte)
      final prompt = _buildProgrammePrompt(matiere, niveau, annee, options);
      
      // Appeler ChatGPT
      final response = await _openAIService.makeOpenAIRequest(prompt);
      
      if (response != null && response.isNotEmpty) {
        // Extraire les chapitres du contenu généré
        final chapitres = _extractChapitres(response);
        
        // Créer le modèle de programme avec les nouvelles options
        final programme = ProgrammeModel(
          id: ProgrammeModel.generateId(matiere, niveau, annee, options: options),
          matiere: matiere,
          niveau: niveau,
          options: options,
          annee: annee,
          contenu: response,
          chapitres: chapitres,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          source: 'generated',
          tags: ProgrammeModel.generateTags(matiere, niveau, options),
          metadata: {
            'generated_by': 'openai',
            'model': 'gpt-5',
            'prompt_version': '1.0',
            'options': options,
          },
        );
        
        // Sauvegarder dans Firebase
        await _saveProgrammeToFirestore(programme);
        
        Logger.info('Programme généré et sauvegardé: ${programme.id}');
        return programme;
      }
      
      return null;
    } catch (e) {
      Logger.error('Erreur génération programme: $e');
      return null;
    }
  }
  
  /// Construit le prompt pour ChatGPT
  String _buildProgrammePrompt(String matiere, String niveau, int annee, List<String> options) {
    String optionsContext = '';
    if (options.isNotEmpty) {
      optionsContext = '\n\nContexte : L\'étudiant a choisi les spécialités suivantes : ${options.join(', ')}. Cela peut légèrement influencer le style pédagogique mais le programme de $matiere reste officiel et inchangé.';
    }

    return '''
Génère UNIQUEMENT la liste des cours du programme scolaire officiel français pour $matiere en classe de $niveau pour l'année scolaire $annee-${annee + 1}.

Instructions IMPORTANTES :
- Suis exactement le programme officiel de l'Éducation Nationale française
- Génère SEULEMENT les titres des cours/chapitres, sans contenu détaillé
- Format : liste simple avec tirets (-)
- Pas de descriptions longues, juste les titres
- Maximum 15-20 cours par programme
- Titres courts et précis (2-8 mots maximum)$optionsContext

Exemple de format EXACT à suivre :
- Les nombres entiers
- Fractions et nombres décimaux
- Géométrie dans l'espace
- Proportionnalité
- Statistiques et probabilités
- Equations du premier degré
- Fonctions linéaires

Génère maintenant UNIQUEMENT la liste des titres de cours pour $matiere - $niveau :
''';
  }
  
  /// Extrait la liste des chapitres depuis le contenu généré
  List<String> _extractChapitres(String contenu) {
    final List<String> chapitres = [];
    
    // Extraire les éléments de liste avec tirets
    final RegExp listRegex = RegExp(r'^-\s+(.+)$', multiLine: true);
    final listMatches = listRegex.allMatches(contenu);
    
    for (final match in listMatches) {
      final item = match.group(1)?.trim();
      if (item != null && item.isNotEmpty) {
        // Nettoyer le titre et le formater
        final titreClean = item
            .replaceFirst(RegExp(r'^(Cours|Chapitre|Leçon)\s+\d+\s*:\s*'), '')
            .trim();
        if (titreClean.isNotEmpty && titreClean.length <= 100) {
          chapitres.add(titreClean);
        }
      }
    }
    
    // Si aucun chapitre avec tirets trouvé, essayer les numéros
    if (chapitres.isEmpty) {
      final RegExp numberedRegex = RegExp(r'^\d+\.\s+(.+)$', multiLine: true);
      final numberedMatches = numberedRegex.allMatches(contenu);
      
      for (final match in numberedMatches) {
        final item = match.group(1)?.trim();
        if (item != null && item.isNotEmpty && item.length <= 100) {
          chapitres.add(item);
        }
      }
    }
    
    // Fallback : extraire les titres de section (## ou ###)
    if (chapitres.isEmpty) {
      final RegExp chapterRegex = RegExp(r'^#{2,3}\s+(.+)$', multiLine: true);
      final matches = chapterRegex.allMatches(contenu);
      
      for (final match in matches) {
        final titre = match.group(1)?.trim();
        if (titre != null && titre.isNotEmpty) {
          final titreClean = titre
              .replaceFirst(RegExp(r'^(Chapitre|Thématique)\s+\d+\s*:\s*'), '')
              .trim();
          if (titreClean.isNotEmpty) {
            chapitres.add(titreClean);
          }
        }
      }
    }
    
    return chapitres;
  }
  
  /// Sauvegarde un programme dans Firestore
  Future<bool> _saveProgrammeToFirestore(ProgrammeModel programme) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(programme.id)
          .set(programme.toFirestore());
      return true;
    } catch (e) {
      Logger.error('Erreur sauvegarde programme: $e');
      return false;
    }
  }
  
  /// Force la régénération d'un programme
  Future<ProgrammeModel?> regenerateProgramme({
    required String matiere,
    required String niveau,
    List<String>? options,
    int? annee,
  }) async {
    annee ??= DateTime.now().year;
    
    // NORMALISER les entrées pour éviter les doublons
    final normalizedMatiere = TextNormalizer.normalizeMatiere(matiere);
    final normalizedNiveau = TextNormalizer.normalizeNiveau(niveau);
    
    try {
      // Supprimer l'ancien programme s'il existe
      final searchOptions = options ?? [];
      final programmeId = ProgrammeModel.generateId(normalizedMatiere, normalizedNiveau, annee, options: searchOptions);
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(programmeId)
          .delete();
      
      // Générer un nouveau programme
      return await _generateProgramme(normalizedMatiere, normalizedNiveau, annee, searchOptions);
    } catch (e) {
      Logger.error('Erreur régénération programme: $e');
      return null;
    }
  }
  
  /// Vérifie si un programme existe pour une matière/niveau/année
  Future<bool> programmeExists({
    required String matiere,
    required String niveau,
    List<String>? options,
    int? annee,
  }) async {
    annee ??= DateTime.now().year;
    
    // NORMALISER les entrées pour éviter les doublons
    final normalizedMatiere = TextNormalizer.normalizeMatiere(matiere);
    final normalizedNiveau = TextNormalizer.normalizeNiveau(niveau);
    
    try {
      final searchOptions = options ?? [];
      final programmeId = ProgrammeModel.generateId(normalizedMatiere, normalizedNiveau, annee, options: searchOptions);
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(programmeId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
  
  /// Retourne la liste des matières disponibles
  List<String> getAvailableSubjects() {
    return [
      'Mathématiques',
      'Français',
      'Histoire-Géographie',
      'Physique-Chimie',
      'SVT',
      'Anglais',
      'Espagnol',
      'Allemand',
      'Philosophie',
      'Économie',
      'Sciences',
      'Arts plastiques',
      'Musique',
      'EPS',
    ];
  }
  
  /// Retourne la liste des niveaux disponibles
  List<String> getAvailableLevels() {
    return [
      '6ème',
      '5ème', 
      '4ème',
      '3ème',
      '2nde',
      '1ère Générale',
      '1ère STMG',
      '1ère STI2D',
      '1ère STL',
      '1ère ST2S',
      'Terminale Générale',
      'Terminale STMG',
      'Terminale STI2D',
      'Terminale STL',
      'Terminale ST2S',
    ];
  }
  
  /// Retourne les spécialités disponibles pour 1ère et Terminale Générale
  List<String> getAvailableSpecialities(String niveau) {
    if (niveau == '1ère Générale' || niveau == 'Terminale Générale') {
      return [
        'Mathématiques',
        'Physique-Chimie',
        'SVT',
        'Histoire-Géographie',
        'SES',
        'Anglais',
        'Espagnol',
        'Allemand',
        'Philosophie',
        'Arts plastiques',
        'Musique',
        'NSI',
        'SI',
      ];
    }
    return [];
  }
  
  /// Recherche des programmes existants par tags (spécialités similaires)
  Future<List<ProgrammeModel>> searchProgrammesByTags({
    required String matiere,
    required String niveau,
    required List<String> userOptions,
    int? annee,
  }) async {
    annee ??= DateTime.now().year;
    
    try {
      // Créer les tags de recherche basés sur les spécialités de l'utilisateur
      final searchTags = ProgrammeModel.generateTags(matiere, niveau, userOptions);
      
      // Rechercher dans Firestore les programmes ayant des tags similaires
      // Simplifier la requête pour éviter les erreurs d'index
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('matiere', isEqualTo: matiere)
          .where('niveau', isEqualTo: niveau)
          .where('annee', isEqualTo: annee)
          .limit(10)
          .get();
      
      // Filtrer les résultats pour ne garder que ceux avec des tags compatibles
      final programmes = querySnapshot.docs
          .map((doc) => ProgrammeModel.fromFirestore(doc))
          .where((programme) {
            // Vérifier si le programme a des tags en commun avec les spécialités de l'utilisateur
            if (userOptions.isEmpty) return true;
            return programme.tags.any((tag) => 
                searchTags.contains(tag) || userOptions.any((option) => 
                    tag.toLowerCase().contains(option.toLowerCase())));
          })
          .toList();
      
      // Trier par nombre de spécialités en commun
      programmes.sort((a, b) {
        int scoreA = _calculateCompatibilityScore(a, userOptions);
        int scoreB = _calculateCompatibilityScore(b, userOptions);
        return scoreB.compareTo(scoreA);
      });
      
      return programmes.take(5).toList();
    } catch (e) {
      Logger.error('Erreur recherche programmes par tags: $e');
      return [];
    }
  }
  
  /// Récupère un programme optimisé en tenant compte des spécialités de l'utilisateur
  /// Essaie d'abord de trouver un programme exact, puis un similaire, sinon génère
  Future<ProgrammeModel?> getProgrammeOptimized({
    required String matiere,
    required String niveau,
    required List<String> userOptions,
    int? annee,
  }) async {
    annee ??= DateTime.now().year;
    final normalizedMatiere = TextNormalizer.normalizeMatiere(matiere);
    final normalizedNiveau = TextNormalizer.normalizeNiveau(niveau);
    
    try {
      Logger.info('getProgrammeOptimized: $normalizedMatiere, $normalizedNiveau, ${userOptions.join(', ')}');
      
      // 1. Chercher un programme exact avec les mêmes spécialités
      try {
        final exactProgramme = await getProgramme(
          matiere: normalizedMatiere,
          niveau: normalizedNiveau,
          options: userOptions,
          annee: annee,
        );
        
        if (exactProgramme != null) {
          Logger.info('Programme exact trouvé avec spécialités: ${userOptions.join(', ')}');
          return exactProgramme;
        }
      } catch (e) {
        Logger.warning('Erreur recherche programme exact: $e');
      }
      
      // 2. Chercher des programmes similaires avec spécialités compatibles
      try {
        final similarProgrammes = await searchProgrammesByTags(
          matiere: normalizedMatiere,
          niveau: normalizedNiveau,
          userOptions: userOptions,
          annee: annee,
        );
        
        if (similarProgrammes.isNotEmpty) {
          Logger.info('Programme similaire trouvé avec spécialités compatibles');
          // Prendre le plus récent qui a le plus de tags en commun
          final bestMatch = _findBestMatch(similarProgrammes, userOptions);
          if (bestMatch != null) {
            return bestMatch;
          }
        }
      } catch (e) {
        Logger.warning('Erreur recherche programmes similaires: $e');
      }
      
      // 3. Générer un nouveau programme avec les spécialités de l'utilisateur
      Logger.info('Génération nouveau programme avec spécialités: ${userOptions.join(', ')}');
      return await _generateProgramme(normalizedMatiere, normalizedNiveau, annee, userOptions);
      
    } catch (e) {
      Logger.error('Erreur getProgrammeOptimized: $e');
      return null;
    }
  }
  
  /// Trouve le meilleur programme correspondant aux spécialités de l'utilisateur
  ProgrammeModel? _findBestMatch(List<ProgrammeModel> programmes, List<String> userOptions) {
    if (programmes.isEmpty) return null;
    
    ProgrammeModel? bestMatch;
    int bestScore = 0;
    
    for (final programme in programmes) {
      // Calculer le score de correspondance basé sur les spécialités communes
      int score = 0;
      for (final option in userOptions) {
        if (programme.options.contains(option) || 
            programme.tags.contains(option.toLowerCase())) {
          score++;
        }
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestMatch = programme;
      }
    }
    
    return bestMatch;
  }
  
  /// Calcule le score de compatibilité entre un programme et les spécialités utilisateur
  int _calculateCompatibilityScore(ProgrammeModel programme, List<String> userOptions) {
    if (userOptions.isEmpty) return 0;
    
    int score = 0;
    for (final option in userOptions) {
      // Score pour correspondance exacte dans les options
      if (programme.options.contains(option)) {
        score += 3;
      }
      // Score pour correspondance dans les tags
      else if (programme.tags.any((tag) => tag.toLowerCase() == option.toLowerCase())) {
        score += 2;
      }
      // Score pour correspondance partielle
      else if (programme.tags.any((tag) => tag.toLowerCase().contains(option.toLowerCase()))) {
        score += 1;
      }
    }
    return score;
  }
}