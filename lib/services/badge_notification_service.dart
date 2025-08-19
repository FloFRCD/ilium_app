import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../theme/app_theme.dart';

/// Service pour les notifications de badges débloqués
class BadgeNotificationService {
  
  /// Affiche une notification animée pour un nouveau badge
  static void showBadgeUnlockedNotification(
    BuildContext context,
    BadgeModel badge,
  ) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _BadgeNotificationContent(badge: badge),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Voir',
          textColor: AppColors.white,
          onPressed: () {
            _showBadgeDialog(context, badge);
          },
        ),
      ),
    );
  }

  /// Affiche plusieurs badges débloqués en cascade
  static void showMultipleBadgesUnlocked(
    BuildContext context,
    List<BadgeModel> badges,
  ) {
    if (badges.isEmpty || !context.mounted) return;

    for (int i = 0; i < badges.length; i++) {
      Future.delayed(Duration(milliseconds: 500 * i), () {
        if (context.mounted) {
          showBadgeUnlockedNotification(context, badges[i]);
        }
      });
    }
  }

  /// Affiche un dialog détaillé du badge
  static void _showBadgeDialog(BuildContext context, BadgeModel badge) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône du badge avec animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: badge.rarityColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: badge.rarityColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIconData(badge.icon),
                      color: AppColors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Nom du badge
            Text(
              badge.name,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.greyDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Rareté
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badge.rarityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: badge.rarityColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                badge.rarityDisplayName,
                style: AppTextStyles.caption.copyWith(
                  color: badge.rarityColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              badge.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.greyMedium,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Récompense XP  
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accent2.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: AppColors.accent2,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${badge.xpReward} XP',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.accent2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Génial !',
              style: AppTextStyles.button.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Convertit l'icône string en IconData
  static IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'explore':
        return Icons.explore;
      case 'menu_book':
        return Icons.menu_book;
      case 'quiz':
        return Icons.quiz;
      case 'star':
        return Icons.star;
      case 'trending_up':
        return Icons.trending_up;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'military_tech':
        return Icons.military_tech;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'share':
        return Icons.share;
      case 'flag':
        return Icons.flag;
      default:
        return Icons.star;
    }
  }
}

/// Widget pour le contenu de la notification
class _BadgeNotificationContent extends StatelessWidget {
  final BadgeModel badge;

  const _BadgeNotificationContent({
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icône du badge
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: badge.rarityColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            BadgeNotificationService._getIconData(badge.icon),
            color: AppColors.white,
            size: 20,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Texte
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏆 Nouveau badge débloqué !',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                badge.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // XP
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+${badge.xpReward}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}