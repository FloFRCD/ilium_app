import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../services/global_suggestions_service.dart';
import '../widgets/grouped_favorite_button.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../screens/course_detail_screen.dart';

/// Widget réutilisable pour afficher des suggestions sans doublons
class SuggestionsWidget extends StatefulWidget {
  final UserModel user;
  final String pageId;
  final int limit;
  final String title;
  final bool showTitle;
  final VoidCallback? onSuggestionUsed;

  const SuggestionsWidget({
    super.key,
    required this.user,
    required this.pageId,
    this.limit = 3,
    this.title = 'Suggestions pour vous',
    this.showTitle = true,
    this.onSuggestionUsed,
  });

  @override
  State<SuggestionsWidget> createState() => _SuggestionsWidgetState();
}

class _SuggestionsWidgetState extends State<SuggestionsWidget> {
  final GlobalSuggestionsService _suggestionsService = GlobalSuggestionsService();
  List<CourseModel> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      List<CourseModel> suggestions = await _suggestionsService.getSuggestionsForPage(
        widget.user,
        pageId: widget.pageId,
        limit: widget.limit,
      );
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erreur chargement suggestions pour ${widget.pageId}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshSuggestions() async {
    setState(() {
      _isLoading = true;
    });
    await _loadSuggestions();
  }

  void _onCourseAction(CourseModel course) async {
    // Marquer la suggestion comme utilisée
    _suggestionsService.markSuggestionAsUsed(widget.user.uid, course.id);
    
    // Callback optionnel
    widget.onSuggestionUsed?.call();
    
    // Recharger les suggestions
    await _refreshSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.title,
                style: AppTextStyles.h3,
              ),
            ),
          ...List.generate(widget.limit, (index) => _buildLoadingCard()),
        ],
      );
    }

    if (_suggestions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.title,
                style: AppTextStyles.h3,
              ),
            ),
          _buildEmptyState(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.h3,
                  ),
                ),
                TextButton.icon(
                  onPressed: _refreshSuggestions,
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('Actualiser'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ...List.generate(_suggestions.length, (index) {
          return _buildSuggestionCard(_suggestions[index]);
        }),
      ],
    );
  }

  Widget _buildSuggestionCard(CourseModel course) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          _onCourseAction(course);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(
                course: course,
                user: widget.user,
              ),
            ),
          );
        },
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              course.matiere.isNotEmpty ? course.matiere[0].toUpperCase() : 'C',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          course.title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${course.matiere} • ${course.niveau}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.greyMedium,
              ),
            ),
            if (course.estimatedDuration != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: AppColors.greyMedium),
                  const SizedBox(width: 4),
                  Text(
                    '${course.estimatedDuration} min',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.greyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GroupedFavoriteButton(
              course: course,
              userId: widget.user.uid,
              onFavoriteChanged: (group) => _onCourseAction(course),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.greyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: AppColors.greyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune suggestion disponible',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nous préparons de nouvelles suggestions personnalisées pour vous !',
            style: AppTextStyles.body.copyWith(
              color: AppColors.greyMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshSuggestions,
            icon: Icon(Icons.refresh),
            label: Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}