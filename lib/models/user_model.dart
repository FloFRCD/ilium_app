import 'package:cloud_firestore/cloud_firestore.dart';
import 'badge_model.dart';
import 'progression_model.dart';
import 'freemium_limitations_model.dart';

enum UserStatus {
  active,
  inactive,
  suspended,
  premium,
}

enum SubscriptionType {
  free,
  premium,
  premiumPlus,
}

class UserModel {
  final String uid;
  final String pseudo;
  final String email;
  final String niveau;
  final String? profileImageUrl;  // URL de l'image de profil personnalisée
  final String? avatarId;         // ID de l'avatar prédéfini choisi
  final List<String> options;  // Options/spécialités de l'utilisateur
  final DateTime? birthDate;  // Date de naissance pour calcul automatique de l'âge
  final UserStatus status;
  final SubscriptionType subscriptionType;
  final DateTime? subscriptionExpiresAt;
  final List<BadgeModel> badges;
  final GlobalProgressionModel progression;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;
  final FreemiumLimitationsModel limitations;

  UserModel({
    required this.uid,
    required this.pseudo,
    required this.email,
    required this.niveau,
    this.profileImageUrl,
    this.avatarId,
    this.options = const [],
    this.birthDate,
    required this.status,
    required this.subscriptionType,
    this.subscriptionExpiresAt,
    required this.badges,
    required this.progression,
    required this.createdAt,
    required this.updatedAt,
    required this.preferences,
    required this.limitations,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      pseudo: data['pseudo'] ?? '',
      email: data['email'] ?? '',
      niveau: data['niveau'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      avatarId: data['avatarId'],
      options: List<String>.from(data['options'] ?? []),
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.active,
      ),
      subscriptionType: SubscriptionType.values.firstWhere(
        (e) => e.name == data['subscriptionType'],
        orElse: () => SubscriptionType.free,
      ),
      subscriptionExpiresAt: data['subscriptionExpiresAt'] != null
          ? (data['subscriptionExpiresAt'] as Timestamp).toDate()
          : null,
      badges: (data['badges'] as List<dynamic>? ?? [])
          .map((badge) => BadgeModel.fromMap(badge as Map<String, dynamic>))
          .toList(),
      progression: GlobalProgressionModel.fromMap(
        data['progression'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      limitations: FreemiumLimitationsModel.fromMap(
        Map<String, dynamic>.from(data['limitations'] ?? {}),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'uid': uid,
        'pseudo': pseudo,
        'email': email,
        'niveau': niveau,
        'profileImageUrl': profileImageUrl,
        'avatarId': avatarId,
        'options': options,
        'birthDate': birthDate != null
            ? Timestamp.fromDate(birthDate!)
            : null,
        'status': status.name,
        'subscriptionType': subscriptionType.name,
        'subscriptionExpiresAt': subscriptionExpiresAt != null
            ? Timestamp.fromDate(subscriptionExpiresAt!)
            : null,
        'badges': badges.map((badge) => badge.toMap()).toList(),
        'progression': progression.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'preferences': preferences,
        'limitations': limitations.toMap(),
      };
    } catch (e) {
      print('🚨 ERREUR dans toFirestore(): $e');
      
      // Debug chaque champ individuellement
      print('  uid: $uid');
      print('  pseudo: $pseudo');
      print('  email: $email');
      print('  niveau: $niveau');
      print('  options: $options');
      print('  birthDate: $birthDate');
      print('  status: $status');
      print('  subscriptionType: $subscriptionType');
      print('  badges.length: ${badges.length}');
      print('  progression: ${progression.toString()}');
      print('  createdAt: $createdAt');
      print('  updatedAt: $updatedAt');
      print('  preferences: $preferences');
      
      rethrow;
    }
  }

  UserModel copyWith({
    String? uid,
    String? pseudo,
    String? email,
    String? niveau,
    String? profileImageUrl,
    String? avatarId,
    List<String>? options,
    DateTime? birthDate,
    UserStatus? status,
    SubscriptionType? subscriptionType,
    DateTime? subscriptionExpiresAt,
    List<BadgeModel>? badges,
    GlobalProgressionModel? progression,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    FreemiumLimitationsModel? limitations,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      pseudo: pseudo ?? this.pseudo,
      email: email ?? this.email,
      niveau: niveau ?? this.niveau,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      avatarId: avatarId ?? this.avatarId,
      options: options ?? this.options,
      birthDate: birthDate ?? this.birthDate,
      status: status ?? this.status,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      badges: badges ?? this.badges,
      progression: progression ?? this.progression,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      limitations: limitations ?? this.limitations,
    );
  }

  // Méthodes utiles pour l'âge et l'anniversaire
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  bool get isBirthdayToday {
    if (birthDate == null) return false;
    final now = DateTime.now();
    return now.month == birthDate!.month && now.day == birthDate!.day;
  }

  int? get daysUntilBirthday {
    if (birthDate == null) return null;
    final now = DateTime.now();
    DateTime thisYearBirthday = DateTime(now.year, birthDate!.month, birthDate!.day);
    
    if (thisYearBirthday.isBefore(now)) {
      thisYearBirthday = DateTime(now.year + 1, birthDate!.month, birthDate!.day);
    }
    
    return thisYearBirthday.difference(now).inDays;
  }
}