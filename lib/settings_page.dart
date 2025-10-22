
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'settings_controller.dart';
import 'progress_service.dart';

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
                    print('Error clearing progress cache: $e');
                  }
                  
                  // Logout completo do Google Sign-In
                  try {
                    // Primeiro faz signOut
                    await _googleSignIn.signOut();
                    // Depois tenta disconnect para limpar completamente
                    await _googleSignIn.disconnect();
                  } catch (e) {
                    // Se disconnect falhar, tenta apenas signOut novamente
                    print('Error with Google disconnect, trying signOut again: $e');
                    try {
                      await _googleSignIn.signOut();
                    } catch (e2) {
                      print('Error signing out from Google: $e2');
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
}
