import '../services/openai_service.dart';
import '../utils/logger.dart';

/// Service IA économique pour les tâches basiques
/// Utilise gpt-5-nano pour réduire les coûts
class AIBasicService {
  final OpenAIService _openaiService = OpenAIService();
  
  /// Formate et corrige le niveau scolaire saisi par l'utilisateur
  Future<String> formatNiveauScolaire(String niveauSaisi) async {
    try {
      String prompt = '''
Corrige et formate ce niveau scolaire: "$niveauSaisi"

Règles:
- Retourner le niveau correct en français (CP, CE1, CE2, CM1, CM2, 6ème, 5ème, 4ème, 3ème, 2nde, 1ère, Terminale)
- Si "terminal" → "Terminale" 
- Si "premiere" → "1ère"
- Si "seconde" → "2nde"
- Si incertain, retourner le niveau le plus probable

Répondre UNIQUEMENT avec le niveau corrigé, rien d'autre.
''';

      String? response = await _openaiService.makeBasicOpenAIRequest(prompt);
      
      if (response != null && _isValidNiveau(response.trim())) {
        return response.trim();
      }
      
      return _fallbackNiveauCorrection(niveauSaisi);
    } catch (e) {
      Logger.error('Erreur formatage niveau', e);
      return _fallbackNiveauCorrection(niveauSaisi);
    }
  }
  
  /// Formate et corrige les spécialités/options saisies par l'utilisateur
  Future<List<String>> formatSpecialites(List<String> specialitesSaisies, String niveau) async {
    try {
      String prompt = '''
Corrige et formate ces spécialités pour un élève de $niveau: ${specialitesSaisies.join(', ')}

Règles:
- Utiliser les noms officiels des spécialités françaises
- Exemples: "Mathématiques", "Physique-Chimie", "SVT", "Histoire-Géographie", "SES", "Anglais", "Espagnol", "NSI", "SI"
- Si "maths" → "Mathématiques"
- Si "physique" → "Physique-Chimie" 
- Si "bio" → "SVT"
- Si "informatique" → "NSI"
- Adapter au niveau (pas de spécialités pour collège)

Format de réponse (une par ligne):
Mathématiques
Physique-Chimie
SVT
''';

      String? response = await _openaiService.makeBasicOpenAIRequest(prompt);
      
      if (response != null) {
        return _parseFormattedSpecialites(response);
      }
      
      return _fallbackSpecialitesCorrection(specialitesSaisies, niveau);
    } catch (e) {
      Logger.error('Erreur formatage spécialités', e);
      return _fallbackSpecialitesCorrection(specialitesSaisies, niveau);
    }
  }
  
  /// Génère une réponse conversationnelle pour l'inscription
  Future<String> generateConversationalResponse({
    required String userMessage,
    required String etapeInscription,
    String? contexte,
  }) async {
    try {
      String prompt = '''
Tu es l'assistant d'inscription d'Ilium, une plateforme éducative. Réponds de manière conversationnelle et bienveillante.

Étape actuelle: $etapeInscription
Message utilisateur: "$userMessage"
${contexte != null ? 'Contexte: $contexte' : ''}

Instructions:
- Réponse courte (1-2 phrases max)
- Ton amical et encourageant
- Français naturel, tutoiement
- Poser la prochaine question logique

Exemples de réponses selon l'étape:
- niveau: "Super ! Tu es en Terminale alors. Quelles spécialités as-tu choisies cette année ?"
- specialites: "Excellent choix ! Math et Physique-Chimie, ça va te mener loin 🚀 Maintenant, quel pseudo aimerais-tu utiliser ?"
- pseudo: "Parfait ! Ton profil est prêt. Bienvenue sur Ilium ! 🎉"
''';

      String? response = await _openaiService.makeBasicOpenAIRequest(prompt);
      
      if (response != null && response.trim().isNotEmpty) {
        return response.trim();
      }
      
      return _getDefaultConversationalResponse(etapeInscription);
    } catch (e) {
      Logger.error('Erreur génération réponse conversationnelle', e);
      return _getDefaultConversationalResponse(etapeInscription);
    }
  }
  
