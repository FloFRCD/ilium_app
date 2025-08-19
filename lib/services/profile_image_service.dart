import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// Service pour gérer les photos de profil personnalisées et avatars
class ProfileImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Sélectionner une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      
      if (image != null) {
        Logger.info('Image sélectionnée depuis la galerie: ${image.path}');
        return File(image.path);
      }
      Logger.info('Aucune image sélectionnée depuis la galerie');
      return null;
    } catch (e) {
      Logger.error('Erreur sélection image galerie: $e');
      rethrow; // Relancer l'erreur pour que l'appelant puisse la gérer
    }
  }

  /// Prendre une photo avec la caméra
  Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      
      if (image != null) {
        Logger.info('Photo prise avec la caméra: ${image.path}');
        return File(image.path);
      }
      Logger.info('Aucune photo prise avec la caméra');
      return null;
    } catch (e) {
      Logger.error('Erreur prise photo caméra: $e');
      rethrow; // Relancer l'erreur pour que l'appelant puisse la gérer
    }
  }

  /// Upload une image de profil vers Firebase Storage
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Référence vers le fichier dans Firebase Storage
      final Reference ref = _storage
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      // Upload du fichier
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      // Récupérer l'URL de téléchargement
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      Logger.info('Image de profil uploadée: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      Logger.error('Erreur upload image profil: $e');
      return null;
    }
  }

  /// Mettre à jour l'URL de la photo de profil dans Firestore
  Future<bool> updateUserProfileImage(String userId, String? imageUrl, String? avatarId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
        'avatarId': avatarId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.info('Photo de profil mise à jour pour $userId');
      return true;

    } catch (e) {
      Logger.error('Erreur mise à jour photo profil: $e');
      return false;
    }
  }

  /// Supprimer une ancienne photo de profil
  Future<void> deleteOldProfileImage(String userId) async {
    try {
      final Reference ref = _storage
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      await ref.delete();
      Logger.info('Ancienne photo de profil supprimée pour $userId');

    } catch (e) {
      // Ne pas faire échouer si l'image n'existe pas
      Logger.info('Aucune ancienne photo à supprimer pour $userId');
    }
  }

  /// Obtenir la liste des avatars prédéfinis
  static List<Avatar> getPredefinedAvatars() {
    return [
      Avatar(id: 'avatar_1', emoji: '😊', name: 'Souriant'),
      Avatar(id: 'avatar_2', emoji: '🤓', name: 'Intello'),
      Avatar(id: 'avatar_3', emoji: '😎', name: 'Cool'),
      Avatar(id: 'avatar_4', emoji: '🌟', name: 'Étoile'),
      Avatar(id: 'avatar_5', emoji: '🚀', name: 'Fusée'),
      Avatar(id: 'avatar_6', emoji: '🎨', name: 'Artiste'),
      Avatar(id: 'avatar_7', emoji: '🎵', name: 'Musical'),
      Avatar(id: 'avatar_8', emoji: '⚡', name: 'Éclair'),
      Avatar(id: 'avatar_9', emoji: '🔥', name: 'Feu'),
      Avatar(id: 'avatar_10', emoji: '💎', name: 'Diamant'),
      Avatar(id: 'avatar_11', emoji: '🌈', name: 'Arc-en-ciel'),
      Avatar(id: 'avatar_12', emoji: '🦄', name: 'Licorne'),
      Avatar(id: 'avatar_13', emoji: '🎯', name: 'Précis'),
      Avatar(id: 'avatar_14', emoji: '🏆', name: 'Champion'),
      Avatar(id: 'avatar_15', emoji: '📚', name: 'Studieux'),
      Avatar(id: 'avatar_16', emoji: '🧠', name: 'Cerveau'),
    ];
  }
}

/// Modèle pour un avatar prédéfini
class Avatar {
  final String id;
  final String emoji;
  final String name;

  Avatar({
    required this.id,
    required this.emoji,
    required this.name,
  });
}