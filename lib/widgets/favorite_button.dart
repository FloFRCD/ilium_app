import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';

class FavoriteButton extends StatefulWidget {
  final CourseModel course;
  final String userId;
  final VoidCallback? onFavoriteChanged;

  const FavoriteButton({
    super.key,
    required this.course,
    required this.userId,
    this.onFavoriteChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      bool isFavorite = await _favoritesService.isFavorite(
        userId: widget.userId,
        courseId: widget.course.id,
      );
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      debugPrint('Erreur vérification statut favori: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _favoritesService.toggleFavorite(
        userId: widget.userId,
        courseId: widget.course.id,
      );

      if (success && mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });

        // Déclencher l'animation
        _animationController.forward().then((_) {
          _animationController.reverse();
        });

        // Callback optionnel
        widget.onFavoriteChanged?.call();

        // Afficher un snackbar de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite
                  ? 'Cours ajouté aux favoris'
                  : 'Cours retiré des favoris',
            ),
            backgroundColor: _isFavorite ? AppColors.success : AppColors.warning,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur toggle favori: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la modification des favoris'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: IconButton(
            onPressed: _isLoading ? null : _toggleFavorite,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isFavorite ? AppColors.accent2 : AppColors.greyMedium,
                      ),
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? AppColors.accent2 : AppColors.greyMedium,
                    size: 24,
                  ),
            tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
          ),
        );
      },
    );
  }
}