  /// Génère un message de bienvenue personnalisé pendant l'inscription
  Future<String> generateWelcomeMessage({
    required String pseudo,
    required String niveau,
    List<String>? specialities,
  }) async {
    try {
      String specialitiesText = specialities?.isNotEmpty == true 
          ? 'avec les spécialités ${specialities!.join(', ')}'
          : '';
          
      String prompt = '''
Écris un message de bienvenue chaleureux et motivant pour $pseudo, un élève de $niveau $specialitiesText qui vient de s'inscrire sur Ilium (plateforme d'apprentissage).

Le message doit:
- Être court (2-3 phrases max)
- Être encourageant et personnalisé
- Mentionner Ilium
- Être adapté au niveau scolaire

Exemple: "Bienvenue sur Ilium, Sarah ! En tant qu'élève de Terminale, tu vas découvrir des ressources qui t'aideront à exceller dans tes études. Prête à commencer cette aventure d'apprentissage ?"
''';

      String? response = await _openaiService.makeBasicOpenAIRequest(prompt);
      
      if (response != null && response.trim().isNotEmpty) {
        return response.trim();
      }
      
      return _getDefaultWelcomeMessage(pseudo, niveau);
    } catch (e) {
      Logger.error('Erreur génération message de bienvenue', e);
      return _getDefaultWelcomeMessage(pseudo, niveau);
    }
  }
  
  /// Valide et corrige le pseudo de l'utilisateur
  Future<String> validateAndSuggestPseudo(String pseudo) async {
    try {
      // Si le pseudo est déjà correct, le retourner
      if (_isPseudoValid(pseudo)) {
        return pseudo;
      }
      
      String prompt = '''
Corrige ce pseudo pour qu'il soit approprié pour une plateforme éducative: "$pseudo"

Règles:
- Garder l'esprit du pseudo original
- Supprimer les caractères inappropriés
- Maximum 20 caractères
- Pas de mots vulgaires ou inappropriés

Répondre UNIQUEMENT avec le pseudo corrigé, rien d'autre.
''';

      String? response = await _openaiService.makeBasicOpenAIRequest(prompt);
      
      if (response != null && _isPseudoValid(response.trim())) {
        return response.trim();
      }
      
      return _sanitizePseudo(pseudo);
    } catch (e) {
      Logger.error('Erreur validation pseudo', e);
      return _sanitizePseudo(pseudo);
    }
  }
  
  // Méthodes utilitaires privées
  
  List<String> _parseSpecialitySuggestions(String response) {
    List<String> suggestions = [];
    
    // Extraire les lignes qui commencent par un chiffre et un point
    RegExp lineRegex = RegExp(r'^\d+\.\s*(.+)$', multiLine: true);
    Iterable<RegExpMatch> matches = lineRegex.allMatches(response);
    
    for (RegExpMatch match in matches) {
      String? specialty = match.group(1)?.trim();
      if (specialty != null && specialty.isNotEmpty) {
        suggestions.add(specialty);
      }
    }
    
    return suggestions.take(3).toList();
  }
  
  List<String> _getDefaultSpecialitySuggestions(String niveau) {
    Map<String, List<String>> defaultSuggestions = {
      'Terminale': ['Mathématiques', 'Physique-Chimie', 'SVT'],
      '1ère': ['Mathématiques', 'Français', 'Histoire-Géographie'],
      '2nde': ['Mathématiques', 'Français', 'SVT'],
      // Ajouter d'autres niveaux si besoin
    };
    
    return defaultSuggestions[niveau] ?? ['Mathématiques', 'Français', 'Sciences'];
  }
  
  String _getDefaultWelcomeMessage(String pseudo, String niveau) {
    return 'Bienvenue sur Ilium, $pseudo ! En tant qu\'élève de $niveau, tu vas découvrir des ressources adaptées à ton niveau. Prêt(e) à commencer ?';
  }
  
  bool _isPseudoValid(String pseudo) {
    // Règles de validation basiques
    return pseudo.length >= 2 && 
           pseudo.length <= 20 && 
           RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(pseudo);
  }
  
  String _sanitizePseudo(String pseudo) {
    // Nettoyage basique du pseudo
    String cleaned = pseudo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    if (cleaned.length < 2) cleaned = 'Utilisateur';
    if (cleaned.length > 20) cleaned = cleaned.substring(0, 20);
    return cleaned;
  }
  
  /// Valide si un niveau scolaire est correct
  bool _isValidNiveau(String niveau) {
    List<String> niveauxValides = [
      'CP', 'CE1', 'CE2', 'CM1', 'CM2',
      '6ème', '5ème', '4ème', '3ème',
      '2nde', '1ère', 'Terminale',
      'Seconde', 'Première' // Variantes acceptées
    ];
    return niveauxValides.contains(niveau.trim());
  }
  
