import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as dart_math;
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/qcm_model.dart';
import '../services/course_catalog_service.dart';
import '../widgets/grouped_favorite_button.dart';
import '../theme/app_theme.dart';
import '../utils/course_type_utils.dart';
import '../utils/logger.dart';
import '../utils/text_normalizer.dart';
import 'course_detail_screen.dart';
import 'qcm_screen.dart';

/// Types de contenu disponibles dans le catalogue (Cours + QCM)
enum ContentType {
  cours,
  qcm,
}

/// Classe pour unifier cours et QCM dans l'affichage
class CatalogItem {
  final String id;
  final String title;
  final String matiere;
  final String niveau;
  final ContentType contentType;
  final CourseModel? course;
  final QCMModel? qcm;
  final double? averageUserScore;
  
  CatalogItem({
    required this.id,
    required this.title,
    required this.matiere,
    required this.niveau,
    required this.contentType,
    this.course,
    this.qcm,
    this.averageUserScore,
  });
  
  factory CatalogItem.fromCourse(CourseModel course) {
    return CatalogItem(
      id: course.id,
      title: course.title,
      matiere: course.matiere,
      niveau: course.niveau,
      contentType: ContentType.cours,
      course: course,
    );
  }
  
  factory CatalogItem.fromQCM(QCMModel qcm, {double? averageScore, String? matiere, String? niveau}) {
    return CatalogItem(
      id: qcm.id,
      title: qcm.title,
      matiere: matiere ?? 'General',
      niveau: niveau ?? 'Tous niveaux',
      contentType: ContentType.qcm,
      qcm: qcm,
      averageUserScore: averageScore,
    );
  }
}

/// Écran principal "Contenu" - Catalogue de cours et QCM avec recherche
class EnhancedCoursesScreen extends StatefulWidget {
  final UserModel user;

  const EnhancedCoursesScreen({super.key, required this.user});

  @override
  State<EnhancedCoursesScreen> createState() => _EnhancedCoursesScreenState();
}

class _EnhancedCoursesScreenState extends State<EnhancedCoursesScreen> {
  final CourseCatalogService _catalogService = CourseCatalogService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _niveauController = TextEditingController();
  final TextEditingController _matiereController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<CatalogItem> _allItems = [];
  List<CatalogItem> _displayedItems = [];
  final List<CourseType> _selectedCourseTypes = []; // Types de cours sélectionnés
  final List<ContentType> _selectedContentTypes = []; // Types de contenu sélectionnés (cours/qcm)
  
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isHeaderCollapsed = false;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _loadCatalogData();
    _searchController.addListener(_onSearchChanged);
    _niveauController.addListener(_onSearchChanged);
    _matiereController.addListener(_onSearchChanged);
    
