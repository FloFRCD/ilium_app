# 📱 Instructions pour builder Ilium Mobile

## 🛠️ Prérequis Android

### 1. Installer Android Studio
```bash
# Télécharge depuis : https://developer.android.com/studio
# Installe avec les composants par défaut
```

### 2. Configurer Flutter pour Android
```bash
flutter doctor                      # Vérifier l'installation
flutter doctor --android-licenses   # Accepter les licences Android
```

### 3. Créer l'APK
```bash
cd /Users/flofrcd/ilium_app
flutter clean                       # Nettoyer le cache
flutter pub get                     # Récupérer les dépendances
flutter build apk --release         # Créer l'APK de production
```

### 4. Trouver l'APK
```
Le fichier sera dans : build/app/outputs/flutter-apk/app-release.apk
```

## 🌐 Alternative : Test Web Mobile

### Accéder depuis ton téléphone
```bash
# 1. Sur ton Mac, lance :
cd /Users/flofrcd/ilium_app/build/web
python -m http.server 8081

# 2. Trouve l'IP de ton Mac :
ifconfig | grep "inet "

# 3. Sur ton téléphone, va sur :
http://[IP_DE_TON_MAC]:8081
# Exemple : http://192.168.1.100:8081
```

## 🚀 Build Commands Complets

### Web
```bash
flutter build web --release
cd build/web
python -m http.server 8081
```

### Android APK
```bash
flutter build apk --release
# Fichier : build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
# Fichier : build/app/outputs/bundle/release/app-release.aab
```

## 🎨 Caractéristiques du Design Actuel

✅ **Design System :**
- Palette : #667eea, #764ba2, #4ecdc4, #feca57
- Typographie : Inter avec hiérarchie complète
- Gradients et ombres modernes
- Material 3 personnalisé

✅ **Interface :**
- Écran de connexion avec gradient
- Navigation 4 onglets : Accueil, Cours, Sauvegardes, Profil  
- Boutons avec gradients
- Cartes modernes avec ombres

✅ **Fonctionnalités :**
- Système d'authentification
- Progression et badges
- Catalogue de cours
- QCM interactifs
- Mode freemium/premium

## 🐛 Troubleshooting

### Erreur "Android SDK not found"
```bash
# Option 1 : Installer Android Studio
# Option 2 : Configurer manuellement
export ANDROID_HOME=/Users/$USER/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### Erreur de dépendances
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Test sans APK
```bash
# Utilise la version web responsive sur mobile
flutter build web --release
# Accède depuis ton téléphone via l'IP locale
```