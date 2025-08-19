import 'package:cloud_firestore/cloud_firestore.dart';

enum CourseStatus {
  saved,       // Enregistré (favoris)
  inProgress,  // En cours
  completed,   // Terminé
  archived,    // Archivé
}

class CourseStatusModel {
  final String userId;
  final String courseId;
  final CourseStatus status;
  final DateTime statusUpdatedAt;
  final double progress; // 0.0 à 1.0 (100%)
  final DateTime lastAccessedAt;
  final int timeSpentMinutes;
  final Map<String, dynamic> metadata; // Données supplémentaires (score, notes, etc.)

  CourseStatusModel({
    required this.userId,
    required this.courseId,
    required this.status,
    required this.statusUpdatedAt,
    required this.progress,
    required this.lastAccessedAt,
    required this.timeSpentMinutes,
    required this.metadata,
  });

  factory CourseStatusModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Validation des Timestamps
      DateTime statusUpdatedAt;
      try {
        statusUpdatedAt = (data['statusUpdatedAt'] as Timestamp).toDate();
      } catch (e) {
        statusUpdatedAt = DateTime.now(); // Fallback
      }
      
      DateTime lastAccessedAt;
      try {
        lastAccessedAt = (data['lastAccessedAt'] as Timestamp).toDate();
      } catch (e) {
        lastAccessedAt = DateTime.now(); // Fallback
      }
      
      return CourseStatusModel(
        userId: data['userId']?.toString() ?? '',
        courseId: data['courseId']?.toString() ?? '',
        status: CourseStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => CourseStatus.saved,
        ),
        statusUpdatedAt: statusUpdatedAt,
        progress: double.tryParse(data['progress']?.toString() ?? '0.0') ?? 0.0,
        lastAccessedAt: lastAccessedAt,
        timeSpentMinutes: int.tryParse(data['timeSpentMinutes']?.toString() ?? '0') ?? 0,
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
    } catch (e) {
      // En cas d'erreur de parsing, retourner un modèle par défaut
      return CourseStatusModel(
        userId: '',
        courseId: doc.id.split('_').length > 1 ? doc.id.split('_')[1] : doc.id, // Extraire courseId du docId si possible
        status: CourseStatus.saved,
        statusUpdatedAt: DateTime.now(),
        progress: 0.0,
        lastAccessedAt: DateTime.now(),
        timeSpentMinutes: 0,
        metadata: {},
      );
    }
  }

  factory CourseStatusModel.fromMap(Map<String, dynamic> map) {
    return CourseStatusModel(
      userId: map['userId'] ?? '',
      courseId: map['courseId'] ?? '',
      status: CourseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CourseStatus.saved,
      ),
      statusUpdatedAt: map['statusUpdatedAt'] != null
          ? (map['statusUpdatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      progress: (map['progress'] ?? 0.0).toDouble(),
      lastAccessedAt: map['lastAccessedAt'] != null
          ? (map['lastAccessedAt'] as Timestamp).toDate()
          : DateTime.now(),
      timeSpentMinutes: map['timeSpentMinutes'] ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'courseId': courseId,
      'status': status.name,
      'statusUpdatedAt': Timestamp.fromDate(statusUpdatedAt),
      'progress': progress,
      'lastAccessedAt': Timestamp.fromDate(lastAccessedAt),
      'timeSpentMinutes': timeSpentMinutes,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'status': status.name,
      'statusUpdatedAt': Timestamp.fromDate(statusUpdatedAt),
      'progress': progress,
      'lastAccessedAt': Timestamp.fromDate(lastAccessedAt),
      'timeSpentMinutes': timeSpentMinutes,
      'metadata': metadata,
    };
  }

  CourseStatusModel copyWith({
    String? userId,
    String? courseId,
    CourseStatus? status,
    DateTime? statusUpdatedAt,
    double? progress,
    DateTime? lastAccessedAt,
    int? timeSpentMinutes,
    Map<String, dynamic>? metadata,
  }) {
    return CourseStatusModel(
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      status: status ?? this.status,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      progress: progress ?? this.progress,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Méthodes utiles
  String get statusDisplayName {
    switch (status) {
      case CourseStatus.saved:
        return 'Enregistré';
      case CourseStatus.inProgress:
        return 'En cours';
      case CourseStatus.completed:
        return 'Terminé';
      case CourseStatus.archived:
        return 'Archivé';
    }
  }

  String get progressPercentage {
    return '${(progress * 100).toInt()}%';
  }

  bool get isCompleted => status == CourseStatus.completed;
  bool get isInProgress => status == CourseStatus.inProgress;
  bool get isSaved => status == CourseStatus.saved;
  bool get isArchived => status == CourseStatus.archived;

  String get timeSpentDisplay {
    if (timeSpentMinutes < 60) {
      return '${timeSpentMinutes}min';
    } else {
      int hours = timeSpentMinutes ~/ 60;
      int minutes = timeSpentMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  Duration get timeSpent => Duration(minutes: timeSpentMinutes);

  // Méthodes pour récupérer des métadonnées spécifiques
  double? get lastScore => metadata['lastScore']?.toDouble();
  int? get bestScore => metadata['bestScore']?.toInt();
  List<String>? get notes => metadata['notes']?.cast<String>();
  String? get lastChapterCompleted => metadata['lastChapterCompleted'];
  int? get totalAttempts => metadata['totalAttempts']?.toInt();
}