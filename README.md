# Ilium - Soutien Scolaire Intelligent

Application multiplateforme Flutter (iOS, Android, Web) de soutien scolaire avec intelligence artificielle.

## 🚀 Fonctionnalités

- **Recherche intelligente** : Par matière, niveau et sujet
- **Cours interactifs** : Fiches structurées, QCM et vulgarisation
- **Système de votes** : 👍👎 pour évaluer les cours
- **Commentaires et partage** : Interaction communautaire
- **Profils utilisateurs** : Badges, progression et statistiques
- **Modèle freemium** : Version limitée/premium avec historique et favoris

## 🛠️ Stack Technique

- **Frontend** : Flutter (Dart)
- **Backend** : Firebase (Auth, Firestore, Storage, Analytics)
- **IA** : OpenAI API
- **IDE** : VS Code avec extensions Flutter/Dart

## 📁 Architecture du Projet

```
lib/
├── main.dart              # Point d'entrée de l'application
├── firebase_options.dart  # Configuration Firebase
├── models/               # Modèles de données
│   └── user_model.dart
├── services/             # Services (Auth, API, etc.)
│   └── auth_service.dart
├── views/               # Écrans de l'application
│   ├── home_view.dart
│   ├── course_view.dart
│   ├── saved_view.dart
│   └── profile_settings_view.dart
└── widgets/             # Composants réutilisables
```

## 🔧 Installation

### Prérequis

- Flutter SDK (≥ 3.0.0)
- Dart SDK
- VS Code avec extensions Flutter/Dart
- Compte Firebase

### Étapes d'installation

1. **Cloner le projet**
   ```bash
   git clone <repository-url>
   cd ilium_app
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configuration Firebase**
   - Créer un projet Firebase
   - Configurer Authentication (Email/Password)
   - Configurer Firestore Database
   - Remplacer les clés dans `lib/firebase_options.dart`

4. **Lancer l'application**
   ```bash
   # Web
   flutter run -d chrome
   
   # iOS (macOS uniquement)
   flutter run -d ios
   
   # Android
   flutter run -d android
   ```

## 🎯 Navigation

L'application utilise une **bottom navigation bar** avec 4 sections :

- **🏠 Accueil** : Page d'accueil et recherche
- **📚 Cours** : Parcours des matières et niveaux
- **❤️ Favoris** : Cours sauvegardés (Premium)
- **👤 Profil** : Paramètres et statistiques

## 🔥 Firebase Configuration

### Services utilisés :
- **Authentication** : Connexion email/password
- **Firestore** : Base de données NoSQL
- **Storage** : Stockage des fichiers
- **Analytics** : Suivi des performances

### Structure Firestore :
```
users/
├── {userId}/
│   ├── email: string
│   ├── displayName: string
│   ├── isPremium: boolean
│   ├── badges: array
│   └── progress: map
```

## 🚀 Commandes Utiles

```bash
# Lancer l'app en mode debug
flutter run

# Lancer sur une plateforme spécifique
flutter run -d chrome    # Web
flutter run -d ios       # iOS
flutter run -d android   # Android

# Build pour production
flutter build web
flutter build ios
flutter build android

# Analyser le code
flutter analyze

# Lancer les tests
flutter test

# Nettoyer le cache
flutter clean
```

## 🎨 Thème et Design

- **Couleur principale** : Bleu (`Colors.blue`)
- **Design System** : Material 3
- **Responsive** : Optimisé pour mobile, tablette et web

## 🔐 Sécurité

- Authentification Firebase
- Règles de sécurité Firestore
- Validation côté client et serveur

## 📱 Plateformes Supportées

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 11+)
- ✅ **Web** (Chrome, Firefox, Safari)

## 🚧 Prochaines Étapes

1. Configuration complète Firebase
2. Implémentation de l'authentification
3. Intégration OpenAI API
4. Développement des fonctionnalités principales
5. Tests et optimisations

## 📄 License

Ce projet est sous licence MIT.