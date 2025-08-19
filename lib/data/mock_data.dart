import '../models/models.dart';
import '../models/progression_model.dart';
import '../models/freemium_limitations_model.dart';

class MockData {
  static List<CourseModel> getMockCourses() {
    DateTime now = DateTime.now();
    
    return [
      CourseModel(
        id: '1',
        title: 'Les équations du second degré',
        matiere: 'Mathématiques',
        niveau: 'Première',
        type: CourseType.cours,
        content: '''
# Les équations du second degré

## Introduction
Une équation du second degré est une équation de la forme ax² + bx + c = 0 où a ≠ 0.

## Résolution
Pour résoudre une équation du second degré, on utilise le discriminant Δ = b² - 4ac.

### Cas 1: Δ > 0
L'équation admet deux solutions réelles distinctes :
- x₁ = (-b + √Δ) / (2a)
- x₂ = (-b - √Δ) / (2a)

### Cas 2: Δ = 0
L'équation admet une solution double :
- x = -b / (2a)

### Cas 3: Δ < 0
L'équation n'admet pas de solution réelle.

## Exemple
Résolvons x² - 5x + 6 = 0
- a = 1, b = -5, c = 6
- Δ = (-5)² - 4(1)(6) = 25 - 24 = 1
- x₁ = (5 + 1) / 2 = 3
- x₂ = (5 - 1) / 2 = 2

Vérification : 3² - 5(3) + 6 = 9 - 15 + 6 = 0 ✓
        ''',
        popularity: 145,
        votes: {'up': 23, 'down': 2},
        commentaires: [
          {
            'userId': 'user1',
            'userName': 'Marie',
            'comment': 'Très clair, merci !',
            'createdAt': now.subtract(Duration(hours: 2)),
          }
        ],
        authorId: 'author1',
        authorName: 'Prof. Dupont',
        createdAt: now.subtract(Duration(days: 2)),
        updatedAt: now.subtract(Duration(days: 1)),
      ),
      CourseModel(
        id: '2',
        title: 'La révolution française',
        matiere: 'Histoire',
        niveau: 'Quatrième',
        type: CourseType.vulgarise,
        content: '''
# La Révolution française (1789-1799)

## Contexte
En 1789, la France traverse une grave crise financière. Le roi Louis XVI convoque les États-Généraux.

## Les causes
- Crise financière de l'État
- Inégalités sociales
- Influence des idées des Lumières

## Chronologie
### 1789
- 5 mai : Ouverture des États-Généraux
- 20 juin : Serment du Jeu de paume
- 14 juillet : Prise de la Bastille

### 1792
- Proclamation de la République

### 1793-1794
- La Terreur

## Conséquences
- Abolition de l'Ancien Régime
- Déclaration des droits de l'homme et du citoyen
- Naissance de la République
        ''',
        popularity: 89,
        votes: {'up': 15, 'down': 1},
        commentaires: [],
        authorId: 'author2',
        authorName: 'Prof. Martin',
        createdAt: now.subtract(Duration(days: 5)),
        updatedAt: now.subtract(Duration(days: 3)),
      ),
      CourseModel(
        id: '3',
        title: 'Les liaisons chimiques',
        matiere: 'Chimie',
        niveau: 'Terminale',
        type: CourseType.fiche,
        content: '''
# Les liaisons chimiques - Fiche de révision

## Types de liaisons
- **Liaison ionique** : transfert d'électrons
- **Liaison covalente** : mise en commun d'électrons
- **Liaison métallique** : mer d'électrons

## Liaison ionique
- Entre métal et non-métal
- Formation d'ions (cation + anion)
- Exemple : NaCl (Na⁺ + Cl⁻)

## Liaison covalente
- Entre non-métaux
- Partage d'électrons
- Simple, double ou triple
- Exemple : H₂O, CO₂

## Propriétés
- Ionique : soluble dans l'eau, conducteur fondu
- Covalente : point de fusion variable, isolant

## À retenir
- Règle de l'octet
- Électronégativité
- Géométrie moléculaire
        ''',
        popularity: 67,
        votes: {'up': 12, 'down': 0},
        commentaires: [],
        authorId: 'author3',
        authorName: 'Dr. Lemoine',
        createdAt: now.subtract(Duration(days: 1)),
        updatedAt: now.subtract(Duration(days: 1)),
      ),
    ];
  }

  static List<QCMModel> getMockQCMs() {
    DateTime now = DateTime.now();
    
    return [
      QCMModel(
        id: 'qcm1',
        courseId: '1',
        title: 'QCM - Équations du second degré',
        questions: [
          QuestionModel(
            id: '1',
            question: 'Quelle est la forme générale d\'une équation du second degré ?',
            options: [
              'ax + b = 0',
              'ax² + bx + c = 0',
              'ax³ + bx² + cx + d = 0',
              'ax² + b = 0'
            ],
            correctAnswer: 1,
            explanation: 'Une équation du second degré a la forme ax² + bx + c = 0 avec a ≠ 0.',
          ),
          QuestionModel(
            id: '2',
            question: 'Que vaut le discriminant Δ pour l\'équation x² - 4x + 4 = 0 ?',
            options: [
              'Δ = 0',
              'Δ = 4',
              'Δ = 16',
              'Δ = -4'
            ],
            correctAnswer: 0,
            explanation: 'Δ = b² - 4ac = (-4)² - 4(1)(4) = 16 - 16 = 0',
          ),
        ],
        minimumSuccessRate: 70,
        difficulty: QCMDifficulty.moyen,
        createdAt: now.subtract(Duration(days: 1)),
        updatedAt: now.subtract(Duration(days: 1)),
      ),
    ];
  }

  static UserModel getMockUser() {
    DateTime now = DateTime.now();
    
    return UserModel(
      uid: 'user123',
      pseudo: 'Alex',
      email: 'alex@example.com',
      niveau: 'Première',
      status: UserStatus.active,
      subscriptionType: SubscriptionType.free,
      badges: [],
      progression: GlobalProgressionModel(
        totalXp: 1250,
        currentLevel: 3,
        xpToNextLevel: 750,
        tier: UserTier.silver,
        totalCoursCompleted: 12,
        totalQcmPassed: 28,
        totalStreakDays: 5,
        maxStreakDays: 15,
        currentStreak: 3,
        memberSince: now.subtract(Duration(days: 30)),
        lastLoginDate: now,
        subjectProgressions: {},
        achievements: [],
        overallAverageScore: 78.5,
      ),
      createdAt: now.subtract(Duration(days: 30)),
      updatedAt: now,
      preferences: {'notifications': true, 'darkMode': false},
      limitations: FreemiumLimitationsModel.free(),
    );
  }

  static List<String> getMatieres() {
    return [
      'Mathématiques',
      'Français',
      'Histoire',
      'Géographie',
      'Physique',
      'Chimie',
      'SVT',
      'Anglais',
      'Espagnol',
      'Philosophie',
    ];
  }

  static List<String> getNiveaux() {
    return [
      'Sixième',
      'Cinquième',
      'Quatrième',
      'Troisième',
      'Seconde',
      'Première',
      'Terminale',
    ];
  }
}