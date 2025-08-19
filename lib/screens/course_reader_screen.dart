import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/course_status_service.dart';
import '../services/course_views_service.dart';
import '../services/anti_gaming_service.dart';
import '../widgets/course_rating_widget.dart';
import '../widgets/grouped_favorite_button.dart';
import '../theme/app_theme.dart';
import '../utils/course_type_utils.dart';

class CourseReaderScreen extends StatefulWidget {
  final CourseModel course;
  final UserModel user;

  const CourseReaderScreen({
    super.key,
    required this.course,
    required this.user,
  });

  @override
  State<CourseReaderScreen> createState() => _CourseReaderScreenState();
}

class _CourseReaderScreenState extends State<CourseReaderScreen>
    with TickerProviderStateMixin {
  final CourseStatusService _statusService = CourseStatusService();
  final CourseViewsService _viewsService = CourseViewsService();
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final ScrollController _scrollController = ScrollController();
  
  // Variables de tracking du temps
  DateTime? _startTime;
  int _sessionTimeMinutes = 0;
  
  // Variables de progression de lecture
  double _readingProgress = 0.0;
  
  // Variables anti-gaming
  int _totalReadingTimeSeconds = 0;
  double _maxScrollPosition = 0.0;
  final List<DateTime> _scrollMilestones = [];
  bool _hasScrolledToEnd = false;
  DateTime? _lastScrollTime;
  DateTime? _lastActiveTime;
  Timer? _readingTimer;
  
  // Constantes de validation
  static const int _minimumReadingTimeSeconds = 60; // 1 minute minimum
  static const double _minimumScrollProgress = 0.8; // 80% du contenu minimum
  static const int _minimumScrollMilestones = 3; // Au moins 3 pauses de lecture

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // Démarrer l'animation
    _fadeController.forward();
    
    // Initialiser les données
    _initializeData();
    _startReadingSession();
    
    // Configurer le scroll listener pour tracker la progression
    _scrollController.addListener(_onScroll);
    
    // Démarrer le timer de lecture active
    _startReadingTimer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _readingTimer?.cancel();
    _endReadingSession();
    super.dispose();
  }

  void _initializeData() async {
    // Récupérer la progression actuelle avec le nouveau service
    final status = await _statusService.getCourseStatus(
      userId: widget.user.uid,
      courseId: widget.course.id,
    );
    
    if (status != null) {
      _readingProgress = status.progress;
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _startReadingSession() {
    _startTime = DateTime.now();
    
    // Marquer le cours comme démarré avec le nouveau service
    // Seulement si le cours a un ID valide (cours sauvé en Firebase)
    if (widget.course.id.isNotEmpty) {
      _statusService.startCourse(
        userId: widget.user.uid,
        courseId: widget.course.id,
      );
      
      // Ajouter une vue réelle de l'utilisateur
      _viewsService.addUserView(
        courseId: widget.course.id,
        userId: widget.user.uid,
        courseCreatedAt: widget.course.createdAt,
      );
    }
  }

  void _endReadingSession() {
    if (_startTime != null) {
      final sessionTime = DateTime.now().difference(_startTime!).inMinutes;
      _sessionTimeMinutes += sessionTime;
      
      // Sauvegarder la progression finale
      _updateProgress(_readingProgress, additionalTime: sessionTime);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final now = DateTime.now();
    
    if (maxScroll > 0) {
      final newProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      
      // Tracker la position maximale atteinte
      if (newProgress > _maxScrollPosition) {
        _maxScrollPosition = newProgress;
      }
      
      // Détecter si l'utilisateur a atteint la fin
      if (newProgress >= 0.95) {
        _hasScrolledToEnd = true;
      }
      
      // Enregistrer les pauses de lecture (quand l'utilisateur s'arrête de scroller)
      if (_lastScrollTime != null) {
        final timeSinceLastScroll = now.difference(_lastScrollTime!).inSeconds;
        
        // Si l'utilisateur s'est arrêté de scroller pendant plus de 5 secondes
        if (timeSinceLastScroll >= 5 && newProgress > 0.1) {
          _scrollMilestones.add(now);
          
          // Garder seulement les 10 dernières pauses pour éviter la surcharge mémoire
          if (_scrollMilestones.length > 10) {
            _scrollMilestones.removeAt(0);
          }
        }
      }
      
      _lastScrollTime = now;
      _lastActiveTime = now; // Marquer comme activité récente
      
      // Mettre à jour la progression visuelle seulement
      if (newProgress > _readingProgress) {
        setState(() {
          _readingProgress = newProgress;
        });
        
        // Mettre à jour la progression toutes les 5% de lecture
        if ((newProgress * 100).round() % 5 == 0) {
          _updateProgress(newProgress);
        }
      }
    }
  }

  /// Démarre le timer pour calculer le temps de lecture actif
  void _startReadingTimer() {
    _lastActiveTime = DateTime.now();
    
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      
      // Si l'utilisateur a été actif dans les 30 dernières secondes
      if (_lastActiveTime != null && 
          now.difference(_lastActiveTime!).inSeconds <= 30) {
        _totalReadingTimeSeconds++;
      }
    });
  }

  /// Valide si l'utilisateur peut marquer le cours comme terminé
  bool _canMarkAsCompleted() {
    final validation = AntiGamingService.validateActivity(
      activityType: 'course_reading',
      totalTimeSeconds: _totalReadingTimeSeconds,
      minimumTimeRequired: _minimumReadingTimeSeconds,
      additionalData: {
        'maxScrollProgress': _maxScrollPosition,
        'scrollMilestones': _scrollMilestones.length,
        'hasScrolledToEnd': _hasScrolledToEnd,
      },
    );
    
    return validation.isValid;
  }

  /// Retourne un message expliquant pourquoi le cours ne peut pas être marqué comme terminé
  String _getCompletionBlockReason() {
    final validation = AntiGamingService.validateActivity(
      activityType: 'course_reading',
      totalTimeSeconds: _totalReadingTimeSeconds,
      minimumTimeRequired: _minimumReadingTimeSeconds,
      additionalData: {
        'maxScrollProgress': _maxScrollPosition,
        'scrollMilestones': _scrollMilestones.length,
        'hasScrolledToEnd': _hasScrolledToEnd,
      },
    );
    
    return validation.primaryReason;
  }

  void _updateProgress(double progress, {int? additionalTime}) async {
    // Seulement si le cours a un ID valide (cours sauvé en Firebase)
    if (widget.course.id.isNotEmpty) {
      await _statusService.updateProgress(
        userId: widget.user.uid,
        courseId: widget.course.id,
        progress: progress,
        additionalTimeMinutes: additionalTime,
      );
      
      // Rafraîchir la progression actuelle
      final status = await _statusService.getCourseStatus(
        userId: widget.user.uid,
        courseId: widget.course.id,
      );
      if (status != null) {
        setState(() {
          _readingProgress = status.progress;
        });
      }
    }
  }


  void _markAsCompleted() async {
    // Vérifier les conditions anti-gaming
    if (!_canMarkAsCompleted()) {
      _showValidationError();
      return;
    }
    
    // Seulement si le cours a un ID valide (cours sauvé en Firebase)
    if (widget.course.id.isNotEmpty) {
      final success = await _statusService.completeCourse(
        userId: widget.user.uid,
        courseId: widget.course.id,
        metadata: {
          'readingTimeSeconds': _totalReadingTimeSeconds,
          'maxScrollProgress': _maxScrollPosition,
          'scrollMilestones': _scrollMilestones.length,
          'validatedCompletion': true,
        },
      );
      
      if (success) {
        setState(() {
          _readingProgress = 1.0;
        });
        
        _showCompletionDialog();
      }
    } else {
      // Pour un cours généré sans ID, juste montrer la dialog
      setState(() {
        _readingProgress = 1.0;
      });
      _showCompletionDialog();
    }
  }

  /// Affiche une erreur si les conditions ne sont pas remplies
  void _showValidationError() {
    final reason = _getCompletionBlockReason();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Lecture en cours'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason),
            const SizedBox(height: 16),
            Text(
              'Progression actuelle:',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildValidationProgress(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuer la lecture'),
          ),
        ],
      ),
    );
  }

  /// Widget de progression des critères de validation
  Widget _buildValidationProgress() {
    return Column(
      children: [
        _buildCriteriaItem(
          'Temps de lecture',
          _totalReadingTimeSeconds,
          _minimumReadingTimeSeconds,
          'sec',
          Icons.timer,
        ),
        _buildCriteriaItem(
          'Contenu lu',
          (_maxScrollPosition * 100).round(),
          (_minimumScrollProgress * 100).round(),
          '%',
          Icons.visibility,
        ),
        _buildCriteriaItem(
          'Pauses de lecture',
          _scrollMilestones.length,
          _minimumScrollMilestones,
          '',
          Icons.pause_circle,
        ),
        Row(
          children: [
            Icon(
              _hasScrolledToEnd ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _hasScrolledToEnd ? AppColors.success : AppColors.greyMedium,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Lecture jusqu\'à la fin',
              style: AppTextStyles.body.copyWith(
                color: _hasScrolledToEnd ? AppColors.success : AppColors.greyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCriteriaItem(String label, int current, int required, String unit, IconData icon) {
    final isCompleted = current >= required;
    final progress = (current / required).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isCompleted ? AppColors.success : AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: $current/$required$unit',
                  style: AppTextStyles.body.copyWith(
                    color: isCompleted ? AppColors.success : AppColors.greyDark,
                  ),
                ),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.greyLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget compact pour afficher l'état de validation d'un critère
  Widget _buildValidationIndicator(bool isCompleted, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.success : AppColors.greyLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted ? Colors.white : AppColors.greyMedium,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isCompleted ? AppColors.success : AppColors.greyMedium,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: AppColors.accent1),
            const SizedBox(width: 8),
            const Text('Félicitations !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vous avez terminé le cours "${widget.course.title}" !'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent1.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school, size: 32, color: AppColors.accent1),
                  const SizedBox(height: 8),
                  const Text('Cours terminé', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (_sessionTimeMinutes > 0)
                    Text('Temps de lecture: ${_sessionTimeMinutes}min'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retourner à l'écran précédent
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar avec progression
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Progression overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 4,
                        child: LinearProgressIndicator(
                          value: _readingProgress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Bouton favoris groupé
              GroupedFavoriteButton(
                course: widget.course,
                userId: widget.user.uid,
                favoriteColor: Colors.white,
                unfavoriteColor: Colors.white.withValues(alpha: 0.7),
                onFavoriteChanged: (group) {
                  // Le bouton GroupedFavoriteButton gère son état automatiquement
                },
              ),
              // Menu options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'complete':
                      _markAsCompleted();
                      break;
                    case 'share':
                      // TODO: Implémenter le partage
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Partage en cours de développement')),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text('Marquer comme terminé'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Partager'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Informations du cours
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges du cours
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(widget.course.matiere, AppColors.primary),
                        _buildBadge(widget.course.niveau, AppColors.secondary),
                        CourseTypeUtils.buildBadge(widget.course.type),
                        if (widget.course.isPremium)
                          _buildBadge('PREMIUM', Colors.amber),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description si disponible
                    if (widget.course.description != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.course.description!,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.black.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    
                    // Informations sur l'auteur et la progression
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            widget.course.authorName.isNotEmpty 
                                ? widget.course.authorName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.course.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              Text(
                                'Progression: ${(_readingProgress * 100).toInt()}%',
                                style: TextStyle(
                                  color: AppColors.black.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.course.estimatedDuration != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent1.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.course.estimatedDuration}min',
                              style: const TextStyle(
                                color: AppColors.accent1,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Contenu du cours
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contenu du cours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    MarkdownBody(
                      data: widget.course.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 16,
                          color: AppColors.black,
                          height: 1.6,
                        ),
                        h1: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                          height: 1.3,
                        ),
                        h2: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                        h3: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                        h4: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greyDark,
                          height: 1.4,
                        ),
                        strong: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        em: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.greyDark,
                        ),
                        code: TextStyle(
                          fontFamily: 'monospace',
                          backgroundColor: AppColors.greyLight,
                          color: AppColors.primary,
                        ),
                        blockquote: TextStyle(
                          color: AppColors.greyMedium,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Widget de notation
                    if (widget.course.id.isNotEmpty)
                      CourseRatingWidget(
                        courseId: widget.course.id,
                        userId: widget.user.uid,
                        courseCreatedAt: widget.course.createdAt,
                        onRatingChanged: () {
                          // Optionnel: actions après notation
                        },
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Bouton de fin de lecture avec validation anti-gaming
                    if (_readingProgress > 0.8)
                      Center(
                        child: Column(
                          children: [
                            // Indicateur de validation en temps réel
                            if (!_canMarkAsCompleted())
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.warning.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, color: AppColors.warning, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Continuez la lecture pour débloquer la validation',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Bouton principal
                            ElevatedButton.icon(
                              onPressed: _markAsCompleted,
                              icon: Icon(_canMarkAsCompleted() ? Icons.check_circle : Icons.access_time),
                              label: Text(_canMarkAsCompleted() 
                                ? 'Marquer comme terminé' 
                                : 'Validation en cours...'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _canMarkAsCompleted() 
                                  ? AppColors.accent1 
                                  : AppColors.greyMedium,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            
                            // Mini-indicateurs de progression
                            if (!_canMarkAsCompleted())
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildValidationIndicator(
                                      _totalReadingTimeSeconds >= _minimumReadingTimeSeconds,
                                      Icons.timer,
                                      'Temps',
                                    ),
                                    const SizedBox(width: 16),
                                    _buildValidationIndicator(
                                      _maxScrollPosition >= _minimumScrollProgress,
                                      Icons.visibility,
                                      'Lecture',
                                    ),
                                    const SizedBox(width: 16),
                                    _buildValidationIndicator(
                                      _scrollMilestones.length >= _minimumScrollMilestones,
                                      Icons.pause_circle,
                                      'Attention',
                                    ),
                                    const SizedBox(width: 16),
                                    _buildValidationIndicator(
                                      _hasScrolledToEnd,
                                      Icons.done_all,
                                      'Fin',
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Padding bottom pour éviter que le contenu soit coupé
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}