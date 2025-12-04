import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'style_guide.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const String _welcomeScreenKey = 'show_welcome_screen';

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
  
  /// Permite que o usuário volte a ver o passo a passo (reset manual)
  static Future<void> resetSessionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = await _getCurrentUserId();
    final userKey = 'show_welcome_screen_$currentUserId';
    await prefs.remove(userKey);
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    _loadDontShowAgain();
    // Precarregar imagens das animações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAnimationImages();
    });
  }

  Future<void> _loadDontShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = await WelcomeScreen._getCurrentUserId();
    final userKey = '${WelcomeScreen._welcomeScreenKey}_$currentUserId';
    setState(() {
      _dontShowAgain = prefs.getBool(userKey) ?? false;
    });
  }

  void _preloadAnimationImages() {
    // Precarregar imagens do DragAnimationWidget
    precacheImage(AssetImage('assets/images/drag1.png'), context);
    precacheImage(AssetImage('assets/images/drag2.png'), context);
    precacheImage(AssetImage('assets/images/drag3.png'), context);
    precacheImage(AssetImage('assets/images/drag4.png'), context);
    precacheImage(AssetImage('assets/images/drag5.png'), context);
    // Precarregar imagens do LockAnimationWidget
    precacheImage(AssetImage('assets/images/lock1.png'), context);
    precacheImage(AssetImage('assets/images/lock2.png'), context);
    precacheImage(AssetImage('assets/images/lock3.png'), context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = await WelcomeScreen._getCurrentUserId();
    // Sempre salva o estado atual da checkbox
    final userKey = '${WelcomeScreen._welcomeScreenKey}_$currentUserId';
    await prefs.setBool(userKey, _dontShowAgain);
    if (!mounted) return;
    // Navega diretamente para HomeScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userName: 'Jogador',
          currentLevel: 1,
          maxLevel: 10,
          totalPoints: 0,
        ),
      ),
    );
  }

  bool _isPortuguese() {
    return Localizations.localeOf(context).languageCode == 'pt';
  }

  // Página 1: Bem-vindo
  Widget _buildPage1(bool isDarkMode, Color textColor, Color cardColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final imageAreaHeight = totalHeight * 0.45;
        return SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Área da imagem: top 60%
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: imageAreaHeight,
                  child: Center(
                    child: SizedBox(
                      width: imageAreaHeight * 0.6,
                      height: imageAreaHeight * 0.6,
                      child: Image.asset(
                        'assets/images/icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Área do texto: bottom 40%
                Positioned.fill(
                  top: imageAreaHeight,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      0.0,
                      24.0,
                      MediaQuery.of(context).padding.bottom + 60.0,
                    ),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
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
                        Text(
                          _isPortuguese()
                              ? 'Leia este pequeno tutorial antes de começar a jogar.\n\nO objetivo deste jogo é resolver puzzles com os mais bonitos azulejos portugueses.'
                              : 'Read this short tutorial before you start playing.\n\nThe objective of this game is to solve puzzles featuring the most beautiful Portuguese tiles (azulejos).',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                            fontStyle: FontStyle.normal,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Página 2: Como jogar
  Widget _buildPage2(bool isDarkMode, Color textColor, Color cardColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final imageAreaHeight = totalHeight * 0.45;
        final textAreaHeight = totalHeight * 0.55;
        return SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Área da imagem: top 50%
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: imageAreaHeight,
                  child: Center(
                    child: SizedBox(
                      width: imageAreaHeight,
                      height: imageAreaHeight,
                      child: Icon(
                        Icons.play_arrow,
                        size: imageAreaHeight * 0.8, // 80% do tamanho do container para margem
                        color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                      ),
                    ),
                  ),
                ),
                // Área do texto: bottom 40%
                Positioned(
                  top: imageAreaHeight,
                  left: 0,
                  right: 0,
                  height: textAreaHeight,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      0.0,
                      24.0,
                      MediaQuery.of(context).padding.bottom + 60.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          _isPortuguese() ? 'Como iniciar' : 'Getting Started',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Descrição
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 24,
                              color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                              fontStyle: FontStyle.normal,
                              height: 1.3,
                            ),
                            children: [
                              TextSpan(
                                text: _isPortuguese()
                                    ? 'Comece pelo primeiro puzzle. Memorize a imagem. Ao clicar no icon'
                                    : 'Start with the first puzzle. Memorize the image. When you click the icon',
                              ),
                              WidgetSpan(
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 35,
                                  color: isDarkMode ? Colors.amber : Colors.teal,
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              TextSpan(
                                text: _isPortuguese()
                                    ? 'a imagem irá ser misturada e o tempo começará a contar.\n'
                                    : 'the image will be scrambled and the timer will begin.\n',
                              ),
                              WidgetSpan(child: SizedBox(height: 50)),
                              WidgetSpan(
                                child: Icon(
                                  Icons.lightbulb,
                                  size: 35,
                                  color: isDarkMode ? Colors.white : Colors.red,
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              TextSpan(
                                text: _isPortuguese()
                                    ? 'Você pode pausar com o icon'
                                    : 'Você pode pausar com o icon',
                              ),
                              WidgetSpan(
                                child: Icon(
                                  Icons.pause,
                                  size: 35,
                                  color: isDarkMode ? Colors.amber : Colors.teal,
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              
                              TextSpan(
                                text: _isPortuguese()
                                    ? ', mas aí o seu tempo já não vai contar para o Ranking.'
                                    : ',but then your time won\'t count for the Ranking',
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Página 3: Arrastar
  Widget _buildPage3(bool isDarkMode, Color textColor, Color cardColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final imageAreaHeight = totalHeight * 0.45;
        final textAreaHeight = totalHeight * 0.55;
        return SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Área da imagem: top 60%
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: imageAreaHeight,
                  child: Center(
                    child: SizedBox(
                      width: imageAreaHeight * 0.6,
                      height: imageAreaHeight * 0.6,
                      child: DragAnimationWidget(),
                    ),
                  ),
                ),
                // Área do texto: bottom 40%
                Positioned(
                  top: imageAreaHeight,
                  left: 0,
                  right: 0,
                  height: textAreaHeight,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      0.0,
                      24.0,
                      MediaQuery.of(context).padding.bottom + 60.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          _isPortuguese() ? 'Arrastar e largar' : 'Drag and Drop',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isPortuguese()
                              ? 'Arraste as peças até acertar. Quando encaixar a peça no lugar certo vai ter um efeito visual e um efeito sonoro (se não quiser ouvir sons desligue nas definições).'
                              : 'Drag the pieces until they are correctly placed. When you fit a piece into the right spot, there will be a visual effect and a sound effect (if you don\'t want to hear sounds, you can turn them off in the settings).',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                            fontStyle: FontStyle.normal,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Página 4: Desbloquear
  Widget _buildPage4(
    bool isDarkMode,
    Color textColor,
    Color cardColor, ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final imageAreaHeight = totalHeight * 0.45;
        final textAreaHeight = totalHeight * 0.55;
        return SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Área da imagem: top 60%
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: imageAreaHeight,
                  child: Center(
                    child: SizedBox(
                      width: imageAreaHeight * 0.6,
                      height: imageAreaHeight * 0.6,
                      child: LockAnimationWidget(),
                    ),
                  ),
                ),
                // Área do texto: bottom 40%
                Positioned(
                  top: imageAreaHeight,
                  left: 0,
                  right: 0,
                  height: textAreaHeight,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      0.0,
                      24.0,
                      MediaQuery.of(context).padding.bottom + 60.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          _isPortuguese() ? 'Desbloquear' : 'Unblock',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 16),

                        // Descrição
                        Text(
                          _isPortuguese()
                              ? 'Complete o puzzle para desbloquear o seguinte e avançar no jogo.'
                              : 'Complete the puzzle to unlock the next one and progress in the game.',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                            fontStyle: FontStyle.normal,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 24),


                       
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Página 5: Tempo
  Widget _buildPage5(bool isDarkMode, Color textColor, Color cardColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final imageAreaHeight = totalHeight * 0.45;
        final textAreaHeight = totalHeight * 0.55;
        return SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Área da imagem: top 60%
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: imageAreaHeight,
                  child: Center(
                    child: SizedBox(
                      width: imageAreaHeight,
                      height: imageAreaHeight,
                      child: Icon(
                        Icons.access_time,
                        size: imageAreaHeight * 0.6, // 80% do tamanho do container para margem
                        color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                      ),
                    ),
                  ),
                ),
                // Área do texto: bottom 40%
                Positioned(
                  top: imageAreaHeight,
                  left: 0,
                  right: 0,
                  height: textAreaHeight,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      0.0,
                      24.0,
                      MediaQuery.of(context).padding.bottom + 16.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          _isPortuguese() ? 'Tempo' : 'Time',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isPortuguese()
                              ? 'Pode ver o cronômetro na parte superior da tela. Desafie-se a si mesmo ou compita com jogadores de todo o mundo e veja seu progresso no Ranking.'
                              : 'You can view the timer at the top of the screen. Challenge yourself or compete with players worldwide and track your progress on the Leaderboard.',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                            fontStyle: FontStyle.normal,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Página 6: Ranking
  Widget _buildPage6(bool isDarkMode, Color textColor, Color cardColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final imageAreaHeight = totalHeight * 0.45;
        final textAreaHeight = totalHeight * 0.55;
        return SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Área da imagem: top 60%
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: imageAreaHeight,
                  child: Center(
                    child: SizedBox(
                      width: imageAreaHeight,
                      height: imageAreaHeight,
                      child: Icon(
                        Icons.emoji_events,
                        size: imageAreaHeight * 0.6, // 80% do tamanho do container para margem
                        color: isDarkMode ? Colors.white :  const Color.fromARGB(255, 3, 104, 197),
                      ),
                    ),
                  ),
                ),
                // Área do texto: bottom 40%
                Positioned(
                  top: imageAreaHeight,
                  left: 0,
                  right: 0,
                  height: textAreaHeight,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      0.0,
                      24.0,
                      MediaQuery.of(context).padding.bottom + 16.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          _isPortuguese() ? 'Ranking' : 'Ranking',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isPortuguese()
                              ? 'Compita com os melhores. No Ranking pode ver os seus melhores tempos e os melhores tempos a nível global. '
                              : 'Choose between light and dark mode for a comfortable experience.',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white :  const Color.fromARGB(255, 3, 104, 197),
                            fontStyle: FontStyle.normal,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Página 7: Configurações
  Widget _buildPage7(bool isDarkMode, Color textColor, Color cardColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final imageAreaHeight = totalHeight * 0.45;
        return SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              // Área da imagem: top 50%
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: imageAreaHeight,
                child: Center(
                  child: SizedBox(
                    width: imageAreaHeight,
                    height: imageAreaHeight,
                    child: Icon(
                      Icons.menu,
                      size: imageAreaHeight * 0.6,
                      color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                    ),
                  ),
                ),
              ),
              // Área do texto: ocupa o restante espaço e é rolável
              Positioned.fill(
                top: imageAreaHeight,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24.0,
                    0.0,
                    24.0,
                    // Garante espaço extra no fundo para não ficar sob a nav bar
                    MediaQuery.of(context).padding.bottom + 60.0,
                  ),
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        _isPortuguese() ? 'Definições' : 'Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 24,
                                color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                fontStyle: FontStyle.normal,
                                height: 1.3,
                              ),
                              children: [
                                TextSpan(
                                  text: _isPortuguese()
                                      ? 'Clique no '
                                      : 'Click the ',
                                ),
                                WidgetSpan(
                                  child: Icon(
                                    Icons.menu,
                                    size: 35,
                                    color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                  ),
                                  alignment: PlaceholderAlignment.middle,
                                ),
                                TextSpan(
                                  text: _isPortuguese()
                                      ? ' para acessar ao seu perfil e a definições. Aqui pode:'
                                      : ' to access your profile and settings. Here you can:',
                                ),
                              ],
                            ),
                            textAlign: TextAlign.left,
                          ),
                           const SizedBox(height: 16),
                           // Primeira fila: Volume
                          Row(
                            children: [
                              Icon(
                                Icons.volume_up,
                                color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isPortuguese()
                                      ? 'Ativar ou desativar o som'
                                      : 'Enable or disable sound',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                    fontStyle: FontStyle.italic,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Segunda fila: Tema
                          Row(
                            children: [
                              Icon(
                                Icons.brightness_6,
                                color: isDarkMode ? Colors.white :const Color.fromARGB(255, 3, 104, 197),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isPortuguese()
                                      ? 'Escolher o modo de luz'
                                      : 'Choose the light mode',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                    fontStyle: FontStyle.italic,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Terceira fila: Idioma
                          Row(
                            children: [
                              Icon(
                                Icons.language,
                                color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isPortuguese()
                                      ? 'Selecionar o idioma'
                                      : 'Select the language',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                    fontStyle: FontStyle.italic,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Quarta fila: Username
                          Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isPortuguese()
                                      ? 'Redefinir o nome de usuário'
                                      : 'Reset username',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                    fontStyle: FontStyle.italic,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // quinta fila: ver tutorial
                          Row(
                            children: [
                              Icon(
                                Icons.help_center_outlined,
                                color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isPortuguese()
                                      ? 'Voltar a ver este tutorial'
                                      : 'Show this tutorial again',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                                    fontStyle: FontStyle.italic,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Página 8: Congrats
  Widget _buildPage8(bool isDarkMode, Color textColor, Color cardColor, {
    bool showCheckbox = false,
    bool checkboxValue = false,
    ValueChanged<bool?>? onCheckboxChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final imageAreaHeight = totalHeight * 0.45;
        final textAreaHeight = totalHeight * 0.55;
        return SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Área da imagem: top 60%
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: imageAreaHeight,
                  child: Center(
                    child: SizedBox(
                      width: imageAreaHeight,
                      height: imageAreaHeight,
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          // Build thin stripes across full 0.0–1.0 range
                          List<Color> palette = isDarkMode
                              ? [Colors.yellow, Colors.red, Colors.pinkAccent, Colors.green, Colors.amber, Colors.lightBlueAccent, Colors.purple, Colors.orange, Colors.yellow, Colors.green, Colors.blue, ]
                              : [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple];
                          // Alternate colors with repeats to make thin bands
                          final colors = <Color>[];
                          final stops = <double>[];
                          const step = 0.01; // stripe thickness (~2%)
                          double s = 0.0;
                          int i = 0;
                          while (s < 1.0 - step) {
                            final c = palette[i % palette.length];
                            colors.add(c);
                            colors.add(c);
                            stops.add(s);
                            stops.add(s + step);
                            s += step * 2; // small gap before next color pair
                            i++;
                          }
                          // Ensure last stop hits 1.0
                          if (stops.isEmpty || stops.last < 1.0) {
                            colors.add(palette[i % palette.length]);
                            stops.add(1.0);
                          }
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors,
                            stops: stops,
                            tileMode: TileMode.clamp,
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcIn,
                        child: Icon(
                          Icons.celebration,
                          size: imageAreaHeight * 0.6, // 60% do tamanho do container para margem
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Área do texto: bottom 40%
                Positioned(
                  top: imageAreaHeight,
                  left: 0,
                  right: 0,
                  height: textAreaHeight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      0.0,
                      24.0,
                      MediaQuery.of(context).padding.bottom + 16.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          _isPortuguese() ? 'Parabéns!' : 'Congratulations',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isPortuguese()
                              ? 'Tudo pronto para começar o jogo. Se não quiser ver mais este tutorial no início marque a caixa de verificação. Se precisar de voltar a ver o tutorial vá à página de definições.'
                              : 'All set to start the game. If you don\'t want to see this tutorial again at startup, check the box. If you need to see the tutorial again, go to the settings page.',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                            fontStyle: FontStyle.normal,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        // Checkbox e frase aparecem apenas se showCheckbox for true
                        if (showCheckbox) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Checkbox(
                                value: checkboxValue,
                                onChanged: onCheckboxChanged,
                              ),
                              Expanded(
                                child: Text(
                                  _isPortuguese()
                                      ? 'Não mostrar novamente'
                                      : "Don't show again",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Conteúdo principal ocupa toda a tela
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage1(isDarkMode, textColor, cardColor),
                  _buildPage2(isDarkMode, textColor, cardColor),
                  _buildPage3(isDarkMode, textColor, cardColor),
                  _buildPage4(isDarkMode, textColor, cardColor),
                  _buildPage5(isDarkMode, textColor, cardColor),
                  _buildPage6(isDarkMode, textColor, cardColor),
                  _buildPage7(isDarkMode, textColor, cardColor),
                  _buildPage8(
                    isDarkMode,
                    textColor,
                    cardColor,
                    showCheckbox: true,
                    checkboxValue: _dontShowAgain,
                    onCheckboxChanged: (value) {
                      setState(() {
                        _dontShowAgain = value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Indicadores e botões fixos no fundo
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  color: isDarkMode ? Colors.black : Colors.white,
                  padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                  child: Row(
                    children: [
                      // Botão Pular alinhado à esquerda
                      SizedBox(
                        width: 90,
                        child: (_currentPage < 7)
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _finishWelcome,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(80, 36),
                                    alignment: Alignment.centerLeft,
                                  ),
                                  child: Text(
                                    _isPortuguese() ? 'Pular' : 'Skip',
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.7),
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      // Indicadores centralizados
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            8,
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
                      // Botão Próximo alinhado à direita
                      SizedBox(
                        width: 110,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              if (_currentPage < 7) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _finishWelcome();
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(100, 36),
                              alignment: Alignment.centerRight,
                            ),
                            child: Text(
                              _currentPage < 7
                                  ? (_isPortuguese() ? 'Próximo' : 'Next')
                                  : (_isPortuguese() ? 'Começar' : 'Start'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.blue : const Color.fromARGB(255, 3, 104, 197),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class DragAnimationWidget extends StatefulWidget {
  const DragAnimationWidget({super.key});

  @override
  DragAnimationWidgetState createState() => DragAnimationWidgetState();
}

class DragAnimationWidgetState extends State<DragAnimationWidget> with TickerProviderStateMixin {
  late AnimationController _controller;

  final List<String> _images = [
    'assets/images/drag1.png',
    'assets/images/drag2.png',
    'assets/images/drag3.png',
    'assets/images/drag4.png',
    'assets/images/drag5.png',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000), // 4 segundos total
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getFrame(double progress) {
    if (progress < 0.125) return 0;  // Frame 1: 500ms
    if (progress < 0.25) return 1;   // Frame 2: 500ms
    if (progress < 0.375) return 2;  // Frame 3: 500ms
    if (progress < 0.5) return 3;    // Frame 4: 500ms
    return 4;                        // Frame 5: 2000ms (até o fim)
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        int frame = _getFrame(_controller.value);
        return Image.asset(
          _images[frame],
          fit: BoxFit.contain,
        );
      },
    );
  }
}

class LockAnimationWidget extends StatefulWidget {
  const LockAnimationWidget({super.key});

  @override
  LockAnimationWidgetState createState() => LockAnimationWidgetState();
}

class LockAnimationWidgetState extends State<LockAnimationWidget> with TickerProviderStateMixin {
  late AnimationController _controller;

  final List<String> _images = [
    'assets/images/lock1.png',
    'assets/images/lock2.png',
    'assets/images/lock3.png',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000), // 4 segundos total
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getFrame(double progress) {
    if (progress < 0.25) return 0;   // Frame 1: 1000ms
    if (progress < 0.5) return 1;    // Frame 2: 1000ms
    return 2;                        // Frame 3: 2000ms
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        int frame = _getFrame(_controller.value);
        return Image.asset(
          _images[frame],
          fit: BoxFit.contain,
        );
      },
    );
  }
}
