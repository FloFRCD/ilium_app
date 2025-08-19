import 'package:cloud_firestore/cloud_firestore.dart';
import 'text_normalizer.dart';
import 'logger.dart';

/// Utilitaire pour migrer et nettoyer les doublons dans Firestore
class FirestoreMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _programmesCollection = 'programme';
  static const String _coursesCollection = 'cours';

  /// Migre et nettoie tous les doublons de programmes
  static Future<void> migrateProgrammes() async {
    Logger.info('🧹 Début migration programmes - nettoyage des doublons');
    
    try {
      // 1. Récupérer tous les programmes existants
      final snapshot = await _firestore
          .collection(_programmesCollection)
          .get();

      Map<String, List<DocumentSnapshot>> programmeGroups = {};
      
      // 2. Grouper par matière/niveau/année normalisés
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final matiere = data['matiere'] as String? ?? '';
        final niveau = data['niveau'] as String? ?? '';
        final annee = data['annee'] as int? ?? DateTime.now().year;
        
        // Générer la clé normalisée
        final normalizedMatiere = TextNormalizer.normalizeMatiere(matiere);
        final normalizedNiveau = TextNormalizer.normalizeNiveau(niveau);
        final normalizedKey = '${normalizedMatiere}_${normalizedNiveau}_$annee';
        
        if (!programmeGroups.containsKey(normalizedKey)) {
          programmeGroups[normalizedKey] = [];
        }
        programmeGroups[normalizedKey]!.add(doc);
      }

      // 3. Traiter chaque groupe
      int mergedCount = 0;
      int deletedCount = 0;
      
      for (var entry in programmeGroups.entries) {
        final key = entry.key;
        final docs = entry.value;
        
        if (docs.length > 1) {
          Logger.info('📋 Trouvé ${docs.length} doublons pour: $key');
          
          // Garder le plus récent et fusionner les contenus
          await _mergeProgrammes(docs);
          mergedCount++;
          deletedCount += docs.length - 1;
        }
      }
      
      Logger.info('✅ Migration terminée: $mergedCount groupes fusionnés, $deletedCount doublons supprimés');
      
    } catch (e) {
      Logger.error('❌ Erreur migration programmes: $e');
    }
  }

  /// Fusionne plusieurs programmes doublons en un seul
  static Future<void> _mergeProgrammes(List<DocumentSnapshot> docs) async {
    try {
      // Trier par date de création (le plus récent en premier)
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        final aCreated = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bCreated = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        return bCreated.compareTo(aCreated); // Plus récent en premier
      });

      final mainDoc = docs.first;
      final mainData = mainDoc.data() as Map<String, dynamic>;
      
      // Normaliser les données du document principal
      final normalizedMatiere = TextNormalizer.normalizeMatiere(mainData['matiere'] as String? ?? '');
      final normalizedNiveau = TextNormalizer.normalizeNiveau(mainData['niveau'] as String? ?? '');
      
      // Fusionner les chapitres de tous les documents
      Set<String> allChapitres = {};
      String? bestContenu = mainData['contenu'] as String?;
      
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final chapitres = (data['chapitres'] as List?)?.cast<String>() ?? [];
        allChapitres.addAll(chapitres);
        
        // Garder le contenu le plus long/détaillé
        final contenu = data['contenu'] as String?;
        if (contenu != null && (bestContenu == null || contenu.length > bestContenu.length)) {
          bestContenu = contenu;
        }
      }

      // Créer le document fusionné avec des données normalisées
      final mergedData = {
        ...mainData,
        'matiere': normalizedMatiere,
        'niveau': normalizedNiveau,
        'chapitres': allChapitres.toList(),
        'contenu': bestContenu,
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          ...((mainData['metadata'] as Map<String, dynamic>?) ?? {}),
          'merged_from': docs.map((d) => d.id).toList(),
          'merged_at': DateTime.now().toIso8601String(),
        },
      };

      // Créer nouveau document avec ID normalisé
      final normalizedId = _generateNormalizedId(normalizedMatiere, normalizedNiveau, mainData['annee'] as int? ?? DateTime.now().year);
      
      await _firestore
          .collection(_programmesCollection)
          .doc(normalizedId)
          .set(mergedData);

      // Supprimer tous les anciens documents
      final batch = _firestore.batch();
      for (var doc in docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      Logger.info('🔄 Fusionné ${docs.length} programmes -> $normalizedId');
      
    } catch (e) {
      Logger.error('❌ Erreur fusion programmes: $e');
    }
  }

  /// Génère un ID normalisé pour éviter les doublons futurs
  static String _generateNormalizedId(String matiere, String niveau, int annee) {
    final normalizedMatiere = matiere.toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ç', 'c');
    
    final normalizedNiveau = niveau.toLowerCase()
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll(' ', '_');
    
    return '${normalizedMatiere}_${normalizedNiveau}_$annee';
  }

  /// Migre et nettoie tous les doublons de cours
  static Future<void> migrateCourses() async {
    Logger.info('🧹 Début migration cours - nettoyage des doublons');
    
    try {
      final snapshot = await _firestore
          .collection(_coursesCollection)
          .get();

      Map<String, List<DocumentSnapshot>> courseGroups = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String? ?? '';
        final matiere = data['matiere'] as String? ?? '';
        final niveau = data['niveau'] as String? ?? '';
        final type = data['type'] as String? ?? '';
        
        final normalizedMatiere = TextNormalizer.normalizeMatiere(matiere);
        final normalizedNiveau = TextNormalizer.normalizeNiveau(niveau);
        final normalizedKey = '${title.toLowerCase()}_${normalizedMatiere}_${normalizedNiveau}_$type';
        
        if (!courseGroups.containsKey(normalizedKey)) {
          courseGroups[normalizedKey] = [];
        }
        courseGroups[normalizedKey]!.add(doc);
      }

      int mergedCount = 0;
      int deletedCount = 0;
      
      for (var entry in courseGroups.entries) {
        final docs = entry.value;
        
        if (docs.length > 1) {
          Logger.info('📚 Trouvé ${docs.length} cours doublons pour: ${entry.key}');
          await _mergeCourses(docs);
          mergedCount++;
          deletedCount += docs.length - 1;
        }
      }
      
      Logger.info('✅ Migration cours terminée: $mergedCount groupes fusionnés, $deletedCount doublons supprimés');
      
    } catch (e) {
      Logger.error('❌ Erreur migration cours: $e');
    }
  }

  /// Fusionne plusieurs cours doublons
  static Future<void> _mergeCourses(List<DocumentSnapshot> docs) async {
    try {
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        final aCreated = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bCreated = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        return bCreated.compareTo(aCreated);
      });

      final mainDoc = docs.first;
      final mainData = mainDoc.data() as Map<String, dynamic>;
      
      final normalizedMatiere = TextNormalizer.normalizeMatiere(mainData['matiere'] as String? ?? '');
      final normalizedNiveau = TextNormalizer.normalizeNiveau(mainData['niveau'] as String? ?? '');
      
      String? bestContent = mainData['content'] as String?;
      
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final content = data['content'] as String?;
        if (content != null && (bestContent == null || content.length > bestContent.length)) {
          bestContent = content;
        }
      }

      final mergedData = {
        ...mainData,
        'matiere': normalizedMatiere,
        'niveau': normalizedNiveau,
        'content': bestContent,
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          ...((mainData['metadata'] as Map<String, dynamic>?) ?? {}),
          'merged_from': docs.map((d) => d.id).toList(),
          'merged_at': DateTime.now().toIso8601String(),
        },
      };

      await _firestore
          .collection(_coursesCollection)
          .doc(mainDoc.id)
          .set(mergedData);

      final batch = _firestore.batch();
      for (var doc in docs.skip(1)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      Logger.info('🔄 Fusionné ${docs.length} cours -> ${mainDoc.id}');
      
    } catch (e) {
      Logger.error('❌ Erreur fusion cours: $e');
    }
  }

  /// Lance la migration complète
  static Future<void> runFullMigration() async {
    Logger.info('🚀 Début migration complète Firestore');
    
    await migrateProgrammes();
    await migrateCourses();
    
    Logger.info('🎉 Migration complète terminée !');
  }
}