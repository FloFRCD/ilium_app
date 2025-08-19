import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/course_model.dart';
import '../utils/logger.dart';

/// Service pour gérer l'engagement des cours (vues, notes) avec données factices
class CourseEngagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Génère et persiste les données factices d'engagement lors de la première sauvegarde
  Future<Map<String, dynamic>> initializeFakeEngagementData(String courseId) async {
    try {
      final docRef = _firestore.collection('course_engagement').doc(courseId);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Générer les données factices une seule fois
        final fakeData = _generateFakeData();
        
        await docRef.set({
          'viewsCount': fakeData['viewsCount'],
          'rating': fakeData['rating'],
          'createdAt': FieldValue.serverTimestamp(),
          'isInitialized': true,
        });

        Logger.info('Données factices initialisées pour cours $courseId');
        return fakeData;
      } else {
        // Retourner les données existantes
        final data = doc.data()!;
        return {
          'viewsCount': data['viewsCount'] ?? 0,
          'rating': Map<String, dynamic>.from(data['rating'] ?? {}),
        };
      }
    } catch (e) {
      Logger.error('Erreur initialisation données factices: $e');
      return _generateFakeData(); // Fallback
    }
  }

  /// Génère des données factices réalistes
  Map<String, dynamic> _generateFakeData() {
    final random = Random();
    
    // Générer 10 notes entre 4.3 et 5.0
    List<double> fakeRatings = [];
    for (int i = 0; i < 10; i++) {
      fakeRatings.add(4.3 + random.nextDouble() * 0.7); // 4.3 à 5.0
    }
    
    // Calculer la moyenne
    double averageRating = fakeRatings.reduce((a, b) => a + b) / fakeRatings.length;
    
    return {
      'viewsCount': 30 + random.nextInt(271), // 30 à 300
      'rating': {
        'average': double.parse(averageRating.toStringAsFixed(1)),
        'count': 10,
        'totalStars': fakeRatings.reduce((a, b) => a + b),
      },
    };
  }

  /// Récupère les données d'engagement actuelles d'un cours
  Future<Map<String, dynamic>> getCourseEngagement(String courseId) async {
    try {
      final doc = await _firestore.collection('course_engagement').doc(courseId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'viewsCount': data['viewsCount'] ?? 0,
          'rating': Map<String, dynamic>.from(data['rating'] ?? {}),
        };
      } else {
        // Si pas encore initialisé, retourner valeurs par défaut (cours généré)
        return {
          'viewsCount': 0,
          'rating': {},
        };
      }
    } catch (e) {
      Logger.error('Erreur récupération engagement: $e');
      return {
        'viewsCount': 0,
        'rating': {},
      };
    }
  }

  /// Ajoute une vue réelle au cours
  Future<bool> addView(String courseId) async {
    try {
      final docRef = _firestore.collection('course_engagement').doc(courseId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          // Initialiser avec données factices si première vue
          final fakeData = _generateFakeData();
          transaction.set(docRef, {
            'viewsCount': fakeData['viewsCount'] + 1, // +1 pour la vraie vue
            'rating': fakeData['rating'],
            'createdAt': FieldValue.serverTimestamp(),
            'isInitialized': true,
          });
        } else {
          // Incrémenter les vues existantes
          final currentViews = doc.data()!['viewsCount'] ?? 0;
          transaction.update(docRef, {
            'viewsCount': currentViews + 1,
          });
        }
      });
      
      Logger.info('Vue ajoutée pour cours $courseId');
      return true;
    } catch (e) {
      Logger.error('Erreur ajout vue: $e');
      return false;
    }
  }

  /// Ajoute une note réelle au cours
  Future<bool> addRating(String courseId, double rating) async {
    if (rating < 1.0 || rating > 5.0) return false;

    try {
      final docRef = _firestore.collection('course_engagement').doc(courseId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          // Initialiser avec données factices si première note
          final fakeData = _generateFakeData();
          final fakeRating = fakeData['rating'] as Map<String, dynamic>;
          
          // Ajouter la vraie note aux notes factices
          final newTotal = fakeRating['totalStars'] + rating;
          final newCount = fakeRating['count'] + 1;
          final newAverage = newTotal / newCount;
          
          transaction.set(docRef, {
            'viewsCount': fakeData['viewsCount'],
            'rating': {
              'average': double.parse(newAverage.toStringAsFixed(1)),
              'count': newCount,
              'totalStars': newTotal,
            },
            'createdAt': FieldValue.serverTimestamp(),
            'isInitialized': true,
          });
        } else {
          // Mettre à jour les notes existantes
          final data = doc.data()!;
          final currentRating = Map<String, dynamic>.from(data['rating'] ?? {});
          
          final currentTotal = currentRating['totalStars'] ?? 0.0;
          final currentCount = currentRating['count'] ?? 0;
          
          final newTotal = currentTotal + rating;
          final newCount = currentCount + 1;
          final newAverage = newTotal / newCount;
          
          transaction.update(docRef, {
            'rating': {
              'average': double.parse(newAverage.toStringAsFixed(1)),
              'count': newCount,
              'totalStars': newTotal,
            },
          });
        }
      });
      
      Logger.info('Note $rating ajoutée pour cours $courseId');
      return true;
    } catch (e) {
      Logger.error('Erreur ajout note: $e');
      return false;
    }
  }

  /// Met à jour les métadonnées d'un CourseModel avec les données d'engagement
  Future<CourseModel> enrichCourseWithEngagement(CourseModel course) async {
    final engagement = await getCourseEngagement(course.id);
    
    return course.copyWith(
      viewsCount: engagement['viewsCount'],
      rating: Map<String, double>.from(
        (engagement['rating'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value.toDouble())
        )
      ),
    );
  }

  /// Applique les données factices lors de la sauvegarde en Firebase
  Future<CourseModel> applyfakeDataOnSave(CourseModel course) async {
    if (course.metadata?['hasBeenSavedToFirebase'] == true) {
      // Déjà sauvé, utiliser les données existantes
      return await enrichCourseWithEngagement(course);
    } else {
      // Première sauvegarde, appliquer les données factices
      final fakeData = await initializeFakeEngagementData(course.id);
      
      return course.copyWith(
        viewsCount: fakeData['viewsCount'],
        rating: Map<String, double>.from(
          (fakeData['rating'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value.toDouble())
          )
        ),
        metadata: {
          ...course.metadata ?? {},
          'hasBeenSavedToFirebase': true,
        },
      );
    }
  }

  /// Nettoie les anciennes données d'engagement
  Future<void> cleanupOldEngagementData({int daysToKeep = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final oldDocs = await _firestore
          .collection('course_engagement')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      Logger.info('${oldDocs.docs.length} anciennes données d\'engagement nettoyées');
    } catch (e) {
      Logger.error('Erreur nettoyage engagement: $e');
    }
  }
}