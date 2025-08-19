import 'package:flutter/material.dart';

/// Design System Ilium - Couleurs basées sur le logo
/// Palette moderne et cohérente inspirée du logo Ilium
class AppColors {
  // Couleurs principales - inspirées du logo
  static const Color primary = Color(0xFF4F7BF5);      // Bleu principal du logo
  static const Color primaryLight = Color(0xFF6B93FF);  // Bleu clair
  static const Color primaryDark = Color(0xFF3B5998);   // Bleu foncé
  
  static const Color secondary = Color(0xFF8B5CF6);     // Violet du dégradé
  static const Color secondaryLight = Color(0xFFA78BFA); // Violet clair
  static const Color secondaryDark = Color(0xFF7C3AED);  // Violet foncé
  
  // Couleurs d'accent - harmonieuses avec le logo
  static const Color accent = Color(0xFF06B6D4);        // Cyan moderne
  static const Color accentWarm = Color(0xFFF59E0B);    // Ambre énergisant
  
  // Couleurs fonctionnelles
  static const Color success = Color(0xFF10B981);       // Vert moderne
  static const Color warning = Color(0xFFF59E0B);       // Ambre
  static const Color error = Color(0xFFEF4444);         // Rouge moderne
  static const Color info = Color(0xFF3B82F6);          // Bleu info
  
  // Couleurs neutres - système 8pt
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);        // Background très clair
  static const Color grey100 = Color(0xFFF4F4F5);       // Background clair
  static const Color grey200 = Color(0xFFE4E4E7);       // Bordures claires
  static const Color grey300 = Color(0xFFD4D4D8);       // Bordures
  static const Color grey400 = Color(0xFFA1A1AA);       // Texte disabled
  static const Color grey500 = Color(0xFF71717A);       // Texte secondaire
  static const Color grey600 = Color(0xFF52525B);       // Texte normal
  static const Color grey700 = Color(0xFF3F3F46);       // Texte principal
  static const Color grey800 = Color(0xFF27272A);       // Texte très sombre
  static const Color grey900 = Color(0xFF18181B);       // Texte maximum
  static const Color black = Color(0xFF000000);
  
  // Couleurs d'arrière-plan
  static const Color background = grey50;
  static const Color surface = white;
  static const Color surfaceVariant = grey100;
  
  // Gradients - basés sur le logo
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient primaryGradientReverse = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: [primary, secondary],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF059669)],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, Color(0xFFD97706)],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF0891B2)],
  );
  
  // Gradients subtils pour les cartes
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
  );
  
  // Legacy aliases pour compatibilité
  static const Color greyLight = grey100;
  static const Color greyMedium = grey500;
  static const Color greyDark = grey700;
  static const Color accent1 = accent;
  static const Color accent2 = accentWarm;
  static const LinearGradient energyGradient = warningGradient;
}

/// Système d'espacement cohérent - 8pt grid
class AppSpacing {
  static const double xs = 4.0;   // 4pt
  static const double sm = 8.0;   // 8pt
  static const double md = 16.0;  // 16pt
  static const double lg = 24.0;  // 24pt
  static const double xl = 32.0;  // 32pt
  static const double xxl = 48.0; // 48pt
  static const double xxxl = 64.0; // 64pt
}

/// Système de border radius cohérent
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double circle = 999.0;
}

/// Système typographique moderne et cohérent
/// Basé sur une échelle harmonique avec hauteurs de ligne optimisées
class AppTextStyles {
  // Font family par défaut
  static const String _fontFamily = 'Inter';
  
  // Display - Pour les titres principaux (36px)
  static const TextStyle display = TextStyle(
    fontSize: 36,
    height: 1.2,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
    color: AppColors.grey900,
    letterSpacing: -0.5,
  );
  
