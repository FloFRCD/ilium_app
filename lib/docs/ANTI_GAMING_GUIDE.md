# Guide du Système Anti-Gaming

## Vue d'ensemble

Le système anti-gaming d'Ilium empêche les utilisateurs de tricher pour obtenir de l'XP en validant que les activités ont été réellement effectuées avec un engagement approprié.

## Architecture

### Services Principaux

1. **AntiGamingService** - Service centralisé de validation
2. **XPAwardService** - Attribution d'XP avec validation intégrée  
3. **SecuredProgressionService** - Wrapper sécurisé pour UserProgressionService

### Flux de Validation

```
Activité Utilisateur → Tracking Temps/Engagement → Validation Anti-Gaming → Attribution XP
```

## Types d'Activités Validées

### 1. Lecture de Cours (`course_reading`)

**Critères de validation :**
- ✅ Temps minimum : 60 secondes de lecture active
- ✅ Progression scrolling : 80% du contenu minimum
- ✅ Pauses de lecture : 3 minimum (preuve d'attention)
- ✅ Lecture jusqu'à la fin obligatoire

**Implémentation :**
```dart
// Dans CourseReaderScreen
bool _canMarkAsCompleted() {
  final validation = AntiGamingService.validateActivity(
    activityType: 'course_reading',
    totalTimeSeconds: _totalReadingTimeSeconds,
    minimumTimeRequired: 60,
    additionalData: {
      'maxScrollProgress': _maxScrollPosition,
      'scrollMilestones': _scrollMilestones.length,
      'hasScrolledToEnd': _hasScrolledToEnd,
    },
  );
  return validation.isValid;
}
```

### 2. Completion de QCM (`qcm_completion`)

**Critères de validation :**
- ✅ Temps minimum total : 30 secondes
- ✅ Temps par question : 10 secondes minimum sur 50% des questions
- ✅ Taux d'engagement : 60% minimum (temps actif / temps total)

**Implémentation :**
```dart
// Dans QCMScreen
bool _canAwardXP() {
  final validation = AntiGamingService.validateActivity(
    activityType: 'qcm_completion',
    totalTimeSeconds: _totalActiveTimeSeconds,
    minimumTimeRequired: 30,
    additionalData: {
      'questionTimesSeconds': _questionTimeSeconds,
      'engagementRate': engagementRate,
    },
  );
  return validation.isValid;
}
```

### 3. Activités de Badges (`badge_activity`)

**Critères selon le type :**
- **Connexion quotidienne** : 30 secondes minimum + activité réelle
- **Maintien de série** : 60 secondes minimum + activité réelle

## Comment Ajouter la Validation à une Nouvelle Feature

### Étape 1 : Tracking de l'Activité

```dart
class MaFeatureScreen extends StatefulWidget {
  // Variables de tracking
  DateTime? _startTime;
  int _totalActiveTimeSeconds = 0;
  Timer? _activityTimer;
  
  void _startTracking() {
    _startTime = DateTime.now();
    _activityTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Incrémenter seulement si utilisateur actif
      if (_isUserActive()) {
        _totalActiveTimeSeconds++;
      }
    });
  }
}
```

### Étape 2 : Validation avant Attribution XP

```dart
Future<void> _completeActivity() async {
  final validation = AntiGamingService.validateActivity(
    activityType: 'mon_type_activite',
    totalTimeSeconds: _totalActiveTimeSeconds,
    minimumTimeRequired: 45, // Minimum requis
    additionalData: {
      'customMetric1': _maMetrique1,
      'customMetric2': _maMetrique2,
    },
  );
  
  if (!validation.isValid) {
    _showValidationError(validation.primaryReason);
    return;
  }
  
  // Attribuer l'XP
  final result = await XPAwardService().awardXP(
    userId: widget.user.uid,
    xpAmount: 25,
    activityType: 'mon_type_activite',
    totalTimeSeconds: _totalActiveTimeSeconds,
    minimumTimeRequired: 45,
    additionalData: additionalData,
  );
}
```

### Étape 3 : Ajouter la Validation au Service Anti-Gaming

```dart
// Dans AntiGamingService._validateCustomActivity()
static List<String> _validateCustomActivity(int totalTime, Map<String, dynamic>? data) {
  List<String> violations = [];
  
  if (data != null) {
    // Vos critères de validation spécifiques
    int? customMetric = data['customMetric1'] as int?;
    if (customMetric != null && customMetric < 5) {
      violations.add('Métrique insuffisante: $customMetric / 5 requis');
    }
  }
  
  return violations;
}
```

## Bonnes Pratiques

### 1. Tracking Utilisateur Actif
- Marquer l'activité sur les interactions (tap, scroll, etc.)
- Timer avec timeout pour détecter l'inactivité
- Ne compter que le temps d'engagement réel

### 2. Messages d'Erreur Utiles
- Expliquer clairement pourquoi la validation échoue
- Donner des indications sur ce qu'il faut faire
- Éviter les messages techniques

### 3. Logging et Monitoring
- Logger toutes les tentatives de triche
- Tracker les taux de validation par feature
- Alertes sur les patterns suspects

## Exemple Complet : Nouvelle Feature "Quiz Rapide"

```dart
class QuizRapideScreen extends StatefulWidget {
  // Tracking variables
  DateTime? _startTime;
  int _totalActiveSeconds = 0;
  Timer? _trackingTimer;
  DateTime? _lastActivityTime;
  
  @override
  void initState() {
    super.initState();
    _startTracking();
  }
  
  void _startTracking() {
    _startTime = DateTime.now();
    _lastActivityTime = DateTime.now();
    
    _trackingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_lastActivityTime != null && 
          DateTime.now().difference(_lastActivityTime!).inSeconds <= 10) {
        _totalActiveSeconds++;
      }
    });
  }
  
  void _markActivity() {
    _lastActivityTime = DateTime.now();
  }
  
  Future<void> _finishQuiz() async {
    final validation = AntiGamingService.validateActivity(
      activityType: 'quiz_rapide',
      totalTimeSeconds: _totalActiveSeconds,
      minimumTimeRequired: 30,
      additionalData: {
        'questionsAnswered': _questionsAnswered,
        'averageTimePerQuestion': _totalActiveSeconds / _questionsAnswered,
      },
    );
    
    if (!validation.isValid) {
      _showError(validation.primaryReason);
      return;
    }
    
    // Attribuer XP via le service sécurisé
    final xpResult = await XPAwardService().awardXP(
      userId: widget.user.uid,
      xpAmount: 15,
      activityType: 'quiz_rapide',
      totalTimeSeconds: _totalActiveSeconds,
      minimumTimeRequired: 30,
      reason: 'Quiz rapide complété',
    );
    
    if (xpResult.wasAwarded) {
      _showSuccess();
    } else {
      _showError(xpResult.reason);
    }
  }
}
```

## Métadonnées de Validation

Toutes les validations génèrent des métadonnées pour le debugging :

```dart
final metadata = validation.toMetadata();
// {
//   'validated': false,
//   'activityType': 'course_reading',
//   'totalTimeSeconds': 45,
//   'violations': ['Temps insuffisant: 45s / 60s requis'],
//   'timestamp': '2024-01-15T10:30:00.000Z'
// }
```

## Impact Utilisateur

### Messages d'Interface
- ✅ **Validation réussie** : XP accordé normalement
- ⚠️ **Validation échouée** : Message explicatif + suggestions
- 🔄 **En cours** : Indicateurs de progression des critères

### Expérience Utilisateur
- Feedback en temps réel sur les critères
- Pas de punition, juste pas d'XP non mérité
- Encouragement à l'engagement réel

## Monitoring

### Métriques à Suivre
- Taux de validation par feature
- Temps moyen d'engagement
- Tentatives de triche détectées
- Impact sur la rétention utilisateur

### Alertes
- Spike de validations échouées
- Patterns suspects récurrents
- Dégradation des métriques d'engagement