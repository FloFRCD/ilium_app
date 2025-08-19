import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/qcm_model.dart';
import '../services/firestore_service.dart';
import '../services/openai_service.dart';

class QCMService {
  final FirestoreService _firestoreService = FirestoreService();
  final OpenAIService _openAIService = OpenAIService();

  /// Obtenir ou générer un QCM pour un cours avec une difficulté spécifique
  Future<QCMModel?> getOrGenerateQCM({
    required CourseModel course,
    required QCMDifficulty difficulty,
    int numberOfQuestions = 10,
  }) async {
    try {
      // 1. Vérifier si le QCM existe déjà dans Firebase
      QCMModel? existingQCM = await _firestoreService.findQCMByCourseAndDifficulty(
        course.id,
        difficulty.name,
      );

      if (existingQCM != null) {
        debugPrint('QCM existant trouvé pour ${course.title} - ${difficulty.name}');
        return existingQCM;
      }

      // 2. Si le QCM n'existe pas, le générer avec ChatGPT
      debugPrint('Génération QCM pour ${course.title} - ${difficulty.name}');
      
      QCMModel? generatedQCM = await _openAIService.generateQCM(
        courseId: course.id,
        courseContent: course.content,
        title: 'QCM ${difficulty.name} - ${course.title}',
        difficulty: difficulty,
        numberOfQuestions: numberOfQuestions,
      );

      if (generatedQCM != null) {
        // 3. Générer l'ID formaté pour le QCM
        String qcmId = '${course.generateDocumentId()}-QCM-${difficulty.name}';
        
        QCMModel qcmToSave = generatedQCM.copyWith(
          id: qcmId,
          courseId: course.id,
        );

        // 4. Sauvegarder dans Firebase
        bool saved = await _firestoreService.saveQCM(qcmToSave);
        
        if (saved) {
          debugPrint('QCM sauvegardé avec succès: $qcmId');
          return qcmToSave;
        } else {
          debugPrint('Erreur lors de la sauvegarde du QCM');
        }
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('ERREUR QCM SERVICE: $e');
      debugPrint('STACK TRACE: $stackTrace');
      return null;
    }
  }

  /// Obtenir tous les QCM disponibles pour un cours
  Future<Map<QCMDifficulty, QCMModel?>> getAllQCMsForCourse(CourseModel course) async {
    Map<QCMDifficulty, QCMModel?> qcms = {};
    
    for (QCMDifficulty difficulty in QCMDifficulty.values) {
      try {
        QCMModel? qcm = await _firestoreService.findQCMByCourseAndDifficulty(
          course.id,
          difficulty.name,
        );
        qcms[difficulty] = qcm;
      } catch (e) {
        debugPrint('Erreur récupération QCM ${difficulty.name}: $e');
        qcms[difficulty] = null;
      }
    }
    
    return qcms;
  }

  /// Générer automatiquement tous les niveaux de QCM pour un cours
  Future<List<QCMModel>> generateAllQCMLevels(CourseModel course) async {
    List<QCMModel> generatedQCMs = [];
    
    for (QCMDifficulty difficulty in QCMDifficulty.values) {
      try {
        QCMModel? qcm = await getOrGenerateQCM(
          course: course,
          difficulty: difficulty,
          numberOfQuestions: _getQuestionsCountForDifficulty(difficulty),
        );
        
        if (qcm != null) {
          generatedQCMs.add(qcm);
        }
        
        // Délai entre les générations pour éviter de surcharger l'API
        await Future.delayed(Duration(seconds: 1));
        
      } catch (e) {
        debugPrint('Erreur génération QCM ${difficulty.name}: $e');
      }
    }
    
    return generatedQCMs;
  }

  /// Helper pour déterminer le nombre de questions selon la difficulté
  int _getQuestionsCountForDifficulty(QCMDifficulty difficulty) {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return 8;  // Questions simples, plus courtes
      case QCMDifficulty.moyen:
        return 10; // Standard
      case QCMDifficulty.difficile:
        return 12; // Plus de questions pour tester davantage
      case QCMDifficulty.tresDifficile:
        return 15; // Maximum pour expertise
    }
  }

  /// Vérifier si au moins un QCM existe pour un cours
  Future<bool> hasAnyQCM(String courseId) async {
    try {
      List<QCMModel> qcms = await _firestoreService.getQCMsByCourse(courseId);
      return qcms.isNotEmpty;
    } catch (e) {
      debugPrint('Erreur vérification QCM: $e');
      return false;
    }
  }

  /// Obtenir le meilleur niveau de QCM disponible pour un utilisateur
  Future<QCMModel?> getRecommendedQCM(CourseModel course, String userLevel) async {
    // Logique pour recommander un QCM selon le niveau de l'utilisateur
    QCMDifficulty recommendedDifficulty;
    
    switch (userLevel.toLowerCase()) {
      case 'cp':
      case 'ce1':
      case 'ce2':
        recommendedDifficulty = QCMDifficulty.facile;
        break;
      case 'cm1':
      case 'cm2':
      case '6ème':
        recommendedDifficulty = QCMDifficulty.moyen;
        break;
      case '5ème':
      case '4ème':
      case '3ème':
      case '2nde':
        recommendedDifficulty = QCMDifficulty.difficile;
        break;
      case '1ère':
      case 'terminale':
        recommendedDifficulty = QCMDifficulty.tresDifficile;
        break;
      default:
        recommendedDifficulty = QCMDifficulty.moyen;
    }

    return await getOrGenerateQCM(
      course: course,
      difficulty: recommendedDifficulty,
    );
  }
}