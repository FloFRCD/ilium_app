import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/global_favorites_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';

/// Bouton favori avec synchronisation globale entre toutes les pages
/// 
/// AVANTAGES :
/// - État synchronisé automatiquement entre toutes les pages
/// - Cache intelligent pour éviter les requêtes répétées
/// - Animation fluide avec feedback visuel
/// - Gestion d'erreur robuste
/// 
/// UTILISATION :
/// ```dart
/// GlobalFavoriteButton(
///   course: course,
///   userId: user.uid,
///   onFavoriteChanged: () {
///     // Action optionnelle après changement
///   },
/// )
/// ```
class GlobalFavoriteButton extends StatefulWidget {
  final CourseModel course;
  final String userId;
  final VoidCallback? onFavoriteChanged;
  final double size;
  final Color? favoriteColor;
  final Color? unfavoriteColor;

  const GlobalFavoriteButton({
    super.key,
    required this.course,
    required this.userId,
    this.onFavoriteChanged,
    this.size = 24.0,
    this.favoriteColor,
    this.unfavoriteColor,
  });

  @override
  State<GlobalFavoriteButton> createState() => _GlobalFavoriteButtonState();
}

class _GlobalFavoriteButtonState extends State<GlobalFavoriteButton>
    with SingleTickerProviderStateMixin {
  final GlobalFavoritesService _globalFavoritesService = GlobalFavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;
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

  void _initializeFavoriteStatus() {
    // Vérifier d'abord depuis le cache
    bool cachedStatus = _globalFavoritesService.isFavoriteInCache(
      widget.userId, 
      widget.course.id,
    );
    
    setState(() {
      _isFavorite = cachedStatus;
    });
    
    // Puis vérifier depuis Firebase si nécessaire (sans bloquer l'UI)
    _refreshFavoriteStatus();
  }

  Future<void> _refreshFavoriteStatus() async {
    try {
      bool actualStatus = await _globalFavoritesService.isFavorite(
        userId: widget.userId,
        courseId: widget.course.id,
      );
      
      if (mounted && actualStatus != _isFavorite) {
        setState(() {
          _isFavorite = actualStatus;
        });
      }
    } catch (e) {
      Logger.error('Erreur vérification statut favori: $e');
    }
  }

  void _listenToGlobalChanges() {
    // Écouter les changements globaux de sauvegardés
    _globalFavoritesService.favoritesStream.listen((favoritesMap) {
      if (mounted) {
        Set<String> userFavorites = favoritesMap[widget.userId] ?? <String>{};
        bool newStatus = userFavorites.contains(widget.course.id);
        
        if (newStatus != _isFavorite) {
          setState(() {
            _isFavorite = newStatus;
          });
          Logger.debug('Statut favori mis à jour via stream: ${widget.course.id} -> $newStatus');
        }
      }
    });

    // Écouter les changements via ChangeNotifier
    _globalFavoritesService.addListener(_onGlobalFavoritesChanged);
  }

  void _onGlobalFavoritesChanged() {
    if (mounted) {
      bool newStatus = _globalFavoritesService.isFavoriteInCache(
        widget.userId, 
        widget.course.id,
      );
      
      if (newStatus != _isFavorite) {
        setState(() {
          _isFavorite = newStatus;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Optimistic update - mettre à jour l'UI immédiatement
    bool optimisticState = !_isFavorite;
    setState(() {
      _isFavorite = optimisticState;
    });

    // Déclencher l'animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      bool success = await _globalFavoritesService.toggleFavorite(
        userId: widget.userId,
        courseId: widget.course.id,
      );

      if (mounted) {
        if (success) {
          // Callback optionnel
          widget.onFavoriteChanged?.call();

          // Feedback visuel
          _showSuccessFeedback();
        } else {
          // Rollback si échec
          setState(() {
            _isFavorite = !optimisticState;
          });
          _showErrorFeedback();
        }
      }
    } catch (e) {
      Logger.error('Erreur toggle favori: $e');
      
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

  void _showSuccessFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFavorite ? Icons.bookmark_added : Icons.bookmark_border,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _isFavorite
                  ? 'Ajouté aux sauvegardés'
                  : 'Retiré des sauvegardés',
            ),
          ],
        ),
        backgroundColor: _isFavorite 
            ? AppColors.success 
            : AppColors.warning,
        duration: const Duration(seconds: 2),
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
    _globalFavoritesService.removeListener(_onGlobalFavoritesChanged);
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
            child: IconButton(
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
                      child: Icon(
                        _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                        key: ValueKey(_isFavorite),
                        color: _isFavorite 
                            ? (widget.favoriteColor ?? AppColors.accent2)
                            : (widget.unfavoriteColor ?? AppColors.greyMedium),
                        size: widget.size,
                      ),
                    ),
              tooltip: _isFavorite 
                  ? 'Retirer des sauvegardés' 
                  : 'Ajouter aux sauvegardés',
              splashRadius: widget.size + 8,
            ),
          ),
        );
      },
    );
  }
}

/// Widget compact pour les cas où l'espace est limité
class CompactGlobalFavoriteButton extends StatelessWidget {
  final CourseModel course;
  final String userId;
  final VoidCallback? onFavoriteChanged;

  const CompactGlobalFavoriteButton({
    super.key,
    required this.course,
    required this.userId,
    this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlobalFavoriteButton(
      course: course,
      userId: userId,
      onFavoriteChanged: onFavoriteChanged,
      size: 18.0,
      favoriteColor: AppColors.accent2,
      unfavoriteColor: AppColors.greyMedium,
    );
  }
}

/// Widget pour les listes où on veut juste l'icône sans interaction
class FavoriteStatusIcon extends StatefulWidget {
  final CourseModel course;
  final String userId;
  final double size;

  const FavoriteStatusIcon({
    super.key,
    required this.course,
    required this.userId,
    this.size = 16.0,
  });

  @override
  State<FavoriteStatusIcon> createState() => _FavoriteStatusIconState();
}

class _FavoriteStatusIconState extends State<FavoriteStatusIcon> {
  final GlobalFavoritesService _globalFavoritesService = GlobalFavoritesService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _listenToChanges();
  }

  void _checkStatus() {
    bool status = _globalFavoritesService.isFavoriteInCache(
      widget.userId, 
      widget.course.id,
    );
    setState(() {
      _isFavorite = status;
    });
  }

  void _listenToChanges() {
    _globalFavoritesService.addListener(_checkStatus);
  }

  @override
  void dispose() {
    _globalFavoritesService.removeListener(_checkStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFavorite) return const SizedBox.shrink();
    
    return Icon(
      Icons.bookmark,
      size: widget.size,
      color: AppColors.accent2,
    );
  }
}