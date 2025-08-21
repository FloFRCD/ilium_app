import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../models/progression_model.dart';
import '../screens/settings_screen.dart';
import '../services/user_preferences_service.dart';
import '../services/course_completion_notifier.dart';
import '../services/firestore_service.dart';
import '../widgets/profile_avatar.dart';
import '../theme/app_theme.dart';
import '../utils/progression_migration.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel)? onUserUpdated;

  const ProfileScreen({super.key, required this.user, this.onUserUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserPreferencesService _userService = UserPreferencesService();
  final CourseCompletionNotifier _completionNotifier = CourseCompletionNotifier();
  final FirestoreService _firestoreService = FirestoreService();
  final ProgressionMigrationService _migrationService = ProgressionMigrationService();
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUser = widget.user;
    
    // Écouter les changements de progression
    _completionNotifier.addListener(_refreshUserProgression);
  }

  /// Rafraîchit les données de progression utilisateur depuis Firebase
  Future<void> _refreshUserProgression() async {
    try {
      final updatedUser = await _firestoreService.getUser(widget.user.uid);
      if (updatedUser != null && mounted) {
        setState(() {
          _currentUser = updatedUser;
        });
        // Notifier les autres écrans du changement
        widget.onUserUpdated?.call(updatedUser);
        
        debugPrint('✅ Profil rafraîchi: ${updatedUser.badges.length} badges, ${updatedUser.progression.totalXp} XP');
      }
    } catch (e) {
      debugPrint('❌ Erreur rafraîchissement données progression: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _completionNotifier.removeListener(_refreshUserProgression);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: Column(
        children: [
          // Header compact moderne
          _buildCompactHeader(),
          // Contenu avec TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildBadgesTab(),
                _buildProgressionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      clipBehavior: Clip.antiAlias,
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
            // Avatar principal avec prénom et infos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Avatar principal à gauche
                  ProfileAvatar(
                    user: _currentUser,
                    radius: 24,
                    showBorder: true,
                    borderColor: AppColors.white,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.pseudo,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_currentUser.niveau} • ${_currentUser.progression.tierName}',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton paramètres
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.white),
                    onPressed: () => _showSettingsDialog(),
                  ),
                ],
              ),
            ),
            
            // Stats compactes horizontales
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompactStat('${_currentUser.progression.totalXp}', 'XP'),
                  _buildCompactStat('${_currentUser.progression.currentLevel}', 'Niveau'),
                  _buildCompactStat('${_currentUser.badges.where((b) => b.isUnlocked).length}', 'Badges'),
                  _buildCompactStat('${_currentUser.progression.totalCoursCompleted}', 'Cours'),
                ],
              ),
            ),
            
            // TabBar intégré
            const SizedBox(height: 8),
            _buildTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }


  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.white,
      labelColor: AppColors.white,
      unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
      labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      tabs: const [
        Tab(text: 'Vue d\'ensemble'),
        Tab(text: 'Badges'),
        Tab(text: 'Progression'),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubscriptionCard(),
          const SizedBox(height: 20),
          _buildRecentActivityCard(),
          const SizedBox(height: 20),
          _buildStatsCard(),
          const SizedBox(height: 100), // Espace pour navigation bar
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final isPremium = _currentUser.subscriptionType != SubscriptionType.free;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPremium ? AppColors.energyGradient : 
                  LinearGradient(
                    colors: [AppColors.greyLight, AppColors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.star : Icons.person,
                color: isPremium ? AppColors.white : AppColors.greyDark,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _getSubscriptionTitle(),
                style: AppTextStyles.h3.copyWith(
                  color: isPremium ? AppColors.white : AppColors.greyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getSubscriptionDescription(),
            style: AppTextStyles.body.copyWith(
              color: isPremium ? AppColors.white.withValues(alpha: 0.9) : AppColors.greyMedium,
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 16),
            GradientButton(
              text: 'Passer au Premium',
              icon: Icons.star,
              gradient: AppColors.energyGradient,
              onPressed: () => _showUpgradeDialog(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    // Générer des activités basées sur les vraies statistiques
    List<Widget> activities = _generateRecentActivities();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timeline, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Activité récente', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          ...activities,
        ],
      ),
    );
  }

  /// Génère des activités cohérentes avec les statistiques
  List<Widget> _generateRecentActivities() {
    List<Widget> activities = [];
    
    // Si l'utilisateur n'a aucune activité, afficher un message
    if (widget.user.progression.totalCoursCompleted == 0 && 
        widget.user.progression.totalQcmPassed == 0 && 
        widget.user.badges.where((b) => b.isUnlocked).length <= 1) {
      
      activities.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.rocket_launch,
                size: 32,
                color: AppColors.greyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez votre parcours !',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Vos activités apparaîtront ici une fois que vous aurez commencé à étudier.',
                style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
      return activities;
    }

    // Générer des activités basées sur les vraies stats
    int totalActivities = 0;
    
    // Badges récents
    final unlockedBadges = widget.user.badges.where((b) => b.isUnlocked).toList();
    if (unlockedBadges.isNotEmpty && totalActivities < 3) {
      final badge = unlockedBadges.last; // Plus récent
      activities.add(_buildActivityItem(
        Icons.emoji_events,
        'Badge obtenu',
        badge.name,
        'Récemment',
        AppColors.accent2,
      ));
      totalActivities++;
    }
    
    // Cours terminés
    if (widget.user.progression.totalCoursCompleted > 0 && totalActivities < 3) {
      activities.add(_buildActivityItem(
        Icons.book,
        'Cours terminé',
        'Progression dans ${widget.user.niveau}',
        'Récemment',
        AppColors.primary,
      ));
      totalActivities++;
    }
    
    // QCM réussis
    if (widget.user.progression.totalQcmPassed > 0 && totalActivities < 3) {
      activities.add(_buildActivityItem(
        Icons.quiz,
        'QCM réussi',
        'Score moyen: ${widget.user.progression.overallAverageScore.toStringAsFixed(1)}%',
        'Récemment',  
        AppColors.success,
      ));
      totalActivities++;
    }
    
    // Série active
    if (widget.user.progression.totalStreakDays > 0 && totalActivities < 3) {
      activities.add(_buildActivityItem(
        Icons.local_fire_department,
        'Série maintenue',
        '${widget.user.progression.totalStreakDays} jours consécutifs',
        'En cours',
        AppColors.warning,
      ));
      totalActivities++;
    }
    
    // Si toujours pas assez d'activités, ajouter une activité de motivation
    if (totalActivities == 0) {
      activities.add(_buildActivityItem(
        Icons.star,
        'Profil créé',
        'Bienvenue sur Ilium !',
        'Récemment',
        AppColors.secondary,
      ));
    }
    
    return activities;
  }

  Widget _buildActivityItem(IconData icon, String type, String title, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.caption.copyWith(color: AppColors.greyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Statistiques', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${widget.user.progression.totalCoursCompleted}',
                  'Cours terminés',
                  Icons.book,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '${widget.user.progression.totalQcmPassed}',
                  'QCM réussis',
                  Icons.quiz,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${widget.user.progression.totalStreakDays}',
                  'Série actuelle',
                  Icons.local_fire_department,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '${widget.user.progression.overallAverageScore.toStringAsFixed(1)}%',
                  'Moyenne',
                  Icons.trending_up,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.greyMedium),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    List<BadgeModel> unlockedBadges = widget.user.badges.where((badge) => badge.isUnlocked).toList();
    List<BadgeModel> lockedBadges = widget.user.badges.where((badge) => !badge.isUnlocked).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badges obtenus (${unlockedBadges.length})',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          if (unlockedBadges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.greyMedium),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun badge obtenu pour le moment',
                      style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: unlockedBadges.length,
              itemBuilder: (context, index) {
                return _buildBadgeCard(unlockedBadges[index], true);
              },
            ),
          const SizedBox(height: 32),
          Text(
            'Badges à débloquer (${lockedBadges.length})',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: lockedBadges.length,
            itemBuilder: (context, index) {
              return _buildBadgeCard(lockedBadges[index], false);
            },
          ),
          const SizedBox(height: 100), // Espace pour navigation bar
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isUnlocked 
                ? badge.rarityColor.withValues(alpha: 0.2)
                : AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: isUnlocked ? 16 : 8,
          ),
        ],
        border: isUnlocked ? Border.all(
          color: badge.rarityColor.withValues(alpha: 0.3),
          width: 2,
        ) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? badge.rarityColor
                  : AppColors.greyLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isUnlocked ? [
                BoxShadow(
                  color: badge.rarityColor.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ] : null,
            ),
            child: Center(
              child: Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: isUnlocked ? AppColors.white : AppColors.greyMedium,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: isUnlocked ? AppColors.greyDark : AppColors.greyMedium,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            badge.typeDescription,
            style: AppTextStyles.caption.copyWith(color: AppColors.greyMedium),
            textAlign: TextAlign.center,
          ),
          if (isUnlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${badge.xpReward} XP',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelProgressCard(),
          const SizedBox(height: 20),
          _buildSubjectsProgressCard(),
          const SizedBox(height: 100), // Espace pour navigation bar
        ],
      ),
    );
  }

  Widget _buildLevelProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Progression du niveau', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Niveau ${widget.user.progression.currentLevel}',
                style: AppTextStyles.h1.copyWith(color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                '${widget.user.progression.totalXp} XP',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.greyMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.user.progression.levelProgress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.user.progression.xpToNextLevel} XP jusqu\'au niveau ${widget.user.progression.currentLevel + 1}',
            style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.energyGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.subject, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Progression par matière', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.user.progression.subjectProgressions.values.map((subject) {
            return _buildSubjectProgressItem(subject);
          }),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressItem(SubjectProgressionModel subject) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getSubjectColor(subject.matiere).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSubjectIcon(subject.matiere),
                  color: _getSubjectColor(subject.matiere),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subject.matiere,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${subject.preciseCompletionPercentage.toStringAsFixed(1)}%',
                style: AppTextStyles.body.copyWith(
                  color: _getSubjectColor(subject.matiere),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: subject.preciseCompletionPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: _getSubjectColor(subject.matiere),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${subject.coursCompleted}/${subject.coursTotal} cours • ${subject.qcmPassed}/${subject.qcmTotal} QCM',
            style: AppTextStyles.caption.copyWith(color: AppColors.greyMedium),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          user: _currentUser,
          onUserUpdated: (updatedUser) {
            // Mettre à jour l'état local
            setState(() {
              _currentUser = updatedUser;
            });
            // Notifier les autres écrans
            widget.onUserUpdated?.call(updatedUser);
          },
        ),
      ),
    );
    
    // Rafraîchir les données utilisateur au retour (au cas où)
    await _refreshUserProgression();
  }

  Future<void> _refreshUserData() async {
    final updatedUser = await _userService.getUpdatedUser(_currentUser.uid);
    if (updatedUser != null && mounted) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  /// Déclenche manuellement la migration des progressions (pour debug)
  Future<void> _triggerMigration() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Migration en cours...'),
            ],
          ),
        ),
      );

      final success = await _migrationService.migrateUserProgressions(_currentUser.uid);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le dialog de chargement
      
      if (success) {
        // Rafraîchir les données utilisateur
        await _refreshUserProgression();
        
        if (!mounted) return;
        // Afficher confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Migration des progressions terminée'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la migration'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le dialog de chargement si ouvert
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.star, color: AppColors.accent2),
            const SizedBox(width: 8),
            Text(
              'Passer au Premium',
              style: AppTextStyles.h3.copyWith(color: AppColors.greyDark),
            ),
          ],
        ),
        content: Text(
          'Débloquez toutes les fonctionnalités premium !',
          style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.greyMedium),
            child: Text('Annuler', style: AppTextStyles.body),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: GradientButton(
              text: 'S\'abonner',
              icon: Icons.star,
              gradient: AppColors.energyGradient,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubscriptionTitle() {
    switch (_currentUser.subscriptionType) {
      case SubscriptionType.free:
        return 'Compte Gratuit';
      case SubscriptionType.premium:
        return 'Compte Premium';
      case SubscriptionType.premiumPlus:
        return 'Compte Premium+';
    }
  }

  String _getSubscriptionDescription() {
    switch (_currentUser.subscriptionType) {
      case SubscriptionType.free:
        return 'Accès limité aux cours et QCM';
      case SubscriptionType.premium:
        return 'Accès illimité aux cours premium';
      case SubscriptionType.premiumPlus:
        return 'Accès complet + support prioritaire';
    }
  }

  Color _getTierColor(UserTier tier) {
    switch (tier) {
      case UserTier.bronze:
        return const Color(0xFFCD7F32);
      case UserTier.silver:
        return const Color(0xFFC0C0C0);
      case UserTier.gold:
        return AppColors.accent2;
      case UserTier.platinum:
        return const Color(0xFFE5E4E2);
      case UserTier.diamond:
        return AppColors.accent1;
    }
  }

  Color _getSubjectColor(String matiere) {
    switch (matiere) {
      case 'Mathématiques':
        return AppColors.primary;
      case 'Français':
        return AppColors.error;
      case 'Histoire-Géographie':
        return const Color(0xFF8D6E63);
      case 'Sciences':
        return AppColors.success;
      case 'Physique-Chimie':
        return AppColors.secondary;
      case 'SVT':
        return AppColors.accent1;
      case 'Anglais':
        return const Color(0xFF3F51B5);
      case 'Espagnol':
        return AppColors.warning;
      case 'Allemand':
        return AppColors.accent2;
      default:
        return AppColors.greyMedium;
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