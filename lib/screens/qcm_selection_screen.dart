import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/qcm_model.dart';
import '../services/firestore_service.dart';
import '../services/qcm_service.dart';
import '../theme/app_theme.dart';
import 'qcm_screen.dart';

class QCMSelectionScreen extends StatefulWidget {
  final UserModel user;

  const QCMSelectionScreen({super.key, required this.user});

  @override
  State<QCMSelectionScreen> createState() => _QCMSelectionScreenState();
}

class _QCMSelectionScreenState extends State<QCMSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final QCMService _qcmService = QCMService();
  List<CourseModel> _availableCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableCourses();
  }

  Future<void> _loadAvailableCourses() async {
    try {
      List<CourseModel> courses = await _firestoreService.getCourses(
        niveau: widget.user.niveau,
        limit: 10,
      );
      
      setState(() {
        _availableCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startQCM(CourseModel course, QCMDifficulty difficulty) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      QCMModel? qcm = await _qcmService.getOrGenerateQCM(
        course: course,
        difficulty: difficulty,
        numberOfQuestions: 10,
      );

      // Fermer le dialog de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (qcm != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QCMScreen(
              qcm: qcm,
              user: widget.user,
              matiere: course.matiere,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de générer le QCM pour le moment'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Fermer le dialog de chargement
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si l'utilisateur peut accéder aux QCM
    bool canAccessQCM = widget.user.limitations.canAccessQcm;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un QCM'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: !canAccessQCM
          ? _buildQCMBlockedView()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _availableCourses.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun cours disponible pour votre niveau',
                        style: AppTextStyles.body,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableCourses.length,
                      itemBuilder: (context, index) {
                        final course = _availableCourses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            title: Text(
                              course.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${course.matiere} • ${course.niveau}',
                              style: AppTextStyles.caption,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Choisissez la difficulté :',
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _startQCM(course, QCMDifficulty.facile),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Facile'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _startQCM(course, QCMDifficulty.moyen),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Moyen'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _startQCM(course, QCMDifficulty.difficile),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Difficile'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildQCMBlockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QCM réservés aux membres Premium',
                    style: AppTextStyles.h2.copyWith(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Les QCM permettent de tester vos connaissances de manière interactive et sont disponibles avec l\'abonnement Premium.',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Avec Premium, vous bénéficiez de :',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.user.limitations.getFeaturesList().take(4).map((feature) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.body.copyWith(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showUpgradeDialog(),
                      icon: const Icon(Icons.star),
                      label: const Text('Découvrir Premium'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              'Passer au Premium',
              style: AppTextStyles.h3.copyWith(color: AppColors.greyDark),
            ),
          ],
        ),
        content: Text(
          'Débloquez l\'accès aux QCM et à toutes les fonctionnalités premium !',
          style: AppTextStyles.body.copyWith(color: AppColors.greyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.greyMedium),
            child: Text('Plus tard', style: AppTextStyles.body),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigation vers l'écran d'abonnement
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: Text('S\'abonner'),
          ),
        ],
      ),
    );
  }
}