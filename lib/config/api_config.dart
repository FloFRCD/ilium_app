import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Configuration OpenAI - Migration vers GPT-4 pour de meilleures performances
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get gnewsApiKey => dotenv.env['GNEWS_API_KEY'] ?? '';
  
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String openaiModel = 'gpt-4'; // Modèle existant et fiable
  static const String openaiModelBasic = 'gpt-3.5-turbo'; // Modèle économique pour tâches simples
  
  // Configuration Firebase
  static const int maxTokens = 4000;
  static const double temperature = 0.6; // Légèrement plus précis pour du contenu éducatif
  
  // Validation de la configuration
  static bool get isOpenAIConfigured {
    return openaiApiKey.isNotEmpty && openaiApiKey.startsWith('sk-') && 
           openaiApiKey.length > 10;
  }
  
  static bool get isGNewsConfigured {
    return gnewsApiKey.isNotEmpty && gnewsApiKey.length > 10;
  }
}