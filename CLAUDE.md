# Ilium - Configuration Claude

## Configuration requise

### Variables d'environnement
1. Copiez `.env.example` vers `.env`
2. Configurez votre clé API OpenAI:
   ```
   OPENAI_API_KEY=sk-proj-votre_cle_api_ici
   ```

### Firebase
- Le projet utilise Firebase pour l'authentification et Firestore
- Les fichiers de configuration sont inclus dans le repository
- Assurez-vous que les règles Firestore permettent l'accès aux utilisateurs authentifiés

## Commandes utiles
- `flutter run` - Lancer l'application
- `flutter test` - Exécuter les tests
- `flutter analyze` - Analyser le code