import 'package:flutter/material.dart';
import '../services/course_views_service.dart';
import '../theme/app_theme.dart';

/// Widget pour afficher les vues d'un cours
class CourseViewsWidget extends StatefulWidget {
  final String courseId;
  final bool showLabel;
  final double iconSize;
  final TextStyle? textStyle;

  const CourseViewsWidget({
    super.key,
    required this.courseId,
    this.showLabel = true,
    this.iconSize = 16.0,
    this.textStyle,
  });

  @override
  State<CourseViewsWidget> createState() => _CourseViewsWidgetState();
}

class _CourseViewsWidgetState extends State<CourseViewsWidget> {
  final CourseViewsService _viewsService = CourseViewsService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, int>>(
      stream: _viewsService.getCourseViewsStream(widget.courseId),
      builder: (context, snapshot) {
        final views = snapshot.data?['totalViews'] ?? 0;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility,
              size: widget.iconSize,
              color: AppColors.greyMedium,
            ),
            const SizedBox(width: 4),
            Text(
              widget.showLabel ? '$views vues' : '$views',
              style: widget.textStyle ?? TextStyle(
                color: AppColors.greyMedium,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget plus détaillé avec breakdown des vues réelles/artificielles (pour debug/admin)
class DetailedCourseViewsWidget extends StatefulWidget {
  final String courseId;

  const DetailedCourseViewsWidget({
    super.key,
    required this.courseId,
  });

  @override
  State<DetailedCourseViewsWidget> createState() => _DetailedCourseViewsWidgetState();
}

class _DetailedCourseViewsWidgetState extends State<DetailedCourseViewsWidget> {
  final CourseViewsService _viewsService = CourseViewsService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _viewsService.getCourseViews(widget.courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final totalViews = data['totalViews'] ?? 0;
        final realViews = data['realViews'] ?? 0;
        final artificialViews = data['artificialViews'] ?? 0;

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
                  Icon(Icons.visibility, size: 16, color: AppColors.greyDark),
                  const SizedBox(width: 4),
                  Text(
                    'Statistiques de vues',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildViewsStat('Total', totalViews, AppColors.primary),
              _buildViewsStat('Réelles', realViews, AppColors.success),
              _buildViewsStat('Boost', artificialViews, AppColors.accent2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewsStat(String label, int count, Color color) {
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
            count.toString(),
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