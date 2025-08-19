import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

/// Page de tutoriel général de l'application Ilium
/// Présente toutes les fonctionnalités principales avec navigation directe
class AppTutorialScreen extends StatelessWidget {
  final UserModel user;
  final Function(int)? onNavigateToTab;

  const AppTutorialScreen({
    super.key,
    required this.user,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: Column(
        children: [
          // Header avec gradient
          _buildHeader(context),
          
          // Contenu principal
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Titre avec bouton retour
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Guide Ilium',
                      style: AppTextStyles.h2.copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Équilibrer l'espace
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Sous-titre
              Text(
                'Découvrez toutes les fonctionnalités de votre app éducative',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Section Accueil
          _buildSectionCard(
            context,
            icon: Icons.home,
            title: 'Accueil',
            description: 'Votre tableau de bord personnel',
            color: AppColors.primary,
            features: [
              'Suivi de votre progression',
              'Recommandations personnalisées',
              'Cours récents',
              'Statistiques d\'apprentissage',
            ],
            actionText: 'Retour à l\'accueil',
            onTap: () => Navigator.of(context).pop(),
          ),
          
          const SizedBox(height: 20),
          
          // Section Programme
          _buildSectionCard(
            context,
            icon: Icons.school,
            title: 'Programme',
            description: 'Explorez les programmes officiels',
            color: Colors.green,
            features: [
              'Programmes scolaires complets',
              'Recherche par niveau et matière',
              'Génération automatique de contenus',
              'Progression structurée',
            ],
            actionText: 'Explorer les programmes',
            onTap: () => _navigateToProgram(context),
          ),
          
          const SizedBox(height: 20),
          
          // Section Catalogue
          _buildSectionCard(
            context,
            icon: Icons.library_books,
            title: 'Catalogue',
            description: 'Tous vos cours et QCM',
            color: Colors.blue,
            features: [
              'Cours complets, fiches et vulgarisations',
              'QCM avec scores moyens',
              'Filtres avancés par type et matière',
              'Système de favoris',
            ],
            actionText: 'Parcourir le catalogue',
            onTap: () => _navigateToCatalog(context),
          ),
          
          const SizedBox(height: 20),
          
          // Section Profil
          _buildSectionCard(
            context,
            icon: Icons.person,
            title: 'Profil',
            description: 'Votre espace personnel',
            color: Colors.purple,
            features: [
              'Gestion de vos informations',
              'Statistiques détaillées',
              'Préférences d\'apprentissage',
              'Paramètres de l\'application',
            ],
            actionText: 'Voir mon profil',
            onTap: () => _navigateToProfile(context),
          ),
          
          const SizedBox(height: 20),
          
          // Section Conseils généraux
          _buildTipsSection(),
          
          const SizedBox(height: 30),
          
          // Bouton de fermeture
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Commencer à explorer !',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required List<String> features,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône et titre
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Liste des fonctionnalités
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.greyDark,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 16),
            
            // Bouton d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      actionText,
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent1.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent1.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: AppColors.accent1,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Conseils pour bien commencer',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent1,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '🎯 Commencez par définir votre niveau dans Programme\n'
              '📚 Explorez différents types de contenus : Cours, Fiches, QCM\n'
              '⭐ Utilisez les favoris pour organiser vos contenus préférés\n'
              '📊 Suivez votre progression dans votre Profil\n'
              '🔍 Utilisez les filtres pour trouver exactement ce que vous cherchez\n'
              '🔄 Revenez régulièrement pour découvrir de nouveaux contenus',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProgram(BuildContext context) {
    Navigator.of(context).pop(); // Fermer le tutoriel
    if (onNavigateToTab != null) {
      onNavigateToTab!(2); // Index de l'onglet Programme
    }
  }

  void _navigateToCatalog(BuildContext context) {
    Navigator.of(context).pop(); // Fermer le tutoriel
    if (onNavigateToTab != null) {
      onNavigateToTab!(1); // Index de l'onglet Catalogue
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).pop(); // Fermer le tutoriel
    if (onNavigateToTab != null) {
      onNavigateToTab!(4); // Index de l'onglet Profil
    }
  }
}