// Flutter framework
import 'package:flutter/material.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';

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

/// Point d'entrée principal de l'application Ilium.
/// Initialise Firebase et lance l'application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('=== FIREBASE INITIALIZED SUCCESSFULLY ===');
  } catch (e) {
    debugPrint('Firebase init error: $e');
    // Continue sans Firebase - l'app fonctionnera en mode hors ligne
  }
  
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
}