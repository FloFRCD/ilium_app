import 'package:flutter/material.dart';
import '../models/course_group_model.dart';
import '../models/course_model.dart';
import '../models/qcm_model.dart';
import '../models/user_model.dart';
import '../services/grouped_favorites_service.dart';
import '../widgets/grouped_favorite_button.dart';
import '../theme/app_theme.dart';
import 'course_reader_screen.dart';
import 'qcm_selection_screen.dart';

/// Écran détaillé d'un groupe de cours (concept/sujet complet)
/// 
/// FONCTIONNALITÉS POUR LES PARENTS :
/// - Vue d'ensemble du sujet étudié
/// - Choix du type de contenu (cours, fiche, QCM)
/// - Progression détaillée sur chaque type
/// - Statistiques de réussite des QCM
/// - Temps passé sur le sujet
/// - Historique des activités
/// 
/// UTILISATION :
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (context) => CourseGroupDetailScreen(
///     group: courseGroup,
///     user: user,
///   ),
/// ));
/// ```
class CourseGroupDetailScreen extends StatefulWidget {
  final CourseGroupModel group;
  final UserModel user;

  const CourseGroupDetailScreen({
    super.key,
    required this.group,
    required this.user,
  });

  @override
  State<CourseGroupDetailScreen> createState() => _CourseGroupDetailScreenState();
}

class _CourseGroupDetailScreenState extends State<CourseGroupDetailScreen> {
  final GroupedFavoritesService _favoritesService = GroupedFavoritesService();
  late CourseGroupModel _currentGroup;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
  }

  @override
  Widget build(BuildContext context) {
    double progressPercentage = _currentGroup.calculateProgressPercentage(widget.user.uid);
    Map<String, int> qcmSummary = _currentGroup.getQCMSummary(widget.user.uid);

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeroSection(progressPercentage),
                  _buildContentOptions(),
                  if (qcmSummary['total']! > 0) _buildQCMStats(qcmSummary),
                  _buildProgressDetails(),
                  const SizedBox(height: 100), // Espace pour navigation
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _currentGroup.title,
        style: AppTextStyles.h3.copyWith(color: AppColors.white),
      ),
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: _getSubjectGradient(_currentGroup.matiere),
        ),
      ),
      elevation: 0,
      actions: [
        GroupedFavoriteButton(
          course: CourseModel(
            id: 'temp_${_currentGroup.id}',
            title: _currentGroup.title,
            matiere: _currentGroup.matiere,
            niveau: _currentGroup.niveau,
            type: CourseType.cours,
            content: '',
            popularity: 0,
            votes: {},
            commentaires: [],
            authorId: '',
            authorName: '',
            createdAt: _currentGroup.createdAt,
            updatedAt: _currentGroup.updatedAt,
            tags: _currentGroup.tags,
            isPublic: _currentGroup.isPublic,
            isPremium: _currentGroup.isPremium,
          ),
          userId: widget.user.uid,
          favoriteColor: AppColors.white,
          unfavoriteColor: AppColors.white.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildHeroSection(double progressPercentage) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getSubjectGradient(_currentGroup.matiere),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        children: [
          // Informations principales
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _getSubjectIcon(_currentGroup.matiere),
                  color: AppColors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentGroup.matiere} • ${_currentGroup.niveau}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentGroup.availableContentDescription,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progression globale
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression globale',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${progressPercentage.toInt()}%',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressPercentage / 100,
                  backgroundColor: AppColors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentOptions() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Choisissez votre type de contenu',
              style: AppTextStyles.h3.copyWith(color: AppColors.greyDark),
            ),
          ),
          
          // Cours complet
          if (_currentGroup.hasCoursComplet)
            _buildContentOption(
              icon: Icons.school,
              title: 'Cours complet',
              description: 'Théorie complète et explications détaillées',
              isCompleted: _isContentCompleted('cours'),
              onTap: () => _openCourse(_currentGroup.coursComplet!),
            ),
          
          // Fiche de révision
          if (_currentGroup.hasFicheRevision)
            _buildContentOption(
              icon: Icons.description,
              title: 'Fiche de révision',
              description: 'Résumé des points essentiels',
              isCompleted: _isContentCompleted('fiche'),
              onTap: () => _openCourse(_currentGroup.ficheRevision!),
            ),
          
          // QCM
          if (_currentGroup.hasQCMs)
            _buildContentOption(
              icon: Icons.quiz,
              title: 'QCM (${_currentGroup.qcms.length})',
              description: 'Testez vos connaissances',
              isCompleted: _areAllQCMsCompleted(),
              badge: _getQCMBadge(),
              onTap: () => _openQCMSelection(),
            ),
          
          // Exercices
          if (_currentGroup.hasExercices)
            _buildContentOption(
              icon: Icons.fitness_center,
              title: 'Exercices (${_currentGroup.exercices.length})',
              description: 'Mise en pratique des notions',
              isCompleted: _areAllExercicesCompleted(),
              onTap: () => _openExercices(),
            ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildContentOption({
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted 
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.greyLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.greyMedium.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.success : AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : icon,
            color: AppColors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? AppColors.success : AppColors.greyDark,
                ),
              ),
            ),
            if (badge != null) badge,
            if (isCompleted)
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
          ],
        ),
        subtitle: Text(
          description,
          style: AppTextStyles.body.copyWith(
            color: AppColors.greyMedium,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.greyMedium,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildQCMStats(Map<String, int> qcmSummary) {
    int total = qcmSummary['total']!;
    int reussis = qcmSummary['reussis']!;
    double successRate = total > 0 ? (reussis / total) * 100 : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques QCM',
            style: AppTextStyles.h3.copyWith(color: AppColors.greyDark),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.quiz,
                  label: 'Total',
                  value: total.toString(),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Réussis',
                  value: reussis.toString(),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.percent,
                  label: 'Taux',
                  value: '${successRate.toInt()}%',
                  color: successRate >= 70 ? AppColors.success : 
                         successRate >= 50 ? AppColors.warning : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de progression',
            style: AppTextStyles.h3.copyWith(color: AppColors.greyDark),
          ),
          const SizedBox(height: 16),
          
          if (_currentGroup.hasCoursComplet)
            _buildProgressItem(
              'Cours complet',
              _isContentCompleted('cours'),
              Icons.school,
            ),
          
          if (_currentGroup.hasFicheRevision)
            _buildProgressItem(
              'Fiche de révision',
              _isContentCompleted('fiche'),
              Icons.description,
            ),
          
          for (QCMModel qcm in _currentGroup.qcms)
            _buildProgressItem(
              'QCM: ${qcm.title}',
              _isQCMCompleted(qcm.id),
              Icons.quiz,
            ),
          
          for (CourseModel exercice in _currentGroup.exercices)
            _buildProgressItem(
              'Exercice: ${exercice.title}',
              _isExerciceCompleted(exercice.id),
              Icons.fitness_center,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String title, bool isCompleted, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isCompleted ? AppColors.success : AppColors.greyMedium,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(
                color: isCompleted ? AppColors.success : AppColors.greyMedium,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppColors.success : AppColors.greyMedium,
            size: 18,
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires pour vérifier la progression
  bool _isContentCompleted(String contentType) {
    Map<String, dynamic> userProgress = _currentGroup.progressionData[widget.user.uid] ?? {};
    return userProgress['${contentType}_completed'] == true;
  }

  bool _isQCMCompleted(String qcmId) {
    Map<String, dynamic> userProgress = _currentGroup.progressionData[widget.user.uid] ?? {};
    Map<String, bool> qcmResults = Map<String, bool>.from(userProgress['qcm_results'] ?? {});
    return qcmResults[qcmId] == true;
  }

  bool _isExerciceCompleted(String exerciceId) {
    Map<String, dynamic> userProgress = _currentGroup.progressionData[widget.user.uid] ?? {};
    Map<String, bool> exerciceResults = Map<String, bool>.from(userProgress['exercice_results'] ?? {});
    return exerciceResults[exerciceId] == true;
  }

  bool _areAllQCMsCompleted() {
    return _currentGroup.qcms.every((qcm) => _isQCMCompleted(qcm.id));
  }

  bool _areAllExercicesCompleted() {
    return _currentGroup.exercices.every((exercice) => _isExerciceCompleted(exercice.id));
  }

  Widget? _getQCMBadge() {
    Map<String, int> qcmSummary = _currentGroup.getQCMSummary(widget.user.uid);
    int reussis = qcmSummary['reussis']!;
    int total = qcmSummary['total']!;
    
    if (total == 0) return null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: reussis == total ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$reussis/$total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Méthodes de navigation
  void _openCourse(CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseReaderScreen(
          course: course,
          user: widget.user,
        ),
      ),
    ).then((_) {
      // Marquer le contenu comme lu
      _updateProgress('cours', course.id, true);
    });
  }

  void _openQCMSelection() {
    // Navigation vers l'écran de sélection QCM général
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QCMSelectionScreen(
          user: widget.user,
        ),
      ),
    ).then((results) {
      if (results != null && results is Map<String, bool>) {
        // Mettre à jour les résultats des QCM
        for (String qcmId in results.keys) {
          _updateProgress('qcm', qcmId, results[qcmId]!);
        }
      }
    });
  }

  void _openExercices() {
    // TODO: Implémenter l'écran d'exercices
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exercices - À implémenter'),
      ),
    );
  }

  Future<void> _updateProgress(String contentType, String contentId, bool completed) async {
    bool success = await _favoritesService.updateGroupProgress(
      userId: widget.user.uid,
      groupId: _currentGroup.id,
      contentType: contentType,
      contentId: contentId,
      completed: completed,
    );

    if (success && mounted) {
      // Rafraîchir l'écran
      setState(() {
        // La progression sera recalculée automatiquement
      });
    }
  }

  // Méthodes utilitaires pour l'interface
  LinearGradient _getSubjectGradient(String matiere) {
    switch (matiere.toLowerCase()) {
      case 'mathématiques':
      case 'maths':
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'français':
        return const LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'histoire-géographie':
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'sciences':
      case 'svt':
        return const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'physique-chimie':
        return const LinearGradient(
          colors: [Color(0xFFfa709a), Color(0xFFfee140)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppColors.primaryGradient;
    }
  }

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