import 'package:mosaico/game_screen.dart';
import 'package:mosaico/collection_selection_screen.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:flutter/material.dart';

// Dados mockados para demonstração
final List<CollectionData> demoCollections = [
  CollectionData(
    name: 'Coleção 1',
    imagePath: 'assets/images/col_1/puzzle1.png',
    puzzles: [
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
        pieceCount: 16,
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
        pieceFolder: 'assets/images/col_1/puzzle9/5x5/',
        pieceCount: 25,
      ),
      PuzzleData(
        name: 'Puzzle 10',
        imagePath: 'assets/images/col_1/puzzle10.png',
        pieceFolder: 'assets/images/col_1/puzzle10/4x4/',
        pieceCount: 16,
      ),
    ],
  ),
];

Widget buildDemoCollectionSelectionScreen(BuildContext context) {
  return CollectionSelectionScreen(
    collections: demoCollections,
    onPuzzleSelected: (collection, puzzle) async {
      Future<Map<String, dynamic>?> navigateToGame(PuzzleData targetPuzzle) async {
        String puzzlePath = targetPuzzle.pieceFolder;
        if (puzzlePath.endsWith('/')) {
          puzzlePath = puzzlePath.substring(0, puzzlePath.length - 1);
        }
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
          rows = cols = (targetPuzzle.pieceCount > 0) ? sqrt(targetPuzzle.pieceCount).round() : 4;
        }
        return await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (context) => GameScreen(
              title: targetPuzzle.name,
              puzzlePath: puzzlePath,
              rows: rows,
              cols: cols,
              confettiController: ConfettiController(duration: const Duration(seconds: 6)),
              locale: Localizations.localeOf(context),
              isAuthenticated: true,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        );
      }
      Map<String, dynamic>? result = await navigateToGame(puzzle);
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
