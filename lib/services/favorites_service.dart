import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/course_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ajouter un cours aux favoris
  Future<bool> addToFavorites({
    required String userId,
    required String courseId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(courseId)
          .set({
        'courseId': courseId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Cours $courseId ajouté aux favoris de $userId');
      return true;
    } catch (e) {
      debugPrint('Erreur ajout favori: $e');
      return false;
    }
  }

  /// Retirer un cours des favoris
  Future<bool> removeFromFavorites({
    required String userId,
    required String courseId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(courseId)
          .delete();
      
      debugPrint('Cours $courseId retiré des favoris de $userId');
      return true;
    } catch (e) {
      debugPrint('Erreur suppression favori: $e');
      return false;
    }
  }

  /// Vérifier si un cours est en favori
  Future<bool> isFavorite({
    required String userId,
    required String courseId,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(courseId)
          .get();
      
      return doc.exists;
    } catch (e) {
      debugPrint('Erreur vérification favori: $e');
      return false;
    }
  }

  /// Récupérer tous les cours favoris d'un utilisateur
  Future<List<CourseModel>> getFavoriteCourses({
    required String userId,
    int limit = 50,
  }) async {
    try {
      // 1. Récupérer les IDs des cours favoris
      QuerySnapshot favoritesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .limit(limit)
          .get();

      List<String> favoriteIds = favoritesSnapshot.docs
          .map((doc) => doc['courseId'] as String)
          .toList();

      if (favoriteIds.isEmpty) {
        return [];
      }

      // 2. Récupérer les détails des cours
      List<CourseModel> favoriteCourses = [];
      
      // Firestore limite les requêtes "whereIn" à 10 éléments max
      for (int i = 0; i < favoriteIds.length; i += 10) {
        List<String> batch = favoriteIds.skip(i).take(10).toList();
        
        QuerySnapshot coursesSnapshot = await _firestore
            .collection('Cours')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (DocumentSnapshot doc in coursesSnapshot.docs) {
          try {
            CourseModel course = CourseModel.fromFirestore(doc);
            favoriteCourses.add(course);
          } catch (e) {
            debugPrint('Erreur parsing cours favori ${doc.id}: $e');
          }
        }
      }

      // 3. Trier par ordre d'ajout aux favoris
      Map<String, DateTime> favoriteTimestamps = {};
      for (DocumentSnapshot doc in favoritesSnapshot.docs) {
        String courseId = doc['courseId'];
        Timestamp? timestamp = doc['addedAt'];
        if (timestamp != null) {
          favoriteTimestamps[courseId] = timestamp.toDate();
        }
      }

      favoriteCourses.sort((a, b) {
        DateTime timeA = favoriteTimestamps[a.id] ?? DateTime.now();
        DateTime timeB = favoriteTimestamps[b.id] ?? DateTime.now();
        return timeB.compareTo(timeA); // Plus récent en premier
      });

      return favoriteCourses;
    } catch (e) {
      debugPrint('Erreur récupération favoris: $e');
      return [];
    }
  }

  /// Stream des cours favoris en temps réel
  Stream<List<CourseModel>> getFavoritesStream({
    required String userId,
    int limit = 50,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <CourseModel>[];
      }

      List<String> favoriteIds = snapshot.docs
          .map((doc) => doc['courseId'] as String)
          .toList();

      List<CourseModel> favoriteCourses = [];
      
      // Traitement par batch de 10 pour respecter la limite Firestore
      for (int i = 0; i < favoriteIds.length; i += 10) {
        List<String> batch = favoriteIds.skip(i).take(10).toList();
        
        QuerySnapshot coursesSnapshot = await _firestore
            .collection('Cours')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (DocumentSnapshot doc in coursesSnapshot.docs) {
          try {
            CourseModel course = CourseModel.fromFirestore(doc);
            favoriteCourses.add(course);
          } catch (e) {
            debugPrint('Erreur parsing cours favori stream ${doc.id}: $e');
          }
        }
      }

      return favoriteCourses;
    });
  }

  /// Obtenir le nombre de favoris d'un utilisateur
  Future<int> getFavoritesCount({required String userId}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Erreur comptage favoris: $e');
      return 0;
    }
  }

  /// Toggle favori (ajouter si pas en favori, retirer sinon)
  Future<bool> toggleFavorite({
    required String userId,
    required String courseId,
  }) async {
    try {
      bool isCurrentlyFavorite = await isFavorite(
        userId: userId,
        courseId: courseId,
      );

      if (isCurrentlyFavorite) {
        return await removeFromFavorites(
          userId: userId,
          courseId: courseId,
        );
      } else {
        return await addToFavorites(
          userId: userId,
          courseId: courseId,
        );
      }
    } catch (e) {
      debugPrint('Erreur toggle favori: $e');
      return false;
    }
  }

  /// Récupérer les favoris avec métadonnées
  Future<List<Map<String, dynamic>>> getFavoritesWithMetadata({
    required String userId,
    int limit = 50,
  }) async {
    try {
      QuerySnapshot favoritesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> favoritesWithMetadata = [];

      for (DocumentSnapshot favoriteDoc in favoritesSnapshot.docs) {
        String courseId = favoriteDoc['courseId'];
        Timestamp addedAt = favoriteDoc['addedAt'];

        try {
          DocumentSnapshot courseDoc = await _firestore
              .collection('Cours')
              .doc(courseId)
              .get();

          if (courseDoc.exists) {
            CourseModel course = CourseModel.fromFirestore(courseDoc);

            favoritesWithMetadata.add({
              'course': course,
              'addedAt': addedAt.toDate(),
              'favoriteId': favoriteDoc.id,
            });
          }
        } catch (e) {
          debugPrint('Erreur récupération cours $courseId: $e');
        }
      }

      return favoritesWithMetadata;
    } catch (e) {
      debugPrint('Erreur récupération favoris avec métadonnées: $e');
      return [];
    }
  }

  /// Nettoyer les favoris orphelins (cours supprimés)
  Future<void> cleanupOrphanedFavorites({required String userId}) async {
    try {
      QuerySnapshot favoritesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      for (DocumentSnapshot favoriteDoc in favoritesSnapshot.docs) {
        String courseId = favoriteDoc['courseId'];
        
        DocumentSnapshot courseDoc = await _firestore
            .collection('Cours')
            .doc(courseId)
            .get();

        if (!courseDoc.exists) {
          await favoriteDoc.reference.delete();
          debugPrint('Favori orphelin supprimé: $courseId');
        }
      }
    } catch (e) {
      debugPrint('Erreur nettoyage favoris orphelins: $e');
    }
  }
}