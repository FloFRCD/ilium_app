import 'package:flutter/material.dart';
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
      HomeModernScreen(user: widget.user),
      EnhancedCoursesScreen(user: widget.user),
      SavedCoursesScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
  }


  @override
  Widget build(BuildContext context) {
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
}