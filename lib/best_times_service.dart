import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class BestTimesService {
  static const String _prefix = 'bestTimes_';
  static const String _offlineKey = 'bestTimes_offline';
  
  // Cache em memória por usuário
  static final Map<String, Map<String, int>> _memoryCache = {};
  
  /// Obtém chave específica do usuário (ou offline se não autenticado)
  String _getUserKey() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? '$_prefix${user.uid}' : _offlineKey;
  }
  
  /// Carrega bestTimes do usuário atual (cache + sync se online)
  Future<Map<String, int>> loadBestTimes() async {
    final userKey = _getUserKey();
    final user = FirebaseAuth.instance.currentUser;
    
    // 1. PRIMEIRO: Carrega do cache local (SharedPreferences)
    final localTimes = await _loadFromLocalCache(userKey);
    debugPrint('Loaded local cache for $userKey: $localTimes');
    
    // 2. SEGUNDO: Se usuário autenticado, sincroniza com Firestore
    if (user != null) {
      try {
        final firestoreTimes = await _loadFromFirestore(user.uid);
        debugPrint('Loaded Firestore times for ${user.uid}: $firestoreTimes');
        
        // 3. TERCEIRO: Merge inteligente (sempre os melhores tempos)
        final mergedTimes = _mergeBestTimes(localTimes, firestoreTimes);
        debugPrint('Merged times: $mergedTimes');
        
        // 4. QUARTO: Atualiza cache e Firestore com os melhores tempos
        await _saveToLocalCache(userKey, mergedTimes);
        await _saveToFirestore(user.uid, mergedTimes);
        
        // 5. QUINTO: Atualiza cache em memória
        _memoryCache[userKey] = Map.from(mergedTimes);
        
        return mergedTimes;
        
      } catch (e) {
        debugPrint('Firestore sync failed (offline?): $e');
        // FALLBACK: Usa cache local
        _memoryCache[userKey] = Map.from(localTimes);
        return localTimes;
      }
    } else {
      // USUÁRIO OFFLINE: Usa apenas cache local
      _memoryCache[userKey] = Map.from(localTimes);
      return localTimes;
    }
  }
  
  /// Salva novo bestTime (cache + Firestore se online)
  Future<bool> saveBestTime(String puzzleId, int timeSeconds) async {
    final userKey = _getUserKey();
    final user = FirebaseAuth.instance.currentUser;
    
    // 1. Carrega tempos atuais
    final currentTimes = _memoryCache[userKey] ?? await loadBestTimes();
    
    // 2. Verifica se é realmente melhor tempo
    final existingTime = currentTimes[puzzleId];
    if (existingTime != null && timeSeconds >= existingTime) {
      debugPrint('Time $timeSeconds for $puzzleId is not better than existing $existingTime');
      return false; // Não é melhor tempo
    }
    
    // 3. Atualiza com novo melhor tempo
    currentTimes[puzzleId] = timeSeconds;
    debugPrint('New best time for $puzzleId: $timeSeconds seconds');
    
    // 4. Salva no cache local
    await _saveToLocalCache(userKey, currentTimes);
    
    // 5. Salva no Firestore se usuário autenticado
    if (user != null) {
      try {
        await _saveToFirestore(user.uid, currentTimes);
        debugPrint('Best time saved to Firestore for user: ${user.uid}');
      } catch (e) {
        debugPrint('Failed to save to Firestore (offline?): $e');
        // Continua mesmo se Firestore falhar (modo offline)
      }
    }
    
    // 6. Atualiza cache em memória
    _memoryCache[userKey] = Map.from(currentTimes);
    
    return true; // É novo melhor tempo
  }
  
  /// Obtém bestTime específico de um puzzle
  Future<int?> getBestTime(String puzzleId) async {
    final userKey = _getUserKey();
    final currentTimes = _memoryCache[userKey] ?? await loadBestTimes();
    return currentTimes[puzzleId];
  }
  
  /// Obtém todos os bestTimes do usuário atual
  Future<Map<String, int>> getAllBestTimes() async {
    final userKey = _getUserKey();
    return _memoryCache[userKey] ?? await loadBestTimes();
  }
  
  /// Limpa cache do usuário (útil para logout)
  Future<void> clearUserCache() async {
    final userKey = _getUserKey();
    _memoryCache.remove(userKey);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
    
    debugPrint('Cleared cache for $userKey');
  }
  
  /// Migra dados offline para usuário autenticado (primeira vez que faz login)
  Future<void> migrateOfflineData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Carrega dados offline
      final offlineTimes = await _loadFromLocalCache(_offlineKey);
      if (offlineTimes.isEmpty) {
        debugPrint('No offline data to migrate for user: ${user.uid}');
        return;
      }
      
      debugPrint('Migrating offline data for user ${user.uid}: $offlineTimes');
      
      // Carrega dados existentes do usuário no Firestore
      final userTimes = await _loadFromFirestore(user.uid);
      
      // Merge com dados offline (mantém melhores tempos)
      final mergedTimes = _mergeBestTimes(offlineTimes, userTimes);
      
      // Salva dados migrados
      final userKey = '$_prefix${user.uid}';
      await _saveToLocalCache(userKey, mergedTimes);
      await _saveToFirestore(user.uid, mergedTimes);
      
      // Limpa dados offline após migração
      await _clearOfflineData();
      
      debugPrint('Migration completed for user ${user.uid}: $mergedTimes');
      
    } catch (e) {
      debugPrint('Error during offline data migration: $e');
    }
  }
  
  // --- MÉTODOS PRIVADOS ---
  
  /// Carrega bestTimes do cache local (SharedPreferences)
  Future<Map<String, int>> _loadFromLocalCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(key);
      
      if (stored != null) {
        final decoded = Map<String, dynamic>.from(jsonDecode(stored));
        return decoded.map((k, v) => MapEntry(k, v as int));
      }
    } catch (e) {
      debugPrint('Error loading local cache for $key: $e');
    }
    return {};
  }
  
  /// Salva bestTimes no cache local (SharedPreferences)
  Future<void> _saveToLocalCache(String key, Map<String, int> times) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(times));
    } catch (e) {
      debugPrint('Error saving local cache for $key: $e');
    }
  }
  
  /// Carrega bestTimes do Firestore
  Future<Map<String, int>> _loadFromFirestore(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('bestTimes')) {
          final firestoreTimes = Map<String, dynamic>.from(data['bestTimes']);
          return firestoreTimes.map((k, v) => MapEntry(k, v as int));
        }
      }
    } catch (e) {
      debugPrint('Error loading Firestore times for $userId: $e');
      rethrow; // Re-throw para indicar falha de rede
    }
    return {};
  }
  
  /// Salva bestTimes no Firestore
  Future<void> _saveToFirestore(String userId, Map<String, int> times) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
            'bestTimes': times,
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving Firestore times for $userId: $e');
      rethrow; // Re-throw para indicar falha de rede
    }
  }
  
  /// Merge inteligente: sempre mantém os melhores tempos (valores menores)
  Map<String, int> _mergeBestTimes(Map<String, int> times1, Map<String, int> times2) {
    final merged = <String, int>{};
    
    // Adiciona todos os tempos da primeira lista
    merged.addAll(times1);
    
    // Para cada tempo da segunda lista, mantém o melhor
    for (final entry in times2.entries) {
      final puzzleId = entry.key;
      final time2 = entry.value;
      final time1 = merged[puzzleId];
      
      if (time1 == null || time2 < time1) {
        merged[puzzleId] = time2; // time2 é melhor
      }
      // Se time1 <= time2, mantém time1 (já está no merged)
    }
    
    return merged;
  }
  
  /// Limpa dados offline após migração
  Future<void> _clearOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineKey);
      await prefs.remove('bestTimes'); // Remove chave antiga também
      _memoryCache.remove(_offlineKey);
    } catch (e) {
      debugPrint('Error clearing offline data: $e');
    }
  }

  /// Limpa toda a cache de bestTimes (memória e local) - TODOS OS USUÁRIOS
  Future<void> clearCache() async {
    try {
      // Limpa cache de memória
      _memoryCache.clear();
      
      // Limpa cache local
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final bestTimesKeys = keys.where((key) => 
        key.startsWith('bestTimes_') || key == 'bestTimes'
      ).toList();
      
      for (String key in bestTimesKeys) {
        await prefs.remove(key);
      }
      
      debugPrint('BestTimes cache cleared - removed ${bestTimesKeys.length} keys');
    } catch (e) {
      debugPrint('Error clearing BestTimes cache: $e');
    }
  }

  /// Limpa cache de bestTimes apenas do usuário específico
  Future<void> clearSpecificUserCache(String userId) async {
    try {
      // Gera a chave específica do usuário
      final userKey = 'bestTimes_$userId';
      
      // Limpa cache de memória para este usuário
      _memoryCache.remove(userKey);
      _memoryCache.remove(_offlineKey); // Remove offline também se existir
      
      // Limpa cache local do usuário específico
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(userKey);
      await prefs.remove('bestTimes'); // Remove dados offline antigos também
      
      debugPrint('BestTimes cache cleared for user $userId');
    } catch (e) {
      debugPrint('Error clearing BestTimes cache for user $userId: $e');
    }
  }

  /// Limpa apenas cache offline (para usuários não logados)
  Future<void> clearOfflineCache() async {
    try {
      // Limpa cache de memória offline
      _memoryCache.remove(_offlineKey);
      
      // Limpa cache local offline
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineKey);
      await prefs.remove('bestTimes'); // Remove chave antiga para compatibilidade
      
      debugPrint('Offline BestTimes cache cleared');
    } catch (e) {
      debugPrint('Error clearing offline BestTimes cache: $e');
    }
  }

  /// Debug: Lista todas as chaves de bestTimes na cache local
  Future<List<String>> debugListCacheKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final bestTimesKeys = keys.where((key) => 
        key.startsWith('bestTimes_') || key == 'bestTimes'
      ).toList();
      
      debugPrint('BestTimes cache keys found: $bestTimesKeys');
      return bestTimesKeys;
    } catch (e) {
      debugPrint('Error listing cache keys: $e');
      return [];
    }
  }
}