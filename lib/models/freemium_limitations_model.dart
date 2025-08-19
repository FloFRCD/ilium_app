
import 'course_model.dart';

class FreemiumLimitationsModel {
  final int maxCoursesPerDay;
  final int maxQcmPerDay;
  final int maxCoursesPerMonth;
  final int maxQcmPerMonth;
  final bool canAccessPremiumCourses;
  final bool canAccessAdvancedQcm;
  final bool canDownloadPdf;
  final bool canGenerateCustomCourses;
  final bool hasAdsRemoved;
  final bool canAccessProgressionAnalytics;
  final bool canAccessAiTutor;
  final int maxBookmarksAllowed;
  final int maxNotesPerCourse;
  final bool canAccessOfflineMode;
  // Nouvelles limitations spécifiques par type de contenu
  final int maxFullCoursesPerMonth;  // Cours complets seulement
  final bool canAccessVulgariseCourses;
  final bool canAccessFicheRevision;
  final bool canAccessQcm;
  final Map<String, dynamic> customLimitations;

  FreemiumLimitationsModel({
    required this.maxCoursesPerDay,
    required this.maxQcmPerDay,
    required this.maxCoursesPerMonth,
    required this.maxQcmPerMonth,
    required this.canAccessPremiumCourses,
    required this.canAccessAdvancedQcm,
    required this.canDownloadPdf,
    required this.canGenerateCustomCourses,
    required this.hasAdsRemoved,
    required this.canAccessProgressionAnalytics,
    required this.canAccessAiTutor,
    required this.maxBookmarksAllowed,
    required this.maxNotesPerCourse,
    required this.canAccessOfflineMode,
    required this.maxFullCoursesPerMonth,
    required this.canAccessVulgariseCourses,
    required this.canAccessFicheRevision,
    required this.canAccessQcm,
    required this.customLimitations,
  });

  factory FreemiumLimitationsModel.free() {
    return FreemiumLimitationsModel(
      maxCoursesPerDay: 50,  // TEMPORAIRE POUR TESTS
      maxQcmPerDay: 50,  // TEMPORAIRE POUR TESTS - QCM débloqués
      maxCoursesPerMonth: 500,  // TEMPORAIRE POUR TESTS
      maxQcmPerMonth: 500,  // TEMPORAIRE POUR TESTS - QCM débloqués
      canAccessPremiumCourses: true,  // TEMPORAIRE POUR TESTS
      canAccessAdvancedQcm: true,  // TEMPORAIRE POUR TESTS
      canDownloadPdf: true,  // TEMPORAIRE POUR TESTS
      canGenerateCustomCourses: true,  // TEMPORAIRE POUR TESTS
      hasAdsRemoved: true,  // TEMPORAIRE POUR TESTS
      canAccessProgressionAnalytics: true,  // TEMPORAIRE POUR TESTS
      canAccessAiTutor: true,  // TEMPORAIRE POUR TESTS
      maxBookmarksAllowed: 100,  // TEMPORAIRE POUR TESTS
      maxNotesPerCourse: 20,  // TEMPORAIRE POUR TESTS
      canAccessOfflineMode: true,  // TEMPORAIRE POUR TESTS
      // TEMPORAIRE POUR TESTS - Accès à tout
      maxFullCoursesPerMonth: 500,  // TEMPORAIRE POUR TESTS
      canAccessVulgariseCourses: true,  // TEMPORAIRE POUR TESTS - Vulgarisation débloquée
      canAccessFicheRevision: true,  // TEMPORAIRE POUR TESTS - Fiches débloquées
      canAccessQcm: true,  // TEMPORAIRE POUR TESTS - QCM débloqués
      customLimitations: {},
    );
  }

  factory FreemiumLimitationsModel.premium() {
    return FreemiumLimitationsModel(
      maxCoursesPerDay: 20,
      maxQcmPerDay: 50,
      maxCoursesPerMonth: 500,
      maxQcmPerMonth: 1000,
      canAccessPremiumCourses: true,
      canAccessAdvancedQcm: true,
      canDownloadPdf: true,
      canGenerateCustomCourses: true,
      hasAdsRemoved: true,
      canAccessProgressionAnalytics: true,
      canAccessAiTutor: true,
      maxBookmarksAllowed: 100,
      maxNotesPerCourse: 20,
      canAccessOfflineMode: true,
      // Premium a accès à tout
      maxFullCoursesPerMonth: 500,
      canAccessVulgariseCourses: true,
      canAccessFicheRevision: true,
      canAccessQcm: true,
      customLimitations: {},
    );
  }

