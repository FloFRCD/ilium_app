import 'dart:io';
import 'package:flutter/material.dart';
import '../services/profile_image_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';

/// Widget pour sélectionner une photo de profil (personnalisée ou avatar)
class ProfileImageSelector extends StatefulWidget {
  final String userId;
  final String? currentImageUrl;
  final String? currentAvatarId;
  final Function(String? imageUrl, String? avatarId) onImageSelected;

  const ProfileImageSelector({
    super.key,
    required this.userId,
    this.currentImageUrl,
    this.currentAvatarId,
    required this.onImageSelected,
  });

  @override
  State<ProfileImageSelector> createState() => _ProfileImageSelectorState();
}

class _ProfileImageSelectorState extends State<ProfileImageSelector> {
  final ProfileImageService _imageService = ProfileImageService();
  bool _isUploading = false;
  String? _selectedImageUrl;
  String? _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    _selectedImageUrl = widget.currentImageUrl;
    _selectedAvatarId = widget.currentAvatarId;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre
            Text(
              'Choisir une photo de profil',
              style: AppTextStyles.h3.copyWith(color: AppColors.greyDark),
            ),
            const SizedBox(height: 20),

            // Aperçu actuel
            _buildCurrentPreview(),
            const SizedBox(height: 20),

            // Options de sélection
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Caméra'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Avatars prédéfinis
            Text(
              'Ou choisir un avatar',
              style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
            ),
            const SizedBox(height: 12),
            _buildAvatarGrid(),
            const SizedBox(height: 20),

            // Boutons d'action
            Row(
              children: [
                TextButton(
                  onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const Spacer(),
                if (_selectedImageUrl != null || _selectedAvatarId != null)
                  TextButton(
                    onPressed: _isUploading ? null : _removeImage,
                    child: Text(
                      'Supprimer',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isUploading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPreview() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.greyLight, width: 2),
      ),
      child: ClipOval(
        child: _buildProfileImage(),
      ),
    );
  }

  Widget _buildProfileImage() {
    // Image personnalisée
    if (_selectedImageUrl != null) {
      return Image.network(
        _selectedImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
    }

    // Avatar prédéfini
    if (_selectedAvatarId != null) {
      final avatar = ProfileImageService.getPredefinedAvatars()
          .firstWhere((a) => a.id == _selectedAvatarId, orElse: () => 
            ProfileImageService.getPredefinedAvatars().first);
      return Container(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: Center(
          child: Text(
            avatar.emoji,
            style: const TextStyle(fontSize: 40),
          ),
        ),
      );
    }

    // Défaut
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: 50,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildAvatarGrid() {
    final avatars = ProfileImageService.getPredefinedAvatars();
    
    return SizedBox(
      height: 120,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: avatars.length,
        itemBuilder: (context, index) {
          final avatar = avatars[index];
          final isSelected = _selectedAvatarId == avatar.id;

          return GestureDetector(
            onTap: () => _selectAvatar(avatar.id),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.greyLight,
                  width: isSelected ? 3 : 1,
                ),
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
              ),
              child: Center(
                child: Text(
                  avatar.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectAvatar(String avatarId) {
    setState(() {
      _selectedAvatarId = avatarId;
      _selectedImageUrl = null; // Désélectionner l'image personnalisée
    });
  }

  Future<void> _pickFromGallery() async {
    try {
      final File? imageFile = await _imageService.pickImageFromGallery();
      if (imageFile != null) {
        await _uploadImage(imageFile);
      }
    } catch (e) {
      Logger.error('Erreur sélection galerie: $e');
      _showError('Erreur lors de l\'accès à la galerie');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final File? imageFile = await _imageService.takePhotoWithCamera();
      if (imageFile != null) {
        await _uploadImage(imageFile);
      }
    } catch (e) {
      Logger.error('Erreur prise photo: $e');
      _showError('Erreur lors de l\'accès à la caméra');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      // Supprimer l'ancienne image si elle existe
      if (_selectedImageUrl != null) {
        await _imageService.deleteOldProfileImage(widget.userId);
      }

      // Upload la nouvelle image
      String? imageUrl = await _imageService.uploadProfileImage(widget.userId, imageFile);

      if (imageUrl != null) {
        setState(() {
          _selectedImageUrl = imageUrl;
          _selectedAvatarId = null; // Désélectionner l'avatar
        });
      } else {
        _showError('Erreur lors de l\'upload de l\'image');
      }

    } catch (e) {
      Logger.error('Erreur upload image: $e');
      _showError('Erreur lors de l\'upload de l\'image');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageUrl = null;
      _selectedAvatarId = null;
    });
  }

  void _saveChanges() {
    widget.onImageSelected(_selectedImageUrl, _selectedAvatarId);
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}