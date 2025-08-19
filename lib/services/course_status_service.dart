import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/course_status_model.dart';
import '../utils/logger.dart';
import 'user_progression_service.dart';
import 'course_completion_notifier.dart';

/// Service unifié pour gérer le statut et la progression des cours
class CourseStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserProgressionService _progressionService = UserProgressionService();
  final CourseCompletionNotifier _notifier = CourseCompletionNotifier();

  /// Démarre un cours (le marque comme "en cours") - seulement si progression >= 10%
  Future<bool> startCourse({
    required String userId,
    required String courseId,
    Map<String, dynamic>? metadata,
    double initialProgress = 0.1,
  }) async {
    // Validation des paramètres d'entrée
    if (userId.isEmpty || courseId.isEmpty) {
      Logger.error('startCourse: userId ou courseId vide - userId: "$userId", courseId: "$courseId"');
      return false;
    }
    
    // Un cours ne peut être démarré que s'il a au moins 10% de progression
    if (initialProgress < 0.1) {
      Logger.info('startCourse: progression insuffisante (${(initialProgress * 100).toInt()}%) pour démarrer le cours $courseId');
      return false;
    }
    
    try {
      final now = DateTime.now();
      final statusModel = CourseStatusModel(
        userId: userId,
        courseId: courseId,
        status: CourseStatus.inProgress,
        statusUpdatedAt: now,
        progress: initialProgress,
        lastAccessedAt: now,
        timeSpentMinutes: 0,
        metadata: metadata ?? {},
      );

      await _firestore
          .collection('course_status')
          .doc('${userId}_$courseId')
          .set(statusModel.toFirestore());

      // Notifier les autres écrans du changement
      _notifier.notifyCourseStarted(userId, courseId);

      Logger.info('Cours $courseId démarré pour utilisateur $userId avec ${(initialProgress * 100).toInt()}% de progression');
      return true;
    } catch (e) {
      Logger.error('Erreur démarrage cours', e);
      return false;
    }
  }

  /// Met à jour la progression d'un cours
  Future<bool> updateProgress({
    required String userId,
    required String courseId,
    required double progress,
    int? additionalTimeMinutes,
    Map<String, dynamic>? metadata,
  }) async {
    // Validation des paramètres d'entrée
    if (userId.isEmpty || courseId.isEmpty) {
      Logger.error('updateProgress: userId ou courseId vide - userId: "$userId", courseId: "$courseId"');
      return false;
    }
    
    try {
      final docId = '${userId}_$courseId';
      final docRef = _firestore.collection('course_status').doc(docId);
      
      // Récupérer le statut existant
      final doc = await docRef.get();
      if (!doc.exists) {
        // Si pas de statut existant et moins de 10% de progression, ne pas créer de statut
        if (progress < 0.1) {
          Logger.info('Cours $courseId: progression < 10%, pas de statut créé');
          return true; // Retourner true car l'opération est valide
        }
        // Si plus de 10%, démarrer le cours avec la progression actuelle
        return await startCourse(
          userId: userId, 
          courseId: courseId, 
          metadata: metadata,
          initialProgress: progress,
        );
      }

      final existingStatus = CourseStatusModel.fromFirestore(doc);
      final newTimeSpent = existingStatus.timeSpentMinutes + (additionalTimeMinutes ?? 0);
      
      // Déterminer le nouveau statut basé sur la progression
      CourseStatus newStatus;
      if (progress >= 1.0) {
        newStatus = CourseStatus.completed;
      } else if (progress >= 0.1) {
        newStatus = CourseStatus.inProgress;
      } else {
        // Si moins de 10%, garder le statut existant mais ne pas l'afficher comme "en cours"
        newStatus = existingStatus.status;
      }
      
      final updatedStatus = existingStatus.copyWith(
        progress: progress,
        lastAccessedAt: DateTime.now(),
        timeSpentMinutes: newTimeSpent,
        status: newStatus,
        statusUpdatedAt: newStatus == CourseStatus.completed ? DateTime.now() : existingStatus.statusUpdatedAt,
        metadata: {...existingStatus.metadata, ...?metadata},
      );

      await docRef.set(updatedStatus.toFirestore());
      
      // Notifier les autres écrans du changement de progression
      _notifier.notifyProgressUpdated(userId, courseId, progress);
      
      Logger.info('Progression mise à jour pour cours $courseId: ${(progress * 100).toInt()}%');
      return true;
    } catch (e) {
      Logger.error('Erreur mise à jour progression', e);
      return false;
    }
  }

  /// Marque un cours comme terminé et met à jour la progression globale
  Future<bool> completeCourse({
    required String userId,
    required String courseId,
    double? finalScore,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      Map<String, dynamic> completionMetadata = {...?metadata};
      if (finalScore != null) {
        completionMetadata['finalScore'] = finalScore;
        completionMetadata['completedAt'] = DateTime.now().toIso8601String();
      }

      // 1. Mettre à jour le statut du cours
      bool statusUpdated = await updateProgress(
        userId: userId,
        courseId: courseId,
        progress: 1.0,
        metadata: completionMetadata,
      );

      if (statusUpdated) {
        // 2. Récupérer les informations du cours pour la progression globale
        try {
          final courseDoc = await _firestore.collection('Cours').doc(courseId).get();
          if (courseDoc.exists) {
            final course = CourseModel.fromFirestore(courseDoc);
            
            // 3. Mettre à jour la progression globale dans UserProgressionService
            await _progressionService.completeCourse(
              userId,
              course.matiere,
              courseId,
            );
            
            Logger.info('✅ Cours "${course.title}" marqué comme terminé et progression mise à jour');
          }
        } catch (courseError) {
          Logger.warning('Impossible de récupérer les détails du cours $courseId pour la progression: $courseError');
          // Le statut du cours est quand même mis à jour, mais pas la progression globale
        }
        
        // 4. Notifier les autres écrans du changement
        _notifier.notifyCourseCompleted(userId, courseId);
        
        return true;
      }

      return false;
    } catch (e) {
      Logger.error('Erreur completion cours', e);
      return false;
    }
  }

  /// Récupère le statut d'un cours spécifique
  Future<CourseStatusModel?> getCourseStatus({
    required String userId,
    required String courseId,
  }) async {
    try {
      final doc = await _firestore
          .collection('course_status')
          .doc('${userId}_$courseId')
          .get();

      if (doc.exists) {
        return CourseStatusModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Erreur récupération statut cours', e);
      return null;
    }
  }

  /// Récupère tous les statuts de cours d'un utilisateur
  Future<List<CourseStatusModel>> getUserCourseStatuses({
    required String userId,
    CourseStatus? filterByStatus,
    int? limit,
  }) async {
    try {
      // Requête simple sans index pour éviter l'erreur Firestore
      Query query = _firestore
          .collection('course_status')
          .where('userId', isEqualTo: userId);

      if (limit != null) {
        query = query.limit(limit * 2); // Prendre plus pour pouvoir filtrer en mémoire
      }

      final snapshot = await query.get();
      
      List<CourseStatusModel> statuses = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        try {
          CourseStatusModel status = CourseStatusModel.fromFirestore(doc);
          // Vérifier que le courseId est valide
          if (status.courseId.isNotEmpty && status.userId.isNotEmpty) {
            statuses.add(status);
          } else {
            Logger.warning('Statut avec ID invalide ignoré: ${doc.id}');
          }
        } catch (e) {
          Logger.error('Erreur parsing statut ${doc.id}', e);
        }
      }

      // Filtrer par statut en mémoire si nécessaire
      if (filterByStatus != null) {
        Logger.info('🔍 Filtrage par statut: ${filterByStatus.name}');
        Logger.info('📋 Statuts avant filtrage: ${statuses.length}');
        for (var status in statuses) {
          Logger.info('  - ${status.courseId}: ${(status.progress * 100).toInt()}% (${status.status.name})');
        }
        
        statuses = statuses.where((status) {
          // Pour les cours "en cours", s'assurer qu'ils ont au moins 10% de progression
          if (filterByStatus == CourseStatus.inProgress) {
            bool matches = status.status == filterByStatus && status.progress >= 0.1;
            Logger.info('  Cours ${status.courseId}: statut=${status.status.name}, progress=${(status.progress * 100).toInt()}%, matches=$matches');
            return matches;
          }
          return status.status == filterByStatus;
        }).toList();
        
        Logger.info('📋 Statuts après filtrage: ${statuses.length}');
      }

      // Trier par lastAccessedAt en mémoire
      statuses.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));

      // Appliquer la limite finale
      if (limit != null && statuses.length > limit) {
        statuses = statuses.take(limit).toList();
      }

      return statuses;
    } catch (e) {
      Logger.error('Erreur récupération statuts utilisateur', e);
      return [];
    }
  }

  /// Récupère les cours avec leurs statuts
  Future<List<Map<String, dynamic>>> getCoursesWithStatus({
    required String userId,
    CourseStatus? filterByStatus,
    int? limit,
  }) async {
    final requestId = DateTime.now().millisecondsSinceEpoch;
    try {
      Logger.info('🔍 [REQ-$requestId] getCoursesWithStatus démarré - userId: $userId, filter: ${filterByStatus?.name}');
      
      final statuses = await getUserCourseStatuses(
        userId: userId,
        filterByStatus: filterByStatus,
        limit: limit,
      );

      Logger.info('🔍 [REQ-$requestId] getCoursesWithStatus: ${statuses.length} statuts filtrés');

      if (statuses.isEmpty) {
        Logger.info('🔍 [REQ-$requestId] getCoursesWithStatus: Aucun statut, retour liste vide');
        return [];
      }

      List<Map<String, dynamic>> coursesWithStatus = [];
      
      // Récupérer les cours par batch de 10 (limite Firestore)
      List<String> courseIds = statuses
          .map((s) => s.courseId)
          .where((id) => id.isNotEmpty) // Filtrer les IDs vides
          .toList();
      
      Logger.info('📋 Course IDs à rechercher: $courseIds');
      
      if (courseIds.isEmpty) return [];
      
      for (int i = 0; i < courseIds.length; i += 10) {
        List<String> batch = courseIds.skip(i).take(10).toList();
        
        // Validation supplémentaire des IDs
        batch = batch.where((id) => id.isNotEmpty && id.trim().isNotEmpty).toList();
        
        if (batch.isEmpty) continue;
        
        try {
          Logger.info('🔍 [REQ-$requestId] Recherche batch de cours: $batch');
          final coursesSnapshot = await _firestore
              .collection('Cours')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          Logger.info('📚 [REQ-$requestId] Cours trouvés dans Firestore: ${coursesSnapshot.docs.length}');
          for (final doc in coursesSnapshot.docs) {
            Logger.info('  - [REQ-$requestId] Cours trouvé: ${doc.id}');
          }

          for (final courseDoc in coursesSnapshot.docs) {
            try {
              final course = CourseModel.fromFirestore(courseDoc);
              final status = statuses.firstWhere((s) => s.courseId == course.id);
              
              Logger.info('✅ [REQ-$requestId] Cours ${course.title} ajouté avec statut ${status.status.name} (${(status.progress * 100).toInt()}%)');
              
              coursesWithStatus.add({
                'course': course,
                'status': status,
              });
            } catch (e) {
              Logger.error('[REQ-$requestId] Erreur parsing cours ${courseDoc.id}', e);
            }
          }
        } catch (e) {
          Logger.error('Erreur requête batch cours (${batch.length} IDs): $e', e);
          Logger.debug('IDs problématiques: $batch');
          
          // Fallback: essayer de récupérer les cours un par un
          for (String courseId in batch) {
            try {
              final courseDoc = await _firestore
                  .collection('Cours')
                  .doc(courseId)
                  .get();
              
              if (courseDoc.exists) {
                final course = CourseModel.fromFirestore(courseDoc);
                final status = statuses.firstWhere((s) => s.courseId == course.id);
                
                coursesWithStatus.add({
                  'course': course,
                  'status': status,
                });
              } else {
                Logger.warning('Cours introuvable: $courseId');
              }
            } catch (individualError) {
              Logger.error('Erreur récupération cours individuel $courseId', individualError);
            }
          }
        }
      }

      // Trier par dernière activité
      coursesWithStatus.sort((a, b) {
        final statusA = a['status'] as CourseStatusModel;
        final statusB = b['status'] as CourseStatusModel;
        return statusB.lastAccessedAt.compareTo(statusA.lastAccessedAt);
      });

      Logger.info('🎯 [REQ-$requestId] getCoursesWithStatus terminé - Retourne ${coursesWithStatus.length} cours');
      return coursesWithStatus;
    } catch (e) {
      Logger.error('[REQ-$requestId] Erreur récupération cours avec statut', e);
      return [];
    }
  }

  /// Met à jour le temps passé sur un cours
  Future<bool> recordTimeSpent({
    required String userId,
    required String courseId,
    required int additionalMinutes,
  }) async {
    try {
      final docId = '${userId}_$courseId';
      final docRef = _firestore.collection('course_status').doc(docId);
      
      final doc = await docRef.get();
      if (!doc.exists) {
        // Créer un nouveau statut si nécessaire
        return await startCourse(userId: userId, courseId: courseId);
      }

      final status = CourseStatusModel.fromFirestore(doc);
      final updatedStatus = status.copyWith(
        timeSpentMinutes: status.timeSpentMinutes + additionalMinutes,
        lastAccessedAt: DateTime.now(),
      );

      await docRef.set(updatedStatus.toFirestore());
      
      Logger.info('Temps enregistré pour cours $courseId: +${additionalMinutes}min (total: ${updatedStatus.timeSpentMinutes}min)');
      return true;
    } catch (e) {
      Logger.error('Erreur enregistrement temps', e);
      return false;
    }
  }

  /// Stream des statuts de cours en temps réel
  Stream<List<CourseStatusModel>> getUserCourseStatusesStream({
    required String userId,
    CourseStatus? filterByStatus,
    int? limit,
  }) {
    // Requête simple sans index pour éviter l'erreur Firestore
    Query query = _firestore
        .collection('course_status')
        .where('userId', isEqualTo: userId);

    if (limit != null) {
      query = query.limit(limit * 2); // Prendre plus pour pouvoir filtrer en mémoire
    }

    return query.snapshots().map((snapshot) {
      List<CourseStatusModel> statuses = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        try {
          CourseStatusModel status = CourseStatusModel.fromFirestore(doc);
          // Vérifier que le courseId est valide
          if (status.courseId.isNotEmpty && status.userId.isNotEmpty) {
            statuses.add(status);
          } else {
            Logger.warning('Statut avec ID invalide ignoré dans stream: ${doc.id}');
          }
        } catch (e) {
          Logger.error('Erreur parsing statut dans stream ${doc.id}', e);
        }
      }

      // Filtrer par statut en mémoire si nécessaire
      if (filterByStatus != null) {
        Logger.info('🔍 Filtrage par statut: ${filterByStatus.name}');
        Logger.info('📋 Statuts avant filtrage: ${statuses.length}');
        for (var status in statuses) {
          Logger.info('  - ${status.courseId}: ${(status.progress * 100).toInt()}% (${status.status.name})');
        }
        
        statuses = statuses.where((status) {
          // Pour les cours "en cours", s'assurer qu'ils ont au moins 10% de progression
          if (filterByStatus == CourseStatus.inProgress) {
            bool matches = status.status == filterByStatus && status.progress >= 0.1;
            Logger.info('  Cours ${status.courseId}: statut=${status.status.name}, progress=${(status.progress * 100).toInt()}%, matches=$matches');
            return matches;
          }
          return status.status == filterByStatus;
        }).toList();
        
        Logger.info('📋 Statuts après filtrage: ${statuses.length}');
      }

      // Trier par lastAccessedAt en mémoire
      statuses.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));

      // Appliquer la limite finale
      if (limit != null && statuses.length > limit) {
        statuses = statuses.take(limit).toList();
      }

      return statuses;
    });
  }

  /// Supprime le statut d'un cours
  Future<bool> deleteCourseStatus({
    required String userId,
    required String courseId,
  }) async {
    try {
      await _firestore
          .collection('course_status')
          .doc('${userId}_$courseId')
          .delete();
      
      Logger.info('Statut supprimé pour cours $courseId');
      return true;
    } catch (e) {
      Logger.error('Erreur suppression statut cours', e);
      return false;
    }
  }

  /// Récupère les statistiques d'étude d'un utilisateur
  Future<Map<String, dynamic>> getStudyStatistics({
    required String userId,
  }) async {
    try {
      final statuses = await getUserCourseStatuses(userId: userId);
      
      if (statuses.isEmpty) {
        return {
          'totalCourses': 0,
          'inProgressCount': 0,
          'completedCount': 0,
          'totalTimeMinutes': 0,
          'averageProgress': 0.0,
          'averageTimePerCourse': 0,
        };
      }

      int inProgressCount = 0;
      int completedCount = 0;
      int totalTimeMinutes = 0;
      double totalProgress = 0.0;

      for (final status in statuses) {
        switch (status.status) {
          case CourseStatus.inProgress:
            inProgressCount++;
            break;
          case CourseStatus.completed:
            completedCount++;
            break;
          default:
            break;
        }
        totalTimeMinutes += status.timeSpentMinutes;
        totalProgress += status.progress;
      }

      return {
        'totalCourses': statuses.length,
        'inProgressCount': inProgressCount,
        'completedCount': completedCount,
        'totalTimeMinutes': totalTimeMinutes,
        'averageProgress': totalProgress / statuses.length,
        'averageTimePerCourse': statuses.isNotEmpty ? totalTimeMinutes / statuses.length : 0,
      };
    } catch (e) {
      Logger.error('Erreur calcul statistiques', e);
      return {
        'totalCourses': 0,
        'inProgressCount': 0,
        'completedCount': 0,
        'totalTimeMinutes': 0,
        'averageProgress': 0.0,
        'averageTimePerCourse': 0,
      };
    }
  }

  /// Nettoie les statuts anciens (optionnel)
  Future<void> cleanupOldStatuses({
    required String userId,
    int daysToKeep = 90,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final oldStatuses = await _firestore
          .collection('course_status')
          .where('userId', isEqualTo: userId)
          .where('lastAccessedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldStatuses.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      Logger.info('${oldStatuses.docs.length} anciens statuts nettoyés pour utilisateur $userId');
    } catch (e) {
      Logger.error('Erreur nettoyage statuts anciens', e);
    }
  }
}