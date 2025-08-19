import '../models/user_model.dart';
import '../models/progression_model.dart';
import '../services/firestore_service.dart';
import '../services/subject_completion_service.dart';
import '../utils/logger.dart';

/// Service de migration pour convertir les anciennes progressions vers le nouveau système précis
class ProgressionMigrationService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Migre toutes les progressions d'un utilisateur vers le nouveau système
  Future<bool> migrateUserProgressions(String uid) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;

      Logger.info('🔄 Début migration progressions pour utilisateur: $uid');
      
      Map<String, SubjectProgressionModel> migratedProgressions = {};
      bool hasChanges = false;

      for (var entry in user.progression.subjectProgressions.entries) {
        final matiere = entry.key;
        final oldProgression = entry.value;
        
        // Vérifier si la progression a déjà les nouveaux champs
        if (oldProgression.requiredCoursesForCompletion > 0) {
          // Déjà migré, garder tel quel
          migratedProgressions[matiere] = oldProgression;
          continue;
        }

        // Migration nécessaire
        Logger.info('📝 Migration progression: $matiere ${oldProgression.niveau}');
        
        final criteria = SubjectCompletionService.getCompletionCriteria(matiere, user.niveau);
        
        // Estimer les cours complétés basé sur l'ancien pourcentage
        int estimatedCompletedCourses = 0;
        List<String> estimatedCourseIds = [];
        
        if (oldProgression.coursCompleted > 0) {
          // Générer des IDs de cours fictifs basés sur le nombre complété
          estimatedCompletedCourses = oldProgression.coursCompleted;
          for (int i = 1; i <= estimatedCompletedCourses; i++) {
            estimatedCourseIds.add('${matiere.toLowerCase()}_cours_$i');
          }
        }

        // Estimer si le QCM final a été réussi basé sur le score moyen et le nombre de QCM
        bool estimatedFinalQCMPassed = false;
        double estimatedFinalQCMScore = 0.0;
        
        if (oldProgression.qcmPassed > 0 && oldProgression.averageScore >= (criteria['minScore'] ?? 60.0)) {
          // Si l'utilisateur a un bon score moyen et a réussi des QCM, 
          // considérer que le QCM final pourrait être réussi
          estimatedFinalQCMPassed = oldProgression.averageScore >= (criteria['minScore'] ?? 60.0);
          estimatedFinalQCMScore = estimatedFinalQCMPassed ? oldProgression.averageScore : 0.0;
        }

        // Créer la nouvelle progression migrée
        final migratedProgression = oldProgression.copyWith(
          requiredCoursesForCompletion: criteria['requiredCourses'] ?? 0,
          hasPassedFinalQCM: estimatedFinalQCMPassed,
          finalQCMScore: estimatedFinalQCMScore,
          completedCourseIds: estimatedCourseIds,
          finalQCMId: criteria['finalQCMId'],
        );

        migratedProgressions[matiere] = migratedProgression;
        hasChanges = true;

        Logger.info('✅ Migration $matiere: ${estimatedCourseIds.length}/${criteria['requiredCourses']} cours, QCM final: $estimatedFinalQCMPassed');
        Logger.info('   Progression précise: ${migratedProgression.preciseCompletionPercentage.toStringAsFixed(1)}%');
      }

      // Sauvegarder si il y a eu des changements
      if (hasChanges) {
        final updatedProgression = user.progression.copyWith(
          subjectProgressions: migratedProgressions,
        );
        
        final updatedUser = user.copyWith(
          progression: updatedProgression,
          updatedAt: DateTime.now(),
        );

        await _firestoreService.saveUser(updatedUser);
        Logger.info('💾 Progressions migrées et sauvegardées pour $uid');
        return true;
      } else {
        Logger.info('ℹ️ Aucune migration nécessaire pour $uid');
        return true;
      }
    } catch (e) {
      Logger.error('❌ Erreur migration progressions pour $uid: $e');
      return false;
    }
  }

  /// Migre une progression spécifique si elle utilise l'ancien système
  Future<SubjectProgressionModel?> migrateSingleProgression({
    required SubjectProgressionModel progression,
    required String userLevel,
  }) async {
    try {
      // Vérifier si migration nécessaire
      if (progression.requiredCoursesForCompletion > 0) {
        return null; // Déjà migré
      }

      final criteria = SubjectCompletionService.getCompletionCriteria(progression.matiere, userLevel);
      
      // Estimation intelligente basée sur les données existantes
      List<String> estimatedCourseIds = [];
      if (progression.coursCompleted > 0) {
        for (int i = 1; i <= progression.coursCompleted; i++) {
          estimatedCourseIds.add('${progression.matiere.toLowerCase()}_cours_$i');
        }
      }

      bool estimatedFinalQCMPassed = false;
      double estimatedFinalQCMScore = 0.0;
      
      if (progression.qcmPassed > 0 && progression.averageScore >= (criteria['minScore'] ?? 60.0)) {
        estimatedFinalQCMPassed = true;
        estimatedFinalQCMScore = progression.averageScore;
      }

      return progression.copyWith(
        requiredCoursesForCompletion: criteria['requiredCourses'] ?? 0,
        hasPassedFinalQCM: estimatedFinalQCMPassed,
        finalQCMScore: estimatedFinalQCMScore,
        completedCourseIds: estimatedCourseIds,
        finalQCMId: criteria['finalQCMId'],
      );
    } catch (e) {
      Logger.error('Erreur migration progression ${progression.matiere}: $e');
      return null;
    }
  }

  /// Force la migration conservative pour éviter de perdre des progressions
  /// Utilise des valeurs par défaut sûres
  Future<bool> conservativeMigration(String uid) async {
    try {
      UserModel? user = await _firestoreService.getUser(uid);
      if (user == null) return false;

      Map<String, SubjectProgressionModel> safeProgressions = {};
      bool hasChanges = false;

      for (var entry in user.progression.subjectProgressions.entries) {
        final matiere = entry.key;
        final oldProgression = entry.value;
        
        if (oldProgression.requiredCoursesForCompletion > 0) {
          safeProgressions[matiere] = oldProgression;
          continue;
        }

        // Migration conservative : ne pas surestimer
        final criteria = SubjectCompletionService.getCompletionCriteria(matiere, user.niveau);
        
        final safeProgression = oldProgression.copyWith(
          requiredCoursesForCompletion: criteria['requiredCourses'] ?? 0,
          hasPassedFinalQCM: false, // Conservative: pas de QCM final réussi
          finalQCMScore: 0.0,
          completedCourseIds: [], // Conservative: redémarrer à zéro pour les IDs
          finalQCMId: criteria['finalQCMId'],
        );

        safeProgressions[matiere] = safeProgression;
        hasChanges = true;
      }

      if (hasChanges) {
        final updatedProgression = user.progression.copyWith(
          subjectProgressions: safeProgressions,
        );
        
        final updatedUser = user.copyWith(
          progression: updatedProgression,
          updatedAt: DateTime.now(),
        );

        await _firestoreService.saveUser(updatedUser);
        Logger.info('🔒 Migration conservative appliquée pour $uid');
        return true;
      }

      return true;
    } catch (e) {
      Logger.error('Erreur migration conservative: $e');
      return false;
    }
  }
}