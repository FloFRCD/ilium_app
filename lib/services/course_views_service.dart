import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../utils/logger.dart';

/// Service simplifié pour gérer les vues des cours
/// 
/// FONCTIONNEMENT SIMPLIFIÉ :
/// - À 12H après création : Vues réelles + nombre entre 20-75
/// - À 24H après création : Vues réelles + nombre entre n1-200
/// - Comptage automatique des vues utilisateurs réelles
/// 
/// EXEMPLE :
/// - Création à 10h00 le lundi
/// - 22h00 lundi : 3 vues réelles + 45 artificielles = 48 vues
/// - 10h00 mardi : 7 vues réelles + 120 artificielles = 127 vues
class CourseViewsService {
  static final CourseViewsService _instance = CourseViewsService._internal();
  factory CourseViewsService() => _instance;
  CourseViewsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// Ajoute une vue réelle d'utilisateur et applique les vues artificielles si nécessaire
  Future<bool> addUserView({
    required String courseId,
    required String userId,
    DateTime? courseCreatedAt,
  }) async {
    try {
      final docRef = _firestore.collection('course_views').doc(courseId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          // Première vue - initialiser le document
          transaction.set(docRef, {
            'realViews': 1,
            'artificialViews': 0,
            'totalViews': 1,
            'courseCreatedAt': courseCreatedAt != null 
                ? Timestamp.fromDate(courseCreatedAt)
                : FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'artificialViewsApplied': {
              '12h': false,
              '24h': false,
            },
            'viewHistory': {
              userId: FieldValue.serverTimestamp(),
            },
          });
        } else {
          // Incrémenter les vues réelles si l'utilisateur n'a pas déjà vu
          final data = doc.data()!;
          final viewHistory = Map<String, dynamic>.from(data['viewHistory'] ?? {});
          
          if (!viewHistory.containsKey(userId)) {
            // Nouvelle vue d'un utilisateur unique
            final currentRealViews = data['realViews'] ?? 0;
            final currentArtificialViews = data['artificialViews'] ?? 0;
            
            viewHistory[userId] = FieldValue.serverTimestamp();
            
            transaction.update(docRef, {
              'realViews': currentRealViews + 1,
              'totalViews': currentRealViews + 1 + currentArtificialViews,
              'lastUpdated': FieldValue.serverTimestamp(),
              'viewHistory': viewHistory,
            });
          }
        }
      });

      // Appliquer les vues artificielles si c'est le moment
      await _applyArtificialViewsIfNeeded(courseId);
      
