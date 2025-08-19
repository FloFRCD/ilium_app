# Ilium - Configuration Claude

## Configuration requise

### Variables d'environnement
1. Copiez `.env.example` vers `.env`
2. Configurez votre cl� API OpenAI:
   ```
   OPENAI_API_KEY=sk-proj-votre_cle_api_ici
   ```

### Firebase
- Le projet utilise Firebase pour l'authentification et Firestore
- Les fichiers de configuration sont inclus dans le repository
- Assurez-vous que les r�gles Firestore permettent l'acc�s aux utilisateurs authentifi�s

## Commandes utiles
- `flutter run` - Lancer l'application
- `flutter test` - Ex�cuter les tests
- `flutter analyze` - Analyser le code