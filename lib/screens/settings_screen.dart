import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_preferences_service.dart';
import '../services/profile_image_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_image_selector.dart';
import '../theme/app_theme.dart';
import '../screens/auth_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel)? onUserUpdated;

  const SettingsScreen({super.key, required this.user, this.onUserUpdated});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final ProfileImageService _imageService = ProfileImageService();
  final AuthService _authService = AuthService();
  
  late TextEditingController _pseudoController;
  late TextEditingController _levelController;
  late bool _notificationsEnabled;
  late bool _darkModeEnabled;
  late bool _studyReminders;
  late bool _weeklyGoalReminders;
  late String _preferredDifficulty;
  late UserModel _currentUser;
  
  bool _isLoading = false;
  bool _hasChanges = false;
  
  
  final List<String> _difficulties = ['facile', 'moyen', 'difficile'];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _pseudoController = TextEditingController(text: _currentUser.pseudo);
    _levelController = TextEditingController(text: _currentUser.niveau);
    _notificationsEnabled = _currentUser.preferences['notificationsEnabled'] ?? true;
    _darkModeEnabled = _currentUser.preferences['darkModeEnabled'] ?? false;
    _studyReminders = _currentUser.preferences['studyReminders'] ?? true;
    _weeklyGoalReminders = _currentUser.preferences['weeklyGoalReminders'] ?? true;
    _preferredDifficulty = _currentUser.preferences['preferredDifficulty'] ?? 'moyen';
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Mettre à jour le pseudo si changé
      if (_pseudoController.text.trim() != _currentUser.pseudo) {
        bool success = await _preferencesService.updateUserPseudo(
          _currentUser.uid, 
          _pseudoController.text.trim()
        );
        if (!success) {
          _showErrorSnackBar('Erreur lors de la mise à jour du pseudo');
          return;
        }
      }
      
      // Mettre à jour le niveau si changé
      if (_levelController.text.trim() != _currentUser.niveau) {
        bool success = await _preferencesService.updateUserLevel(
          _currentUser.uid, 
          _levelController.text.trim()
        );
        if (!success) {
          _showErrorSnackBar('Erreur lors de la mise à jour du niveau');
          return;
        }
      }
      
      // Mettre à jour les préférences de notification
      bool notificationSuccess = await _preferencesService.updateNotificationSettings(
        _currentUser.uid,
        notificationsEnabled: _notificationsEnabled,
        studyReminders: _studyReminders,
        weeklyGoalReminders: _weeklyGoalReminders,
      );
      
      if (!notificationSuccess) {
        _showErrorSnackBar('Erreur lors de la mise à jour des notifications');
        return;
      }
      
      // Mettre à jour les préférences d'affichage
      bool displaySuccess = await _preferencesService.updateDisplaySettings(
        _currentUser.uid,
        darkModeEnabled: _darkModeEnabled,
        preferredDifficulty: _preferredDifficulty,
      );
      
      if (!displaySuccess) {
        _showErrorSnackBar('Erreur lors de la mise à jour de l\'affichage');
        return;
      }
      
      _showSuccessSnackBar('Paramètres sauvegardés avec succès');
      
      // Indiquer que les données ont été mises à jour
      _hasChanges = true;
      
      // Rafraîchir les données utilisateur locales
      await _refreshUserData();
      
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _signOut() async {
    // Afficher une boîte de dialogue de confirmation
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Déconnexion',
              style: AppTextStyles.h3.copyWith(color: AppColors.greyDark),
            ),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.greyMedium),
            child: Text('Annuler', style: AppTextStyles.body),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Se déconnecter', style: AppTextStyles.body),
          ),
        ],
      ),
    );

    // Procéder à la déconnexion seulement si confirmé
    if (confirmed == true) {
      bool success = await _authService.signOut();
      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthLoginScreen()),
          (route) => false,
        );
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _refreshUserData() async {
    try {
      final updatedUser = await _preferencesService.getUpdatedUser(_currentUser.uid);
      if (updatedUser != null && mounted) {
        setState(() {
          _currentUser = updatedUser;
        });
        // Notifier les autres écrans du changement
        widget.onUserUpdated?.call(updatedUser);
      }
    } catch (e) {
      // Pas d'erreur critique si le refresh échoue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        elevation: 0,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Photo de profil
            _buildSection(
              'Photo de profil',
              [
                _buildProfileImageSection(),
              ],
            ),
            
            const SizedBox(height: 24),

            // Section Profil
            _buildSection(
              'Profil',
              [
                _buildTextField(
                  'Pseudo',
                  _pseudoController,
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Niveau/Classe',
                  _levelController,
                  Icons.school_outlined,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Notifications
            _buildSection(
              'Notifications',
              [
                _buildSwitchTile(
                  'Notifications activées',
                  _notificationsEnabled,
                  Icons.notifications_outlined,
                  (value) => setState(() => _notificationsEnabled = value),
                ),
                _buildSwitchTile(
                  'Rappels d\'étude',
                  _studyReminders,
                  Icons.schedule_outlined,
                  (value) => setState(() => _studyReminders = value),
                ),
                _buildSwitchTile(
                  'Objectifs hebdomadaires',
                  _weeklyGoalReminders,
                  Icons.flag_outlined,
                  (value) => setState(() => _weeklyGoalReminders = value),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Préférences
            _buildSection(
              'Préférences',
              [
                _buildSwitchTile(
                  'Mode sombre',
                  _darkModeEnabled,
                  Icons.dark_mode_outlined,
                  (value) => setState(() => _darkModeEnabled = value),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  'Difficulté préférée',
                  _preferredDifficulty,
                  _difficulties,
                  Icons.tune_outlined,
                  (value) => setState(() => _preferredDifficulty = value!),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Compte
            _buildSection(
              'Compte',
              [
                _buildInfoTile('Email', _currentUser.email, Icons.email_outlined),
                _buildInfoTile('Membre depuis', 
                  '${_currentUser.progression.memberSince.day}/${_currentUser.progression.memberSince.month}/${_currentUser.progression.memberSince.year}', 
                  Icons.calendar_today_outlined
                ),
                _buildInfoTile('Type d\'abonnement', 
                  _currentUser.subscriptionType.name.toUpperCase(), 
                  Icons.card_membership_outlined
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Bouton de déconnexion
            ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Widget _buildDropdown(String label, String value, List<String> items, IconData icon, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
    );
  }
  
  Widget _buildSwitchTile(String title, bool value, IconData icon, Function(bool) onChanged) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.body,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
  
  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.greyMedium),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.greyMedium,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          ProfileAvatar(
            user: _currentUser,
            radius: 50,
            showBorder: true,
            borderColor: AppColors.greyLight,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showImageSelector,
            icon: const Icon(Icons.edit),
            label: const Text('Modifier la photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSelector() {
    showDialog(
      context: context,
      builder: (context) => ProfileImageSelector(
        userId: _currentUser.uid,
        currentImageUrl: _currentUser.profileImageUrl,
        currentAvatarId: _currentUser.avatarId,
        onImageSelected: (imageUrl, avatarId) async {
          bool success = await _imageService.updateUserProfileImage(
            _currentUser.uid,
            imageUrl,
            avatarId,
          );

          if (success) {
            _showSuccessSnackBar('Photo de profil mise à jour');
            _hasChanges = true; // Marquer qu'il y a eu des changements
            
            // Rafraîchir immédiatement les données utilisateur
            await _refreshUserData();
          } else {
            _showErrorSnackBar('Erreur lors de la mise à jour de la photo');
          }
        },
      ),
    );
  }
}