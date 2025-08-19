import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../utils/logger.dart';

/// Service pour suivre l'utilisation mensuelle des utilisateurs
class UsageTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Enregistre qu'un utilisateur a consulté un cours complet
  Future<bool> recordFullCourseAccess(String userId, String courseId) async {
    try {
      String currentMonth = _getCurrentMonthKey();
      
      await _firestore.collection('user_usage').doc(userId).set({
        'fullCourses.$currentMonth': FieldValue.arrayUnion([
          {
            'courseId': courseId,
            'accessedAt': DateTime.now().toIso8601String(),
          }
        ])
      }, SetOptions(merge: true));
      
      Logger.info('Recorded full course access: $courseId for user $userId');
      return true;
    } catch (e) {
      Logger.error('Failed to record full course access', e);
      return false;
    }
  }

  /// Récupère le nombre de cours complets consultés ce mois-ci
  Future<int> getFullCoursesThisMonth(String userId) async {
    try {
      String currentMonth = _getCurrentMonthKey();
      
      DocumentSnapshot doc = await _firestore.collection('user_usage').doc(userId).get();
      if (!doc.exists) return 0;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic>? fullCourses = data['fullCourses']?[currentMonth];
      
      return fullCourses?.length ?? 0;
    } catch (e) {
      Logger.error('Failed to get full courses count', e);
      return 0;
    }
  }

  /// Enregistre qu'un utilisateur a fait un QCM
  Future<bool> recordQCMAccess(String userId, String courseId, String difficulty) async {
    try {
      String currentMonth = _getCurrentMonthKey();
      
      await _firestore.collection('user_usage').doc(userId).set({
        'qcms.$currentMonth': FieldValue.arrayUnion([
          {
            'courseId': courseId,
            'difficulty': difficulty,
            'accessedAt': DateTime.now().toIso8601String(),
          }
        ])
      }, SetOptions(merge: true));
      
      Logger.info('Recorded QCM access: $courseId ($difficulty) for user $userId');
      return true;
    } catch (e) {
      Logger.error('Failed to record QCM access', e);
      return false;
    }
  }

  /// Récupère le nombre de QCM faits ce mois-ci
  Future<int> getQCMsThisMonth(String userId) async {
    try {
      String currentMonth = _getCurrentMonthKey();
      
      DocumentSnapshot doc = await _firestore.collection('user_usage').doc(userId).get();
      if (!doc.exists) return 0;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic>? qcms = data['qcms']?[currentMonth];
      
      return qcms?.length ?? 0;
    } catch (e) {
      Logger.error('Failed to get QCMs count', e);
      return 0;
    }
  }

  /// Enregistre l'accès à un contenu vulgarisé ou fiche
  Future<bool> recordPremiumContentAccess(String userId, String courseId, CourseType type) async {
    try {
      String currentMonth = _getCurrentMonthKey();
      String contentType = type == CourseType.vulgarise ? 'vulgarise' : 'fiches';
      
      await _firestore.collection('user_usage').doc(userId).set({
        '$contentType.$currentMonth': FieldValue.arrayUnion([
          {
            'courseId': courseId,
            'accessedAt': DateTime.now().toIso8601String(),
          }
        ])
      }, SetOptions(merge: true));
      
      Logger.info('Recorded $contentType access: $courseId for user $userId');
      return true;
    } catch (e) {
      Logger.error('Failed to record premium content access', e);
      return false;
    }
  }

  /// Récupère les statistiques d'utilisation pour l'utilisateur
  Future<Map<String, int>> getUsageStats(String userId) async {
    try {
      String currentMonth = _getCurrentMonthKey();
      
      DocumentSnapshot doc = await _firestore.collection('user_usage').doc(userId).get();
      if (!doc.exists) {
        return {
          'fullCourses': 0,
          'qcms': 0,
          'vulgarise': 0,
          'fiches': 0,
        };
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      return {
        'fullCourses': (data['fullCourses']?[currentMonth] as List?)?.length ?? 0,
        'qcms': (data['qcms']?[currentMonth] as List?)?.length ?? 0,
        'vulgarise': (data['vulgarise']?[currentMonth] as List?)?.length ?? 0,
        'fiches': (data['fiches']?[currentMonth] as List?)?.length ?? 0,
      };
    } catch (e) {
      Logger.error('Failed to get usage stats', e);
      return {
        'fullCourses': 0,
        'qcms': 0,
        'vulgarise': 0,
        'fiches': 0,
      };
    }
  }

  /// Génère la clé du mois actuel (format: YYYY-MM)
  String _getCurrentMonthKey() {
    DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}