import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BadgeType {
  achievement,    // Réussite (ex: Premier QCM)
  progression,    // Progression (ex: 10 cours terminés)
  mastery,        // Maîtrise (ex: Expert en Math)
  streak,         // Régularité (ex: 7 jours consécutifs)
  special,        // Spécial (ex: Bêta testeur)
}

enum BadgeRarity {
  common,         // Commun (bronze)
  uncommon,       // Peu commun (argent)
  rare,           // Rare (or)
  epic,           // Épique (platine)
  legendary,      // Légendaire (diamant)
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeType type;
  final BadgeRarity rarity;
  final Map<String, dynamic> requirements;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final int xpReward;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    required this.requirements,
    this.unlockedAt,
    required this.isUnlocked,
    required this.xpReward,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      type: BadgeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BadgeType.achievement,
      ),
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.name == map['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      requirements: Map<String, dynamic>.from(map['requirements'] ?? {}),
      unlockedAt: map['unlockedAt'] != null
          ? (map['unlockedAt'] as Timestamp).toDate()
          : null,
      isUnlocked: map['isUnlocked'] ?? false,
      xpReward: map['xpReward'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type.name,
      'rarity': rarity.name,
      'requirements': requirements,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'isUnlocked': isUnlocked,
      'xpReward': xpReward,
    };
  }

  BadgeModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    BadgeType? type,
    BadgeRarity? rarity,
    Map<String, dynamic>? requirements,
    DateTime? unlockedAt,
    bool? isUnlocked,
    int? xpReward,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      requirements: requirements ?? this.requirements,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  // Méthodes utiles
  String get rarityColorHex {
    switch (rarity) {
      case BadgeRarity.common:
        return '#CD7F32'; // Bronze
      case BadgeRarity.uncommon:
        return '#C0C0C0'; // Argent
      case BadgeRarity.rare:
        return '#FFD700'; // Or
      case BadgeRarity.epic:
        return '#E5E4E2'; // Platine
      case BadgeRarity.legendary:
        return '#B9F2FF'; // Diamant
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case BadgeRarity.common:
        return const Color(0xFFCD7F32); // Bronze
      case BadgeRarity.uncommon:
        return const Color(0xFFC0C0C0); // Argent
      case BadgeRarity.rare:
        return const Color(0xFFFFD700); // Or
      case BadgeRarity.epic:
        return const Color(0xFFE5E4E2); // Platine
      case BadgeRarity.legendary:
        return const Color(0xFFB9F2FF); // Diamant
    }
  }

  String get rarityDisplayName {
    switch (rarity) {
      case BadgeRarity.common:
        return 'Commun';
      case BadgeRarity.uncommon:
        return 'Peu commun';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Épique';
      case BadgeRarity.legendary:
        return 'Légendaire';
    }
  }

  String get typeDescription {
    switch (type) {
      case BadgeType.achievement:
        return 'Réussite';
      case BadgeType.progression:
        return 'Progression';
      case BadgeType.mastery:
        return 'Maîtrise';
      case BadgeType.streak:
        return 'Régularité';
      case BadgeType.special:
        return 'Spécial';
    }
  }
}