import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth_email_password_screen.dart';
import 'password_reset_screen.dart';
import '../main.dart';

class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.isSuccess && result.user != null) {
        // Connexion réussie - naviguer vers l'écran principal
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(user: result.user!),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = _getLocalizedErrorMessage(result.error ?? 'Erreur inconnue');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getLocalizedErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    
    // Naviguer vers l'écran de réinitialisation avec l'email pré-rempli
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PasswordResetScreen(
          initialEmail: email.isNotEmpty ? email : null,
        ),
      ),
    );
  }

  String _getLocalizedErrorMessage(String error) {
    // Messages d'erreur personnalisés pour Ilium
    if (error.contains('user-not-found')) {
      return 'Aucun compte trouvé avec cette adresse email.';
    }
    if (error.contains('wrong-password')) {
      return 'Mot de passe incorrect. Veuillez réessayer.';
    }
    if (error.contains('invalid-email')) {
      return 'Veuillez saisir une adresse email valide.';
    }
    if (error.contains('user-disabled')) {
      return 'Ce compte a été désactivé. Contactez le support.';
    }
    if (error.contains('too-many-requests')) {
      return 'Trop de tentatives. Veuillez patienter quelques minutes.';
    }
    if (error.contains('network-request-failed')) {
      return 'Vérifiez votre connexion internet et réessayez.';
    }
    if (error.contains('invalid-credential')) {
      return 'Email ou mot de passe incorrect.';
    }
    
    // Message par défaut personnalisé
    return 'Une erreur s\'est produite lors de la connexion. Veuillez réessayer.';
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
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.secondary,
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
                  // Logo et titre
                  _buildHeader(),
                  
                  SizedBox(height: 40),
                  
                  // Formulaire de connexion
                  _buildLoginForm(),
                  
                  SizedBox(height: 24),
                  
                  // Bouton de connexion
                  _buildSignInButton(),
                  
                  SizedBox(height: 16),
                  
                  // Lien mot de passe oublié
                  _buildForgotPasswordButton(),
                  
                  SizedBox(height: 32),
                  
                  // Divider
                  _buildDivider(),
                  
                  SizedBox(height: 24),
                  
                  // Lien vers inscription
                  _buildSignUpLink(),
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
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school,
            size: 60,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Ilium',
          style: AppTextStyles.display.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Votre assistant scolaire intelligent',
          style: AppTextStyles.body.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connexion',
              textAlign: TextAlign.center,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.black,
              ),
            ),
            
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
            SizedBox(height: 24),
            
            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Veuillez entrer votre email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Mot de passe
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Veuillez entrer votre mot de passe';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent1,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Se connecter',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: _isLoading ? null : _resetPassword,
      child: Text(
        'Mot de passe oublié ?',
        style: AppTextStyles.body.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ? ',
          style: AppTextStyles.body.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AuthEmailPasswordScreen(),
              ),
            );
          },
          child: Text(
            'S\'inscrire',
            style: AppTextStyles.body.copyWith(
              color: AppColors.accent2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}