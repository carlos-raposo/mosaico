
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_controller.dart';
import 'progress_service.dart';
import 'best_times_service.dart';

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
    Key? key,
    required this.isDarkMode,
    required this.soundEnabled,
    required this.locale,
    required this.toggleTheme,
    required this.setLanguage,
    required this.toggleSound,
    required this.onLogout,
    this.onDeleteAccount,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Configure GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
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
  String get _settingsLabel => _currentLocale.languageCode == 'pt' ? 'Configurações' : 'Settings';
  String get _soundOnLabel => _currentLocale.languageCode == 'pt' ? 'Desligar som' : 'Turn off sound';
  String get _soundOffLabel => _currentLocale.languageCode == 'pt' ? 'Ouvir som' : 'Turn on sound';
  String get _themeLabel => _currentLocale.languageCode == 'pt' ? 'Modo Claro/Escuro' : 'Light/Dark Mode';
  String get _languageLabel => _currentLocale.languageCode == 'pt' ? 'Linguagem' : 'Language';
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
        title: Text(_settingsLabel,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        padding: const EdgeInsets.only(top: 32.0),
        child: ListView(
          children: [
            if (isAuthenticated && email != null) ...[
              ListTile(
                leading: Icon(Icons.email, color: iconColor),
                title: Text(email, style: TextStyle(color: textColor)),
              ),
              Divider(color: iconColor),
            ] else if (!isAuthenticated) ...[
              ListTile(
                leading: Icon(Icons.person_off, color: iconColor),
                title: Text(_notAuthenticatedLabel, style: TextStyle(color: textColor)),
              ),
              Divider(color: iconColor),
            ],
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
                  // Logout do Firebase Auth
                  await FirebaseAuth.instance.signOut();
                  
                  // Limpa cache do sistema de progressão
                  try {
                    final progressService = ProgressService();
                    progressService.clearCache();
                  } catch (e) {
                    debugPrint('Error clearing progress cache: $e');
                  }
                  
                  // Logout completo do Google Sign-In
                  try {
                    // Primeiro faz signOut
                    await _googleSignIn.signOut();
                    // Depois tenta disconnect para limpar completamente
                    await _googleSignIn.disconnect();
                  } catch (e) {
                    // Se disconnect falhar, tenta apenas signOut novamente
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
            // Opção para limpar cache
            ListTile(
              leading: Icon(Icons.clear_all, color: iconColor),
              title: Text('Limpar Cache Local', style: TextStyle(color: textColor)),
              subtitle: Text('Remove dados temporários salvos no dispositivo', 
                           style: TextStyle(color: textColor.withOpacity(0.7))),
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
}