    // Écouter le scroll pour gérer l'état du header
    _scrollController.addListener(() {
      final isCollapsed = _scrollController.hasClients && _scrollController.offset > 150;
      if (isCollapsed != _isHeaderCollapsed) {
        setState(() {
          _isHeaderCollapsed = isCollapsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _niveauController.dispose();
    _matiereController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Charge le catalogue complet (cours + QCM)
  Future<void> _loadCatalogData() async {
    // Éviter de recharger si les données sont récentes (moins de 5 minutes)
    if (_lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!).inMinutes < 5 && 
        _allItems.isNotEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Charger cours et QCM en parallèle avec timeout
      final results = await Future.wait([
        _catalogService.getCoursesByUserPreferences(widget.user, limit: 50),
        _loadAvailableQCMs(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          Logger.warning('⏰ Timeout lors du chargement du catalogue - utilisation des données fallback');
          return [<CourseModel>[], <QCMModel>[]];
        },
      );

      List<CourseModel> courses = results[0] as List<CourseModel>;
      List<QCMModel> qcms = results[1] as List<QCMModel>;

      // Convertir en CatalogItem
      List<CatalogItem> allItems = [];
      
      // Ajouter les cours
      allItems.addAll(courses.map((course) => CatalogItem.fromCourse(course)));
      
      // Ajouter les QCM avec des scores moyens fictifs
      // Créer une map des cours pour un accès O(1) au lieu de O(n) par QCM
      Map<String, CourseModel> courseMap = {
        for (CourseModel course in courses) course.id: course
      };
      
      for (QCMModel qcm in qcms) {
        String? matiere;
        String? niveau;
        
        // Accès O(1) au cours associé
        if (qcm.courseId.isNotEmpty && qcm.courseId != 'general_qcm') {
          CourseModel? associatedCourse = courseMap[qcm.courseId];
          if (associatedCourse != null) {
            matiere = associatedCourse.matiere;
            niveau = associatedCourse.niveau;
          }
        }
        
        allItems.add(CatalogItem.fromQCM(
          qcm, 
          averageScore: _generateFakeAverageScore(),
          matiere: matiere,
          niveau: niveau,
        ));
      }

      if (mounted) {
        setState(() {
          _allItems = allItems;
          _displayedItems = allItems;
          _isLoading = false;
          _lastLoadTime = DateTime.now(); // Marquer le moment de chargement
        });
      }
    } catch (e) {
      Logger.error('Erreur chargement catalogue: $e');
      if (mounted) {
        setState(() {
          _allItems = [];
          _displayedItems = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Charge les QCM disponibles depuis Firebase
  Future<List<QCMModel>> _loadAvailableQCMs() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('QCM')
          .limit(10) // Limite réduite pour améliorer les performances
          .get();
      
      return snapshot.docs.map((doc) => QCMModel.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Erreur chargement QCM: $e');
      return [];
    }
  }

  /// Génère une moyenne fictive pour un QCM (entre 70 et 100)
  double _generateFakeAverageScore() {
    return 70.0 + (dart_math.Random().nextDouble() * 30.0);
  }

  /// Effectue une recherche manuelle via le bouton
  Future<void> _performSearch() async {
    // Recharger les données du catalogue
    await _loadCatalogData();
  }

  /// Calcule la hauteur du header dynamiquement selon le contenu
  double _calculateHeaderHeight() {
    if (_isHeaderCollapsed) return 120;
    
    // Hauteur de base identique à la page programme
    double baseHeight = 280;
    
    // Même logique que la page programme
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    // Adaptation simple pour les petits écrans
    if (isSmallScreen) {
      baseHeight += 20;
    }
    
    return baseHeight;
  }

  /// Fonction de recherche avec filtres
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    final niveauInput = _niveauController.text.trim();
    final matiereInput = _matiereController.text.trim();
    
    setState(() {
      _isSearching = query.isNotEmpty || niveauInput.isNotEmpty || matiereInput.isNotEmpty || 
                     _selectedCourseTypes.isNotEmpty || _selectedContentTypes.isNotEmpty;
      
      if (!_isSearching) {
        _displayedItems = _allItems;
      } else {
        _displayedItems = _allItems.where((item) {
          // Recherche dans le titre
          bool matchesQuery = query.isEmpty || 
                              item.title.toLowerCase().contains(query);
          
          // Recherche niveau avec normalisation
          bool matchesNiveau = niveauInput.isEmpty || _matchesNiveau(item.niveau, niveauInput);
          
          // Recherche matière avec normalisation
          bool matchesMatiere = matiereInput.isEmpty || _matchesMatiere(item.matiere, matiereInput);
          
          // Logique de filtrage par type améliorée
          bool matchesTypeFilters = true;
          
          // Si aucun filtre de type n'est sélectionné, tout passe
          if (_selectedContentTypes.isEmpty && _selectedCourseTypes.isEmpty) {
            matchesTypeFilters = true;
          } else {
            // Vérifier si l'élément correspond aux filtres sélectionnés
            bool isQcmAndSelected = (item.contentType == ContentType.qcm && _selectedContentTypes.contains(ContentType.qcm));
            bool isCourseAndMatches = (item.contentType == ContentType.cours && item.course != null && 
                                     (_selectedCourseTypes.contains(item.course!.type) || _selectedContentTypes.contains(ContentType.cours)));
            
            // L'élément passe si c'est un QCM sélectionné OU un cours qui correspond aux filtres
            matchesTypeFilters = isQcmAndSelected || isCourseAndMatches;
          }
          
          return matchesQuery && matchesNiveau && matchesMatiere && matchesTypeFilters;
        }).toList();
      }
    });
  }

  /// Vérifie si le niveau du cours correspond à la recherche
  bool _matchesNiveau(String courseNiveau, String searchNiveau) {
    if (courseNiveau.toLowerCase().contains(searchNiveau.toLowerCase())) {
      return true;
    }
    
    final normalizedSearch = TextNormalizer.normalizeNiveau(searchNiveau);
    final normalizedCourse = TextNormalizer.normalizeNiveau(courseNiveau);
    
    return normalizedCourse.toLowerCase().contains(normalizedSearch.toLowerCase()) ||
           normalizedSearch.toLowerCase().contains(normalizedCourse.toLowerCase());
  }

  /// Vérifie si la matière du cours correspond à la recherche
  bool _matchesMatiere(String courseMatiere, String searchMatiere) {
    if (courseMatiere.toLowerCase().contains(searchMatiere.toLowerCase())) {
      return true;
    }
    
    final normalizedSearch = TextNormalizer.normalizeMatiere(searchMatiere);
    final normalizedCourse = TextNormalizer.normalizeMatiere(courseMatiere);
    
    return normalizedCourse.toLowerCase() == normalizedSearch.toLowerCase() ||
           normalizedCourse.toLowerCase().contains(normalizedSearch.toLowerCase()) ||
           normalizedSearch.toLowerCase().contains(normalizedCourse.toLowerCase());
  }

  /// Efface tous les filtres
  void _clearAllFilters() {
    _searchController.clear();
    _niveauController.clear();
    _matiereController.clear();
    setState(() {
      _selectedCourseTypes.clear();
      _selectedContentTypes.clear();
    });
    _onSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header collapsible avec recherche
          SliverAppBar(
            expandedHeight: _calculateHeaderHeight(),
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
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
                      Icons.library_books,
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
                          'Cours',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Explorez notre catalogue de contenu',
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
          
          // Espacement équivalent à la section spécialités de la page programme
          SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.sm),
          ),
          
          // Contenu principal
          if (_isLoading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_displayedItems.isEmpty && _isSearching)
            SliverFillRemaining(
              child: _buildEmptySearchState(),
            )
          else if (_displayedItems.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _displayedItems[index];
                  return _buildCatalogItemCard(item);
                },
                childCount: _displayedItems.length,
              ),
            )
        ],
      ),
    );
  }

  /// Header moderne avec style cohérent à la page programme
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
              Container(
                width: isSmallScreen ? 36 : 44,
                height: isSmallScreen ? 36 : 44,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.library_books,
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
                      'Cours',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isSmallScreen ? 20 : null,
                      ),
                    ),
                    Text(
                      'Tous vos contenus éducatifs et QCM',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontSize: isSmallScreen ? 14 : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSearching)
                IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.white),
                  onPressed: _clearAllFilters,
                  tooltip: 'Effacer les filtres',
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

