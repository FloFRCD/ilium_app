import 'dart:async';
import 'package:flutter/material.dart';
import '../models/qcm_model.dart';
import '../models/user_model.dart';
import '../services/user_progression_service.dart';
import '../services/anti_gaming_service.dart';
import '../services/general_qcm_service.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';

class QCMScreen extends StatefulWidget {
  final QCMModel qcm;
  final UserModel user;
  final String matiere;

  const QCMScreen({
    super.key,
    required this.qcm,
    required this.user,
    required this.matiere,
  });

  @override
  State<QCMScreen> createState() => _QCMScreenState();
}

class _QCMScreenState extends State<QCMScreen> {
  final UserProgressionService _progressionService = UserProgressionService();
  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  bool _showResults = false;
  bool _isAnswered = false;
  
  // Variables anti-gaming
  DateTime? _qcmStartTime;
  DateTime? _currentQuestionStartTime;
  List<int> _questionTimeSeconds = []; // Temps passé sur chaque question
  Timer? _timeTracker;
  int _totalActiveTimeSeconds = 0;
  DateTime? _lastActiveTime;
  
  // Constantes de validation anti-gaming  
  static const int _minimumTotalTime = 30; // 30 secondes minimum au total

  @override
  void initState() {
    super.initState();
    _userAnswers = List.filled(widget.qcm.questions.length, null);
    _questionTimeSeconds = List.filled(widget.qcm.questions.length, 0);
    _startQCMTracking();
  }
  
  @override
  void dispose() {
    _timeTracker?.cancel();
    super.dispose();
  }
  