  // H1 - Titres de section (28px)  
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    height: 1.3,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: AppColors.grey900,
    letterSpacing: -0.3,
  );
  
  // H2 - Sous-titres importants (24px)
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    height: 1.3,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: AppColors.grey800,
    letterSpacing: -0.2,
  );
  
  // H3 - Titres de cards/sections (20px)
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: AppColors.grey800,
  );
  
  // H4 - Petits titres (18px)
  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: AppColors.grey700,
  );
  
  // Body Large - Texte important (16px)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: AppColors.grey700,
  );
  
  // Body - Texte standard (14px)
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: AppColors.grey600,
  );
  
  // Body Small - Texte secondaire (13px)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: AppColors.grey500,
  );
  
  // Caption - Légendes et métadonnées (12px)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: AppColors.grey500,
  );
  
  // Overline - Petites étiquettes (11px)
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    color: AppColors.grey400,
    letterSpacing: 0.5,
  );
  
  // Button - Texte de boutons (15px)
  static const TextStyle button = TextStyle(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    letterSpacing: 0.1,
  );
  
  // Button Small - Petits boutons (13px)
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    letterSpacing: 0.1,
  );
  
  // Label - Étiquettes de champs (14px)
  static const TextStyle label = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    color: AppColors.grey700,
  );
}

/// Configuration du thème principal de l'application.
/// Design system moderne basé sur le logo Ilium
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        tertiary: AppColors.accent,
        onTertiary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.grey900,
        error: AppColors.error,
        onError: AppColors.white,
        outline: AppColors.grey300,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.grey600,
      ),
      fontFamily: AppTextStyles._fontFamily,
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display,
        displayMedium: AppTextStyles.h1,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        titleLarge: AppTextStyles.h4,
        titleMedium: AppTextStyles.bodyLarge,
        titleSmall: AppTextStyles.body,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.buttonSmall,
        labelSmall: AppTextStyles.caption,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, 
            vertical: AppSpacing.md
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.white),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, 
            vertical: AppSpacing.md
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, 
            vertical: AppSpacing.sm
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
          minimumSize: const Size(0, 40),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        color: AppColors.surface,
        shadowColor: AppColors.grey900.withValues(alpha: 0.05),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.grey200,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.h4.copyWith(
          color: AppColors.grey900,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.grey700,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.grey700,
          size: 24,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.grey400,
        ),
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.grey400,
          size: 24,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.grey400),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        secondarySelectedColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, 
          vertical: AppSpacing.xs
        ),
        labelStyle: AppTextStyles.bodySmall,
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.circle),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.body,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.grey300;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.grey300;
        }),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.grey300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.3);
          }
          return AppColors.grey200;
        }),
      ),
      
      scaffoldBackgroundColor: AppColors.background,
      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

// Composants UI personnalisés modernes
/// Bouton avec gradient moderne, ombres subtiles et animations
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final double? width;
  final double height;
  final IconData? icon;
  final bool isLoading;
  final EdgeInsets? padding;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient = AppColors.primaryGradient,
    this.width,
    this.height = 48,
    this.icon,
    this.isLoading = false,
    this.padding,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: isEnabled 
                  ? widget.gradient 
                  : LinearGradient(
                      colors: [AppColors.grey300, AppColors.grey400],
                    ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: isEnabled ? [
                BoxShadow(
                  color: widget.gradient.colors.first.withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: widget.gradient.colors.first.withValues(alpha: 0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ] : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: isEnabled ? widget.onPressed : null,
                onTapDown: isEnabled ? (_) => _controller.forward() : null,
                onTapUp: isEnabled ? (_) => _controller.reverse() : null,
                onTapCancel: isEnabled ? () => _controller.reverse() : null,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading) ...[
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ] else if (widget.icon != null) ...[
                        Icon(
                          widget.icon, 
                          color: AppColors.white, 
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Carte de progression moderne avec animations et design épuré
class ProgressCard extends StatefulWidget {
  final String title;
  final double progress;
  final String subtitle;
  final LinearGradient gradient;
  final IconData? icon;
  final bool showPercentage;
  final VoidCallback? onTap;

  const ProgressCard({
    super.key,
    required this.title,
    required this.progress,
    required this.subtitle,
    this.gradient = AppColors.primaryGradient,
    this.icon,
    this.showPercentage = true,
    this.onTap,
  });

  @override
  State<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<ProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Démarrer l'animation après un petit délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: widget.gradient.colors.first.withValues(alpha: 0.3),
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: widget.gradient.colors.first.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône optionnelle
            Row(
              children: [
                if (widget.icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.subtitle,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showPercentage)
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Barre de progression animée
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.white.withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte moderne avec élévation subtile et bordures propres
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
        boxShadow: elevation != null && elevation! > 0 ? [
          BoxShadow(
            color: AppColors.grey900.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.grey900.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}