import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'enhanced_courses_screen.dart';

class CoursesCatalogScreen extends StatefulWidget {
  final UserModel user;

  const CoursesCatalogScreen({super.key, required this.user});

  @override
  State<CoursesCatalogScreen> createState() => _CoursesCatalogScreenState();
}

class _CoursesCatalogScreenState extends State<CoursesCatalogScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  
  late TabController _tabController;




  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCourses() async {

    try {
      // Récupérer les cours depuis Firebase
      List<CourseModel> courses = await _firestoreService.getCourses(limit: 100);
      
      
      if (courses.isEmpty) {
        // Suggérer de générer du contenu
        _showEmptyStateMessage();
      }
    } catch (e) {
      debugPrint('Erreur chargement catalogue: $e');
      _showEmptyStateMessage();
    }
  }

  void _showEmptyStateMessage() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📚 Aucun cours disponible - Recherchez un sujet pour en générer !'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Rechercher',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(); // Retour pour aller vers la recherche
              },
            ),
          ),
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: Text(
          'Cours',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          labelStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(
              icon: Icon(Icons.search, size: 20),
              text: 'Recherche',
            ),
            Tab(
              icon: Icon(Icons.school, size: 20),
              text: 'Programme',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EnhancedCoursesScreen(user: widget.user),
          EnhancedCoursesScreen(user: widget.user),
        ],
      ),
    );
  }














}