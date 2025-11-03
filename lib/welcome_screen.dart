import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'style_guide.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const String _welcomeScreenKey = 'show_welcome_screen';
  static const String _lastUserKey = 'welcome_last_user';

  /// Método estático para verificar se deve mostrar a tela de boas-vindas
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Obtém o ID do usuário atual (se autenticado)
    final currentUserId = await _getCurrentUserId();
    
    // Verifica se este usuário marcou "Não mostrar novamente"
    final userKey = '${_welcomeScreenKey}_$currentUserId';
    final permanentlyHidden = prefs.getBool(userKey) ?? false;
    
    // Só não mostra se marcou permanentemente
    return !permanentlyHidden;
  }
  
  /// Obtém o ID do usuário atual (autenticado ou "guest")
  static Future<String> _getCurrentUserId() async {
    // Tenta importar Firebase Auth dinamicamente
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user?.uid ?? 'guest';
    } catch (e) {
      return 'guest';
    }
  }
  
  /// Este método não é mais necessário mas mantido para compatibilidade
  static Future<void> resetSessionFlag() async {
    // Não faz nada - a lógica agora é mais simples
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = await WelcomeScreen._getCurrentUserId();
    
    if (_dontShowAgain) {
      // Se marcou "Não mostrar novamente", salva permanentemente para este usuário
      final userKey = '${WelcomeScreen._welcomeScreenKey}_$currentUserId';
      await prefs.setBool(userKey, true);
    }
    // Se não marcou, não salva nada - a tela aparecerá novamente
    
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  bool _isPortuguese() {
    return Localizations.localeOf(context).languageCode == 'pt';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header com logo
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'MOSAICO',
                style: AppStyles.title(context).copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                ),
              ),
            ),

            // Páginas de conteúdo
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Página 1: Bem-vindo
                  _buildWelcomePage(isDarkMode, textColor, cardColor),
                  
                  // Página 2: Como jogar
                  _buildHowToPlayPage(isDarkMode, textColor, cardColor),
                  
                  // Página 3: Recursos
                  _buildFeaturesPage(isDarkMode, textColor, cardColor),
                ],
              ),
            ),

            // Indicadores de página
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: _currentPage == index ? 24.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? (isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197))
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              ),
            ),

            // Checkbox "Não mostrar novamente"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    onChanged: (value) {
                      setState(() {
                        _dontShowAgain = value ?? false;
                      });
                    },
                    activeColor: isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197),
                  ),
                  Flexible(
                    child: Text(
                      _isPortuguese() ? 'Não mostrar novamente' : 'Don\'t show again',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Botões de navegação
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão Pular (apenas se não for a última página)
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _finishWelcome,
                      child: Text(
                        _isPortuguese() ? 'Pular' : 'Skip',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Botão Próximo ou Começar
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishWelcome();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      _currentPage < 2
                          ? (_isPortuguese() ? 'Próximo' : 'Next')
                          : (_isPortuguese() ? 'Começar' : 'Start'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildWelcomePage(bool isDarkMode, Color textColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone grande
          SizedBox(
            width: 120,
            height: 120,
            child: Image.asset(
              'assets/images/icon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),

          // Título
          Text(
            _isPortuguese() ? 'Bem-vindo ao Mosaico!' : 'Welcome to Mosaico!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Descrição
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _isPortuguese()
                    ? 'Um tributo à arte dos azulejos em Portugal'
                    : 'A tribute to the art of Portuguese tiles',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recursos principais
          _buildFeatureItem(
            Icons.lock_open,
            _isPortuguese() ? 'Progressão de Puzzles' : 'Puzzle Progression',
            _isPortuguese() ? 'Complete puzzles para desbloquear os próximos' : 'Complete puzzles to unlock the next ones',
            isDarkMode,
            textColor,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Icons.emoji_events,
            _isPortuguese() ? 'Sistema de Ranking' : 'Ranking System',
            _isPortuguese() ? 'Compare seus tempos com outros jogadores' : 'Compare your times with other players',
            isDarkMode,
            textColor,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Icons.dark_mode,
            _isPortuguese() ? 'Tema Personalizável' : 'Customizable Theme',
            _isPortuguese() ? 'Modo claro e escuro disponível' : 'Light and dark mode available',
            isDarkMode,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayPage(bool isDarkMode, Color textColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Ícone
          Icon(
            Icons.help_outline,
            size: 80,
            color: isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            _isPortuguese() ? 'Como Jogar' : 'How to Play',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Instruções passo a passo
          _buildInstructionCard(
            null,
            _isPortuguese() ? 'Comece pelo Primeiro Puzzle' : 'Start with the First Puzzle',
            _isPortuguese()
                ? 'Clique em JOGAR para começar. Novos puzzles são desbloqueados ao completar os anteriores.'
                : 'Click PLAY to start. New puzzles are unlocked by completing previous ones.',
            Icons.play_circle_outline,
            isDarkMode,
            textColor,
            cardColor,
          ),
          const SizedBox(height: 16),

          _buildInstructionCard(
            null,
            _isPortuguese() ? 'Arraste as Peças' : 'Drag the Pieces',
            _isPortuguese()
                ? 'Arraste e solte as peças para reorganizar o mosaico. Use a imagem de referência como guia.'
                : 'Drag and drop pieces to rearrange the mosaic. Use the reference image as a guide.',
            Icons.touch_app,
            isDarkMode,
            textColor,
            cardColor,
          ),
          const SizedBox(height: 16),

          _buildInstructionCard(
            null,
            _isPortuguese() ? 'Complete e Desbloqueie' : 'Complete and Unlock',
            _isPortuguese()
                ? 'Quando todas as peças estiverem corretas, você vence e desbloqueia o próximo puzzle!'
                : 'When all pieces are correct, you win and unlock the next puzzle!',
            Icons.check_circle,
            isDarkMode,
            textColor,
            cardColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(bool isDarkMode, Color textColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Ícone
          Icon(
            Icons.star_outline,
            size: 80,
            color: isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            _isPortuguese() ? 'Recursos Especiais' : 'Special Features',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Lista de recursos
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildFeatureRow(
                    Icons.timer,
                    _isPortuguese() ? 'Cronômetro' : 'Timer',
                    _isPortuguese()
                        ? 'Acompanhe seu tempo e tente melhorar seus recordes.'
                        : 'Track your time and try to improve your records.',
                    isDarkMode,
                    textColor,
                  ),
                  const Divider(height: 24),
                  _buildFeatureRow(
                    Icons.visibility,
                    _isPortuguese() ? 'Imagem de Referência' : 'Reference Image',
                    _isPortuguese()
                        ? 'Veja a imagem completa antes de começar ou durante o jogo.'
                        : 'See the complete image before starting or during the game.',
                    isDarkMode,
                    textColor,
                  ),
                  const Divider(height: 24),
                  _buildFeatureRow(
                    Icons.stars,
                    _isPortuguese() ? 'Sistema de Progresso' : 'Progress System',
                    _isPortuguese()
                        ? 'Desbloqueie novos puzzles conforme avança no jogo.'
                        : 'Unlock new puzzles as you progress through the game.',
                    isDarkMode,
                    textColor,
                  ),
                  const Divider(height: 24),
                  _buildFeatureRow(
                    Icons.emoji_events,
                    _isPortuguese() ? 'Ranking Global' : 'Global Ranking',
                    _isPortuguese()
                        ? 'Faça login para salvar seus tempos e competir com outros jogadores.'
                        : 'Log in to save your times and compete with other players.',
                    isDarkMode,
                    textColor,
                  ),
                  const Divider(height: 24),
                  _buildFeatureRow(
                    Icons.volume_up,
                    _isPortuguese() ? 'Efeitos Sonoros' : 'Sound Effects',
                    _isPortuguese()
                        ? 'Ative ou desative os sons nas configurações.'
                        : 'Enable or disable sounds in settings.',
                    isDarkMode,
                    textColor,
                  ),
                  const Divider(height: 24),
                  _buildFeatureRow(
                    Icons.language,
                    _isPortuguese() ? 'Múltiplos Idiomas' : 'Multiple Languages',
                    _isPortuguese()
                        ? 'Disponível em Português e Inglês.'
                        : 'Available in Portuguese and English.',
                    isDarkMode,
                    textColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mensagem final
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isPortuguese()
                        ? 'Dica: Faça login para desbloquear todos os recursos e salvar seu progresso!'
                        : 'Tip: Log in to unlock all features and save your progress!',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, bool isDarkMode, Color textColor) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard(
    String? number,
    String title,
    String description,
    IconData icon,
    bool isDarkMode,
    Color textColor,
    Color cardColor,
  ) {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone
            Icon(
              icon,
              size: 40,
              color: isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197),
            ),
            const SizedBox(width: 16),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                      height: 1.4,
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

  Widget _buildFeatureRow(IconData icon, String title, String description, bool isDarkMode, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197),
          size: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withOpacity(0.7),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
