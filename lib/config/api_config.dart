class ApiConfig {
  // Configuration OpenAI - Migration vers GPT-5 pour de meilleures performances
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '', // Clé API à définir via variable d'environnement
  );
  
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String openaiModel = 'gpt-5';
  static const String openaiModelBasic = 'gpt-5-nano'; // Modèle économique pour tâches simples
  
  // Configuration Firebase
  static const int maxTokens = 4000; // GPT-5 permet plus de tokens
  static const double temperature = 0.6; // Légèrement plus précis pour du contenu éducatif
  
  // Validation de la configuration
  static bool get isOpenAIConfigured {
    return openaiApiKey.isNotEmpty && openaiApiKey.startsWith('sk-') && 
           openaiApiKey.length > 10;
  }
}