import 'package:flutter/material.dart';
import '../services/course_rating_service.dart';
import '../theme/app_theme.dart';

/// Widget pour afficher et permettre de noter un cours
class CourseRatingWidget extends StatefulWidget {
  final String courseId;
  final String userId;
  final bool allowRating;
  final VoidCallback? onRatingChanged;
  final DateTime? courseCreatedAt;

  const CourseRatingWidget({
    super.key,
    required this.courseId,
    required this.userId,
    this.allowRating = true,
    this.onRatingChanged,
    this.courseCreatedAt,
  });

  @override
  State<CourseRatingWidget> createState() => _CourseRatingWidgetState();
}

class _CourseRatingWidgetState extends State<CourseRatingWidget> {
  final CourseRatingService _ratingService = CourseRatingService();
  double? _userRating;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserRating();
  }

  Future<void> _loadUserRating() async {
    final rating = await _ratingService.getUserRating(widget.courseId, widget.userId);
    if (mounted) {
      setState(() {
        _userRating = rating;
      });
    }
  }

  Future<void> _submitRating(double rating) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final success = await _ratingService.addUserRating(
      courseId: widget.courseId,
      userId: widget.userId,
      rating: rating,
      courseCreatedAt: widget.courseCreatedAt,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _userRating = rating;
        }
      });

      if (success) {
        widget.onRatingChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note enregistrée: ${rating.toStringAsFixed(1)}/5 ⭐'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement de la note'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _ratingService.getCourseRatingStream(widget.courseId),
      builder: (context, snapshot) {
        final ratingData = snapshot.data ?? {
          'averageRating': 0.0,
          'totalRatings': 0,
          'realRatingsCount': 0,
          'artificialRatingsCount': 0,
        };

        final averageRating = ratingData['averageRating'] as double;
        final totalRatings = ratingData['totalRatings'] as int;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec note moyenne
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Note du cours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greyDark,
                      ),
                    ),
                    const Spacer(),
                    if (totalRatings > 0) ...[
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/5',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Affichage des étoiles pour la note moyenne
                if (totalRatings > 0) ...[
                  _buildStarDisplay(averageRating, totalRatings),
                  const SizedBox(height: 16),
                ],
                
                // Interface de notation utilisateur
                if (widget.allowRating) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  Text(
                    _userRating != null 
                        ? 'Votre note: ${_userRating!.toStringAsFixed(1)}/5'
                        : 'Notez ce cours',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyDark,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildRatingStars(),
                  
                  if (_userRating != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Appuyez sur une étoile pour modifier votre note',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.greyMedium,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarDisplay(double averageRating, int totalRatings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...List.generate(5, (index) {
              final starValue = index + 1;
              final filled = averageRating >= starValue;
              final halfFilled = averageRating >= starValue - 0.5 && averageRating < starValue;
              
              return Icon(
                halfFilled ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
                color: Colors.amber,
                size: 20,
              );
            }),
            const SizedBox(width: 8),
            Text(
              '($totalRatings avis)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildRatingBreakdown(averageRating, totalRatings),
      ],
    );
  }

  Widget _buildRatingBreakdown(double averageRating, int totalRatings) {
    // Distribution des étoiles (simplifié pour demo)
    final distributions = [
      {'stars': 5, 'percentage': averageRating >= 4.5 ? 0.6 : 0.3},
      {'stars': 4, 'percentage': 0.3},
      {'stars': 3, 'percentage': 0.1},
      {'stars': 2, 'percentage': 0.0},
      {'stars': 1, 'percentage': 0.0},
    ];

    return Column(
      children: distributions.map((dist) {
        final stars = dist['stars'] as int;
        final percentage = dist['percentage'] as double;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$stars',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.greyMedium,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.star, color: Colors.amber, size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppColors.greyLight,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.greyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      children: List.generate(5, (index) {
        final starValue = (index + 1).toDouble();
        final isSelected = _userRating != null && _userRating! >= starValue;
        
        return GestureDetector(
          onTap: _isLoading ? null : () => _submitRating(starValue),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: _isLoading
                ? SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  )
                : Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
          ),
        );
      }),
    );
  }
}

/// Widget simple pour afficher uniquement la note moyenne
class SimpleRatingDisplay extends StatelessWidget {
  final String courseId;
  final double iconSize;
  final TextStyle? textStyle;

  const SimpleRatingDisplay({
    super.key,
    required this.courseId,
    this.iconSize = 16.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ratingService = CourseRatingService();
    
    return FutureBuilder<Map<String, dynamic>>(
      future: ratingService.getCourseRating(courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final ratingData = snapshot.data!;
        final averageRating = ratingData['averageRating'] as double;
        final totalRatings = ratingData['totalRatings'] as int;

        if (totalRatings == 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_border,
                size: iconSize,
                color: AppColors.greyMedium,
              ),
              const SizedBox(width: 4),
              Text(
                'Pas encore noté',
                style: textStyle ?? TextStyle(
                  color: AppColors.greyMedium,
                  fontSize: 12,
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: iconSize,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              '${averageRating.toStringAsFixed(1)} ($totalRatings)',
              style: textStyle ?? TextStyle(
                color: AppColors.greyDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget détaillé pour debug/admin montrant le breakdown réel/artificiel
class DetailedRatingWidget extends StatelessWidget {
  final String courseId;

  const DetailedRatingWidget({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final ratingService = CourseRatingService();
    
    return FutureBuilder<Map<String, dynamic>>(
      future: ratingService.getCourseRating(courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final averageRating = data['averageRating'] as double;
        final totalRatings = data['totalRatings'] as int;
        final realRatingsCount = data['realRatingsCount'] as int;
        final artificialRatingsCount = data['artificialRatingsCount'] as int;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.greyLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyMedium.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'Statistiques de notation',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildRatingStat('Moyenne', '${averageRating.toStringAsFixed(1)}/5', AppColors.primary),
              _buildRatingStat('Total', totalRatings.toString(), AppColors.greyDark),
              _buildRatingStat('Réelles', realRatingsCount.toString(), AppColors.success),
              _buildRatingStat('Boost', artificialRatingsCount.toString(), AppColors.accent2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.greyMedium,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}