  /// Correction de niveau hors ligne en cas d'échec de l'IA
  String _fallbackNiveauCorrection(String niveauSaisi) {
    String niveau = niveauSaisi.toLowerCase().trim();
    
    // Corrections communes
    Map<String, String> corrections = {
      'terminal': 'Terminale',
      'terminale': 'Terminale',
      'premiere': '1ère',
      'première': '1ère',
      'seconde': '2nde',
      '2nd': '2nde',
      'sixieme': '6ème',
      'sixième': '6ème',
      'cinquieme': '5ème',
      'cinquième': '5ème',
      'quatrieme': '4ème',
      'quatrième': '4ème',
      'troisieme': '3ème',
      'troisième': '3ème',
    };
    
    if (corrections.containsKey(niveau)) {
      return corrections[niveau]!;
    }
    
    // Recherche par similarité basique
    if (niveau.contains('term')) return 'Terminale';
    if (niveau.contains('prem')) return '1ère';
    if (niveau.contains('sec')) return '2nde';
    if (niveau.contains('6')) return '6ème';
    if (niveau.contains('5')) return '5ème';
    if (niveau.contains('4')) return '4ème';
    if (niveau.contains('3')) return '3ème';
    
    // Par défaut
    return 'Terminale';
  }
  
  /// Parse les spécialités formatées par l'IA
  List<String> _parseFormattedSpecialites(String response) {
    List<String> specialites = [];
    
    // Diviser par lignes et nettoyer
    List<String> lignes = response.split('\n');
    
    for (String ligne in lignes) {
      String specialite = ligne.trim();
      
      // Ignorer les lignes vides ou de formatage
      if (specialite.isEmpty || 
          specialite.startsWith('Format') || 
          specialite.startsWith('Règles') ||
          specialite.contains(':')) {
        continue;
      }
      
      // Nettoyer les puces ou numéros
      specialite = specialite.replaceAll(RegExp(r'^[•\-\*\d\.\s]+'), '');
      
      if (specialite.isNotEmpty && specialite.length > 2) {
        specialites.add(specialite);
      }
    }
    
    return specialites.take(5).toList(); // Limite à 5 spécialités
  }
  
  /// Correction de spécialités hors ligne
  List<String> _fallbackSpecialitesCorrection(List<String> specialitesSaisies, String niveau) {
    List<String> specialitesCorrigees = [];
    
    Map<String, String> corrections = {
      'maths': 'Mathématiques',
      'mathematiques': 'Mathématiques',
      'math': 'Mathématiques',
      'physique': 'Physique-Chimie',
      'chimie': 'Physique-Chimie',
      'phys': 'Physique-Chimie',
      'bio': 'SVT',
      'biologie': 'SVT',
      'sciences': 'SVT',
      'informatique': 'NSI',
      'info': 'NSI',
      'nsi': 'NSI',
      'si': 'SI',
      'anglais': 'Anglais',
      'espagnol': 'Espagnol',
      'allemand': 'Allemand',
      'histoire': 'Histoire-Géographie',
      'geo': 'Histoire-Géographie',
      'geographie': 'Histoire-Géographie',
      'ses': 'SES',
      'economie': 'SES',
      'français': 'Français',
      'francais': 'Français',
      'philo': 'Philosophie',
      'philosophie': 'Philosophie',
    };
    
    for (String specialite in specialitesSaisies) {
      String specialiteNormalisee = specialite.toLowerCase().trim();
      
      if (corrections.containsKey(specialiteNormalisee)) {
        specialitesCorrigees.add(corrections[specialiteNormalisee]!);
      } else {
        // Capitaliser la première lettre si pas de correspondance
        String corrigee = specialite.trim();
        if (corrigee.isNotEmpty) {
          corrigee = corrigee[0].toUpperCase() + corrigee.substring(1).toLowerCase();
          specialitesCorrigees.add(corrigee);
        }
      }
    }
    
    return specialitesCorrigees;
  }
  
  /// Génère une réponse conversationnelle par défaut
  String _getDefaultConversationalResponse(String etapeInscription) {
    Map<String, String> reponsesParDefaut = {
      'niveau': 'Super ! Et quelles sont tes matières préférées ou spécialités ?',
      'specialites': 'Excellent choix ! Maintenant, quel pseudo aimerais-tu utiliser sur Ilium ?',
      'pseudo': 'Parfait ! Ton profil est presque prêt. Encore un instant... 🚀',
      'bienvenue': 'Bienvenue dans la communauté Ilium ! Prêt(e) à découvrir une nouvelle façon d\'apprendre ?',
    };
    
    return reponsesParDefaut[etapeInscription] ?? 
           'Merci pour ces informations ! Continuons ensemble... 😊';
  }
}