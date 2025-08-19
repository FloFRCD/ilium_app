import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/freemium_limitations_model.dart';
import '../models/progression_model.dart';
import '../theme/app_theme.dart';
import 'home_modern_screen.dart';
import 'enhanced_courses_screen.dart';
import 'saved_courses_screen.dart';
import 'profile_screen.dart';

class LoginModernScreen extends StatefulWidget {
  const LoginModernScreen({super.key});

  @override
  _LoginModernScreenState createState() => _LoginModernScreenState();
}

class _LoginModernScreenState extends State<LoginModernScreen> {
  final _emailController = TextEditingController(text: 'test@test.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulation de connexion avec utilisateur de test
    final mockUser = UserModel(
      uid: 'test_user_123',
      pseudo: 'Alex Étudiant',
      email: _emailController.text,
      niveau: 'Terminale',
      status: UserStatus.active,
      subscriptionType: SubscriptionType.free,
      badges: [],
      progression: GlobalProgressionModel(
        totalXp: 0,
        currentLevel: 1,
        xpToNextLevel: 100,
        tier: UserTier.bronze,
        totalCoursCompleted: 0,
        totalQcmPassed: 0,
        totalStreakDays: 0,
        maxStreakDays: 0,
        currentStreak: 0,
        memberSince: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginDate: DateTime.now(),
        subjectProgressions: {},
        achievements: [],
        overallAverageScore: 0.0,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      preferences: {'darkMode': false, 'notifications': true, 'language': 'fr'},
      limitations: FreemiumLimitationsModel.free(),
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: MainNavigationScreen(user: mockUser),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = kIsWeb && screenWidth > 768;
    
    if (isWeb) {
      return _buildWebLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  // Design mobile/tablette (inchangé)
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo avec cercle de fond
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 80,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Titre
                  Text(
                    'Ilium',
                    style: AppTextStyles.display.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Votre assistant de soutien scolaire',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Badge de nouveauté
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: AppColors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Nouveau design moderne',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Carte de connexion
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.1),
                          offset: const Offset(0, 8),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Email
                        TextField(
                          controller: _emailController,
                          style: AppTextStyles.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'test@test.com',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                            labelStyle: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Mot de passe
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: AppTextStyles.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            hintText: 'password123',
                            prefixIcon: Icon(Icons.lock_outlined, color: AppColors.primary),
                            labelStyle: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Bouton de connexion
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            text: _isLoading ? 'Connexion...' : 'Se connecter',
                            onPressed: _isLoading ? () {} : _login,
                            gradient: AppColors.primaryGradient,
                            icon: _isLoading ? null : Icons.arrow_forward,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Note d'information
                        Text(
                          'Utilisez n\'importe quelles données pour tester',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.greyMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Nouveau design web inspiré d'Airbnb
  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Partie gauche - Image/illustration
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                    Color(0xFFf093fb),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo principal
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 120,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Titre principal
                    Text(
                      'Bienvenue sur Ilium',
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Sous-titre
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Text(
                        'Votre plateforme d\'apprentissage personnalisée avec intelligence artificielle pour exceller dans vos études',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontSize: 20,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Points clés
                    Column(
                      children: [
                        _buildFeaturePoint('🧠', 'IA conversationnelle pour l\'apprentissage'),
                        const SizedBox(height: 16),
                        _buildFeaturePoint('📚', 'Programmes officiels et cours personnalisés'),
                        const SizedBox(height: 16),
                        _buildFeaturePoint('🏆', 'Système de progression et badges'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Partie droite - Formulaire de connexion
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Titre de connexion
                        Text(
                          'Se connecter',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.grey900,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accédez à votre espace personnel',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Badge démo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, 
                                size: 20, 
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Version démo - utilisez n\'importe quelles données',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Champs de formulaire
                        _buildWebTextField(
                          controller: _emailController,
                          label: 'Adresse email',
                          hint: 'test@test.com',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 24),
                        
                        _buildWebTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          hint: 'password123',
                          icon: Icons.lock_outlined,
                          isPassword: true,
                        ),
                        const SizedBox(height: 32),
                        
                        // Bouton de connexion
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _login,
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: AppColors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Se connecter',
                                            style: AppTextStyles.bodyLarge.copyWith(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: AppColors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Lien mot de passe oublié
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implémenter mot de passe oublié
                            },
                            child: Text(
                              'Mot de passe oublié ?',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePoint(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.grey900,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey900),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.grey500),
              prefixIcon: Icon(icon, color: AppColors.grey600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final UserModel user;

  const MainNavigationScreen({super.key, required this.user});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeModernScreen(user: widget.user, onNavigateToTab: (index) => setState(() => _currentIndex = index)),
      EnhancedCoursesScreen(user: widget.user),
      SavedCoursesScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = kIsWeb && screenWidth > 768;
    
    // Debug temporaire pour forcer le layout web
    if (kIsWeb) {
      return _buildWebLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  // Design mobile/tablette avec TabBar (inchangé)
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.greyMedium,
        backgroundColor: AppColors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Sauvegardes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // Nouveau design web avec sidebar navigation
  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                right: BorderSide(
                  color: AppColors.grey200,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey900.withValues(alpha: 0.05),
                  offset: const Offset(2, 0),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header du sidebar avec logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.grey200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Nom de l'app
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ilium',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.grey900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Learning Platform',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Menu de navigation
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildNavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home,
                          label: 'Accueil',
                          index: 0,
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          icon: Icons.book_outlined,
                          activeIcon: Icons.book,
                          label: 'Catalogue de cours',
                          index: 1,
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          icon: Icons.bookmark_outline,
                          activeIcon: Icons.bookmark,
                          label: 'Mes sauvegardes',
                          index: 2,
                        ),
                        
                        // Divider
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 24),
                          height: 1,
                          color: AppColors.grey200,
                        ),
                        
                        _buildNavItem(
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: 'Mon profil',
                          index: 3,
                        ),
                        
                        const Spacer(),
                        
                        // Section utilisateur en bas
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  widget.user.pseudo.isNotEmpty 
                                      ? widget.user.pseudo[0].toUpperCase() 
                                      : 'U',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.user.pseudo.isNotEmpty 
                                          ? widget.user.pseudo 
                                          : 'Utilisateur',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.grey900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      widget.user.niveau.isNotEmpty 
                                          ? widget.user.niveau 
                                          : 'Niveau',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primary : AppColors.grey600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: isActive ? AppColors.primary : AppColors.grey700,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}