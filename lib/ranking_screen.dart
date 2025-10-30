import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'style_guide.dart';
import 'package:provider/provider.dart';
import 'settings_controller.dart';
import 'settings_page.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String formatTime(int seconds) {
      if (seconds < 60) return '$seconds seg';
      final min = seconds ~/ 60;
      final seg = seconds % 60;
      if (seg == 0) {
        return '$min min';
      }
      return '$min min $seg seg';
    }
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isPortuguese = Localizations.localeOf(context).languageCode == 'pt';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30.0),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPortuguese ? 'Ranking Global' : 'Global Ranking',
              style: TextStyle(
                color: isDarkMode ? Colors.white:  const Color.fromARGB(255, 3, 104, 197), // chocolate ou vermelho
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 28,
            ),
          ],
        ),
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
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
              final settings = Provider.of<SettingsController>(context, listen: false);
              final isAuthenticated = FirebaseAuth.instance.currentUser != null;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkMode: settings.isDarkMode,
                    soundEnabled: settings.soundEnabled,
                    locale: settings.locale,
                    toggleTheme: settings.toggleTheme,
                    setLanguage: settings.setLanguage,
                    toggleSound: settings.toggleSound,
                    onLogout: () {}, // ajuste conforme necessário
                    onDeleteAccount: null,
                    isAuthenticated: isAuthenticated,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('rankings').get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rankings = snapshot.data!.docs;
            if (rankings.isEmpty) {
              return ListTile(
                dense: true,
                title: Text(isPortuguese ? 'Ainda não há rankings globais.' : 'No global rankings yet.'),
              );
            }
            // Sort rankings numerically by puzzle number (if puzzleName contains a number)
            List<QueryDocumentSnapshot> sortedRankings = List.from(rankings);
            int extractPuzzleNumber(String puzzleName) {
              final regex = RegExp(r'(\d+)');
              final match = regex.firstMatch(puzzleName);
              if (match != null) {
                return int.tryParse(match.group(1) ?? '') ?? 0;
              }
              return 0;
            }
            sortedRankings.sort((a, b) {
              final aName = (a.data() as Map<String, dynamic>)['puzzleName'] ?? '';
              final bName = (b.data() as Map<String, dynamic>)['puzzleName'] ?? '';
              return extractPuzzleNumber(aName).compareTo(extractPuzzleNumber(bName));
            });
            final currentUser = FirebaseAuth.instance.currentUser;
            List<Widget> rankingWidgets = sortedRankings
                .map<Widget>((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final topTimes = data['topTimes'] as List<dynamic>;
                  if (topTimes.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final bestTime = topTimes.first;
                  final puzzleName = data['puzzleName'] ?? '';
                  return FutureBuilder<DocumentSnapshot>(
                    future: currentUser != null
                        ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get()
                        : null,
                    builder: (context, userSnapshot) {
                      int? seuMelhorTempo;
                      if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                        if (userData != null) {
                          final bestTimes = userData['bestTimes'] as Map<String, dynamic>?;
                          if (bestTimes != null && bestTimes.containsKey(puzzleName)) {
                            final val = bestTimes[puzzleName];
                            if (val is int) {
                              seuMelhorTempo = val;
                            } else if (val is String) {
                              seuMelhorTempo = int.tryParse(val);
                            }
                          }
                        }
                      }
                      final borderColor = isDarkMode
                          ? AppColors.darkText
                          : AppColors.lightText;
                      final textColor = borderColor;
                      final isRecordHolder = currentUser?.uid == bestTime['userId'];
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(bestTime['userId']).get(),
                        builder: (context, recordUserSnapshot) {
                          String recordUsername = '';
                          if (recordUserSnapshot.hasData && recordUserSnapshot.data != null && recordUserSnapshot.data!.exists) {
                            final recordUserData = recordUserSnapshot.data!.data() as Map<String, dynamic>?;
                            if (recordUserData != null && recordUserData['username'] != null) {
                              recordUsername = recordUserData['username'];
                            }
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: isRecordHolder
                                  ? (isDarkMode
                                      ? const Color.fromARGB(255, 2, 73, 139) // dark chocolate
                                      : const Color(0xFFFFF9C4)) // light yellow
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: textColor, width: 2),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: Text(
                                    puzzleName,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${isPortuguese ? 'Melhor tempo' : 'Best time'}: ${formatTime(bestTime['time'] is int ? bestTime['time'] : int.tryParse(bestTime['time'].toString()) ?? 0)}',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${isPortuguese ? 'Usuário' : 'User'}: $recordUsername',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                if (seuMelhorTempo != null && !isRecordHolder)
                                  Text(
                                    '${isPortuguese ? 'Seu melhor tempo' : 'Your best time'}: ${formatTime(seuMelhorTempo)}',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.amber : Colors.deepOrange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (seuMelhorTempo != null && isRecordHolder)
                                  Text(
                                    isPortuguese ? 'Parabéns, você detém o melhor tempo!' : 'Congratulations, you hold the best time!',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.amber : Colors.deepOrange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                })
                .toList();
            // Adiciona SizedBox de 2px entre containers, exceto após o último
            List<Widget> spacedWidgets = [];
            for (int i = 0; i < rankingWidgets.length; i++) {
              spacedWidgets.add(rankingWidgets[i]);
              if (i < rankingWidgets.length - 1) {
                spacedWidgets.add(const SizedBox(height: 6));
              }
            }
            return ListView(
              children: spacedWidgets,
            );
          },
        ),
      ),
    );
  }
}