import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/qcm_model.dart';
import '../services/programme_service.dart';
import '../services/intelligent_search_service.dart';
import '../services/qcm_service.dart';
import '../theme/app_theme.dart';
import '../utils/text_normalizer.dart';
import '../utils/logger.dart';
import 'course_detail_screen.dart';
import 'qcm_screen.dart';

/// Version fonctionnelle de ProgrammeScreen avec données mock
class ProgrammeScreenWorking extends StatefulWidget {
  final UserModel user;
  final String? initialNiveau;
  final String? initialMatiere;

  const ProgrammeScreenWorking({
    super.key, 
    required this.user,
    this.initialNiveau,
    this.initialMatiere,
  });

  @override
  State<ProgrammeScreenWorking> createState() => _ProgrammeScreenWorkingState();
}

class _ProgrammeScreenWorkingState extends State<ProgrammeScreenWorking> {
  final TextEditingController _matiereController = TextEditingController();
  final TextEditingController _niveauController = TextEditingController();
  final ProgrammeService _programmeService = ProgrammeService();
  final IntelligentSearchService _searchService = IntelligentSearchService();
  final QCMService _qcmService = QCMService();
  List<String> _mockCourses = [];
  bool _isLoading = false;
  final List<String> _options = []; // Options modifiables (initialisées avec les spécialités utilisateur)
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderCollapsed = false;
  
