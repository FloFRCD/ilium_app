/// Utilitaire pour normaliser les textes saisis par l'utilisateur
/// Gère les variantes d'écriture pour matières et niveaux
class TextNormalizer {
  
  /// Normalise le nom d'une matière
  /// Ex: "maths", "Math", "MATHEMATIQUES" -> "Mathématiques"
  static String normalizeMatiere(String input) {
    if (input.trim().isEmpty) {
      return input;
    }
    
    final normalized = input.toLowerCase().trim();
    
    // Mathématiques et variantes
    if (_matchesAny(normalized, [
      'math', 'maths', 'mathématiques', 'mathematiques',
      'mathématique', 'mathematique'
    ])) {
      return 'Mathématiques';
    }
    
    // Français et variantes
    if (_matchesAny(normalized, [
      'français', 'francais', 'french', 'fran', 'littérature',
      'litterature', 'français littérature'
    ])) {
      return 'Français';
    }
    
    // Physique-Chimie et variantes
    if (_matchesAny(normalized, [
      'physique', 'chimie', 'physique-chimie', 'physique chimie',
      'pc', 'phy', 'phys', 'chimie physique'
    ])) {
      return 'Physique-Chimie';
    }
    
    // SVT et variantes
    if (_matchesAny(normalized, [
      'svt', 'biologie', 'bio', 'sciences de la vie',
      'sciences de la terre', 'sciences vie terre',
      'biologie géologie', 'biologie-géologie'
    ])) {
      return 'SVT';
    }
    
    // Histoire-Géographie et variantes
    if (_matchesAny(normalized, [
      'histoire', 'géographie', 'geographie', 'histoire-géographie',
      'histoire geographie', 'hist', 'geo', 'hist-geo', 'hg'
    ])) {
      return 'Histoire-Géographie';
    }
    
    // Anglais et variantes
    if (_matchesAny(normalized, [
      'anglais', 'english', 'ang', 'lv1', 'langue vivante 1'
    ])) {
      return 'Anglais';
    }
    
    // Espagnol et variantes
    if (_matchesAny(normalized, [
      'espagnol', 'español', 'spanish', 'esp', 'lv2'
    ])) {
      return 'Espagnol';
    }
    
    // Allemand et variantes
    if (_matchesAny(normalized, [
      'allemand', 'deutsch', 'german', 'all'
    ])) {
      return 'Allemand';
    }
    
    // Philosophie et variantes
    if (_matchesAny(normalized, [
      'philosophie', 'philo', 'philosophy'
    ])) {
      return 'Philosophie';
    }
    
    // Sciences Économiques et Sociales
    if (_matchesAny(normalized, [
      'ses', 'économie', 'economie', 'sciences économiques',
      'sciences economiques', 'sciences eco', 'eco'
    ])) {
      return 'SES';
    }
    
    // Arts plastiques
    if (_matchesAny(normalized, [
      'arts', 'arts plastiques', 'art plastique',
      'dessin', 'art', 'beaux arts'
    ])) {
      return 'Arts plastiques';
    }
    
    // Musique
    if (_matchesAny(normalized, [
      'musique', 'music', 'solfège', 'solfege'
    ])) {
      return 'Musique';
    }
    
    // EPS
    if (_matchesAny(normalized, [
      'eps', 'sport', 'éducation physique', 'education physique',
      'éducation physique et sportive'
    ])) {
      return 'EPS';
    }
    
    // Informatique
    if (_matchesAny(normalized, [
      'informatique', 'info', 'nsi', 'numérique',
      'numerique', 'programmation', 'coding'
    ])) {
      return 'NSI';
    }
    
    // Si aucune correspondance, retourner avec première lettre en majuscule
    return input.trim().split(' ')
        .map((word) => word.isEmpty ? '' : 
             word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
  
  /// Normalise le niveau scolaire
  /// Ex: "6eme", "sixieme", "6 ème" -> "6ème"
  static String normalizeNiveau(String input) {
    if (input.trim().isEmpty) {
      return input;
    }
    
    final originalNormalized = input.toLowerCase().trim();
    final normalized = originalNormalized
        .replaceAll('è', 'e')  // è -> e pour comparaisons
        .replaceAll('ème', 'eme'); // normaliser les accents
    
    // Classes primaires
    if (_matchesAny(normalized, ['cp'])) {
      return 'CP';
    }
    if (_matchesAny(normalized, ['ce1'])) {
      return 'CE1';
    }
    if (_matchesAny(normalized, ['ce2'])) {
      return 'CE2';
    }
    if (_matchesAny(normalized, ['cm1'])) {
      return 'CM1';
    }
    if (_matchesAny(normalized, ['cm2'])) {
      return 'CM2';
    }
    
    // Collège
    if (_matchesAny(normalized, [
      '6', '6eme', 'sixieme', 'sixth'
    ])) {
      return '6ème';
    }
    
    if (_matchesAny(normalized, [
      '5', '5eme', 'cinquieme', 'fifth'
    ])) {
      return '5ème';
    }
    
    if (_matchesAny(normalized, [
      '4', '4eme', 'quatrieme', 'fourth'
    ])) {
      return '4ème';
    }
    
    if (_matchesAny(normalized, [
      '3', '3eme', 'troisieme', 'third'
    ])) {
      return '3ème';
    }
    
    // Lycée
    if (_matchesAny(normalized, [
      '2nde', '2nd', 'seconde', 'second'
    ])) {
      return '2nde';
    }
    
    // Gestion des filières spécialisées Première
    if (_containsAny(originalNormalized, ['1ere', '1er', '1re', 'premiere']) &&
        _containsAny(originalNormalized, ['stmg', 'gestion', 'mercatique'])) {
      return '1ère STMG';
    }
    if (_containsAny(originalNormalized, ['1ere', '1er', '1re', 'premiere']) &&
        _containsAny(originalNormalized, ['sti2d', 'industriel', 'developpement'])) {
      return '1ère STI2D';
    }
    
    // Première générique
    if (_matchesAny(normalized, [
      '1ere', '1er', '1re', 'premiere', 'first'
    ])) {
      return '1ère';
    }
    
    // Gestion des filières spécialisées Terminale
    if (_containsAny(originalNormalized, ['terminale', 'term', 'tle']) &&
        _containsAny(originalNormalized, ['stmg', 'gestion', 'mercatique'])) {
      return 'Terminale STMG';
    }
    if (_containsAny(originalNormalized, ['terminale', 'term', 'tle']) &&
        _containsAny(originalNormalized, ['sti2d', 'industriel', 'developpement'])) {
      return 'Terminale STI2D';
    }
    
    // Terminale générique
    if (_matchesAny(normalized, [
      'terminale', 'term', 'tle'
    ])) {
      return 'Terminale';
    }
    
    // Post-bac
    if (_containsAny(originalNormalized, ['l1', 'licence 1', 'licence1', 'licence', 'university'])) {
      return 'L1';
    }
    if (_containsAny(originalNormalized, ['l2', 'licence 2', 'licence2'])) {
      return 'L2';
    }
    if (_containsAny(originalNormalized, ['l3', 'licence 3', 'licence3'])) {
      return 'L3';
    }
    if (_containsAny(originalNormalized, ['m1', 'master 1', 'master1', 'master'])) {
      return 'M1';
    }
    if (_containsAny(originalNormalized, ['m2', 'master 2', 'master2'])) {
      return 'M2';
    }
    if (_containsAny(originalNormalized, ['bts'])) {
      return 'BTS';
    }
    if (_containsAny(originalNormalized, ['dut', 'iut'])) {
      return 'DUT';
    }
    
    // Si aucune correspondance, retourner avec première lettre en majuscule
    return input.trim().split(' ')
        .map((word) => word.isEmpty ? '' : 
             word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
  
  /// Vérifie si le texte correspond exactement à une des options
  static bool _matchesAny(String text, List<String> options) {
    return options.any((option) => text == option);
  }
  
  /// Vérifie si le texte contient une des options
  static bool _containsAny(String text, List<String> options) {
    return options.any((option) => text.contains(option));
  }
  
}