  void _startQCMTracking() {
    _qcmStartTime = DateTime.now();
    _currentQuestionStartTime = DateTime.now();
    _lastActiveTime = DateTime.now();
    
    // Timer qui s'exécute toutes les secondes pour tracker le temps actif
    _timeTracker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      
      // Si l'utilisateur a été actif dans les 10 dernières secondes
      if (_lastActiveTime != null && 
          now.difference(_lastActiveTime!).inSeconds <= 10) {
        _totalActiveTimeSeconds++;
        
        // Ajouter du temps à la question courante
        if (_currentQuestionStartTime != null) {
          _questionTimeSeconds[_currentQuestionIndex]++;
        }
      }
    });
  }
  
  void _markUserActive() {
    _lastActiveTime = DateTime.now();
  }
  
  /// Valide si l'utilisateur peut obtenir l'XP (validation anti-gaming)
  bool _canAwardXP() {
    final totalRealTime = _qcmStartTime != null 
        ? DateTime.now().difference(_qcmStartTime!).inSeconds 
        : _totalActiveTimeSeconds;
    final engagementRate = totalRealTime > 0 ? _totalActiveTimeSeconds / totalRealTime : 0.0;
    
    final validation = AntiGamingService.validateActivity(
      activityType: 'qcm_completion',
      totalTimeSeconds: _totalActiveTimeSeconds,
      minimumTimeRequired: _minimumTotalTime,
      additionalData: {
        'questionTimesSeconds': _questionTimeSeconds,
        'engagementRate': engagementRate,
      },
    );
    
    return validation.isValid;
  }
  
  /// Retourne le message expliquant pourquoi l'XP ne peut pas être accordé
  String _getXPBlockReason() {
    final totalRealTime = _qcmStartTime != null 
        ? DateTime.now().difference(_qcmStartTime!).inSeconds 
        : _totalActiveTimeSeconds;
    final engagementRate = totalRealTime > 0 ? _totalActiveTimeSeconds / totalRealTime : 0.0;
    
    final validation = AntiGamingService.validateActivity(
      activityType: 'qcm_completion',
      totalTimeSeconds: _totalActiveTimeSeconds,
      minimumTimeRequired: _minimumTotalTime,
      additionalData: {
        'questionTimesSeconds': _questionTimeSeconds,
        'engagementRate': engagementRate,
      },
    );
    
    return validation.primaryReason;
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.qcm.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentQuestionIndex + 1}/${widget.qcm.questions.length}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.qcm.questions.length,
            backgroundColor: AppColors.greyLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent1),
            minHeight: 6,
          ),
          Expanded(
            child: _buildQuestionCard(),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final question = widget.qcm.questions[_currentQuestionIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Difficulté et numéro
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(widget.qcm.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.qcm.difficulty.name.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Question ${_currentQuestionIndex + 1}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.greyMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Question
              Text(
                question.question,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.black,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),
              
              // Options
              ...question.options.asMap().entries.map((entry) {
                int optionIndex = entry.key;
                String optionText = entry.value;
                bool isSelected = _userAnswers[_currentQuestionIndex] == optionIndex;
                bool isCorrect = optionIndex == question.correctAnswer;
                bool showCorrection = _isAnswered && isSelected;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _isAnswered ? null : () {
                      _markUserActive();
                      _selectAnswer(optionIndex);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getOptionColor(optionIndex, isSelected, isCorrect, showCorrection),
                        border: Border.all(
                          color: _getOptionBorderColor(optionIndex, isSelected, isCorrect, showCorrection),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getOptionIconColor(optionIndex, isSelected, isCorrect, showCorrection),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + optionIndex), // A, B, C, D
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              optionText,
                              style: AppTextStyles.body.copyWith(
                                color: showCorrection 
                                    ? (isCorrect ? AppColors.success : AppColors.error)
                                    : AppColors.black,
                              ),
                            ),
                          ),
                          if (showCorrection)
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? AppColors.success : AppColors.error,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              // Explication (si répondue)
              if (_isAnswered && question.explanation.isNotEmpty) ...[
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent1.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: AppColors.accent1),
                          SizedBox(width: 8),
                          Text(
                            'Explication',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        question.explanation,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.black,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _markUserActive();
                  _previousQuestion();
                },
                icon: Icon(Icons.arrow_back),
                label: Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _canProceed() ? () {
                _markUserActive();
                _nextQuestion();
              } : null,
              icon: Icon(_isLastQuestion() ? Icons.check : Icons.arrow_forward),
              label: Text(_isLastQuestion() ? 'Terminer' : 'Suivant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent1,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    int correctAnswers = 0;
    for (int i = 0; i < widget.qcm.questions.length; i++) {
      if (_userAnswers[i] == widget.qcm.questions[i].correctAnswer) {
        correctAnswers++;
      }
    }
    
    double percentage = (correctAnswers / widget.qcm.questions.length) * 100;
    bool passed = percentage >= widget.qcm.minimumSuccessRate;
    bool canAwardXP = _canAwardXP();

    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats du QCM'),
        backgroundColor: passed ? AppColors.success : AppColors.error,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Score principal
            Card(
              elevation: 6,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                      size: 64,
                      color: passed ? AppColors.success : AppColors.error,
                    ),
                    SizedBox(height: 16),
                    Text(
                      passed ? 'Félicitations !' : 'Continuez vos efforts !',
                      style: AppTextStyles.h1.copyWith(
                        color: passed ? AppColors.success : AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: passed ? AppColors.success : AppColors.error,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$correctAnswers/${widget.qcm.questions.length} réponses correctes',
                      style: AppTextStyles.body,
                    ),
                    if (!passed) ...[
                      SizedBox(height: 8),
                      Text(
                        'Minimum requis: ${widget.qcm.minimumSuccessRate}%',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Message d'avertissement si XP non accordé à cause du système anti-gaming
            if (passed && !canAwardXP) ...[
              SizedBox(height: 16),
              Card(
                color: AppColors.warning.withValues(alpha: 0.1),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'XP non accordé',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _getXPBlockReason(),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.greyDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.home),
                    label: Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                if (!passed)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _retryQCM,
                      icon: Icon(Icons.refresh),
                      label: Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent1,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = optionIndex;
      _isAnswered = true;
    });
  }

  void _nextQuestion() {
    if (_isLastQuestion()) {
      _finishQCM();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = _userAnswers[_currentQuestionIndex] != null;
        // Démarrer le tracking pour la nouvelle question
        _currentQuestionStartTime = DateTime.now();
      });
    }
  }

  void _previousQuestion() {
    setState(() {
      _currentQuestionIndex--;
      _isAnswered = _userAnswers[_currentQuestionIndex] != null;
      // Redémarrer le tracking pour cette question
      _currentQuestionStartTime = DateTime.now();
    });
  }

  void _finishQCM() async {
    setState(() {
      _showResults = true;
    });

    // Calculer le score
    int correctAnswers = 0;
    for (int i = 0; i < widget.qcm.questions.length; i++) {
      if (_userAnswers[i] == widget.qcm.questions[i].correctAnswer) {
        correctAnswers++;
      }
    }
    
    double percentage = (correctAnswers / widget.qcm.questions.length) * 100;
    bool passed = percentage >= widget.qcm.minimumSuccessRate;
    
    // Validation anti-gaming
    bool canAwardXP = _canAwardXP();
    
    // Enregistrer la progression dans Firebase
    try {
      // Vérifier si c'est un QCM général
      bool isGeneralQCM = widget.qcm.courseId == 'general_qcm';
      
      if (isGeneralQCM) {
        // Utiliser le service QCM général
        final generalQCMService = GeneralQCMService();
        await generalQCMService.recordGeneralQCMResult(
          userId: widget.user.uid,
          qcmId: widget.qcm.id,
          percentage: percentage,
          passed: passed,
          correctAnswers: correctAnswers,
          totalQuestions: widget.qcm.questions.length,
          xpAwarded: passed && canAwardXP,
        );
      } else {
        // QCM traditionnel lié à un cours spécifique
        await _progressionService.recordQCMResult(
          widget.user.uid,
          widget.matiere,
          percentage,
          passed && canAwardXP,
        );
      }
      
      // Mettre à jour la streak de l'utilisateur seulement si validation OK
      if (canAwardXP) {
        await _progressionService.updateStreak(widget.user.uid);
      }
      
      Logger.info('Progression QCM enregistrée: ${percentage.toStringAsFixed(1)}% (${passed ? "Réussi" : "Échoué"}) - XP accordé: $canAwardXP - Temps: ${_totalActiveTimeSeconds}s');
    } catch (e) {
      Logger.error('Erreur enregistrement progression QCM', e);
      // Ne pas empêcher l'affichage des résultats même en cas d'erreur
    }
  }

  void _retryQCM() {
    // Arrêter le timer actuel
    _timeTracker?.cancel();
    
    setState(() {
      _currentQuestionIndex = 0;
      _userAnswers = List.filled(widget.qcm.questions.length, null);
      _showResults = false;
      _isAnswered = false;
      
      // Réinitialiser le système anti-gaming
      _questionTimeSeconds = List.filled(widget.qcm.questions.length, 0);
      _totalActiveTimeSeconds = 0;
    });
    
    // Redémarrer le tracking
    _startQCMTracking();
  }

  bool _canProceed() {
    return _userAnswers[_currentQuestionIndex] != null;
  }

  bool _isLastQuestion() {
    return _currentQuestionIndex == widget.qcm.questions.length - 1;
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

  Color _getOptionColor(int optionIndex, bool isSelected, bool isCorrect, bool showCorrection) {
    if (!showCorrection) {
      return isSelected ? AppColors.accent1.withValues(alpha: 0.1) : Colors.white;
    }
    
    if (isSelected) {
      return isCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1);
    }
    
    return Colors.white;
  }

  Color _getOptionBorderColor(int optionIndex, bool isSelected, bool isCorrect, bool showCorrection) {
    if (!showCorrection) {
      return isSelected ? AppColors.accent1 : AppColors.greyLight;
    }
    
    if (isSelected) {
      return isCorrect ? AppColors.success : AppColors.error;
    }
    
    return AppColors.greyLight;
  }

  Color _getOptionIconColor(int optionIndex, bool isSelected, bool isCorrect, bool showCorrection) {
    if (!showCorrection) {
      return isSelected ? AppColors.accent1 : AppColors.greyMedium;
    }
    
    if (isSelected) {
      return isCorrect ? AppColors.success : AppColors.error;
    }
    
    return AppColors.greyMedium;
  }
}