import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/ai_basic_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class RegistrationProfileScreen extends StatefulWidget {
  final String email;
  final String password;

  const RegistrationProfileScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<RegistrationProfileScreen> createState() => _RegistrationProfileScreenState();
}

class _RegistrationProfileScreenState extends State<RegistrationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoController = TextEditingController();
  final AuthService _authService = AuthService();
  final AIBasicService _aiBasicService = AIBasicService();
  
  String _selectedNiveau = 'Terminale';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _niveaux = [
    'Seconde',
    'Première', 
    'Terminale',
  ];

  @override
  void dispose() {
    _pseudoController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Valider et optimiser le pseudo avec l'IA économique
      String validatedPseudo = await _aiBasicService.validateAndSuggestPseudo(
        _pseudoController.text.trim()
      );
      
      final result = await _authService.registerWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
        pseudo: validatedPseudo,
        niveau: _selectedNiveau,
      );

      if (result.isSuccess && result.user != null) {
        // Générer un message de bienvenue personnalisé avec l'IA économique
        String welcomeMessage = await _aiBasicService.generateWelcomeMessage(
          pseudo: validatedPseudo,
          niveau: _selectedNiveau,
        );
        
        // Afficher le message de bienvenue
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(welcomeMessage),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
          
          // Inscription réussie - naviguer vers l'écran principal
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(user: result.user!),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = _getLocalizedErrorMessage(result.error ?? 'Erreur inconnue');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getLocalizedErrorMessage(e.toString());
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getLocalizedErrorMessage(String error) {
    // Messages d'erreur personnalisés pour Ilium
    if (error.contains('email-already-in-use')) {
      return 'Cette adresse email est déjà utilisée. Voulez-vous vous connecter ?';
    }
    if (error.contains('weak-password')) {
      return 'Votre mot de passe doit contenir au moins 6 caractères.';
    }
    if (error.contains('invalid-email')) {
      return 'Veuillez saisir une adresse email valide.';
    }
    if (error.contains('network-request-failed')) {
      return 'Vérifiez votre connexion internet et réessayez.';
    }
    if (error.contains('too-many-requests')) {
      return 'Trop de tentatives. Veuillez patienter quelques minutes.';
    }
    
    // Message par défaut personnalisé
    return 'Une erreur s\'est produite lors de l\'inscription. Veuillez réessayer.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.secondary,
              AppColors.secondary.withValues(alpha: 0.8),
              AppColors.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Message d'erreur
                  if (_errorMessage != null) ...[
                    _buildErrorMessage(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Formulaire de profil
                  _buildProfileForm(),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton d'inscription
                  _buildRegisterButton(),
                  
                  const SizedBox(height: 24),
                  
                  // Lien vers connexion
                  _buildSignInLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Finaliser l\'inscription',
          style: AppTextStyles.h1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Encore quelques informations pour personnaliser votre expérience',
          style: AppTextStyles.body.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Pseudo
            TextFormField(
              controller: _pseudoController,
              decoration: InputDecoration(
                labelText: 'Votre pseudo',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Veuillez choisir un pseudo';
                }
                if (value!.length < 2) {
                  return 'Le pseudo doit contenir au moins 2 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Niveau
            DropdownButtonFormField<String>(
              value: _selectedNiveau,
              decoration: InputDecoration(
                labelText: 'Votre niveau scolaire',
                prefixIcon: const Icon(Icons.school_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _niveaux.map((niveau) {
                return DropdownMenuItem(
                  value: niveau,
                  child: Text(niveau),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedNiveau = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _completeRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent2,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Créer mon compte',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.rocket_launch, color: Colors.white),
                ],
              ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: AppTextStyles.body.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Text(
            'Se connecter',
            style: AppTextStyles.body.copyWith(
              color: AppColors.accent1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}