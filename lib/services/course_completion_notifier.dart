import 'package:flutter/foundation.dart';

/// Service de notification pour les changements de statut des cours
/// Permet aux différents écrans de se synchroniser
class CourseCompletionNotifier extends ChangeNotifier {
  static final CourseCompletionNotifier _instance = CourseCompletionNotifier._internal();
  factory CourseCompletionNotifier() => _instance;
  CourseCompletionNotifier._internal();

  /// Notifie qu'un cours a été terminé
  void notifyCourseCompleted(String userId, String courseId) {
    notifyListeners();
  }

  /// Notifie qu'un cours a été démarré
  void notifyCourseStarted(String userId, String courseId) {
    notifyListeners();
  }

  /// Notifie qu'une progression a été mise à jour
  void notifyProgressUpdated(String userId, String courseId, double progress) {
    notifyListeners();
  }
}