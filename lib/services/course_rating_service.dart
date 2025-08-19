import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../utils/logger.dart';

/// Service pour gérer les notes des cours avec système automatique
/// 
/// FONCTIONNEMENT SIMPLIFIÉ :
/// - À 12H après création : Notes réelles + 8-15 notes artificielles (4.0-5.0)
/// - À 24H après création : Notes réelles + jusqu'à 25 notes artificielles
/// - Interface utilisateur pour noter de 1 à 5 étoiles
/// - Calcul automatique de la moyenne pondérée
class CourseRatingService {
  static final CourseRatingService _instance = CourseRatingService._internal();
  factory CourseRatingService() => _instance;
  CourseRatingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// Ajoute une note d'utilisateur réelle
  Future<bool> addUserRating({
    required String courseId,
    required String userId,
    required double rating,
    DateTime? courseCreatedAt,
  }) async {
    if (rating < 1.0 || rating > 5.0) {
      Logger.error('Note invalide: $rating (doit être entre 1.0 et 5.0)');
      return false;
    }

    try {
      final docRef = _firestore.collection('course_ratings').doc(courseId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          // Première note - initialiser le document
          transaction.set(docRef, {
            'realRatings': {
              userId: rating,
            },
            'artificialRatings': <String, double>{},
            'totalRatings': 1,
            'averageRating': rating,
            'totalStars': rating,
            'courseCreatedAt': courseCreatedAt != null 
                ? Timestamp.fromDate(courseCreatedAt)
                : FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'artificialRatingsApplied': {
              '12h': false,
              '24h': false,
            },
          });
        } else {
          // Mettre à jour ou ajouter la note utilisateur
          final data = doc.data()!;
          final realRatings = Map<String, double>.from(data['realRatings'] ?? {});
          final artificialRatings = Map<String, double>.from(data['artificialRatings'] ?? {});
          
          // Ancienne note utilisateur pour calcul
          final oldUserRating = realRatings[userId];
          realRatings[userId] = rating;
          
          // Recalculer les totaux
          final realTotal = realRatings.values.fold(0.0, (total, r) => total + r);
          final artificialTotal = artificialRatings.values.fold(0.0, (total, r) => total + r);
          final totalStars = realTotal + artificialTotal;
          final totalCount = realRatings.length + artificialRatings.length;
          final newAverage = totalCount > 0 ? totalStars / totalCount : 0.0;
          
          transaction.update(docRef, {
            'realRatings': realRatings,
            'totalRatings': totalCount,
            'averageRating': double.parse(newAverage.toStringAsFixed(1)),
            'totalStars': totalStars,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          
          if (oldUserRating == null) {
            Logger.info('Nouvelle note ajoutée: $rating/5 pour cours $courseId par $userId');
          } else {
            Logger.info('Note mise à jour: $oldUserRating → $rating pour cours $courseId par $userId');
          }
        }
      });

      // Appliquer les notes artificielles si c'est le moment
      await _applyArtificialRatingsIfNeeded(courseId);
      
      return true;
      
    } catch (e) {
      Logger.error('Erreur ajout note utilisateur: $e');
      return false;
    }
  }

  /// Applique les notes artificielles selon le timing (12h et 24h)
  Future<void> _applyArtificialRatingsIfNeeded(String courseId) async {
    try {
      final docRef = _firestore.collection('course_ratings').doc(courseId);
      final doc = await docRef.get();
      
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final courseCreatedAt = (data['courseCreatedAt'] as Timestamp).toDate();
      final artificialRatingsApplied = Map<String, bool>.from(data['artificialRatingsApplied'] ?? {});
      final now = DateTime.now();
      final timeSinceCreation = now.difference(courseCreatedAt);
      
      
      // Vérifier si on doit appliquer les notes de 12h
      if (timeSinceCreation.inHours >= 12 && !artificialRatingsApplied['12h']!) {
        final artificial12h = _generateArtificialRatings12h();
        await _applyArtificialRatings(docRef, artificial12h, '12h');
        Logger.info('Notes artificielles 12h appliquées: ${artificial12h.length} notes pour $courseId');
      }
      
      // Vérifier si on doit appliquer les notes de 24h
      if (timeSinceCreation.inHours >= 24 && !artificialRatingsApplied['24h']!) {
        final currentDoc = await docRef.get();
        final currentData = currentDoc.data()!;
        final currentArtificialRatings = Map<String, double>.from(currentData['artificialRatings'] ?? {});
        
        final additional24h = _generateArtificialRatings24h(currentArtificialRatings.length);
        await _applyArtificialRatings(docRef, additional24h, '24h');
        Logger.info('Notes artificielles 24h appliquées: ${additional24h.length} notes supplémentaires pour $courseId');
      }
      
    } catch (e) {
      Logger.error('Erreur application notes artificielles: $e');
    }
  }

