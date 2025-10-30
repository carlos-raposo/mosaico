import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_controller.dart';
import 'progress_service.dart';
import 'best_times_service.dart';
import 'ranking_screen.dart';
import 'collection_selection_screen.dart';
import 'game_screen.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final bool soundEnabled;
  final Locale locale;
  final VoidCallback toggleTheme;
  final Function(Locale) setLanguage;
  final VoidCallback toggleSound;
  final VoidCallback onLogout;
  final VoidCallback? onDeleteAccount;
  final bool isAuthenticated;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.soundEnabled,
    required this.locale,
    required this.toggleTheme,
    required this.setLanguage,
    required this.toggleSound,
    required this.onLogout,
    this.onDeleteAccount,
    required this.isAuthenticated,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Configure GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final TextEditingController _usernameController = TextEditingController();
  String? _initialUsername;
  bool _isLoadingUsername = false;
  bool _isSavingUsername = false;
  String? _usernameError;
  bool _isEditingUsername = false;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() { _isLoadingUsername = true; });
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      final username = (data != null && data['username'] != null) ? data['username'] as String : '';
      _initialUsername = username;
      _usernameController.text = username;
    } catch (e) {
      _usernameError = 'Erro ao carregar username';
    } finally {
      setState(() { _isLoadingUsername = false; });
    }
  }

  Future<void> _saveUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final newUsername = _usernameController.text.trim();
    // Validação igual à auth_page.dart
    if (newUsername.isEmpty) {
      setState(() { _usernameError = _currentLocale.languageCode == 'pt' ? 'Nome de usuário é obrigatório' : 'Username is required'; });
      return;
    } else if (newUsername.length < 5 || newUsername.length > 9) {
      setState(() { _usernameError = _currentLocale.languageCode == 'pt'
        ? 'Nome de usuário deve ter entre 5 e 9 letras'
        : 'Username must be between 5 and 9 characters'; });
      return;
    }
    if (newUsername == _initialUsername) return;
    setState(() { _isSavingUsername = true; _usernameError = null; });
    try {
      // Verifica unicidade
      final query = await FirebaseFirestore.instance.collection('users')
        .where('username', isEqualTo: newUsername).get();
      if (query.docs.isNotEmpty && query.docs.first.id != user.uid) {
        setState(() { _usernameError = _currentLocale.languageCode == 'pt'
          ? 'Nome de usuário já em uso. Escolha outro.'
          : 'Username already in use. Choose another.'; });
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'username': newUsername});
      setState(() { _initialUsername = newUsername; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_currentLocale.languageCode == 'pt' ? 'Username atualizado!' : 'Username updated!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() { _usernameError = _currentLocale.languageCode == 'pt' ? 'Erro ao salvar username' : 'Error saving username'; });
    } finally {
      setState(() { _isSavingUsername = false; });
    }
  }

  Locale get _currentLocale => Localizations.localeOf(context);
  String? _getCurrentUserEmail() {
    try {
      return FirebaseAuth.instance.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  String get _logoutLabel => _currentLocale.languageCode == 'pt' ? 'Sair' : 'Logout';
  String get _loginLabel => _currentLocale.languageCode == 'pt' ? 'Entrar / Criar Conta' : 'Login / Create Account';
  String get _notAuthenticatedLabel => _currentLocale.languageCode == 'pt' ? 'Não autenticado' : 'Not authenticated';
  String get _deleteAccountLabel => _currentLocale.languageCode == 'pt' ? 'Apagar minha conta' : 'Delete my account';
  String get _soundOnLabel => _currentLocale.languageCode == 'pt' ? 'Desligar som' : 'Turn off sound';
  String get _soundOffLabel => _currentLocale.languageCode == 'pt' ? 'Ouvir som' : 'Turn on sound';
  String get _themeLabel => _currentLocale.languageCode == 'pt' ? 'Modo Claro/Escuro' : 'Light/Dark Mode';
  String get _languageLabel => _currentLocale.languageCode == 'pt' ? 'Linguagem' : 'Language';
  String get _homeLabel => _currentLocale.languageCode == 'pt' ? 'Início' : 'Home';
  String get _playLabel => _currentLocale.languageCode == 'pt' ? 'Jogar' : 'Play';
  String get _rankingLabel => _currentLocale.languageCode == 'pt' ? 'Ranking' : 'Ranking';
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsController>(context);
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final email = isAuthenticated ? _getCurrentUserEmail() : null;
    final isDarkMode = settings.isDarkMode;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0368C5);
    final iconColor = isDarkMode ? Colors.white : const Color(0xFF0368C5);
    return Scaffold(
      appBar: AppBar(
        title: null,
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFFCADEEE),
        iconTheme: IconThemeData(
          color: iconColor,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 30.0, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: ListView(
          children: [
            // --- MENU SECTION ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
              child: Text(
                _currentLocale.languageCode == 'pt' ? 'Menu' : 'Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: iconColor),
              title: Text(_homeLabel, style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
            ListTile(
              leading: Icon(Icons.play_arrow, color: iconColor),
              title: Text(_playLabel, style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => _buildGameSelectionScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.emoji_events, color: iconColor),
              title: Text(_rankingLabel, style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RankingScreen(),
                  ),
                );
              },
            ),
            Divider(color: iconColor),
            // --- ACCOUNT SECTION ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
              child: Text(
                _currentLocale.languageCode == 'pt' ? 'Conta' : 'Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor),
              ),
            ),
            if (isAuthenticated && email != null) ...[
              ListTile(
                leading: Icon(Icons.email, color: iconColor),
                title: Text(email, style: TextStyle(color: textColor)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Username:', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isEditingUsername == true
                              ? TextField(
                                  controller: _usernameController,
                                  autofocus: true,
                                  enabled: !_isLoadingUsername && !_isSavingUsername,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(color: textColor),
                                )
                              : Text(
                                  _usernameController.text,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 16),
                                ),
                        ),
                        if (_isEditingUsername == true)
                          IconButton(
                            icon: _isSavingUsername
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.check, color: iconColor),
                            tooltip: 'Salvar username',
                            onPressed: _isSavingUsername
                                ? null
                                : () async {
                                    await _saveUsername();
                                    if (_usernameError == null) {
                                      setState(() {
                                        _isEditingUsername = false;
                                      });
                                    }
                                  },
                          )
                        else
                          IconButton(
                            icon: Icon(Icons.edit, color: iconColor),
                            tooltip: 'Editar username',
                            onPressed: _isLoadingUsername || _isSavingUsername
                                ? null
                                : () {
                                    setState(() {
                                      _isEditingUsername = true;
                                    });
                                  },
                          ),
                      ],
                    ),
                    if (_usernameError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, left: 2.0, right: 2.0),
                        child: Text(
                          _usernameError!,
                          style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    if (_isLoadingUsername)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
              Divider(color: iconColor),
            ] else if (!isAuthenticated) ...[
              ListTile(
                leading: Icon(Icons.person_off, color: iconColor),
                title: Text(_notAuthenticatedLabel, style: TextStyle(color: textColor)),
              ),
              Divider(color: iconColor),
            ],
            // --- SETTINGS SECTION ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
              child: Text(
                _currentLocale.languageCode == 'pt' ? 'Configurações' : 'Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor),
              ),
            ),
            ListTile(
              leading: Icon(settings.soundEnabled ? Icons.volume_up : Icons.volume_off, color: iconColor),
              title: Text(settings.soundEnabled ? _soundOnLabel : _soundOffLabel, style: TextStyle(color: textColor)),
              onTap: () async {
                await settings.toggleSound();
              },
            ),
            ListTile(
              leading: Icon(Icons.brightness_6, color: iconColor),
              title: Text(_themeLabel, style: TextStyle(color: textColor)),
              onTap: () async {
                await settings.toggleTheme();
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: iconColor),
              title: Row(
                children: [
                  Text(_languageLabel, style: TextStyle(color: textColor)),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await settings.setLanguage(const Locale('en', 'US'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: settings.locale.languageCode == 'en'
                          ? (isDarkMode ? Colors.red : Colors.amber)
                          : Colors.transparent,
                      foregroundColor: textColor,
                      textStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      side: BorderSide(color: textColor, width: 2),
                      elevation: 0,
                    ),
                    child: const Text('EN'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await settings.setLanguage(const Locale('pt', 'BR'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: settings.locale.languageCode == 'pt'
                          ? (isDarkMode ? Colors.red : Colors.amber)
                          : Colors.transparent,
                      foregroundColor: textColor,
                      textStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      side: BorderSide(color: textColor, width: 2),
                      elevation: 0,
                    ),
                    child: const Text('PT'),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(isAuthenticated ? Icons.logout : Icons.login, color: iconColor),
              title: Text(isAuthenticated ? _logoutLabel : _loginLabel, style: TextStyle(color: textColor)),
              onTap: () async {
                if (isAuthenticated) {
                  await FirebaseAuth.instance.signOut();
                  try {
                    final progressService = ProgressService();
                    progressService.clearCache();
                  } catch (e) {
                    debugPrint('Error clearing progress cache: $e');
                  }
                  try {
                    await _googleSignIn.signOut();
                    await _googleSignIn.disconnect();
                  } catch (e) {
                    debugPrint('Error with Google disconnect, trying signOut again: $e');
                    try {
                      await _googleSignIn.signOut();
                    } catch (e2) {
                      debugPrint('Error signing out from Google: $e2');
                    }
                  }
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                  }
                } else {
                  if (mounted) {
                    Navigator.of(context).pushNamed('/auth');
                  }
                }
                widget.onLogout();
                setState(() {});
              },
            ),
            ListTile(
              leading: Icon(Icons.clear_all, color: iconColor),
              title: Text('Limpar Cache Local', style: TextStyle(color: textColor)),
              subtitle: Text('Remove dados temporários salvos no dispositivo', 
                           style: TextStyle(color: textColor.withValues(
                             red: ((textColor.r * 255.0).round() & 0xff).toDouble(),
                             green: ((textColor.g * 255.0).round() & 0xff).toDouble(),
                             blue: ((textColor.b * 255.0).round() & 0xff).toDouble(),
                             alpha: 0.7 * 255,
                           ))),
              onTap: () async {
                bool? confirmClear = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    final user = FirebaseAuth.instance.currentUser;
                    final isLoggedIn = user != null;
                    return AlertDialog(
                      title: const Text('Limpar Cache'),
                      content: Text(
                        isLoggedIn 
                        ? 'Isso irá remover os dados temporários salvos localmente APENAS da sua conta, '
                          'incluindo melhores tempos offline, progresso e configurações. '
                          'Os dados de outros usuários que usaram este dispositivo não serão afetados. '
                          'Os dados salvos na nuvem não serão perdidos.\n\n'
                          'Deseja continuar?'
                        : 'Isso irá remover todos os dados offline salvos localmente, '
                          'incluindo melhores tempos, progresso e configurações. '
                          'Como você não está logado, estes dados não podem ser recuperados.\n\n'
                          'Deseja continuar?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Limpar'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmClear == true) {
                  await _clearAllCache();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache limpa com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
            if (isAuthenticated && widget.onDeleteAccount != null)
              ListTile(
                leading: Icon(Icons.delete, color: iconColor),
                title: Text(_deleteAccountLabel, style: TextStyle(color: textColor)),
                onTap: widget.onDeleteAccount,
              ),
          ],
        ),
      ),
    );
  }

  /// Limpa toda a cache local da aplicação (apenas do usuário atual)
  Future<void> _clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // USUÁRIO LOGADO: Limpa apenas cache específica do usuário
        final userId = user.uid;
        
        // Limpa cache de melhores tempos do usuário específico
        try {
          final bestTimesService = BestTimesService();
          await bestTimesService.clearSpecificUserCache(userId);
        } catch (e) {
          debugPrint('Error clearing user best times cache: $e');
        }
        
        // Limpa cache de progressão do usuário específico
        try {
          final progressService = ProgressService();
          await progressService.clearAllCache(); // Limpa completamente para usuário logado
        } catch (e) {
          debugPrint('Error clearing progress cache: $e');
        }
        
        // Limpa chaves específicas do usuário
        final keys = prefs.getKeys();
        final userKeys = keys.where((key) => 
          key.contains(userId) ||
          key == 'bestTimes_$userId' ||
          key == 'completedPuzzles_$userId' ||
          key == 'progress_$userId'
        ).toList();
        
        for (String key in userKeys) {
          await prefs.remove(key);
        }
        
        debugPrint('User cache cleared successfully - removed ${userKeys.length} keys for user $userId: $userKeys');
        
      } else {
        // USUÁRIO NÃO LOGADO: Limpa apenas dados offline/anônimos
        
        // Limpa cache de melhores tempos offline
        try {
          final bestTimesService = BestTimesService();
          await bestTimesService.clearOfflineCache();
        } catch (e) {
          debugPrint('Error clearing offline best times cache: $e');
        }
        
        // Limpa cache de progressão offline
        try {
          final progressService = ProgressService();
          await progressService.clearAllCache(); // Remove puzzles desbloqueados offline
        } catch (e) {
          debugPrint('Error clearing offline progress cache: $e');
        }
        
        // Limpa outras chaves offline/anônimas
        final keys = prefs.getKeys();
        final offlineKeys = keys.where((key) => 
          key == 'bestTimes' || // Dados offline antigos (compatibilidade)
          key == 'bestTimes_offline' || // Dados offline atuais
          key == 'unlockedPuzzles' || // Progresso de puzzles desbloqueados offline
          key.startsWith('offline_') ||
          key == 'completedPuzzles' || // Progresso offline (se existir)
          key == 'progress' || // Progresso geral offline
          (key.startsWith('completedPuzzles_') && !key.contains('_user')) || // Progresso sem user ID
          (key.startsWith('progress_') && !key.contains('_user')) || // Progresso sem user ID
          (key.startsWith('unlockedPuzzles_') && !key.contains('_user')) // Puzzles desbloqueados sem user ID
        ).toList();
        
        for (String key in offlineKeys) {
          await prefs.remove(key);
        }
        
        debugPrint('Offline cache cleared successfully - removed ${offlineKeys.length} keys: $offlineKeys');
      }
      
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      rethrow;
    }
  }

  Widget _buildGameSelectionScreen() {
    // Dados mockados para demonstração (copiado da home_screen.dart)
    final collections = [
      CollectionData(
        name: 'Coleção 1',
        imagePath: 'assets/images/col_1/puzzle1.png',
        puzzles: [
          // Puzzles originais da coleção 1
          PuzzleData(
            name: 'Puzzle 1',
            imagePath: 'assets/images/col_1/puzzle1.png',
            pieceFolder: 'assets/images/col_1/puzzle1/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 2',
            imagePath: 'assets/images/col_1/puzzle2.png',
            pieceFolder: 'assets/images/col_1/puzzle2/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 3',
            imagePath: 'assets/images/col_1/puzzle3.png',
            pieceFolder: 'assets/images/col_1/puzzle3/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 4',
            imagePath: 'assets/images/col_1/puzzle4.png',
            pieceFolder: 'assets/images/col_1/puzzle4/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 5',
            imagePath: 'assets/images/col_1/puzzle5.png',
            pieceFolder: 'assets/images/col_1/puzzle5/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 6',
            imagePath: 'assets/images/col_1/puzzle6.png',
            pieceFolder: 'assets/images/col_1/puzzle6/4x4/',
            pieceCount: 25,
          ),
          PuzzleData(
            name: 'Puzzle 7',
            imagePath: 'assets/images/col_1/puzzle7.png',
            pieceFolder: 'assets/images/col_1/puzzle7/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 8',
            imagePath: 'assets/images/col_1/puzzle8.png',
            pieceFolder: 'assets/images/col_1/puzzle8/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 9',
            imagePath: 'assets/images/col_1/puzzle9.png',
            pieceFolder: 'assets/images/col_1/puzzle9/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 10',
            imagePath: 'assets/images/col_1/puzzle10.png',
            pieceFolder: 'assets/images/col_1/puzzle10/4x4/',
            pieceCount: 40,
          ),
        ],
      ),
    ];
    
    return CollectionSelectionScreen(
      collections: collections,
      onPuzzleSelected: (collection, puzzle) async {
        // Função auxiliar para navegar para um puzzle
        Future<Map<String, dynamic>?> navigateToGame(PuzzleData targetPuzzle) async {
          String puzzlePath = targetPuzzle.pieceFolder;
          if (puzzlePath.endsWith('/')) {
            puzzlePath = puzzlePath.substring(0, puzzlePath.length - 1);
          }
          
          // Calcular rows e cols a partir de pieceCount
          int rows = 4;
          int cols = 4;
          if (targetPuzzle.pieceCount == 16) {
            rows = 4;
            cols = 4;
          } else if (targetPuzzle.pieceCount == 15) {
            rows = 5;
            cols = 3;    
          } else if (targetPuzzle.pieceCount == 24) {
            rows = 6;
            cols = 4;  
          } else if (targetPuzzle.pieceCount == 25) {
            rows = 5;
            cols = 5;
          } else if (targetPuzzle.pieceCount == 40) {
            rows = 8;
            cols = 5;
          } else {
            // fallback: tentar quadrado
            rows = cols = (targetPuzzle.pieceCount > 0) ? sqrt(targetPuzzle.pieceCount).round() : 4;
          }
          
          final BuildContext navContext = context;
          if (!mounted) return null;
          return await Navigator.of(navContext).push<Map<String, dynamic>>(
            MaterialPageRoute(
              builder: (context) => GameScreen(
                title: targetPuzzle.name,
                puzzlePath: puzzlePath,
                rows: rows,
                cols: cols,
                confettiController: ConfettiController(duration: const Duration(seconds: 6)),
                locale: Localizations.localeOf(navContext),
                isAuthenticated: true,
                isDarkMode: Theme.of(navContext).brightness == Brightness.dark,
              ),
            ),
          );
        }
        
        // Navega para o puzzle inicial
        Map<String, dynamic>? result = await navigateToGame(puzzle);
        
        // Processa o resultado
        while (result != null && result['action'] == 'nextPuzzle') {
          final nextPuzzleNumber = result['puzzleNumber'] as int?;
          if (nextPuzzleNumber != null && nextPuzzleNumber <= collection.puzzles.length) {
            final nextPuzzle = collection.puzzles[nextPuzzleNumber - 1];
            result = await navigateToGame(nextPuzzle);
          } else {
            break;
          }
        }
      },
    );
  }
}
