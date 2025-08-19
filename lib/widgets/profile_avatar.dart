import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/profile_image_service.dart';
import '../theme/app_theme.dart';

/// Widget réutilisable pour afficher la photo de profil d'un utilisateur
class ProfileAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool showBorder;
  final Color? borderColor;

  const ProfileAvatar({
    super.key,
    required this.user,
    this.radius = 40,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showBorder ? BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? AppColors.white,
          width: 2,
        ),
      ) : null,
      child: _buildProfileAvatar(),
    );
  }

  Widget _buildProfileAvatar() {
    // Pour les images réseau, utiliser backgroundImage de CircleAvatar qui centre automatiquement
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.greyLight,
        backgroundImage: NetworkImage(user.profileImageUrl!),
        child: null, // Pas de child pour laisser backgroundImage faire son travail
        onBackgroundImageError: (exception, stackTrace) {
          // L'erreur sera gérée silencieusement
          // Le backgroundColor sera affiché à la place
        },
      );
    }

    // Pour les avatars prédéfinis et fallback, utiliser un child
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.greyLight,
      child: _buildAvatarChild(),
    );
  }

  Widget _buildAvatarChild() {
    // Avatar prédéfini (emoji)
    if (user.avatarId != null && user.avatarId!.isNotEmpty) {
      final avatar = ProfileImageService.getPredefinedAvatars()
          .firstWhere(
            (a) => a.id == user.avatarId,
            orElse: () => ProfileImageService.getPredefinedAvatars().first,
          );
      
      // Affichage simple de l'emoji sans container perturbateur
      return Text(
        avatar.emoji,
        style: TextStyle(
          fontSize: radius * 1.2, // Taille légèrement plus grande
        ),
        textAlign: TextAlign.center,
      );
    }

    // Fallback : première lettre avec fond
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          user.pseudo.isNotEmpty ? user.pseudo[0].toUpperCase() : 'U',
          style: TextStyle(
            color: AppColors.white,
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

}

/// Version compacte pour les listes
class CompactProfileAvatar extends StatelessWidget {
  final UserModel user;
  final double size;

  const CompactProfileAvatar({
    super.key,
    required this.user,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      user: user,
      radius: size / 2,
    );
  }
}