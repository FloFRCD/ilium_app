import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/progression_model.dart';
import '../models/freemium_limitations_model.dart';
import 'firestore_service.dart';
import 'user_progression_service.dart';
import '../utils/progression_migration.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final UserProgressionService _progressionService = UserProgressionService();
  final ProgressionMigrationService _migrationService = ProgressionMigrationService();
  
  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;
  
  /// Inscription avec email et mot de passe
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String pseudo,
    required String niveau,
    List<String>? options,
    DateTime? birthDate,
  }) async {
    try {
      debugPrint('🚀 DÉBUT registerWithEmailAndPassword');
      debugPrint('  email: $email');
      debugPrint('  password: [${password.length} caractères]');
      debugPrint('  pseudo: $pseudo');
      debugPrint('  niveau: $niveau');
      debugPrint('  options: $options');
      debugPrint('  birthDate: $birthDate');
      
      // Créer le compte Firebase Auth
      debugPrint('🔥 Tentative création compte Firebase Auth...');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Compte Firebase Auth créé avec succès');
      
      User? firebaseUser = result.user;
      if (firebaseUser != null) {
        // Mettre à jour le nom d'affichage
        debugPrint('🔄 Mise à jour du nom d\'affichage...');
        try {
          await firebaseUser.updateDisplayName(pseudo);
          debugPrint('✅ Nom d\'affichage mis à jour');
        } catch (e) {
          debugPrint('❌ Erreur mise à jour nom: $e');
          // Continue même si la mise à jour du nom échoue
        }
        
        DateTime now = DateTime.now();
        
        debugPrint('🔄 Création du profil utilisateur...');
        debugPrint('  uid: ${firebaseUser.uid}');
        debugPrint('  pseudo: $pseudo');
        debugPrint('  email: $email');
        debugPrint('  niveau: $niveau');
        debugPrint('  options: $options');
        debugPrint('  birthDate: $birthDate');
        
        // Créer d'abord la progression
        debugPrint('🔄 Création de GlobalProgressionModel...');
        GlobalProgressionModel progression;
        try {
          progression = GlobalProgressionModel(
            totalXp: 0,
            currentLevel: 1,
            xpToNextLevel: 100,
            tier: UserTier.bronze,
            totalCoursCompleted: 0,
            totalQcmPassed: 0,
            totalStreakDays: 0,
            maxStreakDays: 0,
            currentStreak: 0,
            memberSince: now,
            lastLoginDate: now,
            subjectProgressions: {},
            achievements: [],
            overallAverageScore: 0.0,
          );
          debugPrint('✅ GlobalProgressionModel créé avec succès');
        } catch (e) {
          debugPrint('❌ Erreur lors de la création de GlobalProgressionModel: $e');
          rethrow;
        }
        
        // Créer les limitations
        debugPrint('🔄 Création de FreemiumLimitationsModel...');
        FreemiumLimitationsModel limitations;
        try {
          limitations = FreemiumLimitationsModel.free();
          debugPrint('✅ FreemiumLimitationsModel créé avec succès');
        } catch (e) {
          debugPrint('❌ Erreur lors de la création de FreemiumLimitationsModel: $e');
          rethrow;
        }
        
        // Créer le profil utilisateur dans Firestore
        debugPrint('🔄 Création de UserModel...');
        UserModel newUser;
        try {
          newUser = UserModel(
            uid: firebaseUser.uid,
            pseudo: pseudo,
            email: email,
            niveau: niveau,
            options: options ?? [],
            birthDate: birthDate,
            status: UserStatus.active,
            subscriptionType: SubscriptionType.free,
            badges: [],
            progression: progression,
            limitations: limitations,
            preferences: {
              'notificationsEnabled': true,
              'darkModeEnabled': false,
              'preferredDifficulty': 'moyen',
              'favoriteSubjects': <String>[],
              'studyReminders': true,
              'weeklyGoalReminders': true,
            },
            createdAt: now,
            updatedAt: now,
          );
          debugPrint('✅ UserModel créé avec succès');
        } catch (e) {
          debugPrint('❌ Erreur lors de la création de UserModel: $e');
          rethrow;
        }
        
        // Sauvegarder dans Firestore
        debugPrint('🔥 Tentative de sauvegarde dans Firestore...');
        bool firestoreSaved = await _firestoreService.saveUser(newUser);
        
        if (!firestoreSaved) {
          debugPrint('❌ Échec de la sauvegarde Firestore');
          // L'utilisateur Firebase Auth existe mais pas les données Firestore
          // On peut soit supprimer le compte Firebase, soit continuer sans les données
          return AuthResult.error('Erreur lors de la sauvegarde des données utilisateur');
        }
        
        debugPrint('✅ Utilisateur sauvegardé dans Firestore');
        return AuthResult.success(newUser);
      } else {
        return AuthResult.error('Erreur lors de la création du compte');
      }
    } catch (e) {
      debugPrint('🚨 ERREUR COMPLÈTE D\'INSCRIPTION:');
      debugPrint('   Type: ${e.runtimeType}');
      debugPrint('   Message: $e');
      
      if (e is FirebaseAuthException) {
        debugPrint('   Code Firebase: ${e.code}');
        debugPrint('   Message Firebase: ${e.message}');
        debugPrint('   Plugin: ${e.plugin}');
      }
      
      String errorMessage = _getAuthErrorMessage(e);
      debugPrint('   Message traité: $errorMessage');
      
      return AuthResult.error(errorMessage);
    }
  }
  
  /// Connexion avec email et mot de passe
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? firebaseUser = result.user;
      if (firebaseUser != null) {
        // Récupérer le profil utilisateur depuis Firestore
        UserModel? user = await _firestoreService.getUser(firebaseUser.uid);
        
        if (user != null) {
          // Migrer les progressions si nécessaire (une seule fois)
          await _migrationService.migrateUserProgressions(user.uid);
          
          // Mettre à jour la streak et la dernière connexion
          await _progressionService.updateStreak(user.uid);
          
          // Récupérer l'utilisateur mis à jour après la streak et migration
          UserModel? updatedUser = await _firestoreService.getUser(user.uid);
          if (updatedUser != null) {
            return AuthResult.success(updatedUser);
          } else {
            return AuthResult.success(user); // Fallback si récupération échoue
          }
        } else {
          return AuthResult.error('Profil utilisateur introuvable');
        }
      } else {
        return AuthResult.error('Erreur de connexion');
      }
    } catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e));
    }
  }
  
  /// Récupérer l'utilisateur actuel
  Future<UserModel?> getCurrentUserProfile() async {
    User? firebaseUser = currentUser;
    if (firebaseUser != null) {
      try {
        UserModel? user = await _firestoreService.getUser(firebaseUser.uid);
        if (user != null) {
          return user;
        }
        
        // Si l'utilisateur n'existe pas dans Firestore, créer un profil temporaire
        debugPrint('⚠️ Utilisateur Firebase trouvé mais pas de profil Firestore - création d\'un profil temporaire');
        return _createTemporaryUserProfile(firebaseUser);
        
      } catch (e) {
        debugPrint('🚨 Erreur Firestore (probablement permissions): $e');
        
        // En cas d'erreur de permissions, créer un profil temporaire
        if (e.toString().contains('permission-denied')) {
          debugPrint('🔧 Création d\'un profil temporaire en attendant la configuration Firestore');
          return _createTemporaryUserProfile(firebaseUser);
        }
        
        // Pour les autres erreurs, retourner null
        return null;
      }
    }
    return null;
  }
  
  /// Créer un profil utilisateur temporaire en cas de problème Firestore
  UserModel _createTemporaryUserProfile(User firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      pseudo: firebaseUser.displayName ?? 'Utilisateur',
      email: firebaseUser.email ?? '',
      niveau: 'Terminale',
      status: UserStatus.active,
      subscriptionType: SubscriptionType.free,
      badges: [],
      progression: GlobalProgressionModel(
        totalXp: 0,
        currentLevel: 1,
        xpToNextLevel: 100,
        tier: UserTier.bronze,
        totalCoursCompleted: 0,
        totalQcmPassed: 0,
        totalStreakDays: 0,
        maxStreakDays: 0,
        currentStreak: 0,
        memberSince: DateTime.now(),
        lastLoginDate: DateTime.now(),
        subjectProgressions: {},
        achievements: [],
        overallAverageScore: 0.0,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      preferences: {
        'notificationsEnabled': true,
        'darkModeEnabled': false,
        'preferredDifficulty': 'moyen',
        'favoriteSubjects': <String>[],
        'studyReminders': true,
        'weeklyGoalReminders': true,
      },
      limitations: FreemiumLimitationsModel.free(),
    );
  }
  
  /// Déconnexion
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
      return false;
    }
  }
  
  /// Réinitialisation du mot de passe
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null, message: 'Email de réinitialisation envoyé');
    } catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e));
    }
  }
  
  /// Suppression du compte
  Future<AuthResult> deleteAccount() async {
    try {
      User? user = currentUser;
      if (user != null) {
        // Supprimer les données Firestore (à implémenter si nécessaire)
        // await _firestoreService.deleteUser(user.uid);
        
        // Supprimer le compte Firebase Auth
        await user.delete();
        
        return AuthResult.success(null, message: 'Compte supprimé avec succès');
      } else {
        return AuthResult.error('Aucun utilisateur connecté');
      }
    } catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e));
    }
  }
  
  /// Vérifier si l'utilisateur est connecté
  bool get isSignedIn => currentUser != null;
  
  /// Messages d'erreur en français
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé';
        case 'weak-password':
          return 'Le mot de passe est trop faible';
        case 'invalid-email':
          return 'Email invalide';
        case 'user-disabled':
          return 'Ce compte a été désactivé';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard';
        case 'operation-not-allowed':
          return 'Opération non autorisée - vérifiez la configuration Firebase';
        case 'network-request-failed':
          return 'Erreur de réseau - vérifiez votre connexion internet';
        default:
          return 'Erreur d\'authentification: ${error.code} - ${error.message}';
      }
    } else if (error.toString().contains('firebase_core')) {
      return 'Erreur de configuration Firebase - vérifiez firebase_options.dart';
    } else if (error.toString().contains('network')) {
      return 'Erreur de réseau - vérifiez votre connexion internet';
    } else if (error.toString().toLowerCase().contains('permission')) {
      return 'Erreur de permissions - vérifiez la configuration Firebase';
    }
    
    // Pour les erreurs génériques, on donne plus d'infos
    String errorStr = error.toString();
    if (errorStr.length > 100) {
      errorStr = '${errorStr.substring(0, 100)}...';
    }
    
    return 'Erreur technique: $errorStr';
  }
}

/// Classe pour les résultats d'authentification
class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? error;
  final String? message;
  
  AuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
    this.message,
  });
  
  factory AuthResult.success(UserModel? user, {String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      message: message,
    );
  }
  
  factory AuthResult.error(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}