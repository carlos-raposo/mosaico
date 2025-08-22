
import 'package:flutter/material.dart';
import 'style_guide.dart';
import 'package:provider/provider.dart';
import 'settings_controller.dart';
import 'settings_page.dart';


class CollectionSelectionScreen extends StatefulWidget {
  final List<CollectionData> collections;
  final void Function(CollectionData, PuzzleData) onPuzzleSelected;

  const CollectionSelectionScreen({
    super.key,
    required this.collections,
    required this.onPuzzleSelected,
  });

  @override
  State<CollectionSelectionScreen> createState() => _CollectionSelectionScreenState();
}

class _CollectionSelectionScreenState extends State<CollectionSelectionScreen> {
  // Não há mais expansão de coleção

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
              );
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
            return GestureDetector(
              onTap: () => widget.onPuzzleSelected(widget.collections.first, puzzle),
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
                        child: Image.asset(
                          puzzle.imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
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
                              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
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

