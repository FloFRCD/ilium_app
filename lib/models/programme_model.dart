import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle simple pour représenter un programme scolaire
class ProgrammeModel {
  final String id;
  final String matiere;
  final String niveau;
  final List<String> options; // Options/spécialités choisies par l'étudiant
  final int annee; // 2025, 2026, etc.
  final String contenu; // Contenu markdown du programme
  final List<String> chapitres; // Liste des chapitres/notions
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source; // 'generated' ou 'manual'
  final List<String> tags; // Tags pour la recherche (matiere, niveau, options)
  final Map<String, dynamic> metadata;

  const ProgrammeModel({
    required this.id,
    required this.matiere,
    required this.niveau,
    this.options = const [],
    required this.annee,
    required this.contenu,
    required this.chapitres,
    required this.createdAt,
    required this.updatedAt,
    this.source = 'generated',
    this.tags = const [],
    this.metadata = const {},
  });

  /// Génère un ID unique pour le programme basé sur matière/niveau/année/options
  static String generateId(String matiere, String niveau, int annee, {List<String>? options}) {
    final matiereClean = matiere.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final niveauClean = niveau.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    String optionsClean = '';
    if (options != null && options.isNotEmpty) {
      optionsClean = '-${options.map((o) => o.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')).join('-')}';
    }
    return '$matiereClean-$niveauClean-$annee$optionsClean'.toLowerCase();
  }

  /// Génère automatiquement les tags à partir des propriétés
  static List<String> generateTags(String matiere, String niveau, List<String> options) {
    List<String> tags = [
      matiere.toLowerCase(),
      niveau.toLowerCase(),
    ];
    
    // Ajouter les options comme tags
    for (String option in options) {
      tags.add(option.toLowerCase());
    }
    
    return tags;
  }

  /// Crée une instance depuis Firestore
  factory ProgrammeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgrammeModel(
      id: doc.id,
      matiere: data['matiere'] ?? '',
      niveau: data['niveau'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      annee: data['annee'] ?? DateTime.now().year,
      contenu: data['contenu'] ?? '',
      chapitres: List<String>.from(data['chapitres'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: data['source'] ?? 'generated',
      tags: List<String>.from(data['tags'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Convertit vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'matiere': matiere,
      'niveau': niveau,
      'options': options,
      'annee': annee,
      'contenu': contenu,
      'chapitres': chapitres,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'source': source,
      'tags': tags,
      'metadata': metadata,
    };
  }

  /// Crée une copie avec modifications
  ProgrammeModel copyWith({
    String? id,
    String? matiere,
    String? niveau,
    List<String>? options,
    int? annee,
    String? contenu,
    List<String>? chapitres,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return ProgrammeModel(
      id: id ?? this.id,
      matiere: matiere ?? this.matiere,
      niveau: niveau ?? this.niveau,
      options: options ?? this.options,
      annee: annee ?? this.annee,
      contenu: contenu ?? this.contenu,
      chapitres: chapitres ?? this.chapitres,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ProgrammeModel(id: $id, matiere: $matiere, niveau: $niveau, options: $options, annee: $annee)';
  }
}