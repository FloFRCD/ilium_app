import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'programme_screen_working.dart';
import 'enhanced_courses_screen.dart';

/// Page d'introduction au système QCM
/// Explique comment créer des QCM et les retrouver
class QCMIntroductionScreen extends StatelessWidget {
  final UserModel user;

  const QCMIntroductionScreen({
    super.key,
    required this.user,
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
                      'Système QCM',
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
                'Créez et retrouvez vos QCM facilement',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Étape 1 : Créer un QCM
          _buildStepCard(
            context,
            stepNumber: '1',
            title: 'Créer un QCM',
            description: 'Rendez-vous dans la page "Programme" pour générer des QCM personnalisés',
            icon: Icons.add_circle_outline,
            color: AppColors.primary,
            actionText: 'Aller au Programme',
            onTap: () => _navigateToProgram(context),
            details: [
              '• Choisissez votre niveau (ex: Terminale)',
              '• Sélectionnez une matière (ex: Mathématiques)',
              '• Le système génère automatiquement des QCM adaptés',
              '• Vos QCM sont sauvegardés automatiquement',
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Étape 2 : Retrouver ses QCM
          _buildStepCard(
            context,
            stepNumber: '2',
            title: 'Retrouver vos QCM',
            description: 'Consultez tous vos QCM dans la page "Catalogue" avec le filtre QCM',
            icon: Icons.quiz_outlined,
            color: AppColors.accent1,
            actionText: 'Voir le Catalogue',
            onTap: () => _navigateToCatalog(context),
            details: [
              '• Ouvrez la page "Catalogue"',
              '• Cliquez sur l\'icône de filtres',
              '• Sélectionnez "QCM" pour voir tous vos quiz',
              '• Vous verrez la moyenne des scores pour chaque QCM',
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Étape 3 : Conseils
          _buildTipsCard(),
          
          const SizedBox(height: 30),
          
          // Boutons d'action
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String actionText,
    required VoidCallback onTap,
    required List<String> details,
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
            // Header avec numéro et icône
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      stepNumber,
                      style: AppTextStyles.h3.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Détails
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                detail,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.greyDark,
                ),
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

  Widget _buildTipsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
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
                  Icons.lightbulb_outline,
                  color: AppColors.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Conseils utiles',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              '💡 Plus vous précisez votre niveau et matière, plus les QCM seront adaptés\n'
              '📊 Les scores moyens vous aident à identifier les QCM les plus réussis\n'
              '🔄 Vous pouvez refaire un QCM autant de fois que vous voulez\n'
              '⭐ Utilisez les filtres pour organiser vos QCM par matière et niveau',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton principal
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _navigateToProgram(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rocket_launch, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Commencer - Créer mon premier QCM',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Bouton secondaire
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _navigateToCatalog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.view_list, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Voir mes QCM existants',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToProgram(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ProgrammeScreenWorking(user: user),
      ),
    );
  }

  void _navigateToCatalog(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EnhancedCoursesScreen(user: user),
      ),
    );
  }
}