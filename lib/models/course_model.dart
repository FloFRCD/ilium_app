import 'package:cloud_firestore/cloud_firestore.dart';

enum CourseType {
  fiche,        // Fiche de révision
  cours,        // Cours complet
  vulgarise,    // Vulgarisation
}

enum CourseDifficulty {
  facile,
  moyen,
  difficile,
}


class CourseModel {
  final String id;
  final String title;
  final String matiere;
  final String niveau;
  final CourseType type;
  final String content;
  final int popularity;
  final Map<String, int> votes;
  final List<Map<String, dynamic>> commentaires;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Nouvelles propriétés
  final String? description;
  final CourseDifficulty? difficulty;
  final int? estimatedDuration; // en minutes
  final bool isPremium;
  final bool isPublic;
  final List<String> tags;
  final Map<String, double> rating;
  final int viewsCount;
  final Map<String, dynamic>? metadata;

  CourseModel({
    required this.id,
    required this.title,
    required this.matiere,
    required this.niveau,
    required this.type,
    required this.content,
    required this.popularity,
    required this.votes,
    required this.commentaires,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    // Nouvelles propriétés
    this.description,
    this.difficulty,
    this.estimatedDuration,
    this.isPremium = false,
    this.isPublic = true,
    this.tags = const [],
    this.rating = const {},
    this.viewsCount = 0,
    this.metadata,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      matiere: data['matiere'] ?? '',
      niveau: data['niveau'] ?? '',
      type: CourseType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CourseType.fiche,
      ),
      content: data['content'] ?? '',
      popularity: data['popularity'] ?? 0,
      votes: Map<String, int>.from(data['votes'] ?? {}),
      commentaires: List<Map<String, dynamic>>.from(data['commentaires'] ?? []),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      // Nouvelles propriétés
      description: data['description'],
      difficulty: data['difficulty'] != null 
        ? CourseDifficulty.values.firstWhere(
            (e) => e.name == data['difficulty'],
            orElse: () => CourseDifficulty.moyen,
          )
        : null,
      estimatedDuration: data['estimatedDuration'],
      isPremium: data['isPremium'] ?? false,
      isPublic: data['isPublic'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      rating: Map<String, double>.from(data['rating'] ?? {}),
      viewsCount: data['viewsCount'] ?? 0,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'matiere': matiere,
      'niveau': niveau,
      'type': type.name,
      'content': content,
      'popularity': popularity,
      'votes': votes,
      'commentaires': commentaires,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      // Nouvelles propriétés
      'description': description,
      'difficulty': difficulty?.name,
      'estimatedDuration': estimatedDuration,
      'isPremium': isPremium,
      'isPublic': isPublic,
      'tags': tags,
      'rating': rating,
      'viewsCount': viewsCount,
      'metadata': metadata,
    };
  }

  int get upvotes => votes['up'] ?? 0;
  int get downvotes => votes['down'] ?? 0;
  int get totalVotes => upvotes + downvotes;
  
  // Helpers pour les nouvelles propriétés
  double get averageRating {
    if (rating.isEmpty) return 0.0;
    final total = rating.values.reduce((a, b) => a + b);
    return total / rating.length;
  }
  
  int get ratingCount => rating.length;

  // Génère l'ID de document formaté : "Sujet-Type-Niveau"
  String generateDocumentId() {
    String cleanTitle = title
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '') // Supprime caractères spéciaux
        .replaceAll(' ', '')                        // Supprime espaces
        .replaceAll('è', 'e').replaceAll('é', 'e')  // Remplace accents
        .replaceAll('à', 'a').replaceAll('ç', 'c');
    
    String typeStr;
    switch (type) {
      case CourseType.cours:
        typeStr = 'CoursComplet';
        break;
      case CourseType.fiche:
        typeStr = 'FicheRevision';
        break;
      case CourseType.vulgarise:
        typeStr = 'Vulgarisation';
        break;
    }
    
    return '$cleanTitle-$typeStr-$niveau';
  }

  // Helper pour les tags selon le type
  List<String> get typeBasedTags {
    List<String> baseTags = [matiere.toLowerCase(), niveau.toLowerCase()];
    
    switch (type) {
      case CourseType.cours:
        baseTags.add('cours-complet');
        break;
      case CourseType.fiche:
        baseTags.add('fiche-revision');
        break;
      case CourseType.vulgarise:
        baseTags.add('vulgarisation');
        break;
    }
    
    return baseTags;
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? matiere,
    String? niveau,
    CourseType? type,
    String? content,
    int? popularity,
    Map<String, int>? votes,
    List<Map<String, dynamic>>? commentaires,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    CourseDifficulty? difficulty,
    int? estimatedDuration,
    bool? isPremium,
    bool? isPublic,
    List<String>? tags,
    Map<String, double>? rating,
    int? viewsCount,
    Map<String, dynamic>? metadata,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      matiere: matiere ?? this.matiere,
      niveau: niveau ?? this.niveau,
      type: type ?? this.type,
      content: content ?? this.content,
      popularity: popularity ?? this.popularity,
      votes: votes ?? this.votes,
      commentaires: commentaires ?? this.commentaires,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isPremium: isPremium ?? this.isPremium,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      viewsCount: viewsCount ?? this.viewsCount,
      metadata: metadata ?? this.metadata,
    );
  }
}