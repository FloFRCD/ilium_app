import '../models/user_model.dart';
import 'firestore_service.dart';
import '../utils/logger.dart';

class UserPreferencesService {
  final FirestoreService _firestoreService = FirestoreService();
  
  /// Met à jour les préférences de l'utilisateur
  Future<bool> updateUserPreferences(String uid, Map<String, dynamic> preferences) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      UserModel updatedUser = user.copyWith(
        preferences: preferences,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      return true;
    } catch (e) {
      Logger.error('Erreur mise à jour préférences', e);
      return false;
    }
  }
  
  /// Met à jour une préférence spécifique
  Future<bool> updateSpecificPreference(String uid, String key, dynamic value) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      Map<String, dynamic> updatedPreferences = Map.from(user.preferences);
      updatedPreferences[key] = value;
      
      return await updateUserPreferences(uid, updatedPreferences);
    } catch (e) {
      Logger.error('Erreur mise à jour préférence', e);
      return false;
    }
  }
  
  /// Met à jour le niveau de l'utilisateur
  Future<bool> updateUserLevel(String uid, String niveau) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      UserModel updatedUser = user.copyWith(
        niveau: niveau,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      return true;
    } catch (e) {
      Logger.error('Erreur mise à jour niveau', e);
      return false;
    }
  }
  
  /// Met à jour le pseudo de l'utilisateur
  Future<bool> updateUserPseudo(String uid, String pseudo) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      UserModel updatedUser = user.copyWith(
        pseudo: pseudo,
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      return true;
    } catch (e) {
      Logger.error('Erreur mise à jour pseudo', e);
      return false;
    }
  }
  
  /// Ajoute un sujet favori
  Future<bool> addFavoriteSubject(String uid, String subject) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      List<String> favoriteSubjects = List<String>.from(
        user.preferences['favoriteSubjects'] ?? []
      );
      
      if (!favoriteSubjects.contains(subject)) {
        favoriteSubjects.add(subject);
        
        return await updateSpecificPreference(uid, 'favoriteSubjects', favoriteSubjects);
      }
      
      return true;
    } catch (e) {
      Logger.error('Erreur ajout sujet favori', e);
      return false;
    }
  }
  
  /// Retire un sujet favori
  Future<bool> removeFavoriteSubject(String uid, String subject) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      List<String> favoriteSubjects = List<String>.from(
        user.preferences['favoriteSubjects'] ?? []
      );
      
      favoriteSubjects.remove(subject);
      
      return await updateSpecificPreference(uid, 'favoriteSubjects', favoriteSubjects);
    } catch (e) {
      Logger.error('Erreur suppression sujet favori', e);
      return false;
    }
  }
  
  /// Met à jour les paramètres de notification
  Future<bool> updateNotificationSettings(String uid, {
    bool? notificationsEnabled,
    bool? studyReminders,
    bool? weeklyGoalReminders,
  }) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      Map<String, dynamic> updatedPreferences = Map.from(user.preferences);
      
      if (notificationsEnabled != null) {
        updatedPreferences['notificationsEnabled'] = notificationsEnabled;
      }
      if (studyReminders != null) {
        updatedPreferences['studyReminders'] = studyReminders;
      }
      if (weeklyGoalReminders != null) {
        updatedPreferences['weeklyGoalReminders'] = weeklyGoalReminders;
      }
      
      return await updateUserPreferences(uid, updatedPreferences);
    } catch (e) {
      Logger.error('Erreur mise à jour notifications', e);
      return false;
    }
  }
  
  /// Met à jour les paramètres d'affichage
  Future<bool> updateDisplaySettings(String uid, {
    bool? darkModeEnabled,
    String? preferredDifficulty,
  }) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      Map<String, dynamic> updatedPreferences = Map.from(user.preferences);
      
      if (darkModeEnabled != null) {
        updatedPreferences['darkModeEnabled'] = darkModeEnabled;
      }
      if (preferredDifficulty != null) {
        updatedPreferences['preferredDifficulty'] = preferredDifficulty;
      }
      
      return await updateUserPreferences(uid, updatedPreferences);
    } catch (e) {
      Logger.error('Erreur mise à jour affichage', e);
      return false;
    }
  }
  
  /// Sauvegarde automatique des paramètres utilisateur
  Future<bool> autoSaveUserData(String uid, Map<String, dynamic> dataToSave) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;
      
      UserModel updatedUser = user.copyWith(
        preferences: {...user.preferences, ...dataToSave},
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      return true;
    } catch (e) {
      Logger.error('Erreur sauvegarde automatique', e);
      return false;
    }
  }
  
  /// Récupère les préférences utilisateur
  Future<Map<String, dynamic>?> getUserPreferences(String uid) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      return user?.preferences;
    } catch (e) {
      Logger.error('Erreur récupération préférences', e);
      return null;
    }
  }
  
  /// Vérifie si une préférence existe
  Future<T?> getPreference<T>(String uid, String key) async {
    try {
      final preferences = await getUserPreferences(uid);
      return preferences?[key] as T?;
    } catch (e) {
      Logger.error('Erreur récupération préférence $key', e);
      return null;
    }
  }

  /// Récupère les données utilisateur mises à jour depuis Firebase
  Future<UserModel?> getUpdatedUser(String uid) async {
    try {
      return await _firestoreService.getUser(uid);
    } catch (e) {
      Logger.error('Erreur récupération utilisateur: $e');
      return null;
    }
  }
}