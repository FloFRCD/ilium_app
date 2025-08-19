import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/course_model.dart';
import '../models/qcm_model.dart';
import '../models/question_model.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

class OpenAIService {
  static const String _baseUrl = ApiConfig.openaiBaseUrl;
  static const String _apiKey = ApiConfig.openaiApiKey;

  /// Parse les métadonnées du contenu généré par l'IA
  Map<String, dynamic> _parseMetadata(String content) {
    final RegExp metadataRegex = RegExp(
      r'---METADATA---(.*?)---END_METADATA---',
      multiLine: true,
      dotAll: true,
    );
    
    final match = metadataRegex.firstMatch(content);
    if (match != null) {
      try {
        final jsonString = match.group(1)?.trim();
        if (jsonString != null) {
          final Map<String, dynamic> metadata = jsonDecode(jsonString);
          String cleanContent = content.replaceAll(metadataRegex, '').trim();
          // Nettoyer la syntaxe mathématique au cas où l'IA ignorerait les instructions
          cleanContent = _cleanMathSyntax(cleanContent);
          
          return {
            'estimatedDuration': metadata['estimatedDuration'] ?? 30,
            'difficulty': _parseDifficulty(metadata['difficulty']),
            'cleanContent': cleanContent,
          };
        }
      } catch (e) {
        Logger.error('Erreur parsing métadonnées: $e');
      }
    }
    
    // Valeurs par défaut si parsing échoue
    return {
      'estimatedDuration': 30,
      'difficulty': CourseDifficulty.moyen,
      'cleanContent': _cleanMathSyntax(content),
    };
  }

