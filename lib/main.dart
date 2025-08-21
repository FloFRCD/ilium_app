// Flutter framework
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Packages
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Local files
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/enhanced_courses_screen.dart';
import 'screens/home_modern_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/programme_screen_working.dart';
import 'screens/saved_courses_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/custom_bottom_navigation.dart';
import 'widgets/premium_promotion_banner.dart';
import 'utils/logger.dart';

/// Point d'entrée principal de l'application Ilium.
/// Initialise Firebase et lance l'application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Logger.info('🚀 Démarrage de l\'application Ilium');
  
  try {
    // Charger les variables d'environnement depuis .env
    Logger.info('📁 Chargement des variables d\'environnement...');
    await dotenv.load(fileName: ".env");
    Logger.info('✅ Variables d\'environnement chargées');
    
    Logger.info('🔥 Initialisation de Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.info('✅ Firebase initialisé avec succès');
    
  } catch (e) {
    Logger.error('❌ Erreur d\'initialisation Firebase: $e');
    // Continue sans Firebase - l'app fonctionnera en mode hors ligne
  }
  
  Logger.info('🎯 Lancement de l\'interface utilisateur');
  runApp(const IliumApp());
}

/// Widget racine de l'application Ilium.
/// Configure le thème et la navigation principale.
class IliumApp extends StatelessWidget {
  const IliumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ilium',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}


/// Écran principal avec navigation par onglets.
/// Gère la navigation entre les différentes sections de l'app.
class MainNavigationScreen extends StatefulWidget {
  final UserModel user;

  const MainNavigationScreen({super.key, required this.user});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late UserModel _currentUser;
  
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _buildScreens();
  }

  void _buildScreens() {
    _screens = [
      HomeModernScreen(
        user: _currentUser,
        onNavigateToCourses: () => setState(() => _currentIndex = 1),
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      EnhancedCoursesScreen(user: _currentUser),
      ProgrammeScreenWorking(user: _currentUser),
      SavedCoursesScreen(user: _currentUser),
      ProfileScreen(
        user: _currentUser,
        onUserUpdated: _updateUser, // Callback pour synchroniser les changements
      ),
    ];
  }

  /// Met à jour l'utilisateur et reconstruit tous les écrans
  void _updateUser(UserModel updatedUser) {
    setState(() {
      _currentUser = updatedUser;
      _buildScreens(); // Reconstruire tous les écrans avec les nouvelles données
    });
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

  // Layout mobile avec TabBar (design original préservé)
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bandeau premium pour les utilisateurs freemium
          if (_currentUser.subscriptionType == SubscriptionType.free)
            PremiumPromotionBanner(user: _currentUser),
          
          // Navigation du bas
          CustomBottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
    );
  }

  // Layout web professionnel avec sidebar
  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation moderne
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
                          icon: Icons.assignment_outlined,
                          activeIcon: Icons.assignment,
                          label: 'Programme officiel',
                          index: 2,
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          icon: Icons.bookmark_outline,
                          activeIcon: Icons.bookmark,
                          label: 'Mes sauvegardes',
                          index: 3,
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
                          index: 4,
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
                                  _currentUser.pseudo.isNotEmpty 
                                      ? _currentUser.pseudo[0].toUpperCase() 
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
                                      _currentUser.pseudo.isNotEmpty 
                                          ? _currentUser.pseudo 
                                          : 'Utilisateur',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.grey900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _currentUser.niveau.isNotEmpty 
                                          ? _currentUser.niveau 
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