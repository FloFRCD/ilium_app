import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Modèle pour un article de news
class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String source;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.source,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['image'],
      publishedAt: DateTime.parse(json['publishedAt']),
      source: json['source']?['name'] ?? 'Source inconnue',
    );
  }
}

/// Service pour récupérer les actualités éducatives via GNews API
class NewsService {
  static const String _baseUrl = 'https://gnews.io/api/v4';
  static const String _apiKey = '426bdec95627db3f12c0592df7265c0b';
  
  /// Récupère les actualités éducatives en français
  Future<List<NewsArticle>> getEducationNews({int maxArticles = 5}) async {
    try {
      Logger.info('📰 Récupération des actualités éducatives via GNews API...');
      
      // Requête avec des filtres très stricts pour l'éducation
      final query = Uri.encodeComponent('("éducation nationale" OR "ministère éducation" OR "université" OR "formation professionnelle" OR "enseignement" OR "baccalauréat" OR "parcoursup" OR "étudiants" OR "professeurs" OR "réforme scolaire") -football -sport -people -faits');
      final url = '$_baseUrl/search?q=$query&lang=fr&country=fr&max=${maxArticles * 3}&apikey=$_apiKey';
      
      Logger.info('🌐 URL de requête: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Ilium Education App/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['articles'] != null && data['articles'] is List) {
          final articles = (data['articles'] as List)
              .map((articleData) {
                try {
                  return NewsArticle.fromJson(articleData);
                } catch (e) {
                  Logger.warning('⚠️ Erreur lors du parsing d\'un article: $e');
                  return null;
                }
              })
              .whereType<NewsArticle>() // Filtre automatiquement les null
              .where((article) => _isEducationRelevant(article))
              .take(maxArticles) // Limiter après filtrage
              .toList();

          Logger.info('✅ ${articles.length} articles éducatifs récupérés');
          
          if (articles.isNotEmpty) {
            return articles;
          }
        }
      } else {
        Logger.error('❌ Erreur API GNews: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      Logger.error('❌ Erreur lors de la récupération des actualités: $e');
    }

    Logger.info('⚠️ Utilisation du fallback suite à une erreur');
    return _getFallbackNews();
  }

  /// Vérifie si un article est pertinent pour l'éducation avec filtrage renforcé
  bool _isEducationRelevant(NewsArticle article) {
    final titleLower = article.title.toLowerCase();
    final descriptionLower = article.description.toLowerCase();
    final sourceLower = article.source.toLowerCase();
    final fullText = '$titleLower $descriptionLower $sourceLower';

    // Mots-clés éducatifs prioritaires (forte valeur éducative)
    final highValueEducationKeywords = [
      'éducation nationale', 'ministère éducation', 'réforme éducative',
      'baccalauréat', 'parcoursup', 'université', 'formation',
      'enseignement', 'apprentissage', 'étudiant', 'élève',
      'professeur', 'enseignant', 'pédagogie', 'scolarité',
      'programme scolaire', 'rentrée scolaire', 'concours',
      'diplôme', 'licence', 'master', 'doctorat'
    ];

    // Mots-clés éducatifs secondaires
    final educationKeywords = [
      'école', 'lycée', 'collège', 'campus', 'fac', 'faculté',
      'académie', 'crous', 'orientation', 'examens',
      'vacances scolaires', 'cours', 'recherche universitaire'
    ];

    // Sources éducatives fiables (plus strict)
    final educationSources = [
      'education.gouv', 'onisep', 'crous', 'parcoursup',
      'campus france', 'le figaro étudiant', 'l\'étudiant',
      'ministère éducation', 'académie', 'université',
      'enseignementsup', 'eduscol', 'canope'
    ];

    // Mots-clés à exclure absolument (très strict)
    final excludeKeywords = [
      // Sports
      'football', 'rugby', 'tennis', 'basketball', 'cyclisme', 'sport', 'match', 'équipe', 'joueur', 'championnat', 'ligue', 'coupe',
      // Divertissement
      'météo', 'cuisine', 'recette', 'mode', 'beauté', 'shopping', 'célébrité', 'people', 'télé-réalité', 'musique', 'concert', 'festival', 'spectacle',
      // Fait divers
      'accident', 'fait divers', 'criminel', 'police', 'justice', 'tribunal', 'procès', 'incendie', 'vol', 'agression',
      // Politique générale
      'élection', 'guerre', 'conflit', 'international', 'président', 'gouvernement', 'ministre', 'député', 'sénat',
      // Économie générale
      'bourse', 'finance', 'banque', 'euro', 'économie', 'marché', 'entreprise', 'industrie',
      // Autres sujets
      'immobilier', 'voiture', 'automobile', 'transport', 'santé', 'médecine', 'hôpital', 'maladie', 'voyage', 'tourisme',
      // Tech générale
      'smartphone', 'iphone', 'android', 'apple', 'google', 'meta', 'tesla', 'crypto', 'bitcoin',
      // Actualité générale
      'météorologie', 'climat', 'environnement', 'écologie', 'énergie', 'nucléaire'
    ];

    // Vérifications
    final hasHighValueKeywords = highValueEducationKeywords.any((keyword) => 
        fullText.contains(keyword));
    
    final hasEducationKeywords = educationKeywords.any((keyword) => 
        fullText.contains(keyword));
    
    final hasEducationSource = educationSources.any((source) => 
        sourceLower.contains(source));
    
    final hasExcludedKeywords = excludeKeywords.any((keyword) => 
        fullText.contains(keyword));

    // Logique de validation ultra-stricte
    // 1. REJET IMMÉDIAT si contient des mots exclus
    if (hasExcludedKeywords) {
      return false;
    }

    // 2. Accepter SEULEMENT si source fiable ET contient mots haute valeur
    if (hasEducationSource && hasHighValueKeywords) {
      return true;
    }

    // 3. OU si mots-clés haute valeur dans le TITRE (pas seulement description)
    final titleHasHighValue = highValueEducationKeywords.any((keyword) => 
        titleLower.contains(keyword));
    
    if (titleHasHighValue) {
      return true;
    }

    // 4. Rejet strict : ne pas accepter les mots éducatifs secondaires seuls
    // Ils doivent être accompagnés d'une source fiable
    if (hasEducationKeywords && hasEducationSource) {
      final titleHasEducation = [...highValueEducationKeywords, ...educationKeywords]
          .any((keyword) => titleLower.contains(keyword));
      return titleHasEducation;
    }

    // 5. Rejet par défaut si rien ne correspond aux critères stricts
    return false;
  }

  /// Actualités de secours en cas d'erreur API
  List<NewsArticle> _getFallbackNews() {
    Logger.info('⚠️ Utilisation des actualités de secours (fallback)');
    return [
      NewsArticle(
        title: "Intelligence artificielle : révolution dans l'éducation française",
        description: "Les établissements scolaires français adoptent massivement les outils d'IA pour personnaliser l'apprentissage et améliorer les résultats des élèves.",
        url: "https://www.education.gouv.fr/intelligence-artificielle-education-numerique",
        imageUrl: "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=200&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        source: "Ministère de l'Éducation",
      ),
      NewsArticle(
        title: "Réforme du baccalauréat : nouveaux aménagements annoncés",
        description: "Le ministère de l'Éducation présente les derniers ajustements de la réforme du baccalauréat pour la session 2024.",
        url: "https://www.education.gouv.fr/reforme-baccalaureat-2024",
        imageUrl: "https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=400&h=200&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
        source: "Éducation Nationale",
      ),
      NewsArticle(
        title: "Nouveau programme de formation numérique pour les enseignants",
        description: "Un plan ambitieux vise à former 500 000 enseignants aux compétences numériques d'ici 2025 pour moderniser l'enseignement.",
        url: "https://www.education.gouv.fr/formation-numerique-enseignants",
        imageUrl: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400&h=200&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
        source: "France Inter",
      ),
      NewsArticle(
        title: "Parcoursup 2024 : nouvelles formations et calendrier",
        description: "La plateforme d'orientation post-bac évolue avec 23 000 formations disponibles et un calendrier adapté aux besoins des lycéens.",
        url: "https://www.parcoursup.fr/actualites-2024",
        imageUrl: "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=400&h=200&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
        source: "Onisep",
      ),
      NewsArticle(
        title: "Les universités françaises renforcent leurs partenariats internationaux",
        description: "De nouveaux accords d'échanges étudiants sont signés avec des universités européennes et nord-américaines pour 2024.",
        url: "https://www.campusfrance.org/fr/partenariats-internationaux-2024",
        imageUrl: "https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=400&h=200&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 10)),
        source: "Campus France",
      ),
      NewsArticle(
        title: "Formation professionnelle : boom des métiers du numérique",
        description: "Les centres de formation constatent une demande croissante pour les formations en cybersécurité, IA et développement web.",
        url: "https://www.pole-emploi.fr/actualites/formations-numeriques-2024",
        imageUrl: "https://images.unsplash.com/photo-1552664730-d307ca884978?w=400&h=200&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
        source: "Les Échos Formation",
      ),
    ];
  }


  /// Cache simple pour éviter trop de requêtes API
  static List<NewsArticle>? _cachedNews;
  static DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Récupère les actualités avec cache
  Future<List<NewsArticle>> getCachedEducationNews({int maxArticles = 5, bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Vérifier si le cache est encore valide (sauf si forceRefresh)
    if (!forceRefresh && 
        _cachedNews != null && 
        _lastFetch != null && 
        now.difference(_lastFetch!).compareTo(_cacheExpiry) < 0) {
      Logger.info('📰 Utilisation du cache pour les actualités (${_cachedNews!.length} articles)');
      return _cachedNews!.take(maxArticles).toList();
    }

    Logger.info('🔄 Récupération de nouvelles actualités depuis l\'API...');
    
    // Récupérer de nouvelles actualités
    final news = await getEducationNews(maxArticles: maxArticles);
    _cachedNews = news;
    _lastFetch = now;
    
    Logger.info('💾 Cache mis à jour avec ${news.length} articles');
    
    return news;
  }
}