  /// Génère les notes artificielles pour le timing 12h (8-15 notes entre 4.0-5.0)
  Map<String, double> _generateArtificialRatings12h() {
    final count = 8 + _random.nextInt(8); // 8-15 notes
    final Map<String, double> artificialRatings = {};
    
    for (int i = 0; i < count; i++) {
      // Notes entre 4.0 et 5.0 avec tendance vers 4.5-4.8
      double rating;
      if (_random.nextDouble() < 0.7) {
        // 70% entre 4.3 et 4.8
        rating = 4.3 + _random.nextDouble() * 0.5;
      } else {
        // 30% entre 4.8 et 5.0
        rating = 4.8 + _random.nextDouble() * 0.2;
      }
      
      artificialRatings['artificial_12h_$i'] = double.parse(rating.toStringAsFixed(1));
    }
    
    return artificialRatings;
  }

  /// Génère les notes artificielles pour le timing 24h (jusqu'à 25 total)
  Map<String, double> _generateArtificialRatings24h(int existingCount) {
    final maxTotal = 25;
    final additionalCount = (maxTotal - existingCount).clamp(0, 15);
    final Map<String, double> artificialRatings = {};
    
    for (int i = 0; i < additionalCount; i++) {
      // Notes entre 3.8 et 5.0 avec distribution plus réaliste
      double rating;
      final rand = _random.nextDouble();
      
      if (rand < 0.1) {
        // 10% notes moyennes (3.8-4.2)
        rating = 3.8 + _random.nextDouble() * 0.4;
      } else if (rand < 0.3) {
        // 20% bonnes notes (4.2-4.5)
        rating = 4.2 + _random.nextDouble() * 0.3;
      } else if (rand < 0.7) {
        // 40% très bonnes notes (4.5-4.8)
        rating = 4.5 + _random.nextDouble() * 0.3;
      } else {
        // 30% excellentes notes (4.8-5.0)
        rating = 4.8 + _random.nextDouble() * 0.2;
      }
      
      artificialRatings['artificial_24h_$i'] = double.parse(rating.toStringAsFixed(1));
    }
    
    return artificialRatings;
  }

