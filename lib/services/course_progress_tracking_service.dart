import '../models/user_model.dart';
import '../models/course_model.dart';
import 'user_progression_service.dart';
import 'firestore_service.dart';
import '../utils/logger.dart';

class CourseProgressTrackingService {
  final UserProgressionService _progressionService = UserProgressionService();
  final FirestoreService _firestoreService = FirestoreService();
  
  /// Marque un cours comme commencé
  Future<bool> startCourse(UserModel user, CourseModel course) async {
    try {
      // Enregistrer le début du cours dans la progression utilisateur
      Map<String, dynamic> courseStartData = {
        'course_started': {
          'courseId': course.id,
          'coursTitle': course.title,
          'matiere': course.matiere,
          'startedAt': DateTime.now().toIso8601String(),
        }
      };
      
      // Sauvegarde dans les préférences utilisateur pour traçabilité
      UserModel updatedUser = user.copyWith(
        preferences: {...user.preferences, ...courseStartData},
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      
      // Ajouter de l'XP pour avoir commencé un cours
      await _progressionService.addXP(user.uid, 10, reason: 'Cours commencé: ${course.title}');
      
      return true;
    } catch (e) {
      Logger.error('Erreur démarrage cours: $e');
      return false;
    }
  }
  
  /// Marque un cours comme terminé
  Future<bool> completeCourse(UserModel user, CourseModel course) async {
    try {
      // Utiliser le service de progression pour marquer le cours comme complété
      bool success = await _progressionService.completeCourse(
        user.uid,
        course.matiere,
        course.id,
      );
      
      if (success) {
        // Enregistrer les détails de completion
        Map<String, dynamic> courseCompletionData = {
          'last_completed_course': {
            'courseId': course.id,
            'courseTitle': course.title,
            'matiere': course.matiere,
            'completedAt': DateTime.now().toIso8601String(),
          }
        };
        
        UserModel updatedUser = user.copyWith(
          preferences: {...user.preferences, ...courseCompletionData},
          updatedAt: DateTime.now(),
        );
        
        await _firestoreService.saveUser(updatedUser);
        
        Logger.info('Cours "${course.title}" marqué comme terminé pour ${user.pseudo}');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Erreur completion cours: $e');
      return false;
    }
  }
  
  /// Enregistre le temps passé sur un cours
  Future<bool> recordTimeSpent(UserModel user, CourseModel course, int minutesSpent) async {
    try {
      // Sauvegarder le temps d'étude
      Map<String, dynamic> studyTimeData = {
        'study_sessions': user.preferences['study_sessions'] ?? [],
      };
      
      (studyTimeData['study_sessions'] as List).add({
        'courseId': course.id,
        'courseTitle': course.title,
        'matiere': course.matiere,
        'minutesSpent': minutesSpent,
        'studiedAt': DateTime.now().toIso8601String(),
      });
      
      // Garder seulement les 50 dernières sessions
      if ((studyTimeData['study_sessions'] as List).length > 50) {
        (studyTimeData['study_sessions'] as List).removeAt(0);
      }
      
      UserModel updatedUser = user.copyWith(
        preferences: {...user.preferences, ...studyTimeData},
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      
      // Ajouter de l'XP basé sur le temps d'étude (1 XP par minute)
      await _progressionService.addXP(user.uid, minutesSpent, reason: 'Temps d\'étude: ${course.title}');
      
      return true;
    } catch (e) {
      Logger.error('Erreur enregistrement temps: $e');
      return false;
    }
  }
  
  /// Récupère les statistiques d'étude de l'utilisateur
  Future<Map<String, dynamic>> getStudyStats(UserModel user) async {
    try {
      List<dynamic> studySessions = user.preferences['study_sessions'] ?? [];
      
      if (studySessions.isEmpty) {
        return {
          'totalMinutesStudied': 0,
          'sessionsCount': 0,
          'averageSessionLength': 0,
          'studyBySubject': <String, int>{},
          'studyByWeek': <String, int>{},
        };
      }
      
      int totalMinutes = 0;
      Map<String, int> studyBySubject = {};
      Map<String, int> studyByWeek = {};
      
      for (var session in studySessions) {
        int minutes = session['minutesSpent'] ?? 0;
        String matiere = session['matiere'] ?? 'Inconnu';
        String studiedAt = session['studiedAt'] ?? '';
        
        totalMinutes += minutes;
        studyBySubject[matiere] = (studyBySubject[matiere] ?? 0) + minutes;
        
        // Calculer la semaine
        try {
          DateTime studyDate = DateTime.parse(studiedAt);
          String weekKey = '${studyDate.year}-W${_getWeekNumber(studyDate)}';
          studyByWeek[weekKey] = (studyByWeek[weekKey] ?? 0) + minutes;
        } catch (e) {
          // Ignorer les dates malformées
        }
      }
      
      return {
        'totalMinutesStudied': totalMinutes,
        'sessionsCount': studySessions.length,
        'averageSessionLength': studySessions.isNotEmpty ? totalMinutes / studySessions.length : 0,
        'studyBySubject': studyBySubject,
        'studyByWeek': studyByWeek,
      };
    } catch (e) {
      Logger.error('Erreur récupération stats: $e');
      return {
        'totalMinutesStudied': 0,
        'sessionsCount': 0,
        'averageSessionLength': 0,
        'studyBySubject': <String, int>{},
        'studyByWeek': <String, int>{},
      };
    }
  }
  
  /// Calcule le numéro de la semaine dans l'année
  int _getWeekNumber(DateTime date) {
    int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - 1) / 7).floor() + 1;
  }
  
  /// Vérifie si l'utilisateur peut accéder au cours selon ses limitations
  bool canAccessCourse(UserModel user, CourseModel course) {
    return user.limitations.canAccessCourse(course.isPremium);
  }
  
  /// Enregistre l'ouverture d'un cours (pour les statistiques)
  Future<bool> recordCourseView(UserModel user, CourseModel course) async {
    try {
      Map<String, dynamic> viewData = {
        'recent_views': user.preferences['recent_views'] ?? [],
      };
      
      // Ajouter cette vue
      (viewData['recent_views'] as List).add({
        'courseId': course.id,
        'courseTitle': course.title,
        'matiere': course.matiere,
        'viewedAt': DateTime.now().toIso8601String(),
      });
      
      // Garder seulement les 20 dernières vues
      if ((viewData['recent_views'] as List).length > 20) {
        (viewData['recent_views'] as List).removeAt(0);
      }
      
      UserModel updatedUser = user.copyWith(
        preferences: {...user.preferences, ...viewData},
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.saveUser(updatedUser);
      
      return true;
    } catch (e) {
      Logger.error('Erreur enregistrement vue: $e');
      return false;
    }
  }
}