  Widget _buildHeaderWithSearch() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Titre avec icône et description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.library_books,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cours',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Tous vos contenus éducatifs et QCM',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isSearching)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.white),
                      onPressed: _clearAllFilters,
                      tooltip: 'Effacer les filtres',
                    ),
                ],
              ),
            ),
            
            // Section de recherche intégrée
            _buildModernSearchSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchSection() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200), // Limiter la hauteur
      child: SingleChildScrollView( // Rendre scrollable si nécessaire
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prendre le minimum d'espace
          children: [
            // Barre de recherche principale
            TextField(
              controller: _searchController,
              style: AppTextStyles.body.copyWith(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un cours ou QCM...',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                prefixIcon: const Icon(Icons.search, color: AppColors.white),
                filled: true,
                fillColor: AppColors.white.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Réduire le padding
              ),
              onChanged: (_) => _onSearchChanged(),
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
              onChanged: (_) => _onSearchChanged(),
            ),
            
            const SizedBox(height: AppSpacing.sm), // Réduire l'espacement
            
            // Bouton de recherche sans fond
            SizedBox(
              width: double.infinity,
              height: 44, // Réduire la hauteur
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _performSearch,
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
                              'Rechercher dans le catalogue',
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_displayedItems.isEmpty && _isSearching) {
      return _buildEmptySearchState();
    }
    
    if (_displayedItems.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _displayedItems.length,
      itemBuilder: (context, index) {
        final item = _displayedItems[index];
        return _buildCatalogItemCard(item);
      },
    );
  }

  Widget _buildCatalogItemCard(CatalogItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToItemDetail(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: item.contentType == ContentType.cours
                      ? _getSubjectGradient(item.matiere)
                      : const LinearGradient(
                          colors: [Colors.purple, Colors.deepPurple],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.contentType == ContentType.cours
                      ? _getSubjectIcon(item.matiere)
                      : Icons.quiz,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre et badge type
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 60), // Largeur max pour le badge
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.contentType == ContentType.cours
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.accent1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.contentType == ContentType.cours ? 'COURS' : 'QCM',
                            style: AppTextStyles.caption.copyWith(
                              color: item.contentType == ContentType.cours
                                  ? AppColors.primary
                                  : AppColors.accent1,
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Matière et niveau
                    Text(
                      '${item.matiere} • ${item.niveau}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.greyMedium,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Informations spécifiques
                    if (item.contentType == ContentType.cours && item.course != null)
                      CourseTypeUtils.buildBadge(item.course!.type)
                    else if (item.contentType == ContentType.qcm && item.averageUserScore != null)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 100), // Contrainte de largeur
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getScoreColor(item.averageUserScore!).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.analytics,
                              size: 12,
                              color: _getScoreColor(item.averageUserScore!),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Moy: ${item.averageUserScore!.toStringAsFixed(0)}%',
                                style: AppTextStyles.caption.copyWith(
                                  color: _getScoreColor(item.averageUserScore!),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Bouton favoris pour les cours + flèche
              SizedBox(
                width: 40, // Largeur fixe pour éviter l'overflow
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.contentType == ContentType.cours && item.course != null)
                      GroupedFavoriteButton(
                        userId: widget.user.uid,
                        course: item.course!,
                        size: 20,
                      ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.greyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: AppColors.greyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contenu disponible',
              style: AppTextStyles.h3.copyWith(color: AppColors.greyMedium),
            ),
            const SizedBox(height: 8),
            Text(
              'Le catalogue de cours et QCM sera bientôt disponible',
              style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.greyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: AppTextStyles.h3.copyWith(color: AppColors.greyMedium),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearAllFilters,
              child: const Text('Effacer les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Filtres de type unifié
              const Text('Type de contenu', style: TextStyle(fontWeight: FontWeight.bold)),
              
              // QCM en premier
              CheckboxListTile(
                value: _selectedContentTypes.contains(ContentType.qcm),
                onChanged: (bool? value) {
                  setDialogState(() {
                    if (value == true) {
                      _selectedContentTypes.add(ContentType.qcm);
                    } else {
                      _selectedContentTypes.remove(ContentType.qcm);
                    }
                  });
                },
                title: const Text('QCM'),
              ),
              
              // Puis les types de cours
              ...CourseType.values.map((type) {
                bool isSelected = _selectedCourseTypes.contains(type);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value == true) {
                        _selectedCourseTypes.add(type);
                      } else {
                        _selectedCourseTypes.remove(type);
                      }
                    });
                  },
                  title: Text(CourseTypeUtils.getLabel(type)),
                );
              }),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
              _onSearchChanged();
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  /// Navigation vers le détail d'un élément
  void _navigateToItemDetail(CatalogItem item) {
    if (item.contentType == ContentType.cours && item.course != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(
            course: item.course!,
            user: widget.user,
          ),
        ),
      );
    } else if (item.contentType == ContentType.qcm && item.qcm != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QCMScreen(
            qcm: item.qcm!,
            user: widget.user,
            matiere: item.matiere,
          ),
        ),
      );
    }
  }

  /// Couleur en fonction du score moyen
  Color _getScoreColor(double score) {
    if (score >= 90) return AppColors.success;
    if (score >= 75) return Colors.orange;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  /// Gradients pour les matières
  LinearGradient _getSubjectGradient(String matiere) {
    switch (matiere.toLowerCase()) {
      case 'mathématiques':
      case 'maths':
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        );
      case 'français':
        return const LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        );
      case 'histoire-géographie':
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      case 'sciences':
      case 'svt':
        return const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        );
      case 'physique-chimie':
        return const LinearGradient(
          colors: [Color(0xFFfa709a), Color(0xFFfee140)],
        );
      default:
        return AppColors.primaryGradient;
    }
  }

  /// Icônes pour les matières
  IconData _getSubjectIcon(String matiere) {
    switch (matiere.toLowerCase()) {
      case 'mathématiques':
      case 'maths':
        return Icons.calculate;
      case 'français':
        return Icons.menu_book;
      case 'histoire-géographie':
        return Icons.public;
      case 'sciences':
      case 'svt':
        return Icons.biotech;
      case 'physique-chimie':
        return Icons.science;
      case 'anglais':
        return Icons.language;
      default:
        return Icons.school;
    }
  }
}