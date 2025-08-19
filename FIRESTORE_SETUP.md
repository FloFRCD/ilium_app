# Configuration Firestore - Index

## 🔥 Problème des Index Manquants

L'erreur suivante indique qu'un index Firestore composite est requis :

```
[cloud_firestore/failed-precondition] The query requires an index. You can create it here: https://console.firebase.google.com/...
```

## ✅ Solution

### Option 1: Déploiement Automatique (Recommandé)

```bash
# Rendre le script exécutable
chmod +x scripts/deploy_firestore_indexes.sh

# Déployer les index
./scripts/deploy_firestore_indexes.sh
```

### Option 2: Création Manuelle

1. **Accédez à la console Firebase** : [https://console.firebase.google.com/project/ilium-4d0ab/firestore/indexes](https://console.firebase.google.com/project/ilium-4d0ab/firestore/indexes)

2. **Créez les index suivants** :

#### Index 1: course_status (userId + lastAccessedAt)
- Collection: `course_status`
- Champs:
  - `userId` (Ascending)
  - `lastAccessedAt` (Descending)

#### Index 2: course_status (userId + status + lastAccessedAt)
- Collection: `course_status`
- Champs:
  - `userId` (Ascending)
  - `status` (Ascending)
  - `lastAccessedAt` (Descending)

### Option 3: URL Directe

Cliquez sur le lien fourni dans l'erreur pour créer automatiquement l'index manquant.

## 📋 Index Configurés

Le fichier `firestore.indexes.json` contient la configuration complète des index :

```json
{
  "indexes": [
    {
      "collectionGroup": "course_status",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "lastAccessedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "course_status", 
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "lastAccessedAt", "order": "DESCENDING"}
      ]
    }
  ]
}
```

## ⏱️ Temps de Création

- **Index simples** : 1-5 minutes
- **Index complexes** : 5-15 minutes
- **Gros datasets** : Jusqu'à plusieurs heures

## 🔧 Solution Temporaire

En attendant que les index soient créés, le code utilise :
- Requêtes simples sans `orderBy`
- Tri en mémoire côté client
- Filtrage en mémoire si nécessaire

## 🚨 Performances

⚠️ **Important** : Une fois les index créés, réactivez les requêtes optimisées dans `CourseStatusService` pour de meilleures performances.

## 📝 Vérification

Pour vérifier que les index sont actifs :

1. Allez dans Firebase Console > Firestore > Index
2. Vérifiez que le statut est "Activé" (vert)
3. Testez l'application - les erreurs d'index doivent disparaître

## 🔍 Debug

Si les erreurs persistent :

```bash
# Vérifier les index déployés
firebase firestore:indexes --project ilium-4d0ab

# Logs détaillés
flutter run --verbose
```