  @override
  void initState() {
    super.initState();
    // Utiliser les paramètres initiaux s'ils sont fournis, sinon laisser vide
    _niveauController.text = widget.initialNiveau ?? widget.user.niveau;
    _matiereController.text = widget.initialMatiere ?? ''; // Pas de présélection
    
    // Initialiser les options avec les spécialités de l'utilisateur
    _options.addAll(widget.user.options);
    
    // Configurer le listener pour détecter le scroll
    _scrollController.addListener(_onScroll);
    
    // Charger automatiquement le programme complet au lancement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompleteProgramme();
    });
  }

  void _onScroll() {
    const double threshold = 100.0; // Seuil de scroll pour réduire le header
    if (_scrollController.offset > threshold && !_isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = true;
      });
    } else if (_scrollController.offset <= threshold && _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = false;
      });
    }
  }

  /// Charge le programme complet avec toutes les matières (niveau 1 - matières seulement)
  Future<void> _loadCompleteProgramme() async {
    if (widget.user.niveau.isEmpty) {
      Logger.warning('Niveau utilisateur vide, impossible de charger le programme');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _mockCourses = [];
    });
    
    try {
      // Utiliser le nouveau système de génération niveau 1
      final programme = await _programmeService.getProgrammeComplet(
        niveau: widget.user.niveau,
        options: _options,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Logger.warning('⏰ Timeout programme complet');
          return null;
        },
      );
      
      if (programme != null && programme.chapitres.isNotEmpty) {
        if (mounted) {
          setState(() {
            _mockCourses = programme.chapitres; // Les chapitres contiennent les matières
            _isLoading = false;
          });
        }
      } else {
        // Pas de programme trouvé - lancer la génération en arrière-plan
        Logger.info('🚀 Aucun programme trouvé, génération en cours...');
        if (mounted) {
          // Rester en état de chargement, programmer des vérifications
          _scheduleDataRefresh();
        }
      }
    } catch (e) {
      Logger.error('❌ Erreur loadCompleteProgramme: $e');
      if (mounted) {
        // En cas d'erreur, aussi programmer des vérifications plutôt qu'afficher du fallback
        Logger.info('🔄 Erreur rencontrée, programmation des vérifications...');
        _scheduleDataRefresh();
      }
    }
  }
  

  /// Programme une vérification de nouvelles données avec polling progressif
  void _scheduleDataRefresh() {
    Logger.info('📅 Programmation des vérifications automatiques de données...');
    
    // Première vérification après 10 secondes
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        Logger.info('🔍 [1/3] Première vérification de nouvelles données...');
        _checkForUpdatedData();
      }
    });
    
    // Deuxième vérification après 20 secondes
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        Logger.info('🔍 [2/3] Deuxième vérification de nouvelles données...');
        _checkForUpdatedData();
      }
    });
    
    // Troisième vérification après 35 secondes
    Future.delayed(const Duration(seconds: 35), () {
      if (mounted) {
        Logger.info('🔍 [3/3] Vérification finale de nouvelles données...');
        _checkForUpdatedData();
      }
    });
  }

  /// Vérifie s'il y a de nouvelles données générées et met à jour l'interface
  Future<void> _checkForUpdatedData() async {
    try {
      Logger.info('🔄 Vérification de nouvelles données via Firestore direct...');
      
      // Générer l'ID du programme pour requête directe Firestore
      final programmeId = _generateProgrammeId();
      
      // Requête directe Firestore pour éviter le cache local
      final doc = await FirebaseFirestore.instance
          .collection('programme')
          .doc(programmeId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final source = data['source'] as String?;
        final chapitres = (data['chapitres'] as List<dynamic>?)?.cast<String>() ?? [];
        
        Logger.info('🔍 Programme trouvé - Source: $source, Chapitres: ${chapitres.length}');
        
        // Vérifier si on a des données OpenAI valides 
        if (source == 'generated_openai' && chapitres.isNotEmpty && mounted) {
          if (!_listsEqual(chapitres, _mockCourses)) {
            Logger.info('✅ Nouvelles données OpenAI détectées, mise à jour de l\'interface');
            setState(() {
              _mockCourses = chapitres;
              _isLoading = false; // Arrêter le loading une fois qu'on a les vraies données
            });
          } else {
            Logger.info('ℹ️ Données OpenAI identiques, pas de mise à jour nécessaire');
            // S'assurer que le loading s'arrête même si les données sont identiques
            if (_isLoading) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        } else {
          Logger.info('ℹ️ Pas de données OpenAI valides (source: $source, chapitres: ${chapitres.length})');
        }
      } else {
        Logger.info('ℹ️ Aucun programme trouvé avec l\'ID: $programmeId');
      }
    } catch (e) {
      Logger.error('❌ Erreur lors de la vérification des nouvelles données: $e');
    }
  }
  
  /// Compare deux listes pour voir si elles sont identiques
  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
  
  /// Génère l'ID du programme pour la requête directe
  String _generateProgrammeId() {
    final year = DateTime.now().year;
    final normalizedNiveau = widget.user.niveau.toLowerCase().replaceAll(' ', '_');
    final optionsStr = _options.isEmpty ? '' : '_${_options.join('_').toLowerCase().replaceAll(' ', '_')}';
    return 'complete_${normalizedNiveau}_$year$optionsStr';
  }


  @override
  void dispose() {
    _matiereController.dispose();
    _niveauController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Charge le programme depuis Firebase ou le génère
  Future<void> _loadProgramme() async {
    // Si aucune matière sélectionnée, recharger le programme complet (niveau 1)
    if (_matiereController.text.trim().isEmpty) {
      await _loadCompleteProgramme();
      return;
    }
    
    // Sinon, charger le programme détaillé de la matière (niveau 2)
    setState(() {
      _isLoading = true;
      _mockCourses = [];
    });
    
    try {
      // Normaliser les entrées utilisateur
      final matiere = TextNormalizer.normalizeMatiere(_matiereController.text);
      final niveau = TextNormalizer.normalizeNiveau(_niveauController.text.isNotEmpty 
          ? _niveauController.text 
          : widget.user.niveau);
      
      // Mettre à jour les contrôleurs avec les valeurs normalisées
      _matiereController.text = matiere;
      _niveauController.text = niveau;
      
      // Utiliser le nouveau système niveau 2 pour programme détaillé de la matière
      final programme = await _programmeService.getProgrammeMatiere(
        matiere: matiere,
        niveau: niveau,
        options: _options,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Logger.warning('⏰ Timeout programme matière - lancement génération en arrière-plan');
          return null;
        },
      );
      
      if (programme != null) {
        setState(() {
          _mockCourses = programme.chapitres;
          _isLoading = false;
        });
        
        // Afficher un message selon la source
        if (mounted && programme.source == 'generated_matiere' && programme.createdAt.isAfter(DateTime.now().subtract(Duration(seconds: 30)))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Programme détaillé généré et sauvegardé !'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Pas de programme trouvé - lancer la génération en arrière-plan
        Logger.info('🚀 Aucun programme de matière trouvé, génération en cours...');
        if (mounted) {
          // Rester en état de chargement, programmer des vérifications
          _scheduleDataRefresh();
        }
      }
    } catch (e) {
      Logger.error('❌ Erreur _loadProgramme: $e');
      if (mounted) {
        // En cas d'erreur, aussi programmer des vérifications plutôt qu'afficher du fallback
        Logger.info('🔄 Erreur rencontrée, programmation des vérifications...');
        _scheduleDataRefresh();
      }
    }
  }



  /// Calcule la hauteur du header dynamiquement selon le contenu
  double _calculateHeaderHeight() {
    if (_isHeaderCollapsed) return 120;
    
    // Hauteur de base pour le header étendu
    double baseHeight = 280;
    
    // Ajouter de l'espace si le sous-titre est long (matière spécifique)
    if (_matiereController.text.trim().isNotEmpty) {
      String subtitle = 'Programme détaillé de ${_matiereController.text}';
      
      // Estimation plus précise basée sur la longueur du texte et la taille d'écran
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;
      
      // Sur petit écran, les textes longs passent plus facilement sur 2 lignes
      int threshold = isSmallScreen ? 25 : 35;
      
      if (subtitle.length > threshold) {
        baseHeight += isSmallScreen ? 35 : 25; // Plus d'espace sur petit écran
      }
    }
    
    return baseHeight;
  }

  /// Ajoute une nouvelle option
  void _addOption() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Ajouter une option'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nom de l\'option',
              hintText: 'Ex: Mathématiques, Physique-Chimie, SVT...',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _options.add(controller.text.trim());
                  });
                }
                Navigator.pop(context);
              },
              child: Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  /// Supprime une option
  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  /// Gère la sélection d'un élément (matière ou chapitre) dans la liste
  Future<void> _handleCourseSelection(String selectedItem) async {
    // Si aucune matière sélectionnée dans le champ, cela signifie qu'on est en mode niveau 1 (liste des matières)
    if (_matiereController.text.trim().isEmpty) {
      // L'utilisateur a cliqué sur une matière, charger le programme détaillé
      _matiereController.text = selectedItem;
      await _loadProgramme(); // Cela va maintenant utiliser getProgrammeMatiere
      return;
    }
    
    // Sinon, on est en niveau 2 (liste des chapitres), naviguer vers les cours
    await _navigateToCourse(selectedItem);
  }

  /// Navigate vers les cours disponibles pour ce chapitre avec popup de sélection
  Future<void> _navigateToCourse(String courseTitle) async {
    if (_matiereController.text.trim().isEmpty || _niveauController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Matière et niveau requis'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final matiere = TextNormalizer.normalizeMatiere(_matiereController.text);
    final niveau = TextNormalizer.normalizeNiveau(_niveauController.text);

    try {
      // Recherche rapide SANS génération pour voir ce qui existe déjà
      final existingCourses = await _searchService.findExistingCourses(
        query: courseTitle,
        matiere: matiere,
        niveau: niveau,
        options: _options.isNotEmpty ? _options : null,
      );

      // Afficher immédiatement le dialogue de choix du type de cours
      _showCourseTypeDialog(courseTitle, matiere, niveau, existingCourses);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Affiche le dialogue de choix du type de cours
  void _showCourseTypeDialog(String courseTitle, String matiere, String niveau, List<CourseModel> existingCourses) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          courseTitle,
          style: AppTextStyles.h3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisissez le type de contenu souhaité :',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            ...CourseType.values.map((type) {
              // Vérifier si ce type existe déjà
              final existingCourse = existingCourses.where((c) => c.type == type).firstOrNull;
              final isAvailable = existingCourse != null;
              
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isAvailable 
                          ? (existingCourse.authorId == 'ia_assistant' 
                              ? AppColors.energyGradient 
                              : AppColors.primaryGradient)
                          : LinearGradient(
                              colors: [AppColors.greyMedium, AppColors.greyLight],
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCourseIcon(type),
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _getCourseTypeLabel(type),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    isAvailable 
                        ? (existingCourse.authorId == 'ia_assistant' ? 'Disponible (Auto)' : 'Disponible (Communauté)')
                        : 'À générer',
                    style: AppTextStyles.caption.copyWith(
                      color: isAvailable ? AppColors.success : AppColors.greyMedium,
                    ),
                  ),
                  trailing: Icon(
                    isAvailable ? Icons.play_arrow : Icons.add_circle_outline,
                    color: isAvailable ? AppColors.primary : AppColors.greyMedium,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (isAvailable) {
                      // Afficher le cours existant
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CourseDetailScreen(
                            course: existingCourse,
                            user: widget.user,
                          ),
                        ),
                      );
                    } else {
                      // Générer le cours manquant
                      _generateCourse(courseTitle, matiere, niveau, type);
                    }
                  },
                ),
              );
            }),
            SizedBox(height: 16),
            Container(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent1, AppColors.accent2],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.quiz_outlined,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  'QCM d\'évaluation',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Questions et exercices',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.greyMedium,
                  ),
                ),
                trailing: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.accent1,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectQCMDifficulty(courseTitle, matiere, niveau);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }



  /// Affiche le dialogue de sélection de difficulté QCM
  void _selectQCMDifficulty(String courseTitle, String matiere, String niveau) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.quiz_outlined, color: AppColors.accent1),
            SizedBox(width: 8),
            Text('Choisir la difficulté'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sélectionnez le niveau de difficulté pour le QCM :',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ...QCMDifficulty.values.map((difficulty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _generateQCM(courseTitle, matiere, niveau, difficulty);
                    },
                    icon: Icon(_getDifficultyIcon(difficulty)),
                    label: Text(_getDifficultyLabel(difficulty)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getDifficultyColor(difficulty),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  /// Génère un QCM pour le chapitre avec la difficulté choisie
  Future<void> _generateQCM(String courseTitle, String matiere, String niveau, QCMDifficulty difficulty) async {
    // Afficher dialogue de génération en 2 étapes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accent1),
              SizedBox(height: 16),
              Text(
                'Étape 1/2: Génération du contenu...',
                style: AppTextStyles.body,
              ),
              SizedBox(height: 8),
              Text(
                courseTitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.greyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Étape 1: D'abord générer ou récupérer un cours de base
      final searchResult = await _searchService.searchCourses(
        query: courseTitle,
        user: widget.user,
        matiere: matiere,
        niveau: niveau,
        type: CourseType.fiche, // Fiche de révision pour base du QCM
        options: _options.isNotEmpty ? _options : null,
      );

      if (searchResult.courses.isEmpty) {
        // Fermer le dialogue de génération
        if (mounted) Navigator.of(context).pop();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible de générer le contenu de base'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final baseCourse = searchResult.courses.first;

      // Mettre à jour le dialogue pour l'étape 2
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le premier dialogue
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.accent1),
                  SizedBox(height: 16),
                  Text(
                    'Étape 2/2: Génération du QCM...',
                    style: AppTextStyles.body,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Questions de niveau moyen',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.greyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Étape 2: Générer le QCM basé sur le cours
      final qcm = await _qcmService.getOrGenerateQCM(
        course: baseCourse,
        difficulty: difficulty,
        numberOfQuestions: _getQuestionsCountForDifficulty(difficulty),
      );

      // Fermer le dialogue de génération
      if (mounted) Navigator.of(context).pop();

      if (qcm != null) {
        if (mounted) {
          // Navigation directe vers l'écran QCM
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QCMScreen(
                qcm: qcm,
                user: widget.user,
                matiere: matiere,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la génération du QCM'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Fermer le dialogue de génération
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Génère un nouveau cours
  Future<void> _generateCourse(String courseTitle, String matiere, String niveau, CourseType type) async {
    // Afficher dialogue de génération
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Génération du cours...',
                style: AppTextStyles.body,
              ),
              SizedBox(height: 8),
              Text(
                _getCourseTypeLabel(type),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.greyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final searchResult = await _searchService.searchCourses(
        query: courseTitle,
        user: widget.user,
        matiere: matiere,
        niveau: niveau,
        type: type,
        options: _options.isNotEmpty ? _options : null,
      );

      // Fermer le dialogue de génération
      if (mounted) Navigator.of(context).pop();

      if (searchResult.courses.isNotEmpty) {
        final course = searchResult.courses.first;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cours généré avec succès !'),
              backgroundColor: AppColors.success,
            ),
          );

          // Naviguer vers le cours généré
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(
                course: course,
                user: widget.user,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la génération du cours'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Fermer le dialogue de génération
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Retourne l'icône pour un type de cours
  IconData _getCourseIcon(CourseType type) {
    switch (type) {
      case CourseType.fiche:
        return Icons.description_outlined;
      case CourseType.vulgarise:
        return Icons.psychology_outlined;
      case CourseType.cours:
        return Icons.school_outlined;
    }
  }

  /// Retourne le label pour un type de cours
  String _getCourseTypeLabel(CourseType type) {
    switch (type) {
      case CourseType.fiche:
        return 'Fiche de révision';
      case CourseType.vulgarise:
        return 'Vulgarisation';
      case CourseType.cours:
        return 'Cours complet';
    }
  }

  // Header moderne avec style cohérent à la page cours
  Widget _buildModernHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? AppSpacing.md : AppSpacing.lg,
        MediaQuery.of(context).padding.top + AppSpacing.lg,
        isSmallScreen ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre principal
          Row(
            children: [
              // Bouton retour si on est en niveau 2 (matière sélectionnée)
              if (_matiereController.text.trim().isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    _matiereController.clear();
                    _loadCompleteProgramme();
                  },
                  child: Container(
                    width: isSmallScreen ? 36 : 44,
                    height: isSmallScreen ? 36 : 44,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
              ],
              Container(
                width: isSmallScreen ? 36 : 44,
                height: isSmallScreen ? 36 : 44,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _matiereController.text.trim().isEmpty ? Icons.school : Icons.subject,
                  color: AppColors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Programme',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isSmallScreen ? 20 : null,
                      ),
                    ),
                    Text(
                      _matiereController.text.trim().isEmpty
                          ? 'Explorez le programme scolaire complet'
                          : 'Programme détaillé de ${_matiereController.text}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontSize: isSmallScreen ? 14 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Section de recherche moderne
          _buildModernSearchSection(),
        ],
      ),
    );
  }

  // Section de recherche moderne
  Widget _buildModernSearchSection() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200), // Limiter la hauteur
      child: SingleChildScrollView( // Rendre scrollable si nécessaire
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prendre le minimum d'espace
          children: [
            // Champ niveau
            TextField(
              controller: _niveauController,
              style: AppTextStyles.body.copyWith(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Niveau (Ex: Terminale, L1, BTS...)',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                prefixIcon: const Icon(Icons.school, color: AppColors.white),
                filled: true,
                fillColor: AppColors.white.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Réduire le padding
              ),
            ),
            
            const SizedBox(height: AppSpacing.sm), // Réduire l'espacement
            
            // Champ matière
            TextField(
              controller: _matiereController,
              style: AppTextStyles.body.copyWith(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Matière (Ex: Mathématiques, Physique...)',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                prefixIcon: const Icon(Icons.subject, color: AppColors.white),
                filled: true,
                fillColor: AppColors.white.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Réduire le padding
              ),
            ),
            
            const SizedBox(height: AppSpacing.md), // Réduire l'espacement
            
            // Bouton de recherche sans fond
            SizedBox(
              width: double.infinity,
              height: 44, // Réduire la hauteur
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _loadProgramme,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading) ...[
                          SizedBox(
                            width: 18, // Réduire la taille
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible( // Rendre flexible
                            child: Text(
                              'Recherche...',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.white,
                                fontSize: 14, // Réduire la taille
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.search,
                            color: AppColors.white,
                            size: 18, // Réduire la taille
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible( // Rendre flexible
                            child: Text(
                              'Rechercher le programme',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.white,
                                fontSize: 14, // Réduire la taille
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la section d'affichage des spécialités
  Widget _buildSpecialitesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Spécialités prises en compte',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              ..._options.map((specialite) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        specialite,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: () => _removeOption(_options.indexOf(specialite)),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Bouton d'ajout de spécialité
              GestureDetector(
                onTap: _addOption,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Ajouter',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ces spécialités influencent la personnalisation du programme généré',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header collapsible avec hauteur dynamique
          SliverAppBar(
            expandedHeight: _calculateHeaderHeight(),
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: (_matiereController.text.trim().isNotEmpty && _isHeaderCollapsed)
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () {
                      _matiereController.clear();
                      _loadCompleteProgramme();
                    },
                  )
                : null,
            title: AnimatedOpacity(
              opacity: _isHeaderCollapsed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _matiereController.text.trim().isEmpty ? Icons.school : Icons.subject,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Programme',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          _matiereController.text.trim().isEmpty
                              ? 'Explorez le programme scolaire complet'
                              : 'Programme détaillé de ${_matiereController.text}',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildModernHeader(),
            ),
          ),
          
          // Section spécialités si présente
          if (_options.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSpecialitesSection(),
            ),
          
          // Contenu principal - état de chargement
          if (_isLoading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_mockCourses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Aucun programme trouvé',
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.grey600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _matiereController.text.trim().isEmpty
                                ? 'Votre programme complet va apparaître ici.\nAssurez-vous d\'avoir renseigné votre niveau dans le profil.'
                                : 'Aucun chapitre trouvé pour cette matière.\nEssayez de régénérer le programme.',
                            style: AppTextStyles.body.copyWith(color: AppColors.grey500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _matiereController.text.trim().isEmpty
                                ? 'Exemple: Renseignez "Terminale" dans votre profil'
                                : 'Exemple: Effacez la matière pour revenir au programme complet',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            else
              // Liste des cours
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final course = _mockCourses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            course,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _matiereController.text.trim().isEmpty 
                                ? 'Cliquez pour voir le programme détaillé'
                                : 'Cliquez pour explorer les ressources disponibles',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.grey400,
                          ),
                          onTap: () => _handleCourseSelection(course),
                        ),
                      );
                    },
                    childCount: _mockCourses.length,
                  ),
                ),
        ],
      ),
    );
  }



  /// Retourne l'icône correspondant à la difficulté
  IconData _getDifficultyIcon(QCMDifficulty difficulty) {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return Icons.sentiment_satisfied;
      case QCMDifficulty.moyen:
        return Icons.sentiment_neutral;
      case QCMDifficulty.difficile:
        return Icons.sentiment_dissatisfied;
      case QCMDifficulty.tresDifficile:
        return Icons.warning;
    }
  }

  /// Retourne le label correspondant à la difficulté
  String _getDifficultyLabel(QCMDifficulty difficulty) {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return 'Facile (Questions de base)';
      case QCMDifficulty.moyen:
        return 'Moyen (Questions standard)';
      case QCMDifficulty.difficile:
        return 'Difficile (Questions avancées)';
      case QCMDifficulty.tresDifficile:
        return 'Très difficile (Questions d\'expert)';
    }
  }

  /// Retourne la couleur correspondant à la difficulté
  Color _getDifficultyColor(QCMDifficulty difficulty) {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return AppColors.success;
      case QCMDifficulty.moyen:
        return AppColors.warning;
      case QCMDifficulty.difficile:
        return AppColors.error;
      case QCMDifficulty.tresDifficile:
        return AppColors.black;
    }
  }

  /// Retourne le nombre de questions selon la difficulté
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
}