  /// Nettoie la syntaxe mathématique incorrecte
  String _cleanMathSyntax(String content) {
    String cleaned = content;
    
    // === MATHÉMATIQUES ===
    // Remplacer les dots incorrects
    cleaned = cleaned.replaceAll(RegExp(r'\|dots?\b'), '…');
    cleaned = cleaned.replaceAll(RegExp(r'\|ldots?\b'), '…');
    cleaned = cleaned.replaceAll(RegExp(r'\|cdots?\b'), '⋯');
    cleaned = cleaned.replaceAll(RegExp(r'\|vdots?\b'), '⋮');
    
    // Remplacer les indices underscore par des indices Unicode (cas simples)
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z])_1\b'), r'$1₁');
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z])_2\b'), r'$1₂');
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z])_3\b'), r'$1₃');
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z])_4\b'), r'$1₄');
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z])_n\b'), r'$1ₙ');
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z])_i\b'), r'$1ᵢ');
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z])_k\b'), r'$1ₖ');
    
    // Remplacer les exposants caret par des exposants Unicode (cas simples)
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z0-9])\^2\b'), r'$1²');
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z0-9])\^3\b'), r'$1³');
    cleaned = cleaned.replaceAll(RegExp(r'([a-zA-Z0-9])\^n\b'), r'$1ⁿ');
    
    // === PHYSIQUE-CHIMIE ===
    // Formules chimiques courantes
    cleaned = cleaned.replaceAll(RegExp(r'\bH_2O\b'), 'H₂O');
    cleaned = cleaned.replaceAll(RegExp(r'\bCO_2\b'), 'CO₂');
    cleaned = cleaned.replaceAll(RegExp(r'\bH_2SO_4\b'), 'H₂SO₄');
    cleaned = cleaned.replaceAll(RegExp(r'\bCH_4\b'), 'CH₄');
    cleaned = cleaned.replaceAll(RegExp(r'\bO_2\b'), 'O₂');
    cleaned = cleaned.replaceAll(RegExp(r'\bN_2\b'), 'N₂');
    cleaned = cleaned.replaceAll(RegExp(r'\bNH_3\b'), 'NH₃');
    
    // Ions courants
    cleaned = cleaned.replaceAll(RegExp(r'\bNa\+\b'), 'Na⁺');
    cleaned = cleaned.replaceAll(RegExp(r'\bCl-\b'), 'Cl⁻');
    cleaned = cleaned.replaceAll(RegExp(r'\bSO4\^2-\b'), 'SO₄²⁻');
    cleaned = cleaned.replaceAll(RegExp(r'\bH\+\b'), 'H⁺');
    cleaned = cleaned.replaceAll(RegExp(r'\bOH-\b'), 'OH⁻');
    cleaned = cleaned.replaceAll(RegExp(r'\bCa\^2\+\b'), 'Ca²⁺');
    
    // Flèches de réaction
    cleaned = cleaned.replaceAll(RegExp(r'->|=>|-->'), '→');
    cleaned = cleaned.replaceAll(RegExp(r'<->|<=>|<-->'), '⇌');
    
    // Symboles de multiplication
    cleaned = cleaned.replaceAll(RegExp(r'(?<=[0-9])\s*\*\s*(?=[0-9])'), '×');
    cleaned = cleaned.replaceAll(RegExp(r'(?<=[a-zA-Z])\s*\*\s*(?=[a-zA-Z])'), '⋅');
    
    // Notation scientifique
    cleaned = cleaned.replaceAll(RegExp(r'10\^6\b'), '10⁶');
    cleaned = cleaned.replaceAll(RegExp(r'10\^-3\b'), '10⁻³');
    cleaned = cleaned.replaceAll(RegExp(r'10\^-6\b'), '10⁻⁶');
    cleaned = cleaned.replaceAll(RegExp(r'10\^-9\b'), '10⁻⁹');
    
    // Lettres grecques courantes
    cleaned = cleaned.replaceAll(RegExp(r'\|Delta\b'), 'Δ');
    cleaned = cleaned.replaceAll(RegExp(r'\|delta\b'), 'δ');
    cleaned = cleaned.replaceAll(RegExp(r'\|alpha\b'), 'α');
    cleaned = cleaned.replaceAll(RegExp(r'\|beta\b'), 'β');
    cleaned = cleaned.replaceAll(RegExp(r'\|gamma\b'), 'γ');
    cleaned = cleaned.replaceAll(RegExp(r'\|lambda\b'), 'λ');
    cleaned = cleaned.replaceAll(RegExp(r'\|pi\b'), 'π');
    cleaned = cleaned.replaceAll(RegExp(r'\|theta\b'), 'θ');
    
    // Unités avec exposants
    cleaned = cleaned.replaceAll(RegExp(r'\bm/s\^2\b'), 'm/s²');
    cleaned = cleaned.replaceAll(RegExp(r'\bkg\*m/s\^2\b'), 'kg⋅m/s²');
    cleaned = cleaned.replaceAll(RegExp(r'\bJ/mol\^-1\b'), 'J⋅mol⁻¹');
    cleaned = cleaned.replaceAll(RegExp(r'\bdeg[Cc]\b'), '°C');
    
    return cleaned;
  }

  /// Convertit la difficulté string en enum
  CourseDifficulty _parseDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'facile':
        return CourseDifficulty.facile;
      case 'difficile':
        return CourseDifficulty.difficile;
      default:
        return CourseDifficulty.moyen;
    }
  }

  /// Génère des données factices pour donner vie à l'application
  Map<String, dynamic> _generateFakeEngagementData() {
    final random = Random();
    
    // Générer 10 notes entre 4.3 et 5.0
    List<double> fakeRatings = [];
    for (int i = 0; i < 10; i++) {
      fakeRatings.add(4.3 + random.nextDouble() * 0.7); // 4.3 à 5.0
    }
    
    // Calculer la moyenne
    double averageRating = fakeRatings.reduce((a, b) => a + b) / fakeRatings.length;
    
    return {
      'viewsCount': 30 + random.nextInt(271), // 30 à 300
      'rating': {
        'average': double.parse(averageRating.toStringAsFixed(1)),
        'count': 10,
        'fakeRatings': fakeRatings, // Pour debug si besoin
      },
    };
  }

  Future<CourseModel?> generateCourse({
    required String sujet,
    required String matiere,
    required String niveau,
    required CourseType type,
    required String authorId,
    required String authorName,
    List<String>? options,
  }) async {
    try {
      String? content;
      
      // Pour un cours complet, utiliser la génération multi-parties
      if (type == CourseType.cours) {
        content = await _generateMultiPartCourse(sujet, matiere, niveau, options);
      } else {
        // Pour fiche et vulgarisation, génération simple
        String prompt = _buildCoursePrompt(sujet, matiere, niveau, type, options);
        content = await _makeOpenAIRequest(prompt);
      }
      
      if (content != null) {
        // Vérifier si l'IA a refusé la demande pour des raisons de sécurité
        if (content.contains('ERREUR: Cette demande ne concerne pas un contenu éducatif approprié')) {
          Logger.warning('Demande refusée par l\'IA pour des raisons de sécurité: $sujet');
          return null;
        }
        
        DateTime now = DateTime.now();
        
        // Parser les métadonnées du contenu généré
        Map<String, dynamic> parsedData = _parseMetadata(content);
        
        // Générer des de engagement factices pour rendre l'app vivante
        Map<String, dynamic> engagementData = _generateFakeEngagementData();
        
        return CourseModel(
          id: '', 
          title: sujet,
          matiere: matiere,
          niveau: niveau,
          type: type,
          content: parsedData['cleanContent'],
          popularity: 0, // Course généré = 0 vues initialement
          votes: {'up': 0, 'down': 0},
          commentaires: [],
          authorId: authorId,
          authorName: authorName,
          createdAt: now,
          updatedAt: now,
          // Nouvelles métadonnées
          estimatedDuration: parsedData['estimatedDuration'],
          difficulty: parsedData['difficulty'],
          viewsCount: 0, // 0 vues pour course généré, sera mis à jour en Firebase
          rating: {}, // Pas de note pour course généré
          tags: [matiere.toLowerCase(), niveau.toLowerCase()],
          isPremium: type != CourseType.cours || authorId != 'user_generated',
          metadata: {
            'fakeEngagementData': engagementData, // Stocké pour utilisation future
            'hasBeenSavedToFirebase': false,
          },
        );
      }
      
      return null;
    } catch (e) {
      Logger.error('Error generating course', e);
      return null;
    }
  }

  Future<QCMModel?> generateQCM({
    required String courseId,
    required String courseContent,
    required String title,
    required QCMDifficulty difficulty,
    int numberOfQuestions = 10,
  }) async {
    try {
      Logger.info('GÉNÉRATION QCM DÉMARRÉE');
      Logger.info('- courseId: $courseId');
      Logger.info('- title: $title');
      Logger.info('- difficulty: ${difficulty.name}');
      Logger.info('- numberOfQuestions: $numberOfQuestions');
      Logger.info('- courseContent length: ${courseContent.length}');
      
      // Limiter le contenu pour éviter de dépasser les tokens
      String limitedContent = courseContent.length > 4000 
          ? "${courseContent.substring(0, 4000)}\n\n[...contenu tronqué...]"
          : courseContent;
      Logger.info('- contenu limité: ${limitedContent.length} chars');
      
      String prompt = _buildQCMPrompt(limitedContent, numberOfQuestions, difficulty);
      
      String? response = await _makeOpenAIRequest(prompt);
      Logger.info('RÉPONSE OPENAI BRUTE');
      Logger.debug(response != null ? '${response.substring(0, response.length > 500 ? 500 : response.length)}...' : 'RÉPONSE NULL');
      
      if (response != null) {
        List<QuestionModel> questions = _parseQCMResponse(response);
        Logger.info('QUESTIONS PARSÉES: ${questions.length}');
        
        // Si toujours aucune question, forcer l'échec pour diagnostiquer
        if (questions.isEmpty) {
          Logger.error('PARSING COMPLÈTEMENT ÉCHOUÉ');
          Logger.error('Réponse OpenAI complète qui a échoué:');
          Logger.error('========================================');
          Logger.error(response);
          Logger.error('========================================');
          return null; // Forcer l'échec pour voir le problème
        }
        
        if (questions.isNotEmpty) {
          DateTime now = DateTime.now();
          return QCMModel(
            id: '',
            courseId: courseId,
            title: title,
            questions: questions,
            minimumSuccessRate: _getMinimumSuccessRate(difficulty),
            difficulty: difficulty,
            createdAt: now,
            updatedAt: now,
          );
        }
      }
      
      Logger.warning('AUCUNE QUESTION PARSÉE ET AUCUNE RÉPONSE OPENAI');
      Logger.info('API Key configurée: ${ApiConfig.isOpenAIConfigured}');
      return null;
    } catch (e, stackTrace) {
      Logger.error('ERREUR OPENAI QCM', e, stackTrace);
      return null;
    }
  }

  /// Méthode publique pour faire des requêtes OpenAI génériques
  /// Utilise GPT-5 par défaut ou le modèle spécifié
  Future<String?> makeOpenAIRequest(String prompt, {String? model}) async {
    return await _makeOpenAIRequest(prompt, model: model);
  }
  
  /// Méthode spécifique pour les tâches basiques avec modèle économique
  /// Utilise GPT-5-nano pour réduire les coûts (inscription, validation, suggestions simples)
  Future<String?> makeBasicOpenAIRequest(String prompt) async {
    return await _makeOpenAIRequest(prompt, model: ApiConfig.openaiModelBasic);
  }

  Future<String?> _makeOpenAIRequest(String prompt, {String? model}) async {
    // Vérifier si la clé API est configurée
    if (!ApiConfig.isOpenAIConfigured) {
      Logger.info('API OpenAI non configurée - utilisation de réponse mock');
      return _getMockResponse(prompt);
    }
    
    Logger.info('APPEL OPENAI API - Clé: ${_apiKey.substring(0, 10)}...');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': model ?? ApiConfig.openaiModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': ApiConfig.maxTokens,
          'temperature': ApiConfig.temperature,
        }),
      );

      Logger.info('OPENAI RESPONSE STATUS: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String content = data['choices'][0]['message']['content'];
        Logger.info('OPENAI RESPONSE LENGTH: ${content.length} chars');
        return content;
      } else {
        Logger.error('OpenAI API error: ${response.statusCode}');
        Logger.error('Error body: ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.error('Error making OpenAI request', e);
      return null;
    }
  }

  String _buildCoursePrompt(String sujet, String matiere, String niveau, CourseType type, List<String>? options) {
    String typeDescription;
    String formatInstructions;
    
    switch (type) {
      case CourseType.fiche:
        typeDescription = 'sous forme de fiche de révision ultra-pratique pour préparer un examen';
        formatInstructions = '''
📋 STRUCTURE OBLIGATOIRE POUR FICHE DE RÉVISION:

## 📝 MOTS-CLÉS ESSENTIELS
[Liste des 5-8 termes les plus importants avec définition courte]

## 🎯 L'ESSENTIEL EN 3 POINTS
[Les 3 idées principales à absolument retenir]

## 📊 FORMULES/RÈGLES CLÉS 
[Formules, règles, dates importantes - format mémorisable]

## 💡 ASTUCES MNÉMOTECHNIQUES
[Moyens simples pour retenir - acronymes, phrases...]

## ❓ PIÈGES À ÉVITER
[Erreurs classiques dans cette notion]

⏱️ DURÉE DE LECTURE: 3-5 minutes maximum
''';
        break;
        
      case CourseType.vulgarise:
        typeDescription = 'de manière ULTRA-ACCESSIBLE pour que même un débutant complet comprenne';
        formatInstructions = '''
🌟 RÈGLES STRICTES POUR VULGARISATION:

- ❌ BANNIR: jargon technique, mots compliqués, formules abstraites
- ✅ UTILISER: analogies du quotidien, exemples concrets, métaphores simples
- 🗣️ TON: comme si tu expliquais à un ami de 12 ans
- 📖 STRUCTURE: 
  * "C'est quoi en fait ?" (intro ultra-simple)
  * "Un exemple concret" (situation réelle)
  * "Pourquoi c'est utile ?" (application pratique)
  * "En résumé" (3 phrases max)

Exemples d'analogies à utiliser:
- Électricité = eau qui coule dans des tuyaux
- Atomes = briques de construction
- Internet = routes avec des panneaux
''';
        break;
        
      case CourseType.cours:
        typeDescription = 'sous forme de cours traditionnel complet avec théorie et pratique';
        formatInstructions = '''
Format souhaité:
- Introduction claire
- Développement avec sections bien organisées
- Exemples pratiques
- Conclusion avec points à retenir
''';
        break;
    }

    String levelAdaptation = _getLevelAdaptation(niveau);
    String optionsContext = '';
    if (options != null && options.isNotEmpty) {
      optionsContext = '\n\nContexte: L\'étudiant a choisi les spécialités suivantes : ${options.join(', ')}. Adapter légèrement le style mais rester centré sur $matiere.';
    }

    return '''
⚠️ SÉCURITÉ ET VALIDATION:
Avant de générer le contenu, vérifiez que la demande concerne l'éducation, l'apprentissage scolaire ou académique.
Si le sujet demandé contient du contenu inapproprié, des obscénités, de la violence, ou n'a aucun rapport avec l'éducation, répondez uniquement par: "ERREUR: Cette demande ne concerne pas un contenu éducatif approprié."

Créer un contenu sur "$sujet" en $matiere pour le niveau $niveau.
Le contenu doit être présenté $typeDescription.

IMPORTANT: Commencer OBLIGATOIREMENT par ces métadonnées au format JSON (exactement cette structure):

---METADATA---
{
  "estimatedDuration": [durée en minutes pour étudier ce contenu, entre 5 et 120],
  "difficulty": "[facile|moyen|difficile] selon le niveau de complexité pour ce niveau scolaire"
}
---END_METADATA---

🔬 RÈGLES STRICTES POUR FORMULES ET NOTATIONS SCIENTIFIQUES:

📐 MATHÉMATIQUES:
- JAMAIS utiliser |dots, |ldots, |cdots, |vdots → TOUJOURS …, ⋮
- Indices: a₁, a₂, aₙ (pas a_1, a_2, a_n)  
- Exposants: x², x³, xⁿ (pas x^2, x^3, x^n)
- Symboles: ≤, ≥, ≠, ±, ∞, √, ∑, ∏, ∫

⚗️ PHYSIQUE-CHIMIE:
- Formules chimiques: H₂O, CO₂, H₂SO₄ (pas H_2O, CO_2)
- Ions: Na⁺, Cl⁻, SO₄²⁻ (pas Na+, Cl-, SO4^2-)
- Réactions: → (pas ->, =>, -->) 
- Multiplication: × ou ⋅ (pas *, x)
- Unités: m/s², kg⋅m/s², J⋅mol⁻¹ (pas m/s^2, kg*m/s^2)
- Variables: ΔH, ΔS, ΔG (pas |Delta H, Delta H)

🧬 SCIENCES:
- Notation scientifique: 10⁶, 10⁻³ (pas 10^6, 10^-3)
- Température: °C, K (pas degC, deg)

✅ EXEMPLE CORRECT: F = ma, E = mc², H₂ + Cl₂ → 2HCl, pH = -log[H⁺]
❌ EXEMPLE INCORRECT: F = m*a, E = m*c^2, H_2 + Cl_2 -> 2HCl, pH = -log[H+]

$formatInstructions

$levelAdaptation

Le contenu doit être pédagogique et parfaitement adapté au niveau $niveau.$optionsContext

RAPPEL: Commencer ABSOLUMENT par les métadonnées JSON entre ---METADATA--- et ---END_METADATA---, puis le contenu du cours.
''';
  }

  /// Adaptation du contenu selon le niveau scolaire
  String _getLevelAdaptation(String niveau) {
    Map<String, String> adaptations = {
      'CP': '''
🎯 ADAPTATION NIVEAU CP:
- Vocabulaire de 6-7 ans, phrases courtes
- Beaucoup d'exemples avec images mentales
- Ton encourageant et ludique
''',
      'CE1': '''
🎯 ADAPTATION NIVEAU CE1:
- Mots simples, explications pas-à-pas
- Exemples de la vie quotidienne d'un enfant
- Structure claire avec numérotation
''',
      'CE2': '''
🎯 ADAPTATION NIVEAU CE2:
- Vocabulaire accessible 8-9 ans
- Comparaisons avec des objets familiers
- Encourager la curiosité
''',
      'CM1': '''
🎯 ADAPTATION NIVEAU CM1:
- Début d'abstraction mais avec supports concrets
- Exemples variés et interactifs
- Connexions avec d'autres matières
''',
      'CM2': '''
🎯 ADAPTATION NIVEAU CM2:
- Préparation au collège, plus de rigueur
- Exemples de la vie courante et école
- Méthodes de mémorisation
''',
      '6ème': '''
🎯 ADAPTATION NIVEAU 6ème:
- Transition primaire-collège, rassurer
- Exemples concrets avant concepts abstraits  
- Méthodes d'organisation et de travail
''',
      '5ème': '''
🎯 ADAPTATION NIVEAU 5ème:
- Plus d'autonomie, défis intellectuels
- Liens avec l'actualité et culture générale
- Développer l'esprit critique
''',
      '4ème': '''
🎯 ADAPTATION NIVEAU 4ème:
- Approfondissement, nuances
- Exemples d'actualité et société
- Préparer aux choix d'orientation
''',
      '3ème': '''
🎯 ADAPTATION NIVEAU 3ème:
- Préparation au brevet
- Synthèses et révisions efficaces
- Liens avec projets d'orientation
''',
      '2nde': '''
🎯 ADAPTATION NIVEAU 2nde:
- Transition collège-lycée
- Méthodes de travail du lycée
- Autonomie et approfondissement
''',
      '1ère': '''
🎯 ADAPTATION NIVEAU 1ère:
- Préparation au baccalauréat
- Analyse critique et argumentation
- Liens entre spécialités
''',
      'Terminale': '''
🎯 ADAPTATION NIVEAU Terminale:
- Niveau baccalauréat exigé
- Préparation études supérieures
- Synthèse et expertise
''',
    };

    return adaptations[niveau] ?? '''
🎯 ADAPTATION GÉNÉRALE:
- Adapter le vocabulaire au niveau indiqué
- Utiliser des exemples appropriés à l'âge
- Maintenir un ton pédagogique encourageant
''';
  }

  String _buildQCMPrompt(String courseContent, int numberOfQuestions, QCMDifficulty difficulty) {
    String difficultyDescription = _getDifficultyDescription(difficulty);
    
    return '''
Créer un QCM de $numberOfQuestions questions basé sur le contenu suivant:

$courseContent

Niveau de difficulté: $difficultyDescription

🔬 RÈGLES STRICTES POUR FORMULES ET NOTATIONS SCIENTIFIQUES:

📐 MATHÉMATIQUES:
- JAMAIS utiliser |dots, |ldots, |cdots, |vdots → TOUJOURS …, ⋮
- Indices: a₁, a₂, aₙ (pas a_1, a_2, a_n)  
- Exposants: x², x³, xⁿ (pas x^2, x^3, x^n)
- Symboles: ≤, ≥, ≠, ±, ∞, √, ∑, ∏, ∫

⚗️ PHYSIQUE-CHIMIE:
- Formules chimiques: H₂O, CO₂, H₂SO₄ (pas H_2O, CO_2)
- Ions: Na⁺, Cl⁻, SO₄²⁻ (pas Na+, Cl-, SO4^2-)
- Réactions: → (pas ->, =>, -->) 
- Multiplication: × ou ⋅ (pas *, x)
- Unités: m/s², kg⋅m/s², J⋅mol⁻¹ (pas m/s^2, kg*m/s^2)
- Variables: ΔH, ΔS, ΔG (pas |Delta H, Delta H)

🧬 SCIENCES:
- Notation scientifique: 10⁶, 10⁻³ (pas 10^6, 10^-3)
- Température: °C, K (pas degC, deg)

✅ EXEMPLE CORRECT: F = ma, E = mc², H₂ + Cl₂ → 2HCl, pH = -log[H⁺]
❌ EXEMPLE INCORRECT: F = m*a, E = m*c^2, H_2 + Cl_2 -> 2HCl, pH = -log[H+]

IMPORTANT: Respecter EXACTEMENT ce format pour chaque question (y compris les mots-clés en MAJUSCULES):

QUESTION: [texte de la question]
A) [option A]
B) [option B]
C) [option C]
D) [option D]
REPONSE: [A, B, C ou D]
EXPLICATION: [courte explication]

Exemple:
QUESTION: Quelle est la capitale de la France ?
A) Londres
B) Berlin
C) Paris
D) Madrid
REPONSE: C
EXPLICATION: Paris est la capitale et la plus grande ville de France.

Assure-toi que:
- EXACTEMENT $numberOfQuestions questions au total
- Format respecté strictement (QUESTION:, A), B), C), D), REPONSE:, EXPLICATION:)
- Une seule réponse correcte par question
- Options plausibles et réalistes
- Explications courtes mais complètes
''';
  }

  List<QuestionModel> _parseQCMResponse(String response) {
    List<QuestionModel> questions = [];
    
    try {
      Logger.debug('PARSING QCM - Réponse reçue (${response.length} chars)');
      
      // Nouvelle approche : chercher directement les patterns de questions dans toute la réponse
      RegExp globalQuestionRegex = RegExp(
        r'(?:QUESTION\s*:?\s*\d*[.:]?\s*)?(.+?)\n\s*[Aa]\)\s*(.+?)\n\s*[Bb]\)\s*(.+?)\n\s*[Cc]\)\s*(.+?)\n\s*[Dd]\)\s*(.+?)\n\s*(?:REPONSE|RÉPONSE|RESPONSE)\s*:\s*([A-Da-d])\n\s*(?:EXPLICATION|EXPLICATION|EXPLANATION)\s*:\s*(.+?)(?=\n\s*(?:QUESTION|\$))',
        dotAll: true,
        multiLine: true,
        caseSensitive: false
      );
      
      Iterable<Match> matches = globalQuestionRegex.allMatches(response);
      Logger.debug('PARSING QCM - ${matches.length} questions trouvées avec regex globale');
      
      int questionIndex = 1;
      for (Match match in matches) {
        try {
          String? questionText = match.group(1)?.trim();
          List<String?> optionGroups = [
            match.group(2)?.trim(),
            match.group(3)?.trim(),
            match.group(4)?.trim(),
            match.group(5)?.trim(),
          ];
          String? correctLetter = match.group(6)?.trim().toUpperCase();
          String? explanation = match.group(7)?.trim();
          
          // Vérifier que tous les groupes sont non-null
          if (questionText == null || correctLetter == null || explanation == null || 
              optionGroups.any((option) => option == null)) {
            Logger.error('PARSING QCM - Question $questionIndex: groupes manquants dans le match');
            questionIndex++;
            continue;
          }
          
          List<String> options = optionGroups.cast<String>();
          
          // Nettoyer le texte de la question (enlever numérotation si présente)
          questionText = questionText.replaceFirst(RegExp(r'^\d+[.:]?\s*'), '').trim();
          
          int correctAnswer = correctLetter == 'A' ? 0 : 
                            correctLetter == 'B' ? 1 : 
                            correctLetter == 'C' ? 2 : 3;
          
          questions.add(QuestionModel(
            id: questionIndex.toString(),
            question: questionText,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanation,
          ));
          
          Logger.debug('PARSING QCM - Question $questionIndex ajoutée: "${questionText.substring(0, questionText.length > 50 ? 50 : questionText.length)}..."');
          questionIndex++;
        } catch (e) {
          Logger.error('PARSING QCM - Erreur question $questionIndex', e);
        }
      }
      
      // Fallback : essayer l'ancienne méthode si aucune question trouvée
      if (questions.isEmpty) {
        Logger.debug('PARSING QCM - Tentative avec ancienne méthode (split par QUESTION:)');
        List<String> questionBlocks = response.split('QUESTION:');
        Logger.debug('PARSING QCM - Blocs trouvés: ${questionBlocks.length}');
        
        for (int i = 1; i < questionBlocks.length; i++) {
          String block = questionBlocks[i].trim();
          Logger.debug('PARSING QCM - Bloc $i: ${block.substring(0, block.length > 200 ? 200 : block.length)}...');
          
          RegExp questionRegex = RegExp(r'^(.+?)\n\s*[Aa]\)\s*(.+?)\n\s*[Bb]\)\s*(.+?)\n\s*[Cc]\)\s*(.+?)\n\s*[Dd]\)\s*(.+?)\n\s*(?:REPONSE|RÉPONSE):\s*([A-Da-d])\n\s*(?:EXPLICATION|EXPLICATION):\s*(.+?)(?=\n\n|\$)', dotAll: true);
          Match? match = questionRegex.firstMatch(block);
          
          if (match != null) {
            try {
              String questionText = match.group(1)!.trim();
              List<String> options = [
                match.group(2)!.trim(),
                match.group(3)!.trim(),
                match.group(4)!.trim(),
                match.group(5)!.trim(),
              ];
              String correctLetter = match.group(6)!.trim().toUpperCase();
              String explanation = match.group(7)!.trim();
              
              int correctAnswer = correctLetter == 'A' ? 0 : 
                                correctLetter == 'B' ? 1 : 
                                correctLetter == 'C' ? 2 : 3;
              
              questions.add(QuestionModel(
                id: i.toString(),
                question: questionText,
                options: options,
                correctAnswer: correctAnswer,
                explanation: explanation,
              ));
              
              Logger.debug('PARSING QCM - Question $i ajoutée avec ancienne méthode');
            } catch (e) {
              Logger.error('PARSING QCM - Erreur question $i', e);
            }
          } else {
            Logger.debug('PARSING QCM - Regex ne match pas pour bloc $i');
          }
        }
      }
    } catch (e) {
      Logger.error('PARSING QCM - Erreur générale', e);
    }
    
    Logger.info('PARSING QCM - Total questions: ${questions.length}');
    return questions;
  }
  

  // Génération multi-parties pour cours complets
  Future<String?> _generateMultiPartCourse(String sujet, String matiere, String niveau, List<String>? options) async {
    try {
      // 1. Générer d'abord le sommaire
      String summaryPrompt = _buildSummaryPrompt(sujet, matiere, niveau, options);
      String? summary = await _makeOpenAIRequest(summaryPrompt);
      
      if (summary == null) return null;
      
      // 2. Extraire les chapitres du sommaire
      List<String> chapters = _extractChapters(summary);
      
      if (chapters.isEmpty) return null;
      
      // 3. Limiter à 6 chapitres max pour contrôler les coûts
      chapters = chapters.take(6).toList();
      
      // 4. Générer chaque chapitre
      String cleanSummary = _cleanMathSyntax(summary);
      List<String> courseContent = [cleanSummary, '\n\n---\n\n'];
      
      for (int i = 0; i < chapters.length; i++) {
        String chapterPrompt = _buildChapterPrompt(
          sujet: sujet,
          matiere: matiere,
          niveau: niveau,
          chapterTitle: chapters[i],
          chapterNumber: i + 1,
          totalChapters: chapters.length,
          previousContext: i > 0 ? chapters.sublist(0, i).join(', ') : '',
          options: options,
        );
        
        String? chapterContent = await _makeOpenAIRequest(chapterPrompt);
        
        if (chapterContent != null) {
          // Nettoyer la syntaxe mathématique du chapitre
          String cleanChapterContent = _cleanMathSyntax(chapterContent);
          courseContent.add(cleanChapterContent);
          courseContent.add('\n\n---\n\n');
        }
        
        // Petit délai pour éviter de surcharger l'API
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      return courseContent.join('');
      
    } catch (e) {
      Logger.error('Error generating multi-part course', e);
      return null;
    }
  }

  String _buildSummaryPrompt(String sujet, String matiere, String niveau, List<String>? options) {
    String optionsContext = '';
    if (options != null && options.isNotEmpty) {
      optionsContext = '\n- Contexte: l\'étudiant a choisi les spécialités ${options.join(", ")} mais le cours doit rester centré sur la $matiere';
    }
    
    return '''
Créer un plan détaillé de cours sur "$sujet" en $matiere pour le niveau $niveau.

IMPORTANT: Commencer OBLIGATOIREMENT par ces métadonnées au format JSON:

---METADATA---
{
  "estimatedDuration": [durée totale en minutes pour étudier ce cours complet, entre 30 et 120],
  "difficulty": "[facile|moyen|difficile] selon le niveau de complexité pour ce niveau scolaire"
}
---END_METADATA---

🔢 RÈGLES STRICTES POUR LES FORMULES MATHÉMATIQUES:
- JAMAIS utiliser |dots, |ldots, |cdots, |vdots
- TOUJOURS utiliser le caractère Unicode … (trois points de suspension) 
- Indices: utiliser la notation simple a₁, a₂, a₃ (pas a_1, a_2)
- Exposants: utiliser x², x³, xⁿ (pas x^2, x^3, x^n)
- Exemple CORRECT: S = a₁ + a₂ + a₃ + … + aₙ

Instructions:
- Créer un sommaire avec 4 à 6 chapitres maximum
- Chaque chapitre doit être clairement titré
- Le plan doit être progressif et pédagogique
- Adapter la complexité au niveau $niveau$optionsContext

Format attendu après les métadonnées:
# Plan du cours : $sujet

## Introduction
[Description de l'introduction]

## Chapitre 1: [Titre du chapitre]
[Brève description]

## Chapitre 2: [Titre du chapitre]
[Brève description]

[etc...]

## Conclusion
[Description de la conclusion]

RAPPEL: Commencer ABSOLUMENT par les métadonnées JSON entre ---METADATA--- et ---END_METADATA---.
''';
  }

  String _buildChapterPrompt({
    required String sujet,
    required String matiere,
    required String niveau,
    required String chapterTitle,
    required int chapterNumber,
    required int totalChapters,
    required String previousContext,
    List<String>? options,
  }) {
    String optionsContext = '';
    if (options != null && options.isNotEmpty) {
      optionsContext = '\n- Contexte: l\'étudiant a choisi les spécialités ${options.join(", ")} mais le cours doit rester centré sur la $matiere';
    }
    
    return '''
Développer le chapitre $chapterNumber sur $totalChapters pour le cours "$sujet" en $matiere (niveau $niveau).

Titre du chapitre: $chapterTitle

${previousContext.isNotEmpty ? 'Contexte des chapitres précédents: $previousContext' : ''}

🔬 RÈGLES STRICTES POUR FORMULES ET NOTATIONS SCIENTIFIQUES:

📐 MATHÉMATIQUES:
- JAMAIS utiliser |dots, |ldots, |cdots, |vdots → TOUJOURS …, ⋮
- Indices: a₁, a₂, aₙ (pas a_1, a_2, a_n)  
- Exposants: x², x³, xⁿ (pas x^2, x^3, x^n)
- Symboles: ≤, ≥, ≠, ±, ∞, √, ∑, ∏, ∫

⚗️ PHYSIQUE-CHIMIE:
- Formules chimiques: H₂O, CO₂, H₂SO₄ (pas H_2O, CO_2)
- Ions: Na⁺, Cl⁻, SO₄²⁻ (pas Na+, Cl-, SO4^2-)
- Réactions: → (pas ->, =>, -->) 
- Multiplication: × ou ⋅ (pas *, x)
- Unités: m/s², kg⋅m/s², J⋅mol⁻¹ (pas m/s^2, kg*m/s^2)
- Variables: ΔH, ΔS, ΔG (pas |Delta H, Delta H)

🧬 SCIENCES:
- Notation scientifique: 10⁶, 10⁻³ (pas 10^6, 10^-3)
- Température: °C, K (pas degC, deg)

✅ EXEMPLE CORRECT: F = ma, E = mc², H₂ + Cl₂ → 2HCl, pH = -log[H⁺]
❌ EXEMPLE INCORRECT: F = m*a, E = m*c^2, H_2 + Cl_2 -> 2HCl, pH = -log[H+]

Instructions:
- Développer uniquement ce chapitre de manière approfondie
- Rester cohérent avec le plan global du cours
- Inclure des explications détaillées, exemples et exercices
- Adapter le niveau de complexité au niveau $niveau
- Le chapitre doit faire environ 800-1200 mots
- Structurer avec des sous-sections si nécessaire$optionsContext

Format attendu:
# $chapterTitle

[Contenu détaillé du chapitre avec exemples et explications]

## Points clés à retenir
- Point 1
- Point 2
- Point 3
''';
  }

  List<String> _extractChapters(String summary) {
    List<String> chapters = [];
    
    // Extraire les lignes qui commencent par "## Chapitre"
    RegExp chapterRegex = RegExp(r'## Chapitre \d+:\s*(.+)', multiLine: true);
    Iterable<RegExpMatch> matches = chapterRegex.allMatches(summary);
    
    for (RegExpMatch match in matches) {
      String? chapterTitle = match.group(1)?.trim();
      if (chapterTitle != null && chapterTitle.isNotEmpty) {
        chapters.add(chapterTitle);
      }
    }
    
    return chapters;
  }

  // Helper pour obtenir la description de difficulté
  String _getDifficultyDescription(QCMDifficulty difficulty) {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return 'FACILE - Questions de base testant la compréhension générale';
      case QCMDifficulty.moyen:
        return 'MOYEN - Questions nécessitant une analyse et application des concepts';
      case QCMDifficulty.difficile:
        return 'DIFFICILE - Questions complexes testant la maîtrise et la synthèse';
      case QCMDifficulty.tresDifficile:
        return 'TRÈS DIFFICILE - Questions expertes nécessitant une analyse approfondie et des liens entre concepts';
    }
  }

  // Helper pour obtenir le taux de réussite minimum selon la difficulté
  int _getMinimumSuccessRate(QCMDifficulty difficulty) {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return 60; // 60% minimum pour valider
      case QCMDifficulty.moyen:
        return 70; // 70% minimum
      case QCMDifficulty.difficile:
        return 80; // 80% minimum
      case QCMDifficulty.tresDifficile:
        return 85; // 85% minimum pour le niveau expert
    }
  }

  String _getMockResponse(String prompt) {
    if (prompt.contains('QCM')) {
      return '''
QUESTION: Quelle est la capitale de la France ?
A) Londres
B) Berlin
C) Paris
D) Madrid
REPONSE: C
EXPLICATION: Paris est la capitale de la France depuis des siècles.

QUESTION: Combien font 2 + 2 ?
A) 3
B) 4
C) 5
D) 6
REPONSE: B
EXPLICATION: 2 + 2 = 4, c'est une addition basique.
''';
    } else {
      return '''
# Introduction au sujet

Ce cours présente une introduction complète au sujet demandé.

## Section 1: Concepts fondamentaux

Les concepts de base sont essentiels pour comprendre ce domaine.

### Point clé 1
Explication détaillée du premier concept important.

### Point clé 2
Développement du second concept avec exemples pratiques.

## Section 2: Applications pratiques

Des exemples concrets permettent de mieux appréhender la théorie.

### Exemple 1
Illustration pratique du concept avec un cas d'usage réel.

### Exemple 2
Autre exemple montrant une application différente.

## Conclusion

Points à retenir:
- Concept principal 1
- Concept principal 2
- Applications pratiques importantes

Ce cours offre une base solide pour approfondir le sujet.
''';
    }
  }
}