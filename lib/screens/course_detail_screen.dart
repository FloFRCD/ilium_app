import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../services/usage_tracking_service.dart';
import '../services/course_engagement_service.dart';
import '../widgets/grouped_favorite_button.dart';
import '../utils/course_type_utils.dart';
import '../theme/app_theme.dart';
import 'course_reader_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;
  final UserModel user;

  const CourseDetailScreen({super.key, required this.course, required this.user});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final UsageTrackingService _usageTrackingService = UsageTrackingService();
  final CourseEngagementService _engagementService = CourseEngagementService();
  int _fullCoursesThisMonth = 0;
  CourseModel? _enrichedCourse;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
    _loadCourseEngagement();
  }

  void _loadUsageData() async {
    if (widget.course.type == CourseType.cours && 
        widget.user.limitations.subscriptionTier == 'Gratuit') {
      final count = await _usageTrackingService.getFullCoursesThisMonth(widget.user.uid);
      if (mounted) {
        setState(() {
          _fullCoursesThisMonth = count;
        });
      }
    }
  }

  void _loadCourseEngagement() async {
    final enrichedCourse = await _engagementService.enrichCourseWithEngagement(widget.course);
    if (mounted) {
      setState(() {
        _enrichedCourse = enrichedCourse;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            _buildCourseInfo(),
            _buildDescription(),
            if (widget.course.type == CourseType.cours)
              _buildCourseSummary(),
            if (widget.course.type == CourseType.vulgarise)
              _buildConceptsPreview(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 240, // Augmenté pour faire de la place aux boutons
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getSubjectColor(widget.course.matiere), _getSubjectColor(widget.course.matiere).withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Icône de fond
          Positioned.fill(
            child: Icon(
              _getSubjectIcon(widget.course.matiere),
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          
          // Bouton retour (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          
          // Bouton favoris (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: GroupedFavoriteButton(
                course: widget.course,
                userId: widget.user.uid,
                favoriteColor: Colors.white,
                unfavoriteColor: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          
          // Contenu principal
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.course.matiere,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.course.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Niveau ${widget.course.niveau}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfo() {
    final course = _enrichedCourse ?? widget.course;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.access_time,
                  'Durée',
                  _getAdaptedDuration(),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.signal_cellular_alt,
                  'Difficulté',
                  _getDifficultyText(course.difficulty ?? CourseDifficulty.moyen),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.star,
                  'Note',
                  _getRatingText(course),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.visibility,
                  'Vues',
                  '${course.viewsCount}',
                ),
              ),
            ],
          ),
          // Badge pour les types de contenu spéciaux
          if (widget.course.type != CourseType.cours) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CourseTypeUtils.getColor(widget.course.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CourseTypeUtils.getColor(widget.course.type)),
              ),
              child: Row(
                children: [
                  Icon(CourseTypeUtils.getIcon(widget.course.type), color: CourseTypeUtils.getColor(widget.course.type)),
                  SizedBox(width: 8),
                  Text(
                    CourseTypeUtils.getLabel(widget.course.type),
                    style: TextStyle(
                      color: CourseTypeUtils.getColor(widget.course.type),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Informations contextuelles basées sur le type
          SizedBox(height: 16),
          _buildContextualInfo(),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.grey600),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.course.type == CourseType.fiche ? 'Points clés' : 'Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.course.type == CourseType.fiche) ...[
            SizedBox(height: 4),
            Text(
              'Résumé des éléments essentiels à retenir',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey600,
              ),
            ),
          ],
          SizedBox(height: 12),
          widget.course.type == CourseType.fiche
              ? _buildFicheKeyPoints()
              : Text(
                  widget.course.description ?? 'Aucune description disponible',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.grey700,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFicheKeyPoints() {
    // Extraire les points clés du contenu pour les fiches
    final keyPoints = _extractKeyPointsFromContent(widget.course.content);
    if (keyPoints.isNotEmpty) {
      return Column(
        children: keyPoints.map((point) => _buildFicheKeyPointItem(point)).toList(),
      );
    }
    
    // Fallback si pas de points extraits
    return Column(
      children: [
        _buildFicheKeyPointItem('Définitions essentielles'),
        _buildFicheKeyPointItem('Formules importantes'),
        _buildFicheKeyPointItem('Méthodes de résolution'),
        _buildFicheKeyPointItem('Points à retenir'),
        _buildFicheKeyPointItem('Erreurs à éviter'),
      ],
    );
  }

  Widget _buildFicheKeyPointItem(String point) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CourseTypeUtils.getColor(CourseType.fiche).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CourseTypeUtils.getColor(CourseType.fiche).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: CourseTypeUtils.getColor(CourseType.fiche),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              point,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey800,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractKeyPointsFromContent(String content) {
    final keyPoints = <String>[];
    final lines = content.split('\n');
    
    for (String line in lines) {
      line = line.trim();
      // Chercher les points clés (lignes commençant par - ou • ou *)
      if (line.startsWith('- ') || line.startsWith('• ') || line.startsWith('* ')) {
        String point = line.substring(2).trim();
        if (point.isNotEmpty && keyPoints.length < 6) {
          keyPoints.add(point);
        }
      }
    }
    
    return keyPoints;
  }

  Widget _buildCourseSummary() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Plan du cours',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.list_alt,
                size: 20,
                color: CourseTypeUtils.getColor(CourseType.cours),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Organisation du contenu par chapitres progressifs',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey600,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildChapterList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptsPreview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Concepts abordés',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: CourseTypeUtils.getColor(CourseType.vulgarise),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Étapes d\'explication simplifiée des concepts',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey600,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildConceptsList(),
            ),
          ),
        ],
      ),
    );
  }


  List<Widget> _buildChapterList() {
    // Si c'est un cours complet et qu'on peut extraire le sommaire
    if (widget.course.type == CourseType.cours) {
      final chapters = _extractChaptersFromContent(widget.course.content);
      if (chapters.isNotEmpty) {
        return chapters.asMap().entries.map((entry) {
          final index = entry.key;
          final chapter = entry.value;
          // Premier chapitre accessible (Introduction/plan), les autres pas
          return _buildChapterItem(chapter, index == 0);
        }).toList();
      }
    }
    
    // Fallback pour les autres types de cours ou si extraction échoue
    return [
      _buildChapterItem('Introduction', true),
      _buildChapterItem('Développement principal', false),
      _buildChapterItem('Exemples et applications', false),
      _buildChapterItem('Conclusion et points clés', false),
    ];
  }

  List<String> _extractChaptersFromContent(String content) {
    final chapters = <String>[];
    
    // Rechercher les chapitres dans le sommaire (avant le premier "---")
    final parts = content.split('---');
    if (parts.length >= 2) {
      final summaryPart = parts[0];
      
      // Extraire les chapitres du sommaire
      final lines = summaryPart.split('\n');
      for (String line in lines) {
        line = line.trim();
        
        // Chercher les lignes qui commencent par ## (titres de chapitres)
        if (line.startsWith('## ')) {
          String chapterTitle = line.substring(3).trim();
          // Nettoyer le titre
          chapterTitle = chapterTitle.replaceFirst(RegExp(r'^Chapitre \d+:\s*'), '');
          if (chapterTitle.isNotEmpty) {
            chapters.add(chapterTitle);
          }
        }
      }
    }
    
    return chapters;
  }

  Widget _buildChapterItem(String title, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? CourseTypeUtils.getColor(CourseType.cours).withValues(alpha: 0.05)
            : AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked 
              ? CourseTypeUtils.getColor(CourseType.cours).withValues(alpha: 0.2)
              : AppColors.grey200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? CourseTypeUtils.getColor(CourseType.cours)
                  : AppColors.grey400,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isUnlocked ? Icons.play_arrow : Icons.lock,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: isUnlocked ? AppColors.grey800 : AppColors.grey500,
                fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
                height: 1.3,
              ),
            ),
          ),
          if (isUnlocked)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Gratuit',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }


  List<Widget> _buildConceptsList() {
    // Extraire les concepts du contenu pour la vulgarisation
    final concepts = _extractConceptsFromContent(widget.course.content);
    if (concepts.isNotEmpty) {
      return concepts.asMap().entries.map((entry) {
        final index = entry.key;
        final concept = entry.value;
        return _buildConceptItem(concept, index + 1);
      }).toList();
    }
    
    // Fallback pour la vulgarisation
    return [
      _buildConceptItem('Introduction au concept', 1),
      _buildConceptItem('Explication simple', 2),
      _buildConceptItem('Exemples concrets', 3),
      _buildConceptItem('Applications pratiques', 4),
    ];
  }


  Widget _buildConceptItem(String concept, int step) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CourseTypeUtils.getColor(CourseType.vulgarise).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CourseTypeUtils.getColor(CourseType.vulgarise).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CourseTypeUtils.getColor(CourseType.vulgarise),
                  CourseTypeUtils.getColor(CourseType.vulgarise).withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              concept,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey800,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }


  List<String> _extractConceptsFromContent(String content) {
    final concepts = <String>[];
    final lines = content.split('\n');
    
    for (String line in lines) {
      line = line.trim();
      // Chercher les concepts (titres de niveau 3 : ###)
      if (line.startsWith('### ')) {
        String concept = line.substring(4).trim();
        if (concept.isNotEmpty && concepts.length < 5) {
          concepts.add(concept);
        }
      }
    }
    
    return concepts;
  }


  Widget _buildBottomActionBar() {
    // Logique simplifiée basée uniquement sur le type de cours
    bool canAccessThisType = widget.user.limitations.canAccessCourseType(widget.course.type);
    
    // Pour les comptes gratuits, vérifier les limites de cours complets
    bool hasReachedLimit = false;
    if (widget.course.type == CourseType.cours && 
        widget.user.limitations.subscriptionTier == 'Gratuit') {
      hasReachedLimit = widget.user.limitations.hasReachedFullCourseLimit(_fullCoursesThisMonth);
    }
    
    // Déterminer l'accessibilité (suppression de la logique isPremium redondante)
    bool canAccess = canAccessThisType && !hasReachedLimit;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message d'information sur les restrictions
          if (!canAccessThisType || hasReachedLimit) ...[
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasReachedLimit 
                          ? widget.user.limitations.getFullCourseLimitMessage(_fullCoursesThisMonth)
                          : widget.user.limitations.getContentTypeRestrictionMessage(widget.course.type),
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Indicateur de progression si disponible
          if (canAccess && _hasUserProgress()) ...[
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: CourseTypeUtils.getColor(widget.course.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CourseTypeUtils.getColor(widget.course.type).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Votre progression',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CourseTypeUtils.getColor(widget.course.type),
                        ),
                      ),
                      Text(
                        '${_getUserProgressPercentage()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: CourseTypeUtils.getColor(widget.course.type),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _getUserProgressPercentage() / 100,
                    backgroundColor: CourseTypeUtils.getColor(widget.course.type).withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CourseTypeUtils.getColor(widget.course.type),
                    ),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ],
          
          // Boutons d'action différenciés par type
          Row(
            children: [
              if (!canAccess)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUpgradeDialog(),
                    icon: Icon(Icons.upgrade),
                    label: Text('Passer au Premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startCourse(),
                    icon: Icon(_getActionButtonIcon()),
                    label: Text(_getActionButtonText()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CourseTypeUtils.getColor(widget.course.type),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (_hasUserProgress()) ...[
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _continueCourse(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: CourseTypeUtils.getColor(widget.course.type),
                      side: BorderSide(
                        color: CourseTypeUtils.getColor(widget.course.type),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.replay, size: 18),
                        SizedBox(width: 4),
                        Text('Continuer'),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }


  IconData _getActionButtonIcon() {
    switch (widget.course.type) {
      case CourseType.cours:
        return Icons.play_arrow;
      case CourseType.fiche:
        return Icons.description;
      case CourseType.vulgarise:
        return Icons.lightbulb;
    }
  }

  String _getActionButtonText() {
    switch (widget.course.type) {
      case CourseType.cours:
        return _hasUserProgress() ? 'Reprendre le cours' : 'Commencer le cours';
      case CourseType.fiche:
        return _hasUserProgress() ? 'Relire la fiche' : 'Lire la fiche';
      case CourseType.vulgarise:
        return _hasUserProgress() ? 'Revoir l\'explication' : 'Comprendre';
    }
  }

  bool _hasUserProgress() {
    // Simulation : on considère qu'il y a progression si l'utilisateur a déjà visité le cours
    // En réalité, ceci devrait vérifier dans une base de données de progression
    return false; // Pour l'instant, pas de progression simulée
  }

  int _getUserProgressPercentage() {
    // Simulation : retourne un pourcentage de progression
    // En réalité, ceci devrait calculer la vraie progression de l'utilisateur
    return 0; // Pour l'instant, pas de progression
  }

  void _continueCourse() {
    // Même fonction que _startCourse mais pourrait aller à un point spécifique
    _startCourse();
  }

  void _startCourse() async {
    // Enregistrer une vue avant de naviguer vers le lecteur
    await _engagementService.addView(widget.course.id);
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CourseReaderScreen(
            course: _enrichedCourse ?? widget.course,
            user: widget.user,
          ),
        ),
      );
    }
  }

  void _showUpgradeDialog() {
    String dialogTitle;
    String dialogContent;
    
    switch (widget.course.type) {
      case CourseType.vulgarise:
        dialogTitle = 'Cours vulgarisés Premium';
        dialogContent = 'Les cours vulgarisés sont réservés aux membres Premium. Ils offrent des explications ultra-accessibles avec des analogies du quotidien.';
        break;
      case CourseType.fiche:
        dialogTitle = 'Fiches de révision Premium';
        dialogContent = 'Les fiches de révision sont réservées aux membres Premium. Elles proposent des résumés efficaces avec mots-clés et astuces mnémotechniques.';
        break;
      case CourseType.cours:
        dialogTitle = 'Limite de cours gratuits atteinte';
        dialogContent = 'Vous avez atteint votre limite de 1 cours complet gratuit par mois. Passez au Premium pour un accès illimité à tous les cours.';
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                dialogTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dialogContent,
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            SizedBox(height: 16),
            Text(
              'Avec Premium, vous bénéficiez de :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            ...widget.user.limitations.getFeaturesList().take(4).map((feature) => 
              Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(child: Text(feature, style: TextStyle(fontSize: 14))),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigation vers l'écran d'abonnement
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: Text('Découvrir Premium'),
          ),
        ],
      ),
    );
  }

  String _getAdaptedDuration() {
    final course = _enrichedCourse ?? widget.course;
    
    // Durée personnalisée si disponible
    if (course.estimatedDuration != null) {
      return '${course.estimatedDuration} min';
    }
    
    // Durée adaptée selon le type
    switch (widget.course.type) {
      case CourseType.fiche:
        return '10-15 min';
      case CourseType.vulgarise:
        return '15-25 min';
      case CourseType.cours:
        return '45-60 min';
    }
  }

  Widget _buildContextualInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.grey600,
              ),
              SizedBox(width: 8),
              Text(
                'Informations complémentaires',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Objectifs d'apprentissage
          _buildContextualItem(
            Icons.flag_outlined,
            'Objectifs',
            _getCourseObjectives(),
          ),
          
          SizedBox(height: 12),
          
          // Prérequis
          _buildContextualItem(
            Icons.school_outlined,
            'Prérequis',
            _getCoursePrerequisites(),
          ),
          
          SizedBox(height: 12),
          
          // Public cible
          _buildContextualItem(
            Icons.people_outline,
            'Public cible',
            _getTargetAudience(),
          ),
        ],
      ),
    );
  }

  Widget _buildContextualItem(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: CourseTypeUtils.getColor(widget.course.type),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCourseObjectives() {
    switch (widget.course.type) {
      case CourseType.cours:
        return 'Maîtriser les concepts fondamentaux, comprendre la théorie en profondeur et savoir appliquer les connaissances dans des exercices variés.';
      case CourseType.fiche:
        return 'Mémoriser les points essentiels, réviser efficacement et retenir les formules et définitions clés.';
      case CourseType.vulgarise:
        return 'Comprendre intuitivement les concepts, développer une vision globale et acquérir des bases solides de manière accessible.';
    }
  }

  String _getCoursePrerequisites() {
    final niveau = widget.course.niveau;
    
    switch (widget.course.type) {
      case CourseType.cours:
        switch (niveau) {
          case 'Sixième':
          case '6ème':
            return 'Connaissances de base du primaire';
          case 'Cinquième':
          case '5ème':
            return 'Programme de 6ème validé';
          case 'Quatrième':
          case '4ème':
            return 'Programme de 5ème validé';
          case 'Troisième':
          case '3ème':
            return 'Programme de 4ème validé';
          case 'Seconde':
            return 'Diplôme national du brevet';
          case 'Première':
            return 'Programme de seconde validé';
          case 'Terminale':
            return 'Programme de première validé';
          default:
            return 'Niveau équivalent acquis';
        }
      case CourseType.fiche:
        return 'Cours correspondant déjà étudié ou bases du niveau requis';
      case CourseType.vulgarise:
        return 'Aucun prérequis spécifique, accessible à tous';
    }
  }

  String _getTargetAudience() {
    switch (widget.course.type) {
      case CourseType.cours:
        return 'Élèves de ${widget.course.niveau}, enseignants, étudiants souhaitant approfondir leurs connaissances';
      case CourseType.fiche:
        return 'Élèves en révision, préparation d\'examens, besoin de synthèse rapide';
      case CourseType.vulgarise:
        return 'Débutants, élèves en difficulté, parents souhaitant comprendre pour aider';
    }
  }

  String _getDifficultyText(CourseDifficulty difficulty) {
    switch (difficulty) {
      case CourseDifficulty.facile:
        return 'Facile';
      case CourseDifficulty.moyen:
        return 'Moyen';
      case CourseDifficulty.difficile:
        return 'Difficile';
    }
  }

  String _getRatingText(CourseModel course) {
    if (course.rating.isEmpty || course.rating['average'] == null) {
      return '—';
    }
    return course.rating['average']!.toStringAsFixed(1);
  }

  Color _getSubjectColor(String matiere) {
    switch (matiere) {
      case 'Mathématiques':
        return Colors.blue;
      case 'Français':
        return Colors.red;
      case 'Histoire-Géographie':
        return Colors.brown;
      case 'Sciences':
        return Colors.green;
      case 'Physique-Chimie':
        return Colors.purple;
      case 'SVT':
        return Colors.teal;
      case 'Anglais':
        return Colors.indigo;
      case 'Espagnol':
        return Colors.orange;
      case 'Allemand':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubjectIcon(String matiere) {
    switch (matiere) {
      case 'Mathématiques':
        return Icons.functions;
      case 'Français':
        return Icons.book;
      case 'Histoire-Géographie':
        return Icons.public;
      case 'Sciences':
        return Icons.science;
      case 'Physique-Chimie':
        return Icons.psychology;
      case 'SVT':
        return Icons.eco;
      case 'Anglais':
      case 'Espagnol':
      case 'Allemand':
        return Icons.language;
      default:
        return Icons.school;
    }
  }

}