  /// Applique un ensemble de notes artificielles
  Future<void> _applyArtificialRatings(
    DocumentReference docRef, 
    Map<String, double> artificialRatings, 
    String phase
  ) async {
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;
      
      final data = doc.data()! as Map<String, dynamic>;
      final realRatings = Map<String, double>.from(data['realRatings'] ?? {});
      final existingArtificialRatings = Map<String, double>.from(data['artificialRatings'] ?? {});
      
      // Fusionner les nouvelles notes artificielles
      final allArtificialRatings = {...existingArtificialRatings, ...artificialRatings};
      
      // Recalculer les totaux
      final realTotal = realRatings.values.fold(0.0, (total, r) => total + r);
      final artificialTotal = allArtificialRatings.values.fold(0.0, (total, r) => total + r);
      final totalStars = realTotal + artificialTotal;
      final totalCount = realRatings.length + allArtificialRatings.length;
      final newAverage = totalCount > 0 ? totalStars / totalCount : 0.0;
      
      transaction.update(docRef, {
        'artificialRatings': allArtificialRatings,
        'totalRatings': totalCount,
        'averageRating': double.parse(newAverage.toStringAsFixed(1)),
        'totalStars': totalStars,
        'artificialRatingsApplied.$phase': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Récupère les statistiques de notation d'un cours
  Future<Map<String, dynamic>> getCourseRating(String courseId) async {
    try {
      final doc = await _firestore.collection('course_ratings').doc(courseId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'averageRating': data['averageRating'] ?? 0.0,
          'totalRatings': data['totalRatings'] ?? 0,
          'realRatingsCount': (data['realRatings'] as Map? ?? {}).length,
          'artificialRatingsCount': (data['artificialRatings'] as Map? ?? {}).length,
          'totalStars': data['totalStars'] ?? 0.0,
        };
      } else {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
          'realRatingsCount': 0,
          'artificialRatingsCount': 0,
          'totalStars': 0.0,
        };
      }
    } catch (e) {
      Logger.error('Erreur récupération notation: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'realRatingsCount': 0,
        'artificialRatingsCount': 0,
        'totalStars': 0.0,
      };
    }
  }

  /// Récupère la note d'un utilisateur pour un cours
  Future<double?> getUserRating(String courseId, String userId) async {
    try {
      final doc = await _firestore.collection('course_ratings').doc(courseId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final realRatings = Map<String, double>.from(data['realRatings'] ?? {});
        return realRatings[userId];
      }
      
      return null;
    } catch (e) {
      Logger.error('Erreur récupération note utilisateur: $e');
      return null;
    }
  }

  /// Met à jour un CourseModel avec les données de notation actuelles
  Future<CourseModel> enrichCourseWithRating(CourseModel course) async {
    final rating = await getCourseRating(course.id);
    return course.copyWith(
      rating: {
        'average': rating['averageRating'],
        'count': rating['totalRatings'].toDouble(),
        'totalStars': rating['totalStars'],
      },
    );
  }

  /// Initialise le système de notation pour un cours nouvellement créé
  Future<bool> initializeCourseRating({
    required String courseId,
    required DateTime courseCreatedAt,
  }) async {
    try {
      final docRef = _firestore.collection('course_ratings').doc(courseId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        await docRef.set({
          'realRatings': <String, double>{},
          'artificialRatings': <String, double>{},
          'totalRatings': 0,
          'averageRating': 0.0,
          'totalStars': 0.0,
          'courseCreatedAt': Timestamp.fromDate(courseCreatedAt),
          'lastUpdated': FieldValue.serverTimestamp(),
          'artificialRatingsApplied': {
            '12h': false,
            '24h': false,
          },
        });
        
        Logger.info('Système de notation initialisé pour cours $courseId');
        return true;
      }
      
      return true;
    } catch (e) {
      Logger.error('Erreur initialisation notation: $e');
      return false;
    }
  }

  /// Stream des notes en temps réel pour un cours
  Stream<Map<String, dynamic>> getCourseRatingStream(String courseId) {
    return _firestore
        .collection('course_ratings')
        .doc(courseId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'averageRating': data['averageRating'] ?? 0.0,
          'totalRatings': data['totalRatings'] ?? 0,
          'realRatingsCount': (data['realRatings'] as Map? ?? {}).length,
          'artificialRatingsCount': (data['artificialRatings'] as Map? ?? {}).length,
          'totalStars': data['totalStars'] ?? 0.0,
        };
      } else {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
          'realRatingsCount': 0,
          'artificialRatingsCount': 0,
          'totalStars': 0.0,
        };
      }
    });
  }

  /// Tâche de maintenance pour appliquer les notes artificielles aux anciens cours
  Future<void> runMaintenanceTask() async {
    try {
      final snapshot = await _firestore
          .collection('course_ratings')
          .where('artificialRatingsApplied.24h', isEqualTo: false)
          .get();

      Logger.info('Maintenance notation: ${snapshot.docs.length} cours à traiter');

      for (final doc in snapshot.docs) {
        await _applyArtificialRatingsIfNeeded(doc.id);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      Logger.info('Maintenance des notations terminée');
    } catch (e) {
      Logger.error('Erreur maintenance notation: $e');
    }
  }

  /// Récupère les statistiques globales des notations
  Future<Map<String, dynamic>> getGlobalRatingStats() async {
    try {
      final snapshot = await _firestore.collection('course_ratings').get();
      
      int totalCourses = snapshot.docs.length;
      int totalRatings = 0;
      int totalRealRatings = 0;
      int totalArtificialRatings = 0;
      double sumAverageRatings = 0.0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalRatings += (data['totalRatings'] ?? 0) as int;
        totalRealRatings += (data['realRatings'] as Map? ?? {}).length;
        totalArtificialRatings += (data['artificialRatings'] as Map? ?? {}).length;
        sumAverageRatings += (data['averageRating'] ?? 0.0) as double;
      }
      
      return {
        'totalCourses': totalCourses,
        'totalRatings': totalRatings,
        'totalRealRatings': totalRealRatings,
        'totalArtificialRatings': totalArtificialRatings,
        'averageRatingAcrossAllCourses': totalCourses > 0 ? sumAverageRatings / totalCourses : 0.0,
        'averageRatingsPerCourse': totalCourses > 0 ? totalRatings / totalCourses : 0,
      };
    } catch (e) {
      Logger.error('Erreur statistiques globales notation: $e');
      return {};
    }
  }
}