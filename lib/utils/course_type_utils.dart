import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';

/// Utilitaire centralisé pour la gestion des types de cours
/// Fournit des icônes, couleurs et labels cohérents dans toute l'application
class CourseTypeUtils {
  
  /// Retourne l'icône appropriée pour un type de cours
  static IconData getIcon(CourseType type) {
    switch (type) {
      case CourseType.fiche:
        return Icons.description;
      case CourseType.vulgarise:
        return Icons.psychology;
      case CourseType.cours:
        return Icons.school;
    }
  }

  /// Retourne l'icône outline appropriée pour un type de cours
  static IconData getOutlineIcon(CourseType type) {
    switch (type) {
      case CourseType.fiche:
        return Icons.description_outlined;
      case CourseType.vulgarise:
        return Icons.psychology_outlined;
      case CourseType.cours:
        return Icons.school_outlined;
    }
  }

  /// Retourne le label textuel pour un type de cours
  static String getLabel(CourseType type) {
    switch (type) {
      case CourseType.fiche:
        return 'Fiche';
      case CourseType.vulgarise:
        return 'Vulgarisé';
      case CourseType.cours:
        return 'Cours';
    }
  }

  /// Retourne la couleur appropriée pour un type de cours
  static Color getColor(CourseType type) {
    switch (type) {
      case CourseType.fiche:
        return AppColors.primary;
      case CourseType.vulgarise:
        return AppColors.secondary;
      case CourseType.cours:
        return AppColors.accent1;
    }
  }

  /// Construit un badge coloré pour un type de cours
  static Widget buildBadge(CourseType type, {double fontSize = 10, bool compact = false}) {
    final color = getColor(type);
    final label = getLabel(type);
    final icon = getIcon(type);
    
    if (compact) {
      // Version compacte - icône seulement dans un cercle
      return Container(
        width: 28,
        height: 20,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Icon(
          icon, 
          size: 12, 
          color: color,
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 12, 
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une icône dans un container avec gradient
  static Widget buildIconContainer(CourseType type, {double size = 48, double iconSize = 24}) {
    final color = getColor(type);
    final icon = getIcon(type);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }

  /// Retourne une description du type de cours
  static String getDescription(CourseType type) {
    switch (type) {
      case CourseType.fiche:
        return 'Synthèse concise des points essentiels';
      case CourseType.vulgarise:
        return 'Explication simplifiée et accessible';
      case CourseType.cours:
        return 'Contenu complet et détaillé';
    }
  }

  /// Construit un widget informatif compact pour expliquer le type
  static Widget buildTypeHint(CourseType type, {bool showDescription = true}) {
    final color = getColor(type);
    final label = getLabel(type);
    final description = getDescription(type);
    final icon = getIcon(type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (showDescription) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Construit un widget informatif avec icône, label et description
  static Widget buildInfoCard(CourseType type) {
    final color = getColor(type);
    final label = getLabel(type);
    final description = getDescription(type);
    final icon = getIcon(type);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}