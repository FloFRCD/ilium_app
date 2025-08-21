import '../models/programme_model.dart';
import '../services/openai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../utils/text_normalizer.dart';
import '../config/api_config.dart';

/// Service pour gérer les programmes scolaires
class ProgrammeService {
  final OpenAIService _openAIService = OpenAIService();
  
  /// Collections Firebase pour les programmes
  static const String _collection = 'programme';
  static const String _collectionMatiere = 'programme_matiere'; // Programmes détaillés par matière
  
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
    
    Logger.info('Extraction chapitres depuis: ${contenu.substring(0, contenu.length > 200 ? 200 : contenu.length)}...');
    
    // Extraire les éléments avec puces (•) d'abord
    final RegExp bulletRegex = RegExp(r'^•\s+(.+)$', multiLine: true);
    final bulletMatches = bulletRegex.allMatches(contenu);
    
    for (final match in bulletMatches) {
      final item = match.group(1)?.trim();
      if (item != null && item.isNotEmpty) {
        // Nettoyer le titre et supprimer les dates
        final titreClean = _cleanChapterTitle(item);
        if (titreClean.isNotEmpty && titreClean.length <= 150) {
          chapitres.add(titreClean);
          Logger.info('Chapitre extrait: $titreClean');
        }
      }
    }
    
    // Si aucun chapitre avec puces trouvé, essayer les tirets
    if (chapitres.isEmpty) {
      final RegExp listRegex = RegExp(r'^-\s+(.+)$', multiLine: true);
      final listMatches = listRegex.allMatches(contenu);
      
      for (final match in listMatches) {
        final item = match.group(1)?.trim();
        if (item != null && item.isNotEmpty) {
          final titreClean = _cleanChapterTitle(item);
          if (titreClean.isNotEmpty && titreClean.length <= 150) {
            chapitres.add(titreClean);
            Logger.info('Chapitre extrait (tiret): $titreClean');
          }
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
          final titreClean = _cleanChapterTitle(item);
          chapitres.add(titreClean);
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
          final titreClean = _cleanChapterTitle(titre);
          if (titreClean.isNotEmpty) {
            chapitres.add(titreClean);
          }
        }
      }
    }
    