  factory FreemiumLimitationsModel.premiumPlus() {
    return FreemiumLimitationsModel(
      maxCoursesPerDay: -1, // Illimité
      maxQcmPerDay: -1,     // Illimité
      maxCoursesPerMonth: -1,
      maxQcmPerMonth: -1,
      canAccessPremiumCourses: true,
      canAccessAdvancedQcm: true,
      canDownloadPdf: true,
      canGenerateCustomCourses: true,
      hasAdsRemoved: true,
      canAccessProgressionAnalytics: true,
      canAccessAiTutor: true,
      maxBookmarksAllowed: -1, // Illimité
      maxNotesPerCourse: -1,   // Illimité
      canAccessOfflineMode: true,
      // Premium+ a accès illimité à tout
      maxFullCoursesPerMonth: -1,
      canAccessVulgariseCourses: true,
      canAccessFicheRevision: true,
      canAccessQcm: true,
      customLimitations: {
        'prioritySupport': true,
        'exclusiveContent': true,
        'advancedAi': true,
      },
    );
  }

  factory FreemiumLimitationsModel.fromMap(Map<String, dynamic> map) {
    return FreemiumLimitationsModel(
      // TEMPORAIRE POUR TESTS - Valeurs débloquées par défaut
      maxCoursesPerDay: map['maxCoursesPerDay'] ?? 50,
      maxQcmPerDay: map['maxQcmPerDay'] ?? 50,
      maxCoursesPerMonth: map['maxCoursesPerMonth'] ?? 500,
      maxQcmPerMonth: map['maxQcmPerMonth'] ?? 500,
      canAccessPremiumCourses: map['canAccessPremiumCourses'] ?? true,
      canAccessAdvancedQcm: map['canAccessAdvancedQcm'] ?? true,
      canDownloadPdf: map['canDownloadPdf'] ?? true,
      canGenerateCustomCourses: map['canGenerateCustomCourses'] ?? true,
      hasAdsRemoved: map['hasAdsRemoved'] ?? true,
      canAccessProgressionAnalytics: map['canAccessProgressionAnalytics'] ?? true,
      canAccessAiTutor: map['canAccessAiTutor'] ?? true,
      maxBookmarksAllowed: map['maxBookmarksAllowed'] ?? 100,
      maxNotesPerCourse: map['maxNotesPerCourse'] ?? 20,
      canAccessOfflineMode: map['canAccessOfflineMode'] ?? true,
      maxFullCoursesPerMonth: map['maxFullCoursesPerMonth'] ?? 500,
      canAccessVulgariseCourses: map['canAccessVulgariseCourses'] ?? true,
      canAccessFicheRevision: map['canAccessFicheRevision'] ?? true,
      canAccessQcm: map['canAccessQcm'] ?? true, // TEMPORAIRE POUR TESTS - QCM débloqués
      customLimitations: Map<String, dynamic>.from(map['customLimitations'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxCoursesPerDay': maxCoursesPerDay,
      'maxQcmPerDay': maxQcmPerDay,
      'maxCoursesPerMonth': maxCoursesPerMonth,
      'maxQcmPerMonth': maxQcmPerMonth,
      'canAccessPremiumCourses': canAccessPremiumCourses,
      'canAccessAdvancedQcm': canAccessAdvancedQcm,
      'canDownloadPdf': canDownloadPdf,
      'canGenerateCustomCourses': canGenerateCustomCourses,
      'hasAdsRemoved': hasAdsRemoved,
      'canAccessProgressionAnalytics': canAccessProgressionAnalytics,
      'canAccessAiTutor': canAccessAiTutor,
      'maxBookmarksAllowed': maxBookmarksAllowed,
      'maxNotesPerCourse': maxNotesPerCourse,
      'canAccessOfflineMode': canAccessOfflineMode,
      'maxFullCoursesPerMonth': maxFullCoursesPerMonth,
      'canAccessVulgariseCourses': canAccessVulgariseCourses,
      'canAccessFicheRevision': canAccessFicheRevision,
      'canAccessQcm': canAccessQcm,
      'customLimitations': customLimitations,
    };
  }

  FreemiumLimitationsModel copyWith({
    int? maxCoursesPerDay,
    int? maxQcmPerDay,
    int? maxCoursesPerMonth,
    int? maxQcmPerMonth,
    bool? canAccessPremiumCourses,
    bool? canAccessAdvancedQcm,
    bool? canDownloadPdf,
    bool? canGenerateCustomCourses,
    bool? hasAdsRemoved,
    bool? canAccessProgressionAnalytics,
    bool? canAccessAiTutor,
    int? maxBookmarksAllowed,
    int? maxNotesPerCourse,
    bool? canAccessOfflineMode,
    int? maxFullCoursesPerMonth,
    bool? canAccessVulgariseCourses,
    bool? canAccessFicheRevision,
    bool? canAccessQcm,
    Map<String, dynamic>? customLimitations,
  }) {
    return FreemiumLimitationsModel(
      maxCoursesPerDay: maxCoursesPerDay ?? this.maxCoursesPerDay,
      maxQcmPerDay: maxQcmPerDay ?? this.maxQcmPerDay,
      maxCoursesPerMonth: maxCoursesPerMonth ?? this.maxCoursesPerMonth,
      maxQcmPerMonth: maxQcmPerMonth ?? this.maxQcmPerMonth,
      canAccessPremiumCourses: canAccessPremiumCourses ?? this.canAccessPremiumCourses,
      canAccessAdvancedQcm: canAccessAdvancedQcm ?? this.canAccessAdvancedQcm,
      canDownloadPdf: canDownloadPdf ?? this.canDownloadPdf,
      canGenerateCustomCourses: canGenerateCustomCourses ?? this.canGenerateCustomCourses,
      hasAdsRemoved: hasAdsRemoved ?? this.hasAdsRemoved,
      canAccessProgressionAnalytics: canAccessProgressionAnalytics ?? this.canAccessProgressionAnalytics,
      canAccessAiTutor: canAccessAiTutor ?? this.canAccessAiTutor,
      maxBookmarksAllowed: maxBookmarksAllowed ?? this.maxBookmarksAllowed,
      maxNotesPerCourse: maxNotesPerCourse ?? this.maxNotesPerCourse,
      canAccessOfflineMode: canAccessOfflineMode ?? this.canAccessOfflineMode,
      maxFullCoursesPerMonth: maxFullCoursesPerMonth ?? this.maxFullCoursesPerMonth,
      canAccessVulgariseCourses: canAccessVulgariseCourses ?? this.canAccessVulgariseCourses,
      canAccessFicheRevision: canAccessFicheRevision ?? this.canAccessFicheRevision,
      canAccessQcm: canAccessQcm ?? this.canAccessQcm,
      customLimitations: customLimitations ?? this.customLimitations,
    );
  }

  // Méthodes utiles
  bool get isUnlimited => maxCoursesPerDay == -1 && maxQcmPerDay == -1;
  
  bool get isPremium => canAccessPremiumCourses;
  
  bool get isPremiumPlus => isPremium && customLimitations.containsKey('prioritySupport');

  String get subscriptionTier {
    // TEMPORAIRE POUR TESTS - Toujours retourner Premium pour débloquer tout
    return 'Premium+';
    
    // LOGIQUE ORIGINALE (désactivée pour tests)
    // if (isPremiumPlus) return 'Premium+';
    // if (isPremium) return 'Premium';  
    // return 'Gratuit';
  }

  // DEPRECATED: Utiliser canAccessCourseType() à la place
  @Deprecated("Utiliser canAccessCourseType() à la place")
  bool canAccessCourse(bool isPremiumCourse) {
    if (!isPremiumCourse) return true;
    return canAccessPremiumCourses;
  }

  bool canAccessQcmContent(bool isAdvancedQcm) {
    // TEMPORAIRE POUR TESTS - Toujours retourner true
    return true;
    
    // LOGIQUE ORIGINALE (désactivée pour tests)
    // // Si l'utilisateur ne peut pas accéder aux QCM du tout
    // if (!canAccessQcm) return false;
    // // Si c'est un QCM avancé, vérifier les permissions avancées
    // if (isAdvancedQcm) return canAccessAdvancedQcm;
    // return true;
  }

  // Nouvelles méthodes pour les types de contenu spécifiques
  bool canAccessCourseType(CourseType courseType) {
    // TEMPORAIRE POUR TESTS - Toujours retourner true
    return true;
    
    // LOGIQUE ORIGINALE (désactivée pour tests)
    // switch (courseType) {
    //   case CourseType.cours:
    //     return true; // Les cours complets sont toujours accessibles (avec limite)
    //   case CourseType.vulgarise:
    //     return canAccessVulgariseCourses;
    //   case CourseType.fiche:
    //     return canAccessFicheRevision;
    // }
  }

  bool hasReachedFullCourseLimit(int currentFullCoursesThisMonth) {
    // TEMPORAIRE POUR TESTS - Jamais de limite atteinte
    return false;
    
    // LOGIQUE ORIGINALE (désactivée pour tests)
    // if (maxFullCoursesPerMonth == -1) return false; // Illimité
    // return currentFullCoursesThisMonth >= maxFullCoursesPerMonth;
  }

  String getFullCourseLimitMessage(int currentFullCoursesThisMonth) {
    if (maxFullCoursesPerMonth == -1) return 'Cours complets illimités';
    int remaining = maxFullCoursesPerMonth - currentFullCoursesThisMonth;
    if (remaining <= 0) return 'Limite mensuelle de cours complets atteinte';
    return 'Reste: $remaining cours complet${remaining > 1 ? 's' : ''} ce mois';
  }

  String getContentTypeRestrictionMessage(CourseType courseType) {
    switch (courseType) {
      case CourseType.cours:
        return 'Cours complet disponible (limite: $maxFullCoursesPerMonth/mois)';
      case CourseType.vulgarise:
        return canAccessVulgariseCourses 
            ? 'Cours vulgarisé disponible'
            : 'Cours vulgarisés réservés aux membres Premium';
      case CourseType.fiche:
        return canAccessFicheRevision 
            ? 'Fiche de révision disponible'
            : 'Fiches de révision réservées aux membres Premium';
    }
  }

  bool hasReachedDailyLimit(int currentCoursesToday, int currentQcmToday) {
    // TEMPORAIRE POUR TESTS - Jamais de limite atteinte
    return false;
    
    // LOGIQUE ORIGINALE (désactivée pour tests)
    // bool coursesLimitReached = maxCoursesPerDay != -1 && currentCoursesToday >= maxCoursesPerDay;
    // bool qcmLimitReached = maxQcmPerDay != -1 && currentQcmToday >= maxQcmPerDay;
    // return coursesLimitReached || qcmLimitReached;
  }

  bool hasReachedMonthlyLimit(int currentCoursesThisMonth, int currentQcmThisMonth) {
    // TEMPORAIRE POUR TESTS - Jamais de limite atteinte
    return false;
    
    // LOGIQUE ORIGINALE (désactivée pour tests)  
    // bool coursesLimitReached = maxCoursesPerMonth != -1 && currentCoursesThisMonth >= maxCoursesPerMonth;
    // bool qcmLimitReached = maxQcmPerMonth != -1 && currentQcmThisMonth >= maxQcmPerMonth;
    // return coursesLimitReached || qcmLimitReached;
  }

  String getDailyLimitMessage(int currentCoursesToday, int currentQcmToday) {
    if (maxCoursesPerDay == -1) return 'Cours illimités';
    int remainingCourses = maxCoursesPerDay - currentCoursesToday;
    int remainingQcm = maxQcmPerDay - currentQcmToday;
    
    if (remainingCourses <= 0) return 'Limite quotidienne de cours atteinte';
    if (remainingQcm <= 0) return 'Limite quotidienne de QCM atteinte';
    
    return 'Reste: $remainingCourses cours, $remainingQcm QCM';
  }

  List<String> getFeaturesList() {
    List<String> features = [];
    
    // Cours complets
    if (maxFullCoursesPerMonth == -1) {
      features.add('Cours complets illimités');
    } else {
      features.add('$maxFullCoursesPerMonth cours complet${maxFullCoursesPerMonth > 1 ? 's' : ''}/mois');
    }
    
    // Types de contenu
    if (canAccessVulgariseCourses) features.add('Cours vulgarisés');
    if (canAccessFicheRevision) features.add('Fiches de révision');
    if (canAccessQcm) features.add('QCM');
    
    // QCM spécifiques
    if (canAccessQcm && maxQcmPerDay > 0) {
      if (maxQcmPerDay == -1) {
        features.add('QCM illimités');
      } else {
        features.add('$maxQcmPerDay QCM/jour');
      }
    }
    
    // Autres fonctionnalités
    if (canAccessPremiumCourses) features.add('Cours premium');
    if (canAccessAdvancedQcm) features.add('QCM avancés');
    if (canDownloadPdf) features.add('Téléchargement PDF');
    if (canGenerateCustomCourses) features.add('Génération de cours');
    if (hasAdsRemoved) features.add('Sans publicité');
    if (canAccessProgressionAnalytics) features.add('Analytiques avancées');
    if (canAccessAiTutor) features.add('Tuteur personnalisé');
    if (canAccessOfflineMode) features.add('Mode hors ligne');
    
    return features;
  }
}