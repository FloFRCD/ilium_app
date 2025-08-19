import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // TabBar principale
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.greyMedium.withValues(alpha: 0.15),
                offset: const Offset(0, -4),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Cours
                _buildNavItem(
                  index: 1,
                  icon: Icons.book_outlined,
                  activeIcon: Icons.book,
                  label: 'Cours',
                ),
                
                // Programme
                _buildNavItem(
                  index: 2,
                  icon: Icons.school_outlined,
                  activeIcon: Icons.school,
                  label: 'Programme',
                ),
                
                // Espace pour le bouton central
                const Expanded(child: SizedBox()),
                
                // Sauvegardes
                _buildNavItem(
                  index: 3,
                  icon: Icons.bookmark_outline,
                  activeIcon: Icons.bookmark,
                  label: 'Sauvegardes',
                ),
                
                // Profil
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
        
        // Bouton central intégré
        Positioned(
          top: -5, // Dépasse davantage de la TabBar
          left: MediaQuery.of(context).size.width / 2 - 28, // Centré (56/2 = 28)
          child: _buildCenterHomeButton(),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.grey400,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterHomeButton() {
    final isActive = currentIndex == 0;
    
    return GestureDetector(
      onTap: () => onTap(0),
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: isActive ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isActive ? 0.4 : 0.3),
                offset: const Offset(0, 6),
                blurRadius: isActive ? 16 : 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            isActive ? Icons.home : Icons.home_outlined,
            color: AppColors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}