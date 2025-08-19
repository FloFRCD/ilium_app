import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/general_qcm_model.dart';
import '../models/qcm_model.dart';
import '../services/general_qcm_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../widgets/profile_avatar.dart';
import 'qcm_screen.dart';

/// Écran principal pour les QCM généraux adaptatifs
class GeneralQCMScreen extends StatefulWidget {
  final UserModel user;

  const GeneralQCMScreen({super.key, required this.user});

  @override
  State<GeneralQCMScreen> createState() => _GeneralQCMScreenState();
}

class _GeneralQCMScreenState extends State<GeneralQCMScreen>
    with SingleTickerProviderStateMixin {
  final GeneralQCMService _qcmService = GeneralQCMService();
  late TabController _tabController;

  List<GeneralQCMModel> _recommendedQCMs = [];
  List<Map<String, dynamic>> _qcmHistory = [];
  Map<String, dynamic> _userStats = {};
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Charger toutes les données en parallèle
      final results = await Future.wait([
        _qcmService.getRecommendedQCMs(user: widget.user),
        _qcmService.getQCMHistory(userId: widget.user.uid),
        _qcmService.getUserQCMStats(widget.user.uid),
      ]);

      if (mounted) {
        setState(() {
          _recommendedQCMs = results[0] as List<GeneralQCMModel>;
          _qcmHistory = results[1] as List<Map<String, dynamic>>;
          _userStats = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erreur chargement données QCM: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startQCM(GeneralQCMModel generalQCM) async {
    setState(() => _isGenerating = true);

    try {
      // Convertir en QCMModel pour compatibilité avec QCMScreen
      QCMModel qcm = generalQCM.toQCMModel();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QCMScreen(
            qcm: qcm,
            user: widget.user,
            matiere: generalQCM.matieresDescription,
          ),
        ),
      ).then((_) {
        // Recharger les données après le QCM
        _loadData();
      });
    } catch (e) {
      Logger.error('Erreur démarrage QCM: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du démarrage du QCM: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateNewQCM() async {
    // Afficher dialog de sélection de difficulté
    QCMDifficulty? selectedDifficulty = await _showDifficultyDialog();
    if (selectedDifficulty == null) return;

    setState(() => _isGenerating = true);

    try {
      // Obtenir les matières de l'utilisateur
      List<String> userMatieres = _getUserSubjects();
      List<String>? userOptions = _getUserOptions();

      GeneralQCMModel? newQCM = await _qcmService.generateGeneralQCM(
        niveau: widget.user.niveau,
        matieres: userMatieres,
        options: userOptions,
        difficulty: selectedDifficulty,
      );

      if (newQCM != null && mounted) {
        await _startQCM(newQCM);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de générer un nouveau QCM pour le moment'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      Logger.error('Erreur génération QCM: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur génération QCM: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecommendedTab(),
                  _buildHistoryTab(),
                  _buildStatsTab(),
                ],
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('QCM Généraux'),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Icon(
                  Icons.quiz,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                top: 80,
                right: 20,
                child: ProfileAvatar(
                  user: widget.user,
                  radius: 30,
                  showBorder: true,
                  borderColor: Colors.white,
                ),
              ),
              Positioned(
                top: 80,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.niveau,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getUserSubjects().length > 3
                          ? '${_getUserSubjects().take(3).join(', ')}...'
                          : _getUserSubjects().join(', '),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.recommend), text: 'Recommandés'),
          Tab(icon: Icon(Icons.history), text: 'Historique'),
          Tab(icon: Icon(Icons.analytics), text: 'Stats'),
        ],
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        indicatorColor: Colors.white,
      ),
    );
  }

  Widget _buildRecommendedTab() {
    if (_recommendedQCMs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.quiz,
        title: 'Aucun QCM disponible',
        subtitle: 'Générez votre premier QCM adapté à votre niveau',
        actionText: 'Générer un QCM',
        onAction: _generateNewQCM,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recommendedQCMs.length,
        itemBuilder: (context, index) {
          final qcm = _recommendedQCMs[index];
          return _buildQCMCard(qcm);
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_qcmHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'Aucun historique',
        subtitle: 'Vos QCM terminés apparaîtront ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _qcmHistory.length,
      itemBuilder: (context, index) {
        final historyItem = _qcmHistory[index];
        return _buildHistoryCard(historyItem);
      },
    );
  }

  Widget _buildStatsTab() {
    if (_userStats.isEmpty || _userStats['totalAttempts'] == 0) {
      return _buildEmptyState(
        icon: Icons.analytics,
        title: 'Aucune statistique',
        subtitle: 'Terminez des QCM pour voir vos statistiques',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsOverview(),
          const SizedBox(height: 16),
          _buildAchievements(),
        ],
      ),
    );
  }

  Widget _buildQCMCard(GeneralQCMModel qcm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _startQCM(qcm),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      qcm.titre,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(qcm.difficulty).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getDifficultyColor(qcm.difficulty)),
                    ),
                    child: Text(
                      qcm.difficulty.name.toUpperCase(),
                      style: TextStyle(
                        color: _getDifficultyColor(qcm.difficulty),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Matières: ${qcm.matieresDescription}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.greyMedium,
                ),
              ),
              if (qcm.optionsDescription != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Options: ${qcm.optionsDescription}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.greyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.quiz, size: 16, color: AppColors.greyMedium),
                  const SizedBox(width: 4),
                  Text(
                    '${qcm.questions.length} questions',
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  Icon(Icons.track_changes, size: 16, color: AppColors.greyMedium),
                  const SizedBox(width: 4),
                  Text(
                    'Objectif: ${qcm.minimumSuccessRate}%',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> historyItem) {
    final percentage = historyItem['percentage']?.toDouble() ?? 0.0;
    final passed = historyItem['passed'] ?? false;
    final completedAt = historyItem['completedAt']?.toDate() ?? DateTime.now();
    final qcmDetails = historyItem['qcmDetails'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: passed ? AppColors.success : AppColors.error,
          child: Icon(
            passed ? Icons.check : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(
          qcmDetails?['titre'] ?? 'QCM Général',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${percentage.toStringAsFixed(1)}% • ${historyItem['correctAnswers']}/${historyItem['totalQuestions']}',
              style: AppTextStyles.caption,
            ),
            Text(
              _formatDate(completedAt),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.greyMedium,
              ),
            ),
          ],
        ),
        trailing: historyItem['xpAwarded'] == true
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '+10 XP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Statistiques Générales',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'QCM Terminés',
                    _userStats['totalAttempts'].toString(),
                    Icons.quiz,
                    AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Taux de Réussite',
                    '${_userStats['successRate']?.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Score Moyen',
                    '${_userStats['averageScore']?.toStringAsFixed(1)}%',
                    Icons.analytics,
                    AppColors.accent1,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Meilleur Score',
                    '${_userStats['bestScore']?.toStringAsFixed(1)}%',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.greyMedium,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    int totalAttempts = _userStats['totalAttempts'] ?? 0;
    int totalPassed = _userStats['totalPassed'] ?? 0;
    double bestScore = _userStats['bestScore'] ?? 0.0;

    List<Map<String, dynamic>> achievements = [
      {
        'title': 'Premier QCM',
        'description': 'Terminer votre premier QCM',
        'unlocked': totalAttempts >= 1,
        'icon': Icons.play_arrow,
      },
      {
        'title': 'Habitué',
        'description': 'Terminer 5 QCM',
        'unlocked': totalAttempts >= 5,
        'icon': Icons.fitness_center,
      },
      {
        'title': 'Expert',
        'description': 'Obtenir 90% ou plus',
        'unlocked': bestScore >= 90.0,
        'icon': Icons.school,
      },
      {
        'title': 'Perfectionniste',
        'description': 'Réussir 10 QCM',
        'unlocked': totalPassed >= 10,
        'icon': Icons.emoji_events,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Succès',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...achievements.map((achievement) => _buildAchievementItem(achievement)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    bool unlocked = achievement['unlocked'] as bool;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: unlocked ? Colors.amber : AppColors.greyLight,
            child: Icon(
              achievement['icon'] as IconData,
              color: unlocked ? Colors.white : AppColors.greyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'] as String,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unlocked ? AppColors.black : AppColors.greyMedium,
                  ),
                ),
                Text(
                  achievement['description'] as String,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.greyMedium,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(
              Icons.check_circle,
              color: Colors.amber,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.greyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.greyDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(
                color: AppColors.greyMedium,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _isGenerating ? null : _generateNewQCM,
      icon: _isGenerating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(_isGenerating ? 'Génération...' : 'Nouveau QCM'),
      backgroundColor: AppColors.accent1,
      foregroundColor: Colors.white,
    );
  }

  Future<QCMDifficulty?> _showDifficultyDialog() async {
    return showDialog<QCMDifficulty>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la difficulté'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: QCMDifficulty.values
              .map((difficulty) => ListTile(
                    title: Text(_getDifficultyLabel(difficulty)),
                    subtitle: Text(_getDifficultyDescription(difficulty)),
                    leading: Icon(
                      Icons.circle,
                      color: _getDifficultyColor(difficulty),
                    ),
                    onTap: () => Navigator.of(context).pop(difficulty),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // Méthodes utilitaires
  List<String> _getUserSubjects() {
    Map<String, List<String>> standardSubjects = {
      'CP': ['Français', 'Mathématiques'],
      'CE1': ['Français', 'Mathématiques'],
      'CE2': ['Français', 'Mathématiques', 'Sciences'],
      'CM1': ['Français', 'Mathématiques', 'Sciences', 'Histoire-Géographie'],
      'CM2': ['Français', 'Mathématiques', 'Sciences', 'Histoire-Géographie'],
      '6ème': ['Français', 'Mathématiques', 'Histoire-Géographie', 'SVT', 'Anglais'],
      '5ème': ['Français', 'Mathématiques', 'Histoire-Géographie', 'SVT', 'Physique-Chimie', 'Anglais'],
      '4ème': ['Français', 'Mathématiques', 'Histoire-Géographie', 'SVT', 'Physique-Chimie', 'Anglais'],
      '3ème': ['Français', 'Mathématiques', 'Histoire-Géographie', 'SVT', 'Physique-Chimie', 'Anglais'],
      'Seconde': ['Français', 'Mathématiques', 'Histoire-Géographie', 'SVT', 'Physique-Chimie', 'Anglais'],
      'Première': ['Français', 'Histoire-Géographie', 'Anglais'],
      'Terminale': ['Philosophie', 'Histoire-Géographie', 'Anglais'],
    };

    return standardSubjects[widget.user.niveau] ?? ['Français', 'Mathématiques'];
  }

  List<String>? _getUserOptions() {
    return widget.user.preferences['options'] as List<String>?;
  }

  Color _getDifficultyColor(QCMDifficulty difficulty) {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return AppColors.success;
      case QCMDifficulty.moyen:
        return AppColors.warning;
      case QCMDifficulty.difficile:
        return AppColors.error;
      case QCMDifficulty.tresDifficile:
        return AppColors.black;
    }
  }

  String _getDifficultyLabel(QCMDifficulty difficulty) {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return 'Facile';
      case QCMDifficulty.moyen:
        return 'Moyen';
      case QCMDifficulty.difficile:
        return 'Difficile';
      case QCMDifficulty.tresDifficile:
        return 'Très Difficile';
    }
  }

  String _getDifficultyDescription(QCMDifficulty difficulty) {
    switch (difficulty) {
      case QCMDifficulty.facile:
        return 'Questions de base, concepts fondamentaux';
      case QCMDifficulty.moyen:
        return 'Questions standards du niveau';
      case QCMDifficulty.difficile:
        return 'Questions avancées, applications';
      case QCMDifficulty.tresDifficile:
        return 'Questions expertes, analyses approfondies';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}