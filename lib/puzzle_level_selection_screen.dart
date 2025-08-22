
import 'package:flutter/material.dart';




class PuzzleLevelSelectionScreen extends StatelessWidget {
  final String collectionName;
  final String puzzleName;
  final String puzzleImagePath;

  const PuzzleLevelSelectionScreen({
    Key? key,
    required this.collectionName,
    required this.puzzleName,
    required this.puzzleImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$collectionName > $puzzleName'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                puzzleImagePath,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            // ...existing code...
            // Lógica de níveis removida
          ],
        ),
      ),
    );
  }
}
