import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/ai_basic_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';

/// Écran d'inscription conversationnelle avec IA
/// Remplace le formulaire classique par une discussion guidée
class AIRegistrationChatScreen extends StatefulWidget {
  final String email;
  final String password;

  const AIRegistrationChatScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<AIRegistrationChatScreen> createState() => _AIRegistrationChatScreenState();
}

class _AIRegistrationChatScreenState extends State<AIRegistrationChatScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final AIBasicService _aiBasicService = AIBasicService();

  final List<ChatMessage> _messages = [];
  String _currentStep = 'niveau';
  bool _isLoading = false;
  bool _isProcessing = false;
  
  // Données collectées
  String? _niveau;
  List<String> _specialites = [];
  String? _pseudo;

  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    
    // Message de bienvenue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMessage(
        ChatMessage(
          text: "Salut ! 👋 Je suis ton assistant pour créer ton profil Ilium. Pour commencer, quel est ton niveau scolaire actuel ?",
          isBot: true,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty || _isProcessing) return;

    _messageController.clear();
    
    // Ajouter le message de l'utilisateur
    _addMessage(ChatMessage(
      text: message,
      isBot: false,
      timestamp: DateTime.now(),
    ));

    setState(() {
      _isProcessing = true;
    });

    try {
      await _processUserMessage(message);
    } catch (e) {
      _addMessage(ChatMessage(
        text: "Désolé, j'ai eu un petit problème. Peux-tu répéter s'il te plaît ?",
        isBot: true,
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _processUserMessage(String message) async {
    switch (_currentStep) {
      case 'niveau':
        await _processNiveau(message);
        break;
      case 'specialites':
        await _processSpecialites(message);
        break;
      case 'pseudo':
        await _processPseudo(message);
        break;
    }
  }

  Future<void> _processNiveau(String message) async {
    // Formater le niveau avec l'IA
    String niveauFormate = await _aiBasicService.formatNiveauScolaire(message);
    _niveau = niveauFormate;

    // Générer une réponse conversationnelle
    String response = await _aiBasicService.generateConversationalResponse(
      userMessage: message,
      etapeInscription: 'niveau',
      contexte: 'Niveau formaté: $niveauFormate',
    );

    _addMessage(ChatMessage(
      text: response,
      isBot: true,
      timestamp: DateTime.now(),
    ));

    _currentStep = 'specialites';
  }

  Future<void> _processSpecialites(String message) async {
    // Parser les spécialités mentionnées
    List<String> specialitesSaisies = message
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.length > 2)
        .toList();

    // Formater avec l'IA
    if (specialitesSaisies.isNotEmpty) {
      List<String> specialitesFormatees = await _aiBasicService.formatSpecialites(
        specialitesSaisies,
        _niveau!,
      );
      _specialites = specialitesFormatees;
    }

    String response = await _aiBasicService.generateConversationalResponse(
      userMessage: message,
      etapeInscription: 'specialites',
      contexte: 'Spécialités: ${_specialites.join(', ')}',
    );

    _addMessage(ChatMessage(
      text: response,
      isBot: true,
      timestamp: DateTime.now(),
    ));

    _currentStep = 'pseudo';
  }

  Future<void> _processPseudo(String message) async {
    // Valider le pseudo avec l'IA
    String pseudoValide = await _aiBasicService.validateAndSuggestPseudo(message);
    _pseudo = pseudoValide;

    // Message de confirmation
    String response = await _aiBasicService.generateConversationalResponse(
      userMessage: message,
      etapeInscription: 'pseudo',
      contexte: 'Pseudo validé: $pseudoValide',
    );

    _addMessage(ChatMessage(
      text: response,
      isBot: true,
      timestamp: DateTime.now(),
    ));

    // Finaliser l'inscription
    await _completeRegistration();
  }

  Future<void> _completeRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.registerWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
        pseudo: _pseudo!,
        niveau: _niveau!,
        options: _specialites,
      );

      if (result.isSuccess && result.user != null) {
        // Message de bienvenue personnalisé
        String welcomeMessage = await _aiBasicService.generateWelcomeMessage(
          pseudo: _pseudo!,
          niveau: _niveau!,
          specialities: _specialites,
        );

        _addMessage(ChatMessage(
          text: welcomeMessage,
          isBot: true,
          timestamp: DateTime.now(),
        ));

        // Navigation après un délai
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => MainNavigationScreen(user: result.user!),
              ),
              (route) => false,
            );
          }
        });
      } else {
        _addMessage(ChatMessage(
          text: "Oups ! Il y a eu un problème lors de la création de ton compte. Peux-tu réessayer ?",
          isBot: true,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _addMessage(ChatMessage(
        text: "Une erreur s'est produite. Vérifie ta connexion et réessaie.",
        isBot: true,
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.secondary.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildChatArea()),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assistant Ilium',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Configuration de ton profil',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _messages.length + (_isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isProcessing) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: 
            message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: message.isBot ? AppColors.grey100 : AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
                  bottomLeft: message.isBot 
                      ? const Radius.circular(4) 
                      : const Radius.circular(AppRadius.lg),
                  bottomRight: message.isBot 
                      ? const Radius.circular(AppRadius.lg)
                      : const Radius.circular(4),
                ),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.body.copyWith(
                  color: message.isBot ? AppColors.grey800 : Colors.white,
                ),
              ),
            ),
          ),
          if (!message.isBot) ...[
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    double opacity = (0.4 + 
                        0.6 * (((_typingAnimationController.value * 3) - index).clamp(0, 1) * 
                        (1 - ((_typingAnimationController.value * 3) - index - 1).clamp(0, 1)))).clamp(0, 1);
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.grey400.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200,
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isLoading && !_isProcessing,
              decoration: InputDecoration(
                hintText: _getInputHint(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.grey100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              onPressed: _isLoading || _isProcessing ? null : _sendMessage,
              icon: _isLoading 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInputHint() {
    switch (_currentStep) {
      case 'niveau':
        return 'Ex: Terminale, 1ère, 2nde...';
      case 'specialites':
        return 'Ex: Maths, Physique, SVT...';
      case 'pseudo':
        return 'Choisis ton pseudo...';
      default:
        return 'Tape ton message...';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
  });
}