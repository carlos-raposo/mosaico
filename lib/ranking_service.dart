import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RankingService {
  
  // FUNÇÃO CORRIGIDA: Sincroniza tempos offline legitimamente do usuário atual
  Future<void> syncOfflineTimesToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. PRIMEIRO: Preserva tempos offline legítimos (se existem)
      final offlineData = prefs.getString('bestTimes');
      Map<String, dynamic>? legitimateOfflineTimes;
      
      if (offlineData != null) {
        try {
          legitimateOfflineTimes = Map<String, dynamic>.from(jsonDecode(offlineData));
          debugPrint('Found offline times to preserve: ${legitimateOfflineTimes.keys.toList()}');
        } catch (e) {
          debugPrint('Error parsing offline times: $e');
        }
      }
      
      // 2. SEGUNDO: Move tempos offline para chave específica do usuário
      if (legitimateOfflineTimes != null && legitimateOfflineTimes.isNotEmpty) {
        final userSpecificKey = 'bestTimes_${user.uid}';
        
        // Carrega tempos já existentes do usuário (se houver)
        final existingUserData = prefs.getString(userSpecificKey);
        Map<String, dynamic> userTimes = {};
        
        if (existingUserData != null) {
          try {
            userTimes = Map<String, dynamic>.from(jsonDecode(existingUserData));
          } catch (e) {
            debugPrint('Error parsing existing user times: $e');
          }
        }
        
        // Merge inteligente: Mantém o melhor tempo para cada puzzle
        bool hasUpdates = false;
        for (final entry in legitimateOfflineTimes.entries) {
          final puzzleId = entry.key;
          final offlineTime = entry.value as int;
          
          final existingTime = userTimes[puzzleId] as int?;
          if (existingTime == null || offlineTime < existingTime) {
            userTimes[puzzleId] = offlineTime;
            hasUpdates = true;
            debugPrint('Preserving offline time for $puzzleId: $offlineTime seconds');
          }
        }
        
        // Salva tempos do usuário (incluindo offline preservados)
        if (hasUpdates) {
          await prefs.setString(userSpecificKey, jsonEncode(userTimes));
          
          // Sincroniza com Firestore
          for (final entry in legitimateOfflineTimes.entries) {
            final puzzleId = entry.key;
            final time = entry.value as int;
            
            await updateUserBestTime(puzzleId, time);
            // Também atualiza ranking global se aplicável
            await updateRanking(puzzleId, puzzleId, time);
          }
          
          debugPrint('Successfully synced ${legitimateOfflineTimes.length} offline times for user: ${user.uid}');
        }
      }
      
      // 3. TERCEIRO: Remove dados compartilhados SOMENTE após preservar
      if (offlineData != null) {
        await prefs.remove('bestTimes');
        debugPrint('Cleaned up shared bestTimes after preserving legitimate offline data');
      }
      
    } catch (e) {
      debugPrint('Error during offline sync: $e');
    }
    
    /* CÓDIGO ORIGINAL COMENTADO PARA REFERÊNCIA
    try {
      // Carrega tempos locais ESPECÍFICOS DO USUÁRIO
      final prefs = await SharedPreferences.getInstance();
      final userSpecificKey = 'bestTimes_${user.uid}';
      final stored = prefs.getString(userSpecificKey);
      
      if (stored == null) {
        debugPrint('No offline times found for user: ${user.uid}');
        return;
      }
      
      final localBestTimes = Map<String, dynamic>.from(jsonDecode(stored));
      if (localBestTimes.isEmpty) return;
      
      debugPrint('Syncing ${localBestTimes.length} offline times for user: ${user.uid}');
      
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
      
      // LIMPA os tempos offline após sincronizar para evitar re-sincronização
      await prefs.remove(userSpecificKey);
      
      debugPrint('Offline times sync completed and cleared for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error syncing offline times: $e');
    }
    */
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