    return chapitres;
  }
  
  /// Nettoie un titre de chapitre en supprimant les références temporelles et les préfixes
  String _cleanChapterTitle(String title) {
    Logger.debug('🧹 Nettoyage du titre: "$title"');
    
    String cleanedTitle = title
        // Supprimer les préfixes de chapitres/cours
        .replaceFirst(RegExp(r'^(Cours|Chapitre|Leçon|Thème|Partie)\s+\d+\s*:\s*'), '')
        // Supprimer les mentions temporelles entre parenthèses avec mois
        .replaceAll(RegExp(r'\s*\([^)]*(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)[^)]*\)', caseSensitive: false), '')
        // Supprimer les mentions de trimestre/semestre
        .replaceAll(RegExp(r'\s*\([^)]*(?:trimestre|semestre|quadrimestre)[^)]*\)', caseSensitive: false), '')
        // Supprimer les tirets avec dates (ex: "- septembre à octobre", "- de janvier à mars")
        .replaceAll(RegExp(r'\s*-\s*(?:de\s+)?(?:\b(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\b).*', caseSensitive: false), '')
        // Supprimer les mentions temporelles génériques
        .replaceAll(RegExp(r'\s*\(.*(?:début|fin|milieu).*(?:année|trimestre).*\)', caseSensitive: false), '')
        // Supprimer les mentions de périodes numériques (1er trimestre, 2ème semestre, etc.)
        .replaceAll(RegExp(r'\s*\([^)]*(?:\d+(?:er|ère|ème|e)?\s*(?:trimestre|semestre))[^)]*\)', caseSensitive: false), '')
        // Supprimer les ranges de mois avec "à" (janvier à mars, septembre-octobre, etc.)
        // Utiliser des délimiteurs pour éviter de supprimer des parties de mots
        .replaceAll(RegExp(r'\s*(?:\()?(?:\b(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\b)\s*(?:[-à]\s*(?:\b(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\b))?(?:\))?', caseSensitive: false), '')
        .trim();
    
    // Supprimer les caractères de fin indésirables
    cleanedTitle = cleanedTitle.replaceAll(RegExp(r'[:\-\.]$'), '').trim();
    
    if (cleanedTitle != title) {
      Logger.info('🧹 Titre nettoyé: "$title" → "$cleanedTitle"');
    }
    
    return cleanedTitle;
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

  // ===== NOUVEAU SYSTÈME DE GÉNÉRATION À 2 NIVEAUX =====

  /// Génère ou récupère le programme complet (niveau 1 - matières seulement)
  Future<ProgrammeModel?> getProgrammeComplet({
    required String niveau,
    required List<String> options,
    int? annee,
  }) async {
    annee ??= DateTime.now().year;
    
    // Normaliser le niveau
    final normalizedNiveau = TextNormalizer.normalizeNiveau(niveau);
    
    try {
      // 1. Chercher le programme complet existant
      final programmeId = _generateCompleteProgrammeId(normalizedNiveau, annee, options);
      Logger.debug('🔍 Recherche programme existant avec ID: $programmeId');
      
      final existingProgramme = await _getProgrammeFromFirestore(programmeId);
      
      if (existingProgramme != null) {
        Logger.info('✅ Programme complet trouvé en cache: $programmeId');
        Logger.debug('📊 Programme contient ${existingProgramme.chapitres.length} matières');
        return existingProgramme;
      }
      
      // 2. Générer le programme complet (matières seulement)
      Logger.info('🚀 Génération nouveau programme: $normalizedNiveau - $annee - options: ${options.join(',')}');
      final newProgramme = await _generateProgrammeComplet(normalizedNiveau, annee, options);
      
      if (newProgramme != null) {
        Logger.info('✅ Nouveau programme généré avec ${newProgramme.chapitres.length} matières');
      } else {
        Logger.warning('⚠️ Échec de génération du programme');
      }
      
      return newProgramme;
      
    } catch (e) {
      Logger.error('Erreur getProgrammeComplet: $e');
      return null;
    }
  }

  /// Génère ou récupère le programme détaillé d'une matière (niveau 2)
  Future<ProgrammeModel?> getProgrammeMatiere({
    required String matiere,
    required String niveau,
    required List<String> options,
    int? annee,
  }) async {
    annee ??= DateTime.now().year;
    
    // Normaliser les entrées
    final normalizedMatiere = TextNormalizer.normalizeMatiere(matiere);
    final normalizedNiveau = TextNormalizer.normalizeNiveau(niveau);
    
    try {
      // 1. Chercher le programme matière existant
      final programmeId = _generateMatiereProgrammeId(normalizedMatiere, normalizedNiveau, annee, options);
      final existingProgramme = await _getProgrammeMatiereFromFirestore(programmeId);
      
      if (existingProgramme != null) {
        Logger.info('Programme matière trouvé: $programmeId');
        return existingProgramme;
      }
      
      // 2. Générer le programme détaillé de la matière
      Logger.info('Génération programme matière: $normalizedMatiere - $normalizedNiveau - $annee');
      return await _generateProgrammeMatiere(normalizedMatiere, normalizedNiveau, annee, options);
      
    } catch (e) {
      Logger.error('Erreur getProgrammeMatiere: $e');
      return null;
    }
  }

  /// Génère le programme complet avec toutes les matières
  Future<ProgrammeModel?> _generateProgrammeComplet(String niveau, int annee, List<String> options) async {
    try {
      Logger.info('Génération programme complet pour: $niveau, options: ${options.join(', ')}');
      
      // DEBUG: Vérifier la configuration OpenAI
      Logger.info('DEBUG - isOpenAIConfigured: ${ApiConfig.isOpenAIConfigured}');
      Logger.info('DEBUG - openaiApiKey length: ${ApiConfig.openaiApiKey.length}');
      Logger.info('DEBUG - openaiApiKey starts with sk-: ${ApiConfig.openaiApiKey.startsWith('sk-')}');
      Logger.info('DEBUG - openaiApiKey isEmpty: ${ApiConfig.openaiApiKey.isEmpty}');
      
      // Essayer d'utiliser l'API OpenAI d'abord
      Logger.info('DEBUG - Condition check: ${ApiConfig.isOpenAIConfigured}');
      if (ApiConfig.isOpenAIConfigured) {
        Logger.info('Tentative de génération avec OpenAI API...');
        final prompt = _buildCompleteProgrammePrompt(niveau, annee, options);
        final response = await _openAIService.makeOpenAIRequest(prompt);
        
        if (response != null && response.isNotEmpty) {
          Logger.info('Réponse OpenAI reçue: ${response.length} caractères');
          final chapitres = _extractMatieres(response);
          
          if (chapitres.isNotEmpty) {
            final programme = ProgrammeModel(
              id: _generateCompleteProgrammeId(niveau, annee, options),
              matiere: 'PROGRAMME_COMPLET',
              niveau: niveau,
              options: options,
              annee: annee,
              contenu: response,
              chapitres: chapitres,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              source: 'generated_openai',
              tags: _generateCompleteProgrammeTags(niveau, options),
              metadata: {
                'generated_by': 'openai',
                'model': ApiConfig.openaiModel,
                'prompt_version': '2.0_complete',
                'type': 'programme_complet',
                'niveau': niveau,
                'options': options,
                'annee': annee,
              },
            );
            
            await _saveProgrammeToFirestore(programme);
            Logger.info('Programme complet OpenAI sauvegardé: ${programme.id}');
            return programme;
          }
        }
      }
      
      // Fallback si OpenAI échoue
      Logger.info('Utilisation du fallback avec matières correctes');
      final fallbackMatieres = _getFallbackMatieresForNiveau(niveau, options);
      
      final programme = ProgrammeModel(
        id: _generateCompleteProgrammeId(niveau, annee, options),
        matiere: 'PROGRAMME_COMPLET', // Identifiant spécial
        niveau: niveau,
        options: options,
        annee: annee,
        contenu: 'Matières générées automatiquement:\n${fallbackMatieres.map((m) => '• $m').join('\n')}',
        chapitres: fallbackMatieres,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        source: 'generated_fallback',
        tags: _generateCompleteProgrammeTags(niveau, options),
        metadata: {
          'generated_by': 'fallback',
          'model': 'manual',
          'prompt_version': '2.0_fallback',
          'type': 'programme_complet',
          'niveau': niveau,
          'options': options,
          'annee': annee,
        },
      );
      
      // Sauvegarder dans Firebase
      await _saveProgrammeToFirestore(programme);
      Logger.info('Programme complet fallback sauvegardé: ${programme.id}');
      return programme;
      
    } catch (e) {
      Logger.error('Erreur génération programme complet: $e');
      return null;
    }
  }
  
  /// Chapitres de fallback selon la matière et le niveau
  List<String> _getFallbackChapitresForMatiere(String matiere, String niveau, List<String> options) {
    final matiereNorm = matiere.toLowerCase();
    final niveauNorm = niveau.toLowerCase();
    
    if (matiereNorm.contains('math')) {
      if (niveauNorm.contains('terminale')) {
        return [
          'Limites et continuité',
          'Dérivation',
          'Fonction logarithme',
          'Fonction exponentielle', 
          'Intégration',
          'Géométrie dans l\'espace',
          'Suites numériques',
          'Probabilités conditionnelles',
        ];
      } else if (niveauNorm.contains('1ère')) {
        return [
          'Second degré',
          'Dérivation',
          'Suites',
          'Probabilités',
          'Géométrie repérée',
          'Trigonométrie',
        ];
      }
    } else if (matiereNorm.contains('fran') || matiereNorm.contains('français')) {
      if (niveauNorm.contains('terminale')) {
        return [
          'La littérature d\'idées',
          'Le théâtre',
          'La poésie moderne',
          'Le roman contemporain',
        ];
      } else if (niveauNorm.contains('1ère')) {
        return [
          'Le roman et ses personnages',
          'Le théâtre classique',
          'La poésie',
          'L\'argumentation',
        ];
      }
    } else if (matiereNorm.contains('svt')) {
      if (niveauNorm.contains('terminale')) {
        return [
          'Génétique et évolution',
          'Géologie',
          'Écosystèmes',
          'Neurobiologie',
          'Immunologie',
        ];
      }
    } else if (matiereNorm.contains('phys') || matiereNorm.contains('chimie')) {
      if (niveauNorm.contains('terminale')) {
        return [
          'Mécanique',
          'Électricité',
          'Ondes',
          'Optique',
          'Chimie organique',
          'Thermodynamique',
        ];
      }
    } else if (matiereNorm.contains('hist') || matiereNorm.contains('géo')) {
      if (niveauNorm.contains('terminale')) {
        return [
          'La Seconde Guerre mondiale',
          'La guerre froide',
          'Mondialisation',
          'Territoires français',
        ];
      }
    } else if (matiereNorm.contains('philo')) {
      if (niveauNorm.contains('terminale')) {
        return [
          'La conscience',
          'L\'inconscient',
          'Autrui',
          'Le désir',
          'L\'existence et le temps',
          'La culture',
          'Le langage',
          'L\'art',
          'La justice',
          'L\'État',
        ];
      }
    }
    
    // Fallback générique
    return [
      'Introduction à $matiere',
      'Concepts fondamentaux',
      'Méthodes et techniques',
      'Applications pratiques',
      'Exercices et révisions',
    ];
  }
  
  /// Matières de fallback selon le niveau
  List<String> _getFallbackMatieresForNiveau(String niveau, List<String> options) {
    final niveauLower = niveau.toLowerCase();
    
    if (niveauLower.contains('terminale')) {
      final matieres = [
        'Français',
        'Philosophie',
        'Histoire-Géographie',
        'Anglais',
        'Enseignement scientifique',
      ];
      
      // Ajouter les spécialités
      for (final option in options) {
        if (!matieres.contains(option)) {
          matieres.add(option);
        }
      }
      
      return matieres;
    } else if (niveauLower.contains('1ère') || niveauLower.contains('première')) {
      final matieres = [
        'Français',
        'Histoire-Géographie',
        'Anglais',
        'Enseignement scientifique',
        'Éducation physique et sportive',
      ];
      
      // Ajouter les spécialités
      for (final option in options) {
        if (!matieres.contains(option)) {
          matieres.add(option);
        }
      }
      
      return matieres;
    } else {
      return [
        'Mathématiques',
        'Français',
        'Histoire-Géographie',
        'Sciences',
        'Anglais',
      ];
    }
  }

  /// Génère le programme détaillé d'une matière
  Future<ProgrammeModel?> _generateProgrammeMatiere(String matiere, String niveau, int annee, List<String> options) async {
    try {
      Logger.info('Génération programme matière pour: $matiere - $niveau');
      
      // DEBUG: Vérifier la configuration OpenAI pour les matières aussi
      Logger.info('DEBUG MATIERE - isOpenAIConfigured: ${ApiConfig.isOpenAIConfigured}');
      
      // Essayer d'utiliser l'API OpenAI d'abord pour les matières détaillées
      if (ApiConfig.isOpenAIConfigured) {
        Logger.info('Tentative de génération OpenAI pour matière: $matiere');
        final prompt = _buildMatiereProgrammePrompt(matiere, niveau, annee, options);
        final response = await _openAIService.makeOpenAIRequest(prompt);
        
        if (response != null && response.isNotEmpty) {
          Logger.info('Réponse OpenAI matière reçue: ${response.length} caractères');
          final chapitres = _extractChapitres(response);
          
          if (chapitres.isNotEmpty) {
            Logger.info('Chapitres OpenAI extraits: ${chapitres.length} chapitres');
            final programme = ProgrammeModel(
              id: _generateMatiereProgrammeId(matiere, niveau, annee, options),
              matiere: matiere,
              niveau: niveau,
              options: options,
              annee: annee,
              contenu: response,
              chapitres: chapitres,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              source: 'generated_openai_matiere',
              tags: _generateMatiereProgrammeTags(matiere, niveau, options),
              metadata: {
                'generated_by': 'openai',
                'model': ApiConfig.openaiModel,
                'prompt_version': '2.0_matiere',
                'type': 'programme_matiere',
                'matiere': matiere,
                'niveau': niveau,
                'options': options,
                'annee': annee,
              },
            );
            
            await _saveProgrammeMatiereToFirestore(programme);
            Logger.info('Programme matière OpenAI sauvegardé: ${programme.id}');
            return programme;
          }
        }
      }
      
      // Fallback si OpenAI échoue
      Logger.info('Utilisation du fallback avec chapitres spécifiques à la matière');
      final fallbackChapitres = _getFallbackChapitresForMatiere(matiere, niveau, options);
      
      final programme = ProgrammeModel(
        id: _generateMatiereProgrammeId(matiere, niveau, annee, options),
        matiere: matiere,
        niveau: niveau,
        options: options,
        annee: annee,
        contenu: 'Programme détaillé de $matiere ($niveau):\n${fallbackChapitres.map((c) => '• $c').join('\n')}',
        chapitres: fallbackChapitres,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        source: 'generated_fallback_matiere',
        tags: _generateMatiereProgrammeTags(matiere, niveau, options),
        metadata: {
          'generated_by': 'fallback',
          'model': 'manual',
          'prompt_version': '2.0_fallback_matiere',
          'type': 'programme_matiere',
          'matiere': matiere,
          'niveau': niveau,
          'options': options,
          'annee': annee,
        },
      );
      
      // Sauvegarder dans la collection spécialisée
      await _saveProgrammeMatiereToFirestore(programme);
      Logger.info('Programme matière fallback sauvegardé: ${programme.id}');
      
      return programme;
    } catch (e) {
      Logger.error('Erreur génération programme matière: $e');
      return null;
    }
  }

  // ===== MÉTHODES UTILITAIRES POUR LE NOUVEAU SYSTÈME =====

  String _generateCompleteProgrammeId(String niveau, int annee, List<String> options) {
    final optionsStr = options.isEmpty ? 'no_options' : options.join('_').toLowerCase();
    return 'complete_${niveau.toLowerCase()}_${annee}_$optionsStr';
  }

  String _generateMatiereProgrammeId(String matiere, String niveau, int annee, List<String> options) {
    final optionsStr = options.isEmpty ? 'no_options' : options.join('_').toLowerCase();
    return 'matiere_${matiere.toLowerCase()}_${niveau.toLowerCase()}_${annee}_$optionsStr';
  }

  Future<ProgrammeModel?> _getProgrammeMatiereFromFirestore(String programmeId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collectionMatiere)
          .doc(programmeId)
          .get();
      
      if (doc.exists) {
        return ProgrammeModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Erreur lecture Firestore matière: $e');
      return null;
    }
  }

  Future<void> _saveProgrammeMatiereToFirestore(ProgrammeModel programme) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collectionMatiere)
          .doc(programme.id)
          .set(programme.toFirestore());
    } catch (e) {
      Logger.error('Erreur sauvegarde programme matière: $e');
      rethrow;
    }
  }

  List<String> _generateCompleteProgrammeTags(String niveau, List<String> options) {
    final tags = <String>[
      'programme_complet',
      'programme_general',
      niveau.toLowerCase(),
      'annee_${DateTime.now().year}',
      'niveau_$niveau',
      'toutes_matieres',
      'cursus_complet',
    ];
    
    // Ajouter UNIQUEMENT les spécialités choisies par l'élève (pas les matières du programme)
    for (final option in options) {
      // Préfixer avec "specialite_" pour éviter la confusion avec les recherches de matières individuelles
      tags.add('specialite_${option.toLowerCase().replaceAll(' ', '_')}');
      tags.add('option_${option.toLowerCase().replaceAll(' ', '_')}');
    }
    
    return tags;
  }

  List<String> _generateMatiereProgrammeTags(String matiere, String niveau, List<String> options) {
    final tags = <String>[
      'programme_matiere',
      matiere.toLowerCase().replaceAll(' ', '_'),
      niveau.toLowerCase(),
      'annee_${DateTime.now().year}',
      'matiere_$matiere',
      'niveau_$niveau',
    ];
    
    // Ajouter les options/spécialités aux tags
    for (final option in options) {
      tags.add(option.toLowerCase().replaceAll(' ', '_'));
      tags.add('specialite_${option.toLowerCase().replaceAll(' ', '_')}');
      tags.add('${matiere.toLowerCase()}_${option.toLowerCase().replaceAll(' ', '_')}');
    }
    
    return tags;
  }

  List<String> _extractMatieres(String content) {
    // Extraire les matières du contenu généré (niveau 1)
    Logger.info('Contenu reçu pour extraction matières: $content');
    
    final lines = content.split('\n');
    final matieres = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && 
          (trimmed.startsWith('•') || 
           trimmed.startsWith('-') || 
           trimmed.startsWith('*') ||
           trimmed.startsWith('📚'))) {
        // Nettoyer la ligne pour extraire le nom de la matière
        final matiere = trimmed
            .replaceAll(RegExp(r'^[•\-\*📚]\s*'), '')
            .split(':')[0]
            .trim();
        if (matiere.isNotEmpty && matiere.length < 50) { // Éviter les lignes trop longues
          matieres.add(matiere);
          Logger.info('Matière extraite: $matiere');
        }
      }
    }
    
    // Fallback si aucune matière extraite
    if (matieres.isEmpty) {
      Logger.warning('Aucune matière extraite, tentative fallback');
      // Essayer d'extraire sans formatage spécial
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && 
            trimmed.length > 3 && 
            trimmed.length < 50 &&
            !trimmed.toLowerCase().contains('génère') &&
            !trimmed.toLowerCase().contains('instruction') &&
            !trimmed.toLowerCase().contains('exemple')) {
          matieres.add(trimmed);
          Logger.info('Matière fallback extraite: $trimmed');
        }
      }
    }
    
    Logger.info('Matières finales extraites: ${matieres.join(', ')}');
    return matieres;
  }

  String _buildCompleteProgrammePrompt(String niveau, int annee, List<String> options) {
    final optionsStr = options.isEmpty ? '' : '\nSpécialités/Options de l\'élève : ${options.join(', ')}';
    
    return '''Vous êtes un expert du système éducatif français. Je veux SEULEMENT la liste des matières (pas les détails) pour un élève de $niveau.${optionsStr.isEmpty ? '' : optionsStr}

CONSIGNE : Répondez UNIQUEMENT avec la liste des matières, une par ligne, avec • devant chaque matière.

Pour un élève de Terminale avec spécialités SVT et Maths, la réponse correcte serait :
• Français
• Philosophie  
• Histoire-Géographie
• Anglais
• Mathématiques
• SVT
• Enseignement scientifique

Maintenant, donnez-moi la liste des matières pour $niveau${optionsStr.isEmpty ? '' : ' avec les spécialités: ${options.join(', ')}'}:''';
  }

  String _buildMatiereProgrammePrompt(String matiere, String niveau, int annee, List<String> options) {
    final optionsStr = options.isEmpty ? '' : '\nSpécialités/Options : ${options.join(', ')}';
    
    return '''Tu es un expert en éducation française. Génère le programme DÉTAILLÉ de $matiere pour un élève de $niveau.

Matière : $matiere
Niveau : $niveau$optionsStr

Instructions importantes :
1. Détaille tous les chapitres et thèmes du programme officiel
2. Tiens compte des spécialités pour adapter le contenu
3. Sois précis et exhaustif
4. Format : • Chapitre/Thème par ligne
5. NE MENTIONNE AUCUNE DATE, MOIS OU PÉRIODE (septembre, octobre, etc.)
6. NE MENTIONNE AUCUN TRIMESTRE, SEMESTRE, OU PÉRIODE DE L'ANNÉE
7. Utilise uniquement les titres de chapitres et thèmes

Exemple de format CORRECT :
• Les fonctions
• Les équations
• L'analyse littéraire
• La géométrie

Exemple de format INCORRECT (à éviter absolument) :
• Les fonctions (septembre-octobre) ❌
• Chapitre 1 : Les équations (1er trimestre) ❌
• L'analyse (janvier à mars) ❌

IMPORTANT : Aucune mention temporelle ne doit apparaître dans les titres.

Génère maintenant le programme détaillé de $matiere :''';
  }
}