      Logger.info('Vue utilisateur ajoutée pour cours $courseId par $userId');
      return true;
      
    } catch (e) {
      Logger.error('Erreur ajout vue utilisateur: $e');
      return false;
    }
  }

  /// Applique les vues artificielles selon le timing (12h et 24h)
  Future<void> _applyArtificialViewsIfNeeded(String courseId) async {
    try {
      final docRef = _firestore.collection('course_views').doc(courseId);
      final doc = await docRef.get();
      
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final courseCreatedAt = (data['courseCreatedAt'] as Timestamp).toDate();
      final artificialViewsApplied = Map<String, bool>.from(data['artificialViewsApplied'] ?? {});
      final now = DateTime.now();
      final timeSinceCreation = now.difference(courseCreatedAt);
      
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};
      
      // Vérifier si on doit appliquer les vues de 12h
      if (timeSinceCreation.inHours >= 12 && !artificialViewsApplied['12h']!) {
        final artificial12h = 20 + _random.nextInt(56); // 20-75
        final currentRealViews = data['realViews'] ?? 0;
        
        updates['artificialViews'] = artificial12h;
        updates['totalViews'] = currentRealViews + artificial12h;
        updates['artificialViewsApplied.12h'] = true;
        needsUpdate = true;
        
        Logger.info('Vues artificielles 12h appliquées: +$artificial12h pour $courseId');
      }
      
      // Vérifier si on doit appliquer les vues de 24h
      if (timeSinceCreation.inHours >= 24 && !artificialViewsApplied['24h']!) {
        final currentArtificialViews = data['artificialViews'] ?? 0;
        final currentRealViews = data['realViews'] ?? 0;
        
        // Générer entre currentArtificialViews et 200
        final minArtificial = currentArtificialViews as int;
        final maxArtificial = 200;
        final range = (maxArtificial - minArtificial + 1).clamp(1, 200);
        final additional24h = minArtificial + _random.nextInt(range);
        
        updates['artificialViews'] = additional24h;
        updates['totalViews'] = currentRealViews + additional24h;
        updates['artificialViewsApplied.24h'] = true;
        needsUpdate = true;
        
        Logger.info('Vues artificielles 24h appliquées: $additional24h total pour $courseId');
      }
      
      if (needsUpdate) {
        updates['lastUpdated'] = FieldValue.serverTimestamp();
        await docRef.update(updates);
      }
      
    } catch (e) {
      Logger.error('Erreur application vues artificielles: $e');
    }
  }

  /// Récupère les statistiques de vues d'un cours
  Future<Map<String, int>> getCourseViews(String courseId) async {
    try {
      final doc = await _firestore.collection('course_views').doc(courseId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'totalViews': data['totalViews'] ?? 0,
          'realViews': data['realViews'] ?? 0,
          'artificialViews': data['artificialViews'] ?? 0,
        };
      } else {
        return {
          'totalViews': 0,
          'realViews': 0,
          'artificialViews': 0,
        };
      }
    } catch (e) {
      Logger.error('Erreur récupération vues: $e');
      return {
        'totalViews': 0,
        'realViews': 0,
        'artificialViews': 0,
      };
    }
  }

  /// Met à jour un CourseModel avec les vues actuelles
  Future<CourseModel> enrichCourseWithViews(CourseModel course) async {
    final views = await getCourseViews(course.id);
    return course.copyWith(viewsCount: views['totalViews']);
  }

  /// Initialise les vues pour un cours nouvellement créé
  Future<bool> initializeCourseViews({
    required String courseId,
    required DateTime courseCreatedAt,
  }) async {
    try {
      final docRef = _firestore.collection('course_views').doc(courseId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        await docRef.set({
          'realViews': 0,
          'artificialViews': 0,
          'totalViews': 0,
          'courseCreatedAt': Timestamp.fromDate(courseCreatedAt),
          'lastUpdated': FieldValue.serverTimestamp(),
          'artificialViewsApplied': {
            '12h': false,
            '24h': false,
          },
          'viewHistory': {},
        });
        
        Logger.info('Vues initialisées pour cours $courseId');
        return true;
      }
      
      return true;
    } catch (e) {
      Logger.error('Erreur initialisation vues: $e');
      return false;
    }
  }

  /// Tâche de maintenance pour appliquer les vues artificielles aux anciens cours
  Future<void> runMaintenanceTask() async {
    try {
      // Récupérer tous les cours avec vues non appliquées
      final snapshot = await _firestore
          .collection('course_views')
          .where('artificialViewsApplied.24h', isEqualTo: false)
          .get();

      Logger.info('Maintenance: ${snapshot.docs.length} cours à traiter');

      for (final doc in snapshot.docs) {
        await _applyArtificialViewsIfNeeded(doc.id);
        
        // Petit délai pour éviter de surcharger Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      Logger.info('Maintenance des vues terminée');
    } catch (e) {
      Logger.error('Erreur maintenance vues: $e');
    }
  }

  /// Stream des vues en temps réel pour un cours
  Stream<Map<String, int>> getCourseViewsStream(String courseId) {
    return _firestore
        .collection('course_views')
        .doc(courseId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'totalViews': data['totalViews'] ?? 0,
          'realViews': data['realViews'] ?? 0,
          'artificialViews': data['artificialViews'] ?? 0,
        };
      } else {
        return {
          'totalViews': 0,
          'realViews': 0,
          'artificialViews': 0,
        };
      }
    });
  }

  /// Récupère les statistiques globales des vues
  Future<Map<String, dynamic>> getGlobalViewsStats() async {
    try {
      final snapshot = await _firestore.collection('course_views').get();
      
      int totalCourses = snapshot.docs.length;
      int totalViews = 0;
      int totalRealViews = 0;
      int totalArtificialViews = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalViews += (data['totalViews'] ?? 0) as int;
        totalRealViews += (data['realViews'] ?? 0) as int;
        totalArtificialViews += (data['artificialViews'] ?? 0) as int;
      }
      
      return {
        'totalCourses': totalCourses,
        'totalViews': totalViews,
        'totalRealViews': totalRealViews,
        'totalArtificialViews': totalArtificialViews,
        'averageViewsPerCourse': totalCourses > 0 ? totalViews / totalCourses : 0,
      };
    } catch (e) {
      Logger.error('Erreur statistiques globales vues: $e');
      return {};
    }
  }
}