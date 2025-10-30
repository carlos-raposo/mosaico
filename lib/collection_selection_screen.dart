
import 'package:flutter/material.dart';
import 'style_guide.dart';
import 'progress_service.dart';
import 'package:provider/provider.dart';
import 'settings_controller.dart';
import 'settings_page.dart';


class CollectionSelectionScreen extends StatefulWidget {
  final List<CollectionData> collections;
  final Future<void> Function(CollectionData, PuzzleData) onPuzzleSelected;

  const CollectionSelectionScreen({
    super.key,
    required this.collections,
    required this.onPuzzleSelected,
  });

  @override
  State<CollectionSelectionScreen> createState() => _CollectionSelectionScreenState();
}

class _CollectionSelectionScreenState extends State<CollectionSelectionScreen> with WidgetsBindingObserver {
  final ProgressService _progressService = ProgressService();
  List<int> _unlockedPuzzles = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUnlockedPuzzles();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recarrega quando a app volta ao primeiro plano
      _loadUnlockedPuzzles();
    }
  }

  /// Método para ser chamado quando voltar de outras telas
  void refreshPuzzles() {
    _loadUnlockedPuzzles();
  }
  
  Future<void> _loadUnlockedPuzzles() async {
    // FORÇA reload completo do cache para garantir dados atualizados
    await _progressService.forceReloadCache();
    final unlocked = await _progressService.getUnlockedPuzzles();
    debugPrint('Puzzles desbloqueados carregados: $unlocked'); // Debug
    
    if (mounted) {
      setState(() {
        _unlockedPuzzles = unlocked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Assume que há apenas uma coleção
    final puzzles = widget.collections.isNotEmpty ? widget.collections.first.puzzles : [];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkAppBar : AppColors.lightAppBar,
        iconTheme: IconThemeData(
          color: isDarkMode ? AppColors.darkAppBarIcon : AppColors.lightAppBarIcon,
          size: 30.0,
        ),
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: isDarkMode ? AppColors.darkAppBarIcon : AppColors.lightAppBarIcon,
              size: 30.0,
            ),
            tooltip: 'Menu',
            onPressed: () {
              final settings = Provider.of<SettingsController>(context, listen: false);
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
                    isAuthenticated: true, // ajuste conforme necessário
                  ),
                ),
              ).then((_) {
                // FORÇA reload quando volta das configurações
                debugPrint('Voltou das configurações - forçando reload dos puzzles');
                _loadUnlockedPuzzles();
              });
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 0,
            childAspectRatio: 4 / 4.9,
          ),
          itemCount: puzzles.length,
          itemBuilder: (context, puzzleIndex) {
            final puzzle = puzzles[puzzleIndex];
            final puzzleNumber = puzzleIndex + 1; // Puzzle 1, 2, 3...
            final isUnlocked = _unlockedPuzzles.contains(puzzleNumber);
            
            return GestureDetector(
              onTap: () async {
                if (isUnlocked) {
                  // Navega para o jogo e aguarda retorno
                  await widget.onPuzzleSelected(widget.collections.first, puzzle);
                  // SEMPRE recarrega puzzles desbloqueados quando volta do jogo, 
                  // independentemente da ação tomada
                  await _loadUnlockedPuzzles();
                } else {
                  // Mostra mensagem informando que precisa desbloquear
                  final previousPuzzle = puzzleNumber - 1;
                  final message = Localizations.localeOf(context).languageCode == 'pt'
                      ? 'Complete o Puzzle $previousPuzzle para desbloquear este puzzle'
                      : 'Complete Puzzle $previousPuzzle to unlock this puzzle';
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                elevation: 0,
                color: isDarkMode ? AppColors.darkAppBar : AppColors.lightBackground ,
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.asset(
                              puzzle.imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              color: isUnlocked ? null : Colors.black.withAlpha((0.6 * 255).round()),
                              colorBlendMode: isUnlocked ? null : BlendMode.darken,
                            ),
                            if (!isUnlocked)
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.black.withAlpha((0.3 * 255).round()),
                                ),
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 0.0),
                      child: SizedBox(
                        height: 24,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            puzzle.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isUnlocked 
                                  ? (isDarkMode ? AppColors.darkText : AppColors.lightText)
                                  : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CollectionData {
  final String name;
  final String imagePath;
  final List<PuzzleData> puzzles;
  CollectionData({required this.name, required this.imagePath, required this.puzzles});
}

class PuzzleData {
  final String name;
  final String imagePath;
  final String pieceFolder;
  final int pieceCount;
  PuzzleData({required this.name, required this.imagePath, required this.pieceFolder, required this.pieceCount});
}

