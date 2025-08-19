import 'package:flutter/material.dart';
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
  
  @override
  void initState() {
    super.initState();
    // Utiliser les paramètres initiaux s'ils sont fournis, sinon utiliser les valeurs par défaut
    _niveauController.text = widget.initialNiveau ?? widget.user.niveau;
    _matiereController.text = widget.initialMatiere ?? 'Mathématiques';
    
    // Initialiser les options avec les spécialités de l'utilisateur
    _options.addAll(widget.user.options);
    
    // Si des paramètres initiaux sont fournis, lancer la recherche automatiquement
    if (widget.initialNiveau != null || widget.initialMatiere != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProgramme();
      });
    } else {
      // Sinon charger le programme par défaut
      _loadDefaultProgramme();
    }
  }

  /// Charge le programme par défaut pour Mathématiques du niveau de l'utilisateur
  Future<void> _loadDefaultProgramme() async {
    if (widget.user.niveau.isEmpty) {
      Logger.warning('Niveau utilisateur vide, impossible de charger le programme');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _mockCourses = [];
    });
    
    try {
      // Charger le programme de Mathématiques par défaut avec spécialités
      // Utiliser la méthode simple en cas de problème avec l'optimisée
      final programme = await _programmeService.getProgramme(
        matiere: 'Mathématiques',
        niveau: widget.user.niveau,
        options: _options,
      );
      
      if (programme != null && programme.chapitres.isNotEmpty) {
        setState(() {
          _mockCourses = programme.chapitres;
          _isLoading = false;
        });
      } else {
        setState(() {
          _mockCourses = ['Aucun programme disponible pour ${widget.user.niveau} en Mathématiques avec spécialités: ${_options.join(', ')}'];
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erreur loadDefaultProgramme: $e');
      setState(() {
        _mockCourses = ['Erreur lors du chargement du programme: $e'];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _matiereController.dispose();
    _niveauController.dispose();
    super.dispose();
  }

  /// Charge le programme depuis Firebase ou le génère
  Future<void> _loadProgramme() async {
    if (_matiereController.text.trim().isEmpty || _niveauController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez renseigner une matière et un niveau'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _mockCourses = [];
    });
    
    try {
      // Normaliser les entrées utilisateur
      final matiere = TextNormalizer.normalizeMatiere(_matiereController.text);
      final niveau = TextNormalizer.normalizeNiveau(_niveauController.text);
      
      // Mettre à jour les contrôleurs avec les valeurs normalisées
      _matiereController.text = matiere;
      _niveauController.text = niveau;
      
      // Charger le programme depuis Firebase ou le générer (avec optimisation par spécialités)
      final programme = await _programmeService.getProgramme(
        matiere: matiere,
        niveau: niveau,
        options: _options,
      );
      
      if (programme != null) {
        setState(() {
          _mockCourses = programme.chapitres;
          _isLoading = false;
        });
        
        // Afficher un message selon la source
        if (mounted && programme.source == 'generated' && programme.createdAt.isAfter(DateTime.now().subtract(Duration(seconds: 30)))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Programme généré et sauvegardé !'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() {
          _mockCourses = _generateMockCourses(matiere, niveau, _options); // Fallback
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement - données temporaires affichées'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Erreur _loadProgramme: $e');
      setState(() {
        _mockCourses = []; // Fallback
        _isLoading = false;
      });
      
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

  /// Génère des cours mock adaptés uniquement à la matière et au niveau
  /// Les options représentent les spécialités de l'étudiant mais n'influencent pas le programme de la matière demandée
  List<String> _generateMockCourses(String matiere, String niveau, List<String> options) {
    final matiereBase = matiere.toLowerCase();
    final niveauBase = niveau.toLowerCase();
    List<String> baseCourses = [];
    
    if (matiereBase.contains('math')) {
      if (niveauBase.contains('terminale')) {
        baseCourses = [
          'Limites et continuité des fonctions',
          'Dérivation et applications',
          'Fonction logarithme népérien',
          'Fonction exponentielle',
          'Intégration et primitives',
          'Géométrie dans l\'espace: droites et plans',
          'Suites numériques et convergence',
          'Probabilités conditionnelles',
        ];
      } else if (niveauBase.contains('1ère') || niveauBase.contains('première')) {
        baseCourses = [
          'Second degré et paraboles',
          'Dérivation: nombre dérivé et tangente',
          'Suites arithmétiques et géométriques',
          'Probabilités et variables aléatoires',
          'Géométrie repérée dans le plan',
          'Trigonométrie et cercle trigonométrique',
        ];
      } else {
        baseCourses = [
          'Les nombres et calculs',
          'Géométrie plane', 
          'Fonctions et représentations',
          'Statistiques et probabilités',
        ];
      }
    } else if (matiereBase.contains('fran') || matiereBase.contains('français')) {
      if (niveauBase.contains('terminale')) {
        baseCourses = [
          'La littérature d\'idées: Montaigne, La Bruyère',
          'Le théâtre: Marivaux et Beaumarchais',
          'La poésie du XIXe au XXIe siècle: Baudelaire, Apollinaire',
          'Le roman et le récit: Proust, Céline',
          'L\'argumentation et la dissertation',
          'Analyse stylistique et commentaire composé',
          'Histoire littéraire: les mouvements artistiques',
          'Expression orale et débat argumenté',
        ];
      } else if (niveauBase.contains('1ère') || niveauBase.contains('première')) {
        baseCourses = [
          'Le roman et ses personnages: Balzac, Stendhal',
          'Le théâtre du XVIIe siècle: Molière, Racine',
          'La poésie du Moyen Âge au XVIIIe siècle',
          'La question de l\'Homme dans l\'argumentation',
          'L\'écriture poétique et la quête du sens',
          'Le personnage de roman du XVIIe siècle à nos jours',
        ];
      } else {
        baseCourses = [
          'Lecture et compréhension de textes',
          'Expression écrite et rédaction',
          'Grammaire et syntaxe',
          'Vocabulaire et étymologie',
        ];
      }
    } else if (matiereBase.contains('phys') || matiereBase.contains('chimie')) {
      if (niveauBase.contains('terminale')) {
        baseCourses = [
          'Mécanique: mouvement dans un champ',
          'Électricité: circuits RC et RL',
          'Ondes: interférences et diffraction',
          'Optique: lunettes et télescopes',
          'Chimie organique: polymères et biomolécules',
          'Cinétique chimique et catalyse',
          'Thermodynamique: machines thermiques',
        ];
      } else {
        baseCourses = [
          'Mécanique et forces',
          'Électricité et circuits',
          'Optique et lumière',
          'Réactions chimiques',
          'Atomistique',
        ];
      }
    } else if (matiereBase.contains('svt') || matiereBase.contains('bio')) {
      if (niveauBase.contains('terminale')) {
        baseCourses = [
          'Génétique et évolution: brassage génétique',
          'Géologie: histoire de la Terre et datation',
          'Écosystèmes et dynamique des populations',
          'Neurobiologie et comportement',
          'Corps humain: reproduction et sexualité',
          'Immunologie et défenses de l\'organisme',
          'Photosynthèse et respiration cellulaire',
        ];
      } else {
        baseCourses = [
          'La cellule et ses constituants',
          'Reproduction et hérédité',
          'Écosystèmes et chaînes alimentaires',
          'Corps humain et fonctions vitales',
        ];
      }
    } else if (matiereBase.contains('hist') || matiereBase.contains('géo')) {
      if (niveauBase.contains('terminale')) {
        baseCourses = [
          'Histoire: la Seconde Guerre mondiale',
          'Histoire: la guerre froide (1947-1991)',
          'Géographie: mondialisation et territoires',
          'Géographie: dynamiques territoriales de la France',
          'Histoire: gouverner la France depuis 1946',
          'Géographie: l\'Asie du Sud et de l\'Est',
        ];
      } else {
        baseCourses = [
          'Histoire: l\'Europe et le monde au XVIIIe siècle',
          'Histoire: révolutions et nationalismes',
          'Géographie: populations et développement',
          'Géographie: gérer les ressources terrestres',
        ];
      }
    } else if (matiereBase.contains('angl')) {
      if (niveauBase.contains('terminale')) {
        baseCourses = [
          'Myths and heroes: American Dream',
          'Spaces and exchanges: globalization',
          'Places and forms of power: democracy',
          'The idea of progress: technological advances',
          'Literature: Shakespeare and modern authors',
          'Essay writing and argumentation',
        ];
      } else {
        baseCourses = [
          'Grammar fundamentals and tenses',
          'Vocabulary building through themes',
          'Reading comprehension strategies',
          'Writing skills development',
        ];
      }
    } else {
      // Cours générique pour toute autre matière
      baseCourses = [
        'Introduction à la $matiere',
        'Concepts fondamentaux',
        'Méthodes et techniques',
        'Applications pratiques',
        'Exercices et révisions',
        'Approfondissements',
        'Synthèse et évaluation',
      ];
    }
    
    // Les options représentent les spécialités choisies par l'étudiant
    // mais n'influencent pas le programme de la matière demandée
    // (un cours de français reste un cours de français, même si l'étudiant a pris option maths)
    
    return baseCourses;
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


  /// Affiche le dialogue pour générer de nouveaux cours
  void _showGenerateCourseDialog(String courseTitle, String matiere, String niveau) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Générer des cours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucun cours trouvé pour "$courseTitle".',
              style: AppTextStyles.body,
            ),
            SizedBox(height: 16),
            Text(
              'Voulez-vous générer les types de cours suivants ?',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            ...CourseType.values.map((type) => ListTile(
              leading: Icon(_getCourseIcon(type), color: AppColors.primary),
              title: Text(_getCourseTypeLabel(type)),
              trailing: Icon(Icons.add_circle_outline, color: AppColors.primary),
              onTap: () {
                Navigator.of(context).pop();
                _generateCourse(courseTitle, matiere, niveau, type);
              },
            )),
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
        MediaQuery.of(context).padding.top + AppSpacing.md,
        isSmallScreen ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.lg,
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
        children: [
          // Titre principal
          Row(
            children: [
              Container(
                width: isSmallScreen ? 36 : 44,
                height: isSmallScreen ? 36 : 44,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.school,
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
                      'Explorez le programme scolaire complet',
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
    return Column(
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
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
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
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Bouton de recherche sans fond
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _loadProgramme,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Recherche...',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.white,
                        fontSize: 15,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.search,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Rechercher le programme',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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
      body: Column(
            children: [
              // Header moderne avec dégradé
              _buildModernHeader(),
              
              // Affichage des spécialités de l'utilisateur
              if (_options.isNotEmpty) _buildSpecialitesSection(),
              
              // Liste des cours
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _isLoading 
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _mockCourses.isEmpty 
                ? Center(
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
                            'Renseignez une matière et un niveau pour découvrir le programme officiel',
                            style: AppTextStyles.body.copyWith(color: AppColors.grey500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Exemple: Terminale, Mathématiques',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _mockCourses.length,
                    itemBuilder: (context, index) {
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
                            'Cliquez pour explorer les ressources disponibles',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.grey400,
                          ),
                          onTap: () => _navigateToCourse(course),
                        ),
                      );
                    },
                  ),
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