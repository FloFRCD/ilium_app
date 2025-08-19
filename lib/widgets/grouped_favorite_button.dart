import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/course_group_model.dart';
import '../services/grouped_favorites_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';

/// Bouton sauvegarde qui sauvegarde le GROUPE ENTIER de cours (concept/sujet)
/// 
/// RÉVOLUTION DES SAUVEGARDÉS :
/// Au lieu de sauvegarder individuellement chaque type (cours, fiche, QCM),
/// on sauvegarde le SUJET COMPLET avec tous ses contenus !
/// 
/// AVANTAGES POUR LES PARENTS :
/// - Vision globale : "Mon enfant étudie les fractions" 
/// - Progression complète : cours + fiche + QCM + statistiques
/// - Suivi pédagogique : voir ce qui a été fait/réussi
/// - Accès facile à tous les types de contenu
/// 
/// UTILISATION :
/// ```dart
/// GroupedFavoriteButton(
///   course: course,
///   userId: user.uid,
///   onFavoriteChanged: (group) {
///     // Le groupe complet a été ajouté/retiré des sauvegardés
///   },
/// )
/// ```
class GroupedFavoriteButton extends StatefulWidget {
  final CourseModel course;
  final String userId;
  final Function(CourseGroupModel?)? onFavoriteChanged;
  final double size;
  final Color? favoriteColor;
  final Color? unfavoriteColor;
  final bool showProgressIndicator;

  const GroupedFavoriteButton({
    super.key,
    required this.course,
    required this.userId,
    this.onFavoriteChanged,
    this.size = 24.0,
    this.favoriteColor,
    this.unfavoriteColor,
    this.showProgressIndicator = false,
  });

  @override
  State<GroupedFavoriteButton> createState() => _GroupedFavoriteButtonState();
}

class _GroupedFavoriteButtonState extends State<GroupedFavoriteButton>
    with SingleTickerProviderStateMixin {
  final GroupedFavoritesService _favoritesService = GroupedFavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;
  CourseGroupModel? _currentGroup;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeFavoriteStatus();
    _listenToGlobalChanges();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeFavoriteStatus() async {
    try {
      bool isInFavoriteGroup = await _favoritesService.isCourseInFavoriteGroup(
        userId: widget.userId,
        course: widget.course,
      );
      
      if (mounted) {
        setState(() {
          _isFavorite = isInFavoriteGroup;
        });
      }
    } catch (e) {
      Logger.error('Erreur vérification statut favori groupé: $e');
    }
  }

  void _listenToGlobalChanges() {
    _favoritesService.addListener(_onFavoritesChanged);
    
    _favoritesService.favoritesStream.listen((favoritesMap) {
      if (mounted) {
        _checkIfCourseInFavorites(favoritesMap);
      }
    });
  }

  void _onFavoritesChanged() {
    if (mounted) {
      _initializeFavoriteStatus();
    }
  }

  void _checkIfCourseInFavorites(Map<String, List<CourseGroupModel>> favoritesMap) {
    List<CourseGroupModel> userFavorites = favoritesMap[widget.userId] ?? [];
    
    String courseGroupId = CourseGroupModel.generateGroupId(
      widget.course.title,
      widget.course.matiere,
      widget.course.niveau,
    );
    
    bool newStatus = userFavorites.any((group) => group.id == courseGroupId);
    
    if (newStatus != _isFavorite) {
      setState(() {
        _isFavorite = newStatus;
        _currentGroup = userFavorites.firstWhere(
          (group) => group.id == courseGroupId,
          orElse: () => CourseGroupModel.fromSingleCourse(widget.course),
        );
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Optimistic update
    bool optimisticState = !_isFavorite;
    setState(() {
      _isFavorite = optimisticState;
    });

    // Animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      bool success = await _favoritesService.toggleCourseFavorite(
        userId: widget.userId,
        course: widget.course,
      );

      if (mounted) {
        if (success) {
          // Créer ou récupérer le groupe pour le callback
          CourseGroupModel group = CourseGroupModel.fromSingleCourse(widget.course);
          _currentGroup = group;
          
          // Callback avec le groupe
          widget.onFavoriteChanged?.call(optimisticState ? group : null);

          // Feedback visuel
          _showSuccessFeedback(optimisticState, group);
          
          // Forcer un refresh immédiat du statut depuis la base 
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _initializeFavoriteStatus();
            }
          });
        } else {
          // Rollback si échec
          setState(() {
            _isFavorite = !optimisticState;
          });
          _showErrorFeedback();
        }
      }
    } catch (e) {
      Logger.error('Erreur toggle favori groupé: $e');
      
      if (mounted) {
        // Rollback en cas d'erreur
        setState(() {
          _isFavorite = !optimisticState;
        });
        _showErrorFeedback();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessFeedback(bool isAdded, CourseGroupModel group) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAdded ? Icons.bookmark_added : Icons.bookmark_remove,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAdded
                        ? 'Sujet ajouté aux sauvegardés'
                        : 'Sujet retiré des sauvegardés',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '"${group.title}" (${group.matiere})',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            if (isAdded && group.totalContentCount > 1) ...[
              const SizedBox(height: 4),
              Text(
                group.availableContentDescription,
                style: const TextStyle(fontSize: 11, color: Colors.white60),
              ),
            ],
          ],
        ),
        backgroundColor: isAdded 
            ? AppColors.success 
            : AppColors.warning,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Erreur lors de la modification'),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Stack(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : _toggleFavorite,
                  icon: _isLoading
                      ? SizedBox(
                          width: widget.size * 0.8,
                          height: widget.size * 0.8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isFavorite 
                                  ? (widget.favoriteColor ?? AppColors.accent2)
                                  : (widget.unfavoriteColor ?? AppColors.greyMedium),
                            ),
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Stack(
                            key: ValueKey(_isFavorite),
                            children: [
                              Icon(
                                _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                                color: _isFavorite 
                                    ? (widget.favoriteColor ?? AppColors.accent2)
                                    : (widget.unfavoriteColor ?? AppColors.greyMedium),
                                size: widget.size,
                              ),
                              // Indicateur de contenu multiple
                              if (_isFavorite && _currentGroup != null && _currentGroup!.totalContentCount > 1)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent1,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_currentGroup!.totalContentCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                  tooltip: _isFavorite 
                      ? 'Retirer le sujet des sauvegardés' 
                      : 'Ajouter le sujet aux sauvegardés',
                  splashRadius: widget.size + 8,
                ),
                // Indicateur de progression (optionnel)
                if (widget.showProgressIndicator && _isFavorite && _currentGroup != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _currentGroup!.calculateProgressPercentage(widget.userId) / 100,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.favoriteColor ?? AppColors.accent2,
                      ),
                      minHeight: 2,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget compact pour afficher uniquement le statut favori
class GroupedFavoriteStatusIcon extends StatefulWidget {
  final CourseModel course;
  final String userId;
  final double size;

  const GroupedFavoriteStatusIcon({
    super.key,
    required this.course,
    required this.userId,
    this.size = 16.0,
  });

  @override
  State<GroupedFavoriteStatusIcon> createState() => _GroupedFavoriteStatusIconState();
}

class _GroupedFavoriteStatusIconState extends State<GroupedFavoriteStatusIcon> {
  final GroupedFavoritesService _favoritesService = GroupedFavoritesService();
  bool _isFavorite = false;
  CourseGroupModel? _group;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _listenToChanges();
  }

  void _checkStatus() async {
    bool status = await _favoritesService.isCourseInFavoriteGroup(
      userId: widget.userId,
      course: widget.course,
    );
    
    if (status) {
      _group = CourseGroupModel.fromSingleCourse(widget.course);
    }
    
    setState(() {
      _isFavorite = status;
    });
  }

  void _listenToChanges() {
    _favoritesService.addListener(_checkStatus);
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_checkStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFavorite) return const SizedBox.shrink();
    
    return Stack(
      children: [
        Icon(
          Icons.bookmark,
          size: widget.size,
          color: AppColors.accent2,
        ),
        if (_group != null && _group!.totalContentCount > 1)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: AppColors.accent1,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_group!.totalContentCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}