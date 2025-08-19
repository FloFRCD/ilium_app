// Flutter framework
import 'package:flutter/material.dart';

// Local models
import '../models/course_model.dart';
import '../models/course_group_model.dart';
import '../models/course_status_model.dart';
import '../models/user_model.dart';

// Local screens
import 'course_detail_screen.dart';
import 'course_group_detail_screen.dart';

// Local services
import '../services/grouped_favorites_service.dart';
import '../services/course_status_service.dart';
import '../services/course_completion_notifier.dart';

// Local theme
import '../theme/app_theme.dart';

// Local utils
import '../utils/course_type_utils.dart';

/// Écran de gestion des cours sauvegardés.
/// Organise les cours en sauvegardés, en cours et terminés.
class SavedCoursesScreen extends StatefulWidget {
  final UserModel user;
  final int? initialTabIndex;

  const SavedCoursesScreen({super.key, required this.user, this.initialTabIndex});

  @override
  State<SavedCoursesScreen> createState() => _SavedCoursesScreenState();
}

class _SavedCoursesScreenState extends State<SavedCoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CourseGroupModel> _favoriteGroups = [];
  List<Map<String, dynamic>> _inProgressCourses = [];
  List<Map<String, dynamic>> _completedCourses = [];
  
  final GroupedFavoritesService _favoritesService = GroupedFavoritesService();
  final CourseStatusService _statusService = CourseStatusService();
  final CourseCompletionNotifier _completionNotifier = CourseCompletionNotifier();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex ?? 0;
    print('🔍 SavedCoursesScreen initialIndex: $initialIndex');
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: initialIndex,
    );
    _loadUserCourses();
    _listenToFavoritesChanges();
  }

  /// Écouter les changements de sauvegardés et de progression pour actualisation automatique
  void _listenToFavoritesChanges() {
    _favoritesService.addListener(() {
      if (mounted) {
        // Rafraîchir seulement les sauvegardés quand ils changent
        _refreshFavorites();
      }
    });
    
    // Écouter les changements de statut des cours
    _completionNotifier.addListener(() {
      if (mounted) {
        // Rafraîchir les cours avec statuts quand un cours est terminé/démarré
        _refreshCoursesStatus();
      }
    });
  }

  /// Rafraîchir uniquement les sauvegardés groupés
  Future<void> _refreshFavorites() async {
    try {
      List<CourseGroupModel> favorites = await _favoritesService.getFavoriteGroups(
        userId: widget.user.uid,
      );
      
      if (mounted) {
        setState(() {
          _favoriteGroups = favorites;
        });
      }
    } catch (e) {
      debugPrint('Erreur rafraîchissement sauvegardés groupés: $e');
    }
  }

  /// Charge tous les types de cours de l'utilisateur depuis Firebase
  void _loadUserCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger en parallèle tous les types de cours
      final futures = await Future.wait([
        _favoritesService.getFavoriteGroups(userId: widget.user.uid),
        _statusService.getCoursesWithStatus(userId: widget.user.uid, filterByStatus: CourseStatus.inProgress, limit: 50),
        _statusService.getCoursesWithStatus(userId: widget.user.uid, filterByStatus: CourseStatus.completed, limit: 50),
      ]);

      if (mounted) {
        setState(() {
          _favoriteGroups = futures[0] as List<CourseGroupModel>;
          _inProgressCourses = futures[1] as List<Map<String, dynamic>>;
          _completedCourses = futures[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });

        // Afficher message si tout est vide
        if (_favoriteGroups.isEmpty && _inProgressCourses.isEmpty && _completedCourses.isEmpty) {
          _showSuggestionMessage();
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement cours utilisateur: $e');
      if (mounted) {
        setState(() {
          _favoriteGroups = [];
          _inProgressCourses = [];
          _completedCourses = [];
          _isLoading = false;
        });
        _showSuggestionMessage();
      }
    }
  }

  /// Rafraîchit les cours avec statuts (en cours et terminés)
  Future<void> _refreshCoursesStatus() async {
    try {
      final futures = await Future.wait([
        _statusService.getCoursesWithStatus(userId: widget.user.uid, filterByStatus: CourseStatus.inProgress, limit: 50),
        _statusService.getCoursesWithStatus(userId: widget.user.uid, filterByStatus: CourseStatus.completed, limit: 50),
      ]);

      if (mounted) {
        setState(() {
          _inProgressCourses = futures[0];
          _completedCourses = futures[1];
        });
      }
    } catch (e) {
      debugPrint('Erreur rafraîchissement statuts cours: $e');
    }
  }

  /// Affiche un message suggérant d'explorer des cours
  void _showSuggestionMessage() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('💫 Explorez et ajoutez des cours aux sauvegardés pour les retrouver ici !'),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Explorer',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(); // Retour à l'accueil
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _favoritesService.removeListener(_refreshFavorites);
    _completionNotifier.removeListener(_refreshCoursesStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: Column(
        children: [
          // Header moderne avec dégradé
          _buildModernHeader(),
          
          // Contenu avec TabBarView
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
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
                      Icons.bookmark,
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
                          'Sauvegardes',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Vos cours favoris et progression',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // TabBar intégré dans le header
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.white,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
              labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  icon: const Icon(Icons.bookmark, size: 20),
                  text: 'Sauvegardés (${_favoriteGroups.length})',
                ),
                Tab(
                  icon: const Icon(Icons.play_circle, size: 20),
                  text: 'En cours (${_inProgressCourses.length})',
                ),
                Tab(
                  icon: const Icon(Icons.check_circle, size: 20),
                  text: 'Terminés (${_completedCourses.length})',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFavoritesTab(),
        _buildInProgressTab(),
        _buildCompletedTab(),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_favoriteGroups.isEmpty) {
      return _buildEmptyState(
        Icons.bookmark_border,
        'Aucun sauvegardé',
        'Ajoutez des cours à vos sauvegardés pour les retrouver facilement',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteGroups.length,
      itemBuilder: (context, index) {
        final group = _favoriteGroups[index];
        return _buildGroupCard(group);
      },
    );
  }

  Widget _buildInProgressTab() {
    if (_inProgressCourses.isEmpty) {
      return _buildEmptyState(
        Icons.play_circle_outline,
        'Aucun cours en cours',
        'Commencez un cours pour le voir apparaître ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inProgressCourses.length,
      itemBuilder: (context, index) {
        final courseData = _inProgressCourses[index];
        final course = courseData['course'] as CourseModel;
        final status = courseData['status'] as CourseStatusModel;

        return _buildCourseCard(
          course,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${course.matiere} • ${course.niveau}',
                    style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
                  ),
                  const SizedBox(height: 6),
                  CourseTypeUtils.buildBadge(course.type),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: status.progress,
                backgroundColor: AppColors.greyLight,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Progression: ${(status.progress * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(color: AppColors.greyMedium),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${status.timeSpentMinutes}min',
                style: AppTextStyles.caption.copyWith(color: AppColors.greyMedium),
              ),
              const SizedBox(height: 4),
              Icon(Icons.play_arrow, color: AppColors.primary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    if (_completedCourses.isEmpty) {
      return _buildEmptyState(
        Icons.check_circle_outline,
        'Aucun cours terminé',
        'Terminez vos premiers cours pour les voir ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedCourses.length,
      itemBuilder: (context, index) {
        final courseData = _completedCourses[index];
        final course = courseData['course'] as CourseModel;
        final status = courseData['status'] as CourseStatusModel;

        return _buildCourseCard(
          course,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${course.matiere} • ${course.niveau}',
                    style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
                  ),
                  const SizedBox(height: 6),
                  CourseTypeUtils.buildBadge(course.type),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Terminé le ${_formatDate(status.statusUpdatedAt)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.greyMedium),
              ),
              if (status.metadata['finalScore'] != null)
                Text(
                  'Score: ${(status.metadata['finalScore'] as double).toInt()}%',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(height: 4),
              Text(
                '${status.timeSpentMinutes}min',
                style: AppTextStyles.caption.copyWith(color: AppColors.greyMedium),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construit une carte de cours personnalisable.
  /// Prend en charge sous-titres et trailing widgets custom.
  Widget _buildCourseCard(
    CourseModel course, {
    Widget? subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        leading: CourseTypeUtils.buildIconContainer(course.type),
        title: Text(
          course.title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle ?? 
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${course.matiere} • ${course.niveau}',
                  style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
                ),
                const SizedBox(height: 6),
                CourseTypeUtils.buildBadge(course.type),
              ],
            ),
          ),
        trailing: trailing ?? Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.greyMedium,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(
                course: course,
                user: widget.user,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit une carte pour un groupe de cours sauvegardés
  Widget _buildGroupCard(CourseGroupModel group) {
    final progressPercentage = group.calculateProgressPercentage(widget.user.uid);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: _getSubjectGradient(group.matiere),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getSubjectIcon(group.matiere),
            color: AppColors.white,
            size: 24,
          ),
        ),
        title: Text(
          group.title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${group.matiere} • ${group.niveau}',
                style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
              ),
              const SizedBox(height: 4),
              Text(
                group.availableContentDescription,
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
              if (progressPercentage > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progressPercentage / 100,
                        backgroundColor: AppColors.greyLight,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${progressPercentage.toInt()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.bookmark_remove, color: AppColors.error),
              onPressed: () => _removeGroupFromFavorites(group),
              tooltip: 'Retirer des sauvegardés',
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.greyMedium,
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CourseGroupDetailScreen(
                group: group,
                user: widget.user,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Affiche un état vide avec icône, titre et message.
  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.greyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(color: AppColors.greyMedium),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Retire un groupe des sauvegardés avec confirmation
  void _removeGroupFromFavorites(CourseGroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer des sauvegardés'),
        content: Text('Voulez-vous retirer "${group.title}" de vos sauvegardés ?\n\nCela retirera tout le sujet avec ses contenus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _favoritesService.removeGroupFromFavorites(
        userId: widget.user.uid,
        groupId: group.id,
      );

      if (success && mounted) {
        setState(() {
          _favoriteGroups.removeWhere((g) => g.id == group.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${group.title} retiré des sauvegardés'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  /// Méthodes utilitaires pour l'interface des groupes
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