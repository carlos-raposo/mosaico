import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'collection_selection_screen.dart';
import 'game_screen.dart';

import 'settings_page.dart';


import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';


import 'package:firebase_auth/firebase_auth.dart';
import 'style_guide.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final int currentLevel;
  final int maxLevel;
  final int totalPoints;
  final Function(Locale) setLanguage;
  final Locale locale;
  final Future<void> Function() toggleTheme;
  final bool isDarkMode;
  final bool soundEnabled;
  final Future<void> Function() toggleSound;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.currentLevel,
    required this.maxLevel,
    required this.totalPoints,
    required this.setLanguage,
    required this.locale,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.soundEnabled,
    required this.toggleSound,
  });

  @override
  Widget build(BuildContext context) {
  // final screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Usuário não autenticado, mostra Jogador
      return _buildScaffold(context, 'Jogador');
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
        return _buildScaffold(context, username);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, String username) {
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
                          await Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao sair: $e')),
                          );
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
                  Builder(   // Authentication Button
                    builder: (context) {
                      final isAuthenticated = FirebaseAuth.instance.currentUser != null;
                      final buttonTextColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
                      final buttonIconColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
                      final buttonBorderColor = isDarkMode ? AppColors.buttonBorderDark : AppColors.buttonBorderLight;
                      final buttonBgColor = isDarkMode ? AppColors.buttonBgBlue : AppColors.buttonBgWhite;
                      return ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBgColor,
                          foregroundColor: buttonTextColor,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: buttonBorderColor,
                            width: 2,
                          ),
                        ),
                        icon: Icon(
                          isAuthenticated ? Icons.logout : Icons.login,
                          color: buttonIconColor,
                          size: 24,
                        ),
                        label: Text(
                          isAuthenticated
                            ? (Localizations.localeOf(context).languageCode == 'pt' ? 'Logout' : 'Logout')
                            : (Localizations.localeOf(context).languageCode == 'pt' ? 'Entrar / Criar Conta' : 'Login / Create Account'),
                          style: TextStyle(
                            fontSize: 16,
                            color: buttonTextColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: () async {
                          if (isAuthenticated) {
                            await FirebaseAuth.instance.signOut();
                            Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                          } else {
                            Navigator.of(context).pushNamed('/auth');
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(   /// PLAY button
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? AppColors.buttonBgBlue : AppColors.buttonBgWhite,
                      foregroundColor: isDarkMode ? Colors.black : Colors.black,
                      minimumSize: const Size(double.infinity, 44),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => _FakeCollectionSelectionRoute(soundEnabled: soundEnabled),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(   /// Ranking Button
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ?AppColors.buttonBgBlue : AppColors.buttonBgWhite,
                      foregroundColor: isDarkMode ? Colors.black : Colors.black,
                      minimumSize: const Size(double.infinity, 40),
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
                  

                ],
              ),
            ),
            // Rodapé fixo
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                'Versão 1.0.0',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[500] : const Color.fromARGB(255, 3, 104, 197),
                  fontSize: 12,
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
  const _FakeCollectionSelectionRoute({Key? key, required this.soundEnabled}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Dados mockados para demonstração
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
            imagePath: 'assets/images/col_1/puzzle10.png',
            pieceFolder: 'assets/images/col_1/puzzle10/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 3',
            imagePath: 'assets/images/col_1/puzzle8.png',
            pieceFolder: 'assets/images/col_1/puzzle8/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 4',
            imagePath: 'assets/images/col_1/puzzle5.png',
            pieceFolder: 'assets/images/col_1/puzzle5/6x4/',
            pieceCount: 24,
          ),
          PuzzleData(
            name: 'Puzzle 5',
            imagePath: 'assets/images/col_1/puzzle6.png',
            pieceFolder: 'assets/images/col_1/puzzle6/5x5/',
            pieceCount: 25,
          ),
          PuzzleData(
            name: 'Puzzle 6',
            imagePath: 'assets/images/col_1/puzzle2.png',
            pieceFolder: 'assets/images/col_1/puzzle2/5x5/',
            pieceCount: 25,
          ),
          PuzzleData(
            name: 'Puzzle 7',
            imagePath: 'assets/images/col_1/puzzle3.png',
            pieceFolder: 'assets/images/col_1/puzzle3/5x5/',
            pieceCount: 25,
          ),
          PuzzleData(
            name: 'Puzzle 8',
            imagePath: 'assets/images/col_1/puzzle4.png',
            pieceFolder: 'assets/images/col_1/puzzle4/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 9',
            imagePath: 'assets/images/col_1/puzzle7.png',
            pieceFolder: 'assets/images/col_1/puzzle7/4x4/',
            pieceCount: 16,
          ),
          PuzzleData(
            name: 'Puzzle 10',
            imagePath: 'assets/images/col_1/puzzle9.png',
            pieceFolder: 'assets/images/col_1/puzzle9/5x8/',
            pieceCount: 40,
          ),
        ],
      ),
    ];
    return CollectionSelectionScreen(
      collections: collections,
      onPuzzleSelected: (collection, puzzle) async {
        // Remove barra final, se houver, para evitar paths com //
        String puzzlePath = puzzle.pieceFolder;
        if (puzzlePath.endsWith('/')) {
          puzzlePath = puzzlePath.substring(0, puzzlePath.length - 1);
        }
        // Calcular rows e cols a partir de pieceCount
        int rows = 4;
        int cols = 4;
        if (puzzle.pieceCount == 16) {
          rows = 4;
          cols = 4;
        } else if (puzzle.pieceCount == 15) {
          rows = 5;
          cols = 3;    
        } else if (puzzle.pieceCount == 24) {
          rows = 6;
          cols = 4;  
        } else if (puzzle.pieceCount == 25) {
          rows = 5;
          cols = 5;
        } else if (puzzle.pieceCount == 40) {
          rows = 8;
          cols = 5;
        } else {
          // fallback: tentar quadrado
          rows = cols = (puzzle.pieceCount > 0) ? sqrt(puzzle.pieceCount).round() : 4;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GameScreen(
              title: puzzle.name,
              puzzlePath: puzzlePath,
              rows: rows,
              cols: cols,
              confettiController: ConfettiController(duration: const Duration(seconds: 6)),
              locale: Localizations.localeOf(context),
              isAuthenticated: true, // Ajuste conforme necessário
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        );
      },
    );
  }
}
