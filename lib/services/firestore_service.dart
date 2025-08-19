import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/qcm_model.dart';
import '../utils/logger.dart';
import 'course_views_service.dart';
import 'course_rating_service.dart';
import 'course_engagement_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CourseViewsService _viewsService = CourseViewsService();
  final CourseRatingService _ratingService = CourseRatingService();
  final CourseEngagementService _engagementService = CourseEngagementService();

  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Error getting user', e);
      return null;
    }
  }

  Future<bool> saveUser(UserModel user) async {
    try {
      Logger.info('💾 Tentative de sauvegarde utilisateur: ${user.uid}');
      
      // Vérifier la connexion Firestore
      try {
        await _firestore.enableNetwork();
        Logger.info('✅ Connexion Firestore activée');
      } catch (e) {
        Logger.error('❌ Problème de connexion Firestore', e);
      }
      
      // Convertir en données Firestore
      Logger.info('🔄 Début conversion toFirestore...');
      Map<String, dynamic> userData;
      try {
        userData = user.toFirestore();
        Logger.info('📝 Données utilisateur converties (${userData.keys.length} champs)');
      } catch (e) {
        Logger.error('❌ Erreur lors de la conversion toFirestore', e);
        rethrow;
      }
      
      // Sauvegarder
      await _firestore.collection('users').doc(user.uid).set(userData);
      Logger.info('✅ Utilisateur sauvegardé avec succès dans Firestore');
      return true;
    } catch (e) {
      Logger.error('❌ Erreur lors de la sauvegarde utilisateur', e);
      
      // Log détaillé de l'erreur
      if (e.toString().contains('permission')) {
        Logger.error('🚫 Erreur de permissions Firestore - vérifiez les règles de sécurité');
      } else if (e.toString().contains('network')) {
        Logger.error('🌐 Erreur de réseau - vérifiez la connexion internet');
      } else if (e.toString().contains('quota')) {
        Logger.error('💰 Quota Firestore dépassé');
      }
      
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toFirestore());
      return true;
    } catch (e) {
      Logger.error('Error updating user', e);
      return false;
    }
  }

  Future<List<CourseModel>> getCourses({
    String? matiere,
    String? niveau,
    CourseType? type,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('Cours');
      
      if (matiere != null && matiere != 'Toutes') {
        query = query.where('matiere', isEqualTo: matiere);
      }
      
      if (niveau != null && niveau != 'Tous') {
        query = query.where('niveau', isEqualTo: niveau);
      }
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      query = query.limit(limit);
      
      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Error getting courses', e);
      return [];
    }
  }

  /// Alias pour getCourses pour compatibilité avec l'écran curriculum
  Future<List<CourseModel>> getCoursesByFilters({
    String? matiere,
    String? niveau,
    CourseType? type,
    int limit = 20,
  }) async {
    return getCourses(matiere: matiere, niveau: niveau, type: type, limit: limit);
  }

  Future<List<CourseModel>> getOriginalGetCourses({
    String? matiere,
    String? niveau,
    CourseType? type,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('Cours');
      
      if (matiere != null && matiere.isNotEmpty) {
        query = query.where('matiere', isEqualTo: matiere);
      }
      if (niveau != null && niveau.isNotEmpty) {
        query = query.where('niveau', isEqualTo: niveau);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      query = query.orderBy('popularity', descending: true).limit(limit);
      
      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Error getting courses', e);
      return [];
    }
  }

  Future<CourseModel?> getCourse(String courseId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('Cours').doc(courseId).get();
      if (doc.exists) {
        return CourseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Error getting course', e);
      return null;
    }
  }

  Future<bool> saveCourse(CourseModel course) async {
    try {
      // Générer un ID formaté si pas déjà défini
      String docId = course.id.isEmpty ? course.generateDocumentId() : course.id;
      
      // Mettre à jour les tags basés sur le type
      CourseModel updatedCourse = course.copyWith(
        id: docId,
        tags: course.typeBasedTags,
      );
      
      // Appliquer les données factices d'engagement lors de la première sauvegarde
      CourseModel enrichedCourse = await _engagementService.applyfakeDataOnSave(updatedCourse);
      
      await _firestore.collection('Cours').doc(docId).set(enrichedCourse.toFirestore());
      
      // Initialiser le système de vues pour le nouveau cours (legacy)
      await _viewsService.initializeCourseViews(
        courseId: docId,
        courseCreatedAt: enrichedCourse.createdAt,
      );
      
      // Initialiser le système de notation pour le nouveau cours (legacy)
      await _ratingService.initializeCourseRating(
        courseId: docId,
        courseCreatedAt: enrichedCourse.createdAt,
      );
      
      Logger.info('Cours sauvé avec données d\'engagement factices: $docId');
      return true;
    } catch (e) {
      Logger.error('Error saving course', e);
      return false;
    }
  }

  Future<bool> updateCourse(CourseModel course) async {
    try {
      await _firestore.collection('Cours').doc(course.id).update(course.toFirestore());
      return true;
    } catch (e) {
      Logger.error('Error updating course', e);
      return false;
    }
  }

  Future<bool> voteCourse(String courseId, String userId, bool isUpvote) async {
    try {
      DocumentReference courseRef = _firestore.collection('Cours').doc(courseId);
      DocumentReference voteRef = _firestore.collection('votes').doc('${courseId}_$userId');
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot courseDoc = await transaction.get(courseRef);
        DocumentSnapshot voteDoc = await transaction.get(voteRef);
        
        if (courseDoc.exists) {
          CourseModel course = CourseModel.fromFirestore(courseDoc);
          Map<String, int> votes = Map.from(course.votes);
          
          if (voteDoc.exists) {
            Map<String, dynamic> existingVote = voteDoc.data() as Map<String, dynamic>;
            bool wasUpvote = existingVote['isUpvote'] ?? false;
            
            if (wasUpvote) {
              votes['up'] = (votes['up'] ?? 0) - 1;
            } else {
              votes['down'] = (votes['down'] ?? 0) - 1;
            }
          }
          
          if (isUpvote) {
            votes['up'] = (votes['up'] ?? 0) + 1;
          } else {
            votes['down'] = (votes['down'] ?? 0) + 1;
          }
          
          transaction.update(courseRef, {'votes': votes});
          transaction.set(voteRef, {
            'userId': userId,
            'courseId': courseId,
            'isUpvote': isUpvote,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
      return true;
    } catch (e) {
      Logger.error('Error voting course', e);
      return false;
    }
  }

  Future<bool> addComment(String courseId, String userId, String userName, String comment) async {
    try {
      DocumentReference courseRef = _firestore.collection('Cours').doc(courseId);
      
      await courseRef.update({
        'commentaires': FieldValue.arrayUnion([
          {
            'userId': userId,
            'userName': userName,
            'comment': comment,
            'createdAt': Timestamp.now(),
          }
        ])
      });
      
      return true;
    } catch (e) {
      Logger.error('Error adding comment', e);
      return false;
    }
  }

  Future<QCMModel?> getQCM(String qcmId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('QCM').doc(qcmId).get();
      if (doc.exists) {
        return QCMModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Error getting QCM', e);
      return null;
    }
  }

  Future<List<QCMModel>> getQCMsByCourse(String courseId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('QCM')
          .where('courseId', isEqualTo: courseId)
          .get();
      
      return snapshot.docs.map((doc) => QCMModel.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Error getting QCMs by course', e);
      return [];
    }
  }

  Future<bool> saveQCM(QCMModel qcm) async {
    try {
      await _firestore.collection('QCM').doc(qcm.id).set(qcm.toFirestore());
      return true;
    } catch (e) {
      Logger.error('Error saving QCM', e);
      return false;
    }
  }

  /// Récupère les cours par matière et niveau (version optimisée pour la rapidité)
  Future<List<CourseModel>> getCoursesBySubject(String matiere, String niveau) async {
    try {
      // Version optimisée : requête simple sans index complexe
      QuerySnapshot querySnapshot = await _firestore
          .collection('Cours')
          .limit(50) // Limite réduite pour plus de rapidité
          .get();

      List<CourseModel> allCourses = querySnapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();

      // Filtrage simple côté client
      List<CourseModel> filteredCourses = allCourses.where((course) {
        return course.matiere.toLowerCase().contains(matiere.toLowerCase()) ||
               course.niveau.toLowerCase().contains(niveau.toLowerCase());
      }).toList();

      // Retourner maximum 5 cours pour accélérer l'affichage
      return filteredCourses.take(5).toList();
    } catch (e) {
      Logger.error('Error getting courses by subject', e);
      return [];
    }
  }

  /// Récupère les prochains cours dans une matière selon la progression
  Future<List<CourseModel>> getNextCoursesInSubject(String matiere, String niveau, int completedCount) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Cours')
          .where('matiere', isEqualTo: matiere)
          .where('niveau', isEqualTo: niveau)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt')
          .limit(5)
          .get();

      List<CourseModel> courses = querySnapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();

      // Simuler la logique de progression - retourner les cours suivants
      if (courses.length > completedCount) {
        return courses.skip(completedCount).toList();
      }

      return [];
    } catch (e) {
      Logger.error('Error getting next courses', e);
      return [];
    }
  }


  // Nouvelle méthode pour chercher QCM par cours et difficulté
  Future<QCMModel?> findQCMByCourseAndDifficulty(String courseId, String difficulty) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('QCM')
          .where('courseId', isEqualTo: courseId)
          .where('difficulty', isEqualTo: difficulty)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return QCMModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      Logger.error('Error finding QCM by course and difficulty', e);
      return null;
    }
  }

  // Vérifier si un cours existe déjà avec ce format
  Future<CourseModel?> findExistingCourse(String sujet, CourseType type, String niveau) async {
    try {
      String expectedDocId = _generateCourseDocId(sujet, type, niveau);
      DocumentSnapshot doc = await _firestore.collection('Cours').doc(expectedDocId).get();
      
      if (doc.exists) {
        return CourseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error('Error finding existing course', e);
      return null;
    }
  }

  // Helper privé pour générer l'ID de document
  String _generateCourseDocId(String sujet, CourseType type, String niveau) {
    String cleanTitle = sujet
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .replaceAll(' ', '')
        .replaceAll('è', 'e').replaceAll('é', 'e')
        .replaceAll('à', 'a').replaceAll('ç', 'c');
    
    String typeStr;
    switch (type) {
      case CourseType.cours:
        typeStr = 'CoursComplet';
        break;
      case CourseType.fiche:
        typeStr = 'FicheRevision';
        break;
      case CourseType.vulgarise:
        typeStr = 'Vulgarisation';
        break;
    }
    
    return '$cleanTitle-$typeStr-$niveau';
  }

  Future<List<CourseModel>> getSavedCourses(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('savedCourses')
          .where('userId', isEqualTo: userId)
          .get();
      
      List<String> courseIds = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['courseId'] as String)
          .toList();
      
      if (courseIds.isEmpty) return [];
      
      List<CourseModel> courses = [];
      for (String courseId in courseIds) {
        CourseModel? course = await getCourse(courseId);
        if (course != null) {
          courses.add(course);
        }
      }
      
      return courses;
    } catch (e) {
      Logger.error('Error getting saved courses', e);
      return [];
    }
  }

  Future<bool> saveCourseToUser(String userId, String courseId) async {
    try {
      await _firestore.collection('savedCourses').add({
        'userId': userId,
        'courseId': courseId,
        'savedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      Logger.error('Error saving course to user', e);
      return false;
    }
  }

  Future<bool> removeSavedCourse(String userId, String courseId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('savedCourses')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .get();
      
      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      return true;
    } catch (e) {
      Logger.error('Error removing saved course', e);
      return false;
    }
  }
}