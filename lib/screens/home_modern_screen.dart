import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../models/progression_model.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import '../services/news_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_tutorial_screen.dart';

class HomeModernScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onNavigateToCourses;
  final Function(int)? onNavigateToTab;

  const HomeModernScreen({super.key, required this.user, this.onNavigateToCourses, this.onNavigateToTab});

  @override
  State<HomeModernScreen> createState() => _HomeModernScreenState();
}

class _HomeModernScreenState extends State<HomeModernScreen> {
  late List<BadgeModel> _recentBadges;
  final NewsService _newsService = NewsService();
  List<NewsArticle> _newsArticles = [];
  bool _isLoadingNews = true;
  
  // Contrôleur pour le carousel des actualités
  late PageController _newsPageController;

  @override
  void initState() {
    super.initState();
    _refreshBadges();
    _newsPageController = PageController(
      viewportFraction: 0.9, // Plus large pour un meilleur swipe
      initialPage: 0,
    );
    _loadEducationNews();
  }

  /// Rafraîchit les badges récents affichés
  void _refreshBadges() {
    _recentBadges = widget.user.badges.where((b) => b.isUnlocked).take(3).toList();
    print('🏆 Badges récents mis à jour: ${_recentBadges.length} badges');
  }

  @override
  void dispose() {
    _newsPageController.dispose();
    super.dispose();
  }

  Future<void> _loadEducationNews() async {
    try {
      print('🏠 HOME: Démarrage du chargement des actualités...');
      final articles = await _newsService.getCachedEducationNews(maxArticles: 8);
      print('🏠 HOME: ${articles.length} articles reçus');
      
      if (articles.isNotEmpty) {
        print('🏠 HOME: Premier article: "${articles.first.title}"');
      }
      
      if (mounted) {
        setState(() {
          _newsArticles = articles;
          _isLoadingNews = false;
        });
        print('🏠 HOME: Interface mise à jour avec ${articles.length} articles');
      }
    } catch (e) {
      print('🏠 HOME: Erreur lors du chargement des actualités: $e');
      if (mounted) {
        setState(() {
          _newsArticles = [];
          _isLoadingNews = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final progression = widget.user.progression;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1024;
    
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: isLargeScreen 
        ? _buildWebLayout(progression, screenWidth)
        : _buildMobileLayout(progression, screenWidth),
    );
  }

  // Layout mobile/tablette
  Widget _buildMobileLayout(GlobalProgressionModel progression, double screenWidth) {
    return Column(
      children: [
        // Header qui va jusqu'en haut
        _buildTopHeader(),
        
        // Contenu principal scrollable - adaptatif
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              screenWidth < 360 ? AppSpacing.md : AppSpacing.lg
            ),
            child: Column(
              children: [
                // Carte de progression principale
                _buildMainProgressCard(progression),
                const SizedBox(height: AppSpacing.lg),
                
                // Statistiques rapides
                _buildQuickStats(progression),
                const SizedBox(height: AppSpacing.lg),
                
                // Badges récents
                if (_recentBadges.isNotEmpty) ...[
                  _buildRecentBadges(),
                  const SizedBox(height: AppSpacing.lg),
                ],
                
                // Section actualités éducatives
                _buildEducationNews(),
                const SizedBox(height: AppSpacing.lg),
                
                // Carte de découverte
                _buildTipsCard(),
                const SizedBox(height: AppSpacing.xxxl + AppSpacing.xl), // Espace pour navigation bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Layout web pour grands écrans
  Widget _buildWebLayout(GlobalProgressionModel progression, double screenWidth) {
    return Row(
      children: [
        // Sidebar gauche avec header et actions rapides
        Container(
          width: 300,
          color: AppColors.surface,
          child: Column(
            children: [
              _buildTopHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _buildTipsCard(),
                      const SizedBox(height: AppSpacing.lg),
                      if (_recentBadges.isNotEmpty) _buildRecentBadges(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Contenu principal central
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // En-tête de bienvenue pour web
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Bienvenue sur Ilium',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.white,
                            fontSize: 36,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Votre plateforme d\'apprentissage personnalisée',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxxl),
                  
                  // Grid de contenu principal
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: AppSpacing.lg,
                    mainAxisSpacing: AppSpacing.lg,
                    children: [
                      _buildMainProgressCard(progression),
                      _buildQuickStats(progression),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.xxxl),
                  
                  // Section actualités éducatives en pleine largeur
                  _buildEducationNews(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? AppSpacing.md : AppSpacing.lg,
        MediaQuery.of(context).padding.top + AppSpacing.md,
        isSmallScreen ? AppSpacing.md : AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo et nom de l'app groupés verticalement
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo agrandi - adaptatif selon la taille d'écran
              Image.asset(
                'assets/images/Logo_Ilium-removebg-preview.png',
                width: isSmallScreen ? 40 : isMediumScreen ? 45 : 50,
                height: isSmallScreen ? 40 : isMediumScreen ? 45 : 50,
              ),
              
              SizedBox(height: isSmallScreen ? AppSpacing.xs / 2 : AppSpacing.xs),
              
              // Nom de l'app en dessous
              Text(
                'Ilium',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.grey900,
                  fontWeight: FontWeight.w700,
                  fontSize: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                ),
              ),
            ],
          ),
          
          // Greeting centré au milieu - adaptatif et plus compact
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
              child: Text(
                'Bonjour ${widget.user.pseudo.isNotEmpty ? widget.user.pseudo : 'Utilisateur'}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                  fontSize: isSmallScreen ? 14 : isMediumScreen ? 16 : 18,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Photo de profil avec niveau en dessous
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(),
                child: ProfileAvatar(
                  user: widget.user,
                  radius: isSmallScreen ? 18 : isMediumScreen ? 20 : 22,
                  showBorder: true,
                  borderColor: AppColors.grey200,
                ),
              ),
              
              if (widget.user.niveau.isNotEmpty) ...[
                SizedBox(height: isSmallScreen ? AppSpacing.xs / 2 : AppSpacing.xs),
                Text(
                  widget.user.niveau,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildMainProgressCard(GlobalProgressionModel progression) {
    final progressPercent = progression.xpToNextLevel > 0 
        ? (1000 - progression.xpToNextLevel) / 1000 
        : 1.0;

    return ProgressCard(
      title: 'Niveau ${progression.currentLevel}',
      subtitle: '${progression.totalXp} XP • ${_getTierText(progression.tier)}',
      progress: progressPercent,
      gradient: AppColors.primaryGradient,
      icon: Icons.emoji_events,
    );
  }



  Widget _buildQuickStats(GlobalProgressionModel progression) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1024;
    
    if (isLargeScreen) {
      // Pour les grands écrans, afficher verticalement
      return Column(
        children: [
          _buildStatCard(
            icon: Icons.local_fire_department_outlined,
            value: '${progression.currentStreak}',
            label: 'Jours de série',
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatCard(
            icon: Icons.school_outlined,
            value: '${progression.totalCoursCompleted}',
            label: 'Cours terminés',
            color: AppColors.success,
          ),
        ],
      );
    }
    
    // Pour mobile/tablette, afficher horizontalement
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_outlined,
            value: '${progression.currentStreak}',
            label: 'Jours de série',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            icon: Icons.school_outlined,
            value: '${progression.totalCoursCompleted}',
            label: 'Cours terminés',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      elevation: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône avec fond coloré
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon, 
              color: color, 
              size: 24,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Valeur en grand
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.grey900,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xs),
          
          // Label en petit
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBadges() {
    return ModernCard(
      padding: EdgeInsets.zero,
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.emoji_events, 
                    color: AppColors.warning, 
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Badges récents', 
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(
            height: 1,
            color: AppColors.grey200,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),
          
          // Liste horizontale des badges
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _recentBadges.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final badge = _recentBadges[index];
                  final badgeColor = _getBadgeColor(badge.rarity);
                  
                  return SizedBox(
                    width: 90,
                    child: Column(
                      children: [
                        // Badge circulaire moderne
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                badgeColor,
                                badgeColor.withValues(alpha: 0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withValues(alpha: 0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              badge.icon,
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Nom du badge
                        Text(
                          badge.name,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTipsCard() {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Découvrez Ilium',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                    ),
                    onPressed: _showAppTutorial,
                    tooltip: 'Guide de l\'application',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '💡 Explorez les programmes officiels dans "Programme"',
                style: AppTextStyles.body.copyWith(color: AppColors.grey700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '📚 Trouvez tous vos contenus dans "Catalogue"',
                style: AppTextStyles.body.copyWith(color: AppColors.grey700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '🏆 Suivez votre progression dans "Profil"',
                style: AppTextStyles.body.copyWith(color: AppColors.grey700),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAppTutorial,
                  icon: const Icon(Icons.school, size: 18),
                  label: const Text('Guide complet de l\'app'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppTutorial() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppTutorialScreen(
          user: widget.user,
          onNavigateToTab: widget.onNavigateToTab,
        ),
      ),
    );
  }

  void _navigateToProfile() {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(4); // Index de l'onglet Profil
    }
  }

  String _getTierText(UserTier tier) {
    switch (tier) {
      case UserTier.bronze:
        return 'Bronze';
      case UserTier.silver:
        return 'Argent';
      case UserTier.gold:
        return 'Or';
      case UserTier.platinum:
        return 'Platine';
      case UserTier.diamond:
        return 'Diamant';
    }
  }

  Color _getBadgeColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return AppColors.grey400;
      case BadgeRarity.uncommon:
        return AppColors.accent;
      case BadgeRarity.rare:
        return AppColors.primary;
      case BadgeRarity.epic:
        return AppColors.secondary;
      case BadgeRarity.legendary:
        return AppColors.warning;
    }
  }

  Widget _buildEducationNews() {
    return ModernCard(
      padding: EdgeInsets.zero,
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.newspaper, 
                    color: AppColors.accent, 
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Actualités', 
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.grey900,
                  ),
                ),
                const Spacer(),
                if (_newsArticles.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swipe,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_newsArticles.length} articles',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Divider
          Divider(
            height: 1,
            color: AppColors.grey200,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),
          
          // Contenu des actualités - Carousel avec espacement
          SizedBox(
            height: 220, // Hauteur augmentée pour plus d'espace
            child: _isLoadingNews
                ? const Center(child: CircularProgressIndicator())
                : _newsArticles.isEmpty
                    ? _buildEmptyNewsState()
                    : _buildNewsCarousel(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNewsState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper,
            size: 48,
            color: AppColors.grey400,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Actualités indisponibles',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Les actualités éducatives ne sont pas disponibles pour le moment.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCarousel() {
    return Column(
      children: [
        // Carousel principal avec indicateurs
        Expanded(
          child: PageView.builder(
            itemCount: _newsArticles.length,
            controller: _newsPageController,
            physics: const BouncingScrollPhysics(), // Animation plus fluide
            itemBuilder: (context, index) {
              final article = _newsArticles[index];
              return AnimatedBuilder(
                animation: _newsPageController,
                builder: (context, child) {
                  // Animation de scale pour les cartes selon leur position
                  double value = 1;
                  if (_newsPageController.position.haveDimensions) {
                    value = _newsPageController.page! - index;
                    value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
                  }
                  
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildNewsCarouselCard(article),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Indicateurs de pagination avec espacement
        if (_newsArticles.length > 1) ...[
          const SizedBox(height: 12),
          _buildCarouselIndicators(),
          const SizedBox(height: 8), // Espace sous les indicateurs
        ],
      ],
    );
  }

  /// Construit les indicateurs de pagination pour le carousel
  Widget _buildCarouselIndicators() {
    return AnimatedBuilder(
      animation: _newsPageController,
      builder: (context, child) {
        int currentIndex = 0;
        if (_newsPageController.hasClients && _newsPageController.position.haveDimensions) {
          currentIndex = _newsPageController.page?.round() ?? 0;
        }
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_newsArticles.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: currentIndex == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: currentIndex == index 
                    ? AppColors.accent
                    : AppColors.grey300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildNewsCarouselCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => _openNewsArticle(article.url),
      child: Container(
        height: 170, // Hauteur fixe pour éviter les débordements
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey900.withValues(alpha: 0.08),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'article ou placeholder
            SizedBox(
              height: 80, // Hauteur réduite pour l'image
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                ),
                child: article.imageUrl != null && article.imageUrl!.isNotEmpty
                    ? Image.network(
                        article.imageUrl!,
                        width: double.infinity,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.grey100,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            
            // Contenu textuel - hauteur fixe restante
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre compact
                    Text(
                      article.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                        height: 1.1,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Description très courte
                    if (article.description.isNotEmpty)
                      Expanded(
                        child: Text(
                          article.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey600,
                            height: 1.2,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    const SizedBox(height: 6),
                    
                    // Métadonnées en bas
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _formatNewsDate(article.publishedAt),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            article.source,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey500,
                              fontSize: 8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 6,
                          color: AppColors.grey400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              size: 28,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Actualités',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNewsDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}min';
    }
  }

  Future<void> _openNewsArticle(String url) async {
    print('🔗 Tentative d\'ouverture de l\'URL: $url');
    
    try {
      final Uri uri = Uri.parse(url);
      print('✅ URI parsé: ${uri.toString()}');
      print('🔍 Scheme: ${uri.scheme}, Host: ${uri.host}');
      
      final canLaunch = await canLaunchUrl(uri);
      print('🚀 canLaunchUrl result: $canLaunch');
      
      if (canLaunch) {
        print('📱 Lancement en cours...');
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          print('✅ URL lancée avec succès (externalApplication)');
        } catch (e) {
          print('❌ Échec externalApplication, tentative avec inAppBrowserView...');
          try {
            await launchUrl(
              uri,
              mode: LaunchMode.inAppBrowserView,
            );
            print('✅ URL lancée avec succès (inAppBrowserView)');
          } catch (e2) {
            print('❌ Échec inAppBrowserView, tentative avec platformDefault...');
            await launchUrl(uri, mode: LaunchMode.platformDefault);
            print('✅ URL lancée avec succès (platformDefault)');
          }
        }
      } else {
        print('❌ Impossible de lancer l\'URL');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir l\'article\nURL: $url'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture de l\'URL: $e');
      print('🔗 URL problématique: $url');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e\nURL: $url'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}