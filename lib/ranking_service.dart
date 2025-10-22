import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RankingService {
  
  // Sincroniza todos os melhores tempos locais com Firestore
  Future<void> syncOfflineTimesToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Carrega tempos locais (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('bestTimes');
      if (stored == null) return;
      
      final localBestTimes = Map<String, dynamic>.from(jsonDecode(stored));
      if (localBestTimes.isEmpty) return;
      
      // Para cada puzzle com tempo local, sincroniza com Firestore
      for (final entry in localBestTimes.entries) {
        final puzzleId = entry.key;
        final localTime = entry.value as int;
        
        debugPrint('Syncing offline time for $puzzleId: $localTime seconds');
        
        // Atualiza melhor tempo pessoal no Firestore
        await updateUserBestTime(puzzleId, localTime);
        
        // Atualiza ranking global se aplicável
        await updateRanking(puzzleId, puzzleId, localTime);
      }
      
      debugPrint('Offline times sync completed');
    } catch (e) {
      debugPrint('Error syncing offline times: $e');
    }
  }

  Future<void> updateUserBestTime(String puzzleId, int time) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    Map<String, dynamic> bestTimes = {};
    if (userDoc.exists && userDoc.data() != null && userDoc.data()!['bestTimes'] != null) {
      bestTimes = Map<String, dynamic>.from(userDoc.data()!['bestTimes']);
    }
    final currentBest = bestTimes[puzzleId];
    bool shouldUpdate = false;
    if (currentBest == null) {
      shouldUpdate = true;
    } else if (currentBest is int && time < currentBest) {
      shouldUpdate = true;
    } else if (currentBest is String) {
      final parsed = int.tryParse(currentBest);
      if (parsed != null && time < parsed) {
        shouldUpdate = true;
      }
    }
    if (shouldUpdate) {
      bestTimes[puzzleId] = time;
      await userRef.set({'bestTimes': bestTimes}, SetOptions(merge: true));
    }
  }
  // Função utilitária para buscar o melhor tempo do usuário logado em um puzzle
  int? getUserBestTime(List<dynamic> topTimes, String userId) {
    for (final entry in topTimes) {
      if (entry is Map<String, dynamic> && entry['userId'] == userId) {
        if (entry['time'] is int) {
          return entry['time'] as int;
        } else if (entry['time'] is String) {
          return int.tryParse(entry['time']);
        }
      }
    }
    return null;
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> updateRanking(String puzzleId, String puzzleName, int time) async {
  // ...existing code...
  // Função utilitária para exibir ranking sem nulls
    // puzzleId e puzzleName devem ser únicos para cada puzzle
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('User is not authenticated');
      return false;
    }

    debugPrint('Updating ranking for puzzleId: $puzzleId with time: $time');

    final documentId = puzzleId;
    final rankingRef = _firestore.collection('rankings').doc(documentId);

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rankingRef);

      if (!snapshot.exists) {
  debugPrint('Creating new ranking document for puzzleId: $puzzleId');
        transaction.set(rankingRef, {
          'puzzleId': puzzleId,
          'puzzleName': puzzleName,
          'topTimes': [
            {
              'userId': userId,
              'time': time,
              'lastUpdated': Timestamp.now(),
            }
          ],
        });
        return true;
      }

      final data = snapshot.data();
      if (data == null || data is! Map<String, dynamic>) {
  debugPrint('Invalid data format for puzzleId: $puzzleId');
        return false;
      }

      final topTimes = data['topTimes'];
      if (topTimes is! List) {
  debugPrint('Invalid topTimes format for puzzleId: $puzzleId');
        return false;
      }

      final topTimesList = topTimes.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else {
          debugPrint('Invalid item type in topTimes: $item');
          return null;
        }
      }).where((item) => item != null).cast<Map<String, dynamic>>().toList();

      final existingIndex = topTimesList.indexWhere((entry) => entry['userId'] == userId);
      if (existingIndex != -1) {
        if (topTimesList[existingIndex]['time'] is String) {
          topTimesList[existingIndex]['time'] = int.tryParse(topTimesList[existingIndex]['time']) ?? 0;
        }
        if (topTimesList[existingIndex]['time'] <= time) {
          debugPrint('Existing time is better or equal, not updating');
          return false;
        }
        topTimesList[existingIndex] = {
          'userId': userId,
          'time': time,
          'lastUpdated': Timestamp.now(),
        };
      } else {
        topTimesList.add({
          'userId': userId,
          'time': time,
          'lastUpdated': Timestamp.now(),
        });
      }

      topTimesList.forEach((entry) {
        if (entry['time'] is String) {
          entry['time'] = int.tryParse(entry['time']) ?? 0;
        }
      });

      topTimesList.sort((a, b) => (a['time'] as int).compareTo(b['time'] as int));

      if (topTimesList.length > 10) {
  topTimesList.removeLast();
      }

      print('Updating ranking document for puzzleId: $puzzleId with topTimes: $topTimesList');
      debugPrint('Updating ranking document for puzzleId: $puzzleId with topTimes: $topTimesList');
      transaction.update(rankingRef, {
        'puzzleId': puzzleId,
        'puzzleName': puzzleName,
        'topTimes': topTimesList,
      });

      return topTimesList.isNotEmpty && topTimesList.first['userId'] == userId && topTimesList.first['time'] == time;
    });
  }
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int calculateTimeInSeconds(Timestamp timestamp) {
    final now = Timestamp.now();
    final difference = now.seconds - timestamp.seconds;
    return difference;
  }
}