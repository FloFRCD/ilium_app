import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_login_screen.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_progression_service.dart';
import '../main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('=== AUTH WRAPPER: USING FIREBASE AUTH ONLY ===');
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint('Auth state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}');
        
        // En cours de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Utilisateur connecté - utiliser AuthService pour récupérer le profil
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getCurrentUserProfile(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (userSnapshot.hasData && userSnapshot.data != null) {
                // Mettre à jour la streak à chaque ouverture d'app
                final progressionService = UserProgressionService();
                progressionService.updateStreak(userSnapshot.data!.uid);
                
                return MainNavigationScreen(user: userSnapshot.data!);
              }
              
              // Profil utilisateur non trouvé - déconnecter
              FirebaseAuth.instance.signOut();
              return const AuthLoginScreen();
            },
          );
        }
        
        // Utilisateur non connecté
        return const AuthLoginScreen();
      },
    );
  }
}