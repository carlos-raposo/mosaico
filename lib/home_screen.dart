import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'style_guide.dart';
import 'ranking_screen.dart';
import 'settings_controller.dart';
import 'package:provider/provider.dart';
import 'demo_collections.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final int currentLevel;
  final int maxLevel;
  final int totalPoints;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.currentLevel,
    required this.maxLevel,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsController>(context);
    final isDarkMode = settings.isDarkMode;
    final soundEnabled = settings.soundEnabled;
    final locale = settings.locale;
    final setLanguage = settings.setLanguage;
    final toggleTheme = settings.toggleTheme;
    final toggleSound = settings.toggleSound;
  // final screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Usuário não autenticado, mostra Jogador
      return _buildScaffold(context, 'Jogador', isDarkMode, soundEnabled, locale, setLanguage, toggleTheme, toggleSound);
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        String username = 'Jogador';
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['username'] != null && (data['username'] as String).trim().isNotEmpty) {
            username = data['username'];
          }
        }
        return _buildScaffold(context, username, isDarkMode, soundEnabled, locale, setLanguage, toggleTheme, toggleSound);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, String username, bool isDarkMode, bool soundEnabled, Locale locale, Function(Locale) setLanguage, Future<void> Function() toggleTheme, Future<void> Function() toggleSound) {
    // ...existing code...
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color.fromARGB(255, 247, 250, 255),
      appBar: AppBar(
        title: Text('Mosaico',
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
            )),
        backgroundColor: isDarkMode ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 202, 220, 238),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: isDarkMode ? AppColors.darkAppBarIcon : AppColors.lightAppBarIcon,
              size: 30.0,
            ),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.push(
                // ...existing code...
                context,
                MaterialPageRoute(
                  builder: (context) {
                    final isAuthenticated = (FirebaseAuth.instance.currentUser != null);
                    return SettingsPage(
                      isDarkMode: isDarkMode,
                      soundEnabled: soundEnabled,
                      locale: locale,
                      toggleTheme: toggleTheme,
                      setLanguage: setLanguage,
                      toggleSound: toggleSound,
                      onLogout: () async {
                        try {
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (!context.mounted) return;
                          await Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao sair: $e')),
                            );
                          }
                        }
                      },
                      onDeleteAccount: null,
                      isAuthenticated: isAuthenticated,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Topo: 50% da tela
            Expanded(
              flex: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 16.0;
                  const textHeight = 40.0;
                  double logoMaxHeight = (constraints.maxHeight - textHeight - spacing) * 0.8;
                  if (logoMaxHeight < 0) logoMaxHeight = 0;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/icon.svg',
                          width: logoMaxHeight,
                          height: logoMaxHeight,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: spacing),
                        Text(
                          Localizations.localeOf(context).languageCode == 'pt'
                              ? (username.isNotEmpty ? 'Bem-vindo, $username' : 'Bem-vindo')
                              : (username.isNotEmpty ? 'Welcome, $username' : 'Welcome'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color.fromARGB(255, 3, 104, 197),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ...existing code...
            // Centro: 50% da tela
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ... Botão de autenticação removido. Gerenciamento de conta apenas via SettingsPage ...
                  const SizedBox(height: 8),
                  ElevatedButton.icon(   /// PLAY button
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? AppColors.buttonBgBlue : AppColors.buttonBgWhite,
                      foregroundColor: isDarkMode ? Colors.black : Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     side: BorderSide(
                        color: isDarkMode ? AppColors.buttonBorderDark : AppColors.buttonBorderLight,
                        width: 2,
                      ),
                    ),
                    icon: Icon(
                      Icons.play_arrow,
                      size: 28,
                      color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                    ),
                    label: Text(
                      Localizations.localeOf(context).languageCode == 'pt'
                          ? 'JOGAR'
                          : 'PLAY',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    onPressed: () {
                      final isAuthenticated = FirebaseAuth.instance.currentUser != null;
                      if (!isAuthenticated) {
                        // Mostra aviso se não estiver autenticado
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: Text(Localizations.localeOf(context).languageCode == 'pt' ? 'Aviso' : 'Warning'),
                              content: Text(Localizations.localeOf(context).languageCode == 'pt'
                                  ? 'Se entrar sem autentificação não poderá registar nem ver os melhores tempos no ranking global.'
                                  : 'If you enter without authentication, you will not be able to register or see the best times in the global ranking.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    Navigator.of(context).pushNamed('/auth');
                                  },
                                  child: Text(Localizations.localeOf(context).languageCode == 'pt' ? 'Autentificar' : 'Authenticate'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    // Navega para seleção fake sem async gap
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => _FakeCollectionSelectionRoute(soundEnabled: soundEnabled),
                                      ),
                                    );
                                  },
                                  child: Text(Localizations.localeOf(context).languageCode == 'pt' ? 'Continuar' : 'Continue'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        // Se autenticado, vai direto para o jogo
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => _FakeCollectionSelectionRoute(soundEnabled: soundEnabled),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(   /// Ranking Button
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ?AppColors.buttonBgBlue : AppColors.buttonBgWhite,
                      foregroundColor: isDarkMode ? Colors.black : Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(
                        color: isDarkMode ? AppColors.buttonBorderDark : AppColors.buttonBorderLight,
                        width: 2,
                      ),
                    ),
                    icon: Icon(
                      Icons.emoji_events,
                      size: 24,
                      color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                    ),
                    label: Text(
                      'Ranking',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: () {
                      final isAuthenticated = FirebaseAuth.instance.currentUser != null;
                      if (isAuthenticated) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RankingScreen(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              Localizations.localeOf(context).languageCode == 'pt'
                                  ? 'Você precisa estar autenticado para ver o ranking.'
                                  : 'You need to be authenticated to view the ranking.'
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(   /// Exit Button
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? AppColors.buttonBgBlue : AppColors.buttonBgWhite,
                      foregroundColor: isDarkMode ? Colors.black : Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(
                        color: isDarkMode ? AppColors.buttonBorderDark : AppColors.buttonBorderLight,
                        width: 2,
                      ),
                    ),
                    icon: Icon(
                      Icons.exit_to_app,
                      size: 24,
                      color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                    ),
                    label: Text(
                      (() {
                        final isPt = Localizations.localeOf(context).languageCode == 'pt';
                        final isAuthenticated = FirebaseAuth.instance.currentUser != null;
                        if (isAuthenticated) {
                          return isPt ? 'Sair' : 'Logout';
                        } else {
                          return isPt ? 'Entrar' : 'Login';
                        }
                      })(),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final isAuthenticated = FirebaseAuth.instance.currentUser != null;
                      if (!isAuthenticated) {
                        navigator.pushNamed('/auth');
                        return;
                      }
                      final isPortuguese = Localizations.localeOf(context).languageCode == 'pt';
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(isPortuguese ? 'Sair da conta' : 'Logout'),
                            content: Text(isPortuguese ? 'Tem certeza que deseja terminar a sessão?' : 'Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                child: Text(isPortuguese ? 'Cancelar' : 'Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                child: Text(isPortuguese ? 'Sair' : 'Logout'),
                              ),
                            ],
                          );
                        },
                      ) ?? false;
                      if (!confirmed) return;
                      try {
                        await FirebaseAuth.instance.signOut();
                        try {
                          await GoogleSignIn.instance.signOut();
                          await GoogleSignIn.instance.disconnect();
                        } catch (_) {
                          try { await GoogleSignIn.instance.signOut(); } catch (_) {}
                        }
                      } catch (e) {
                        // Ignoring logout errors intentionally; navigation proceeds to auth.
                      }
                      navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
                    },
                  ),
                  

                ],
              ),
            ),
            // Rodapé fixo
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Text(
                  'Versão 1.0.2',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : const Color.fromARGB(255, 3, 104, 197),
                    fontSize: 12,
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

class _FakeCollectionSelectionRoute extends StatelessWidget {
  final bool soundEnabled;
  const _FakeCollectionSelectionRoute({required this.soundEnabled});
  @override
  Widget build(BuildContext context) {
    return buildDemoCollectionSelectionScreen(context);
  }
}
