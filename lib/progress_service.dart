import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProgressService {
  static const String _unlockedPuzzlesKey = 'unlockedPuzzles';
  static const int _totalPuzzles = 10; // Total number of puzzles available
  
  // Cache por instância (não static) para evitar compartilhamento entre usuários
  List<int> _cachedUnlockedPuzzles = [];
  String? _cachedUserId; // Para detectar mudança de usuário

  /// Carrega a lista de puzzles desbloqueados (primeiro local, depois remoto se autenticado)
  Future<List<int>> getUnlockedPuzzles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;
    
    // Se mudou de usuário, limpa o cache
    if (_cachedUserId != currentUserId) {
  debugPrint('User changed from $_cachedUserId to $currentUserId - clearing cache');
      _cachedUnlockedPuzzles.clear();
      _cachedUserId = currentUserId;
    }
    
    if (currentUser != null) {
      // USUÁRIO AUTENTICADO: Tenta Firestore, fallback para cache se offline
      try {
        final remotePuzzles = await _loadUnlockedPuzzlesFromFirestore(currentUser.uid);
        
        if (remotePuzzles.isNotEmpty) {
          // Tem dados no Firestore - usa eles e atualiza cache
          debugPrint('Authenticated user - using Firestore data: $remotePuzzles');
          _cachedUnlockedPuzzles = remotePuzzles;
          return remotePuzzles;
        } else {
          // Não tem dados no Firestore - inicializa com puzzle 1
          debugPrint('Authenticated user - no Firestore data, initializing with Puzzle 1');
          _cachedUnlockedPuzzles = [1];
          await _saveUnlockedPuzzlesToFirestore(currentUser.uid, _cachedUnlockedPuzzles);
          return _cachedUnlockedPuzzles;
        }
      } catch (e) {
        debugPrint('Failed to load from Firestore (offline?): $e');
        
        // FALLBACK: Usa cache se disponível, senão inicializa com [1]
        if (_cachedUnlockedPuzzles.isNotEmpty) {
          debugPrint('Using cached data while offline: $_cachedUnlockedPuzzles');
          return _cachedUnlockedPuzzles;
        } else {
          debugPrint('No cache available, initializing with Puzzle 1');
          _cachedUnlockedPuzzles = [1];
          return _cachedUnlockedPuzzles;
        }
      }
    } else {
      // USUÁRIO NÃO AUTENTICADO: Usa cache local se disponível
      if (_cachedUnlockedPuzzles.isNotEmpty) {
        return _cachedUnlockedPuzzles;
      }
      
      // Carrega dados locais
      final localPuzzles = await _loadUnlockedPuzzlesFromLocal();
      _cachedUnlockedPuzzles = localPuzzles.isEmpty ? [1] : localPuzzles;
      
      // Se inicializou com [1], salva localmente
      if (localPuzzles.isEmpty) {
        await _saveUnlockedPuzzlesToLocal(_cachedUnlockedPuzzles);
      }
      
      return _cachedUnlockedPuzzles;
    }
  }

  /// Força um reload inteligente do cache (funciona online e offline)
  Future<void> forceReloadCache() async {
    debugPrint('Forcing cache reload...');
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      try {
        // Tenta buscar dados atualizados do Firestore
        final remotePuzzles = await _loadUnlockedPuzzlesFromFirestore(currentUser.uid);
        if (remotePuzzles.isNotEmpty) {
          _cachedUnlockedPuzzles = remotePuzzles;
          debugPrint('Cache reloaded from Firestore: $remotePuzzles');
          return;
        }
      } catch (e) {
        debugPrint('Failed to reload from Firestore (offline?): $e');
        // Continua usando cache atual se Firestore falhar
      }
    }
    
    // FORÇA reload do SharedPreferences mesmo se cache não estiver vazia
    debugPrint('Force reloading from local storage...');
    final localPuzzles = await _loadUnlockedPuzzlesFromLocal();
    _cachedUnlockedPuzzles = localPuzzles.isEmpty ? [1] : localPuzzles;
    
    // Se inicializou com [1], salva localmente
    if (localPuzzles.isEmpty) {
      await _saveUnlockedPuzzlesToLocal(_cachedUnlockedPuzzles);
    }
    
    debugPrint('Cache reload completed: $_cachedUnlockedPuzzles');
  }

  /// Verifica se um puzzle específico está desbloqueado
  Future<bool> isPuzzleUnlocked(int puzzleNumber) async {
    final unlockedPuzzles = await getUnlockedPuzzles();
    return unlockedPuzzles.contains(puzzleNumber);
  }

  /// Desbloqueia o próximo puzzle após completar o atual
  Future<int?> unlockNextPuzzle(String currentPuzzleId) async {
    try {
      // Extrai número do puzzle: "Puzzle 5" -> 5
      final currentNumber = _extractPuzzleNumber(currentPuzzleId);
      if (currentNumber == null) {
        debugPrint('Could not extract puzzle number from: $currentPuzzleId');
        return null;
      }
      
      final nextNumber = currentNumber + 1;
      
      // Verifica se próximo puzzle existe
      if (nextNumber > _totalPuzzles) {
        debugPrint('All puzzles already unlocked! Current: $currentNumber, Total: $_totalPuzzles');
        return null; // Todos puzzles já desbloqueados
      }
      
      final unlockedPuzzles = await getUnlockedPuzzles();
      
      // Verifica se já está desbloqueado
      if (unlockedPuzzles.contains(nextNumber)) {
        debugPrint('Puzzle $nextNumber already unlocked');
        return null;
      }
      
      // Adiciona próximo puzzle à lista
      final updatedPuzzles = [...unlockedPuzzles, nextNumber];
      updatedPuzzles.sort(); // Mantém ordenado
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // USUÁRIO AUTENTICADO: Salva APENAS no Firestore
        await _saveUnlockedPuzzlesToFirestore(user.uid, updatedPuzzles);
        debugPrint('Saved progression to Firestore for user: ${user.uid}');
      } else {
        // USUÁRIO NÃO AUTENTICADO: Salva apenas localmente
        await _saveUnlockedPuzzlesToLocal(updatedPuzzles);
        debugPrint('Saved progression locally (offline mode)');
      }
      
      // Atualiza cache imediatamente para refletir a mudança
      _cachedUnlockedPuzzles = updatedPuzzles;
      
      // Force clear any old cache immediately
      if (user != null) {
        debugPrint('Cache updated after unlock - new puzzles: $updatedPuzzles');
      }
      
      debugPrint('Puzzle $nextNumber unlocked successfully!');
      return nextNumber;
      
    } catch (e) {
      debugPrint('Error unlocking next puzzle: $e');
      return null;
    }
  }

  /// Migra utilizadores existentes - VERSÃO RESTRITIVA (apenas se realmente necessário)
  Future<void> migrateExistingUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Verifica se utilizador já tem campo unlockedPuzzles
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        
        // APENAS faz migração se não tem unlockedPuzzles E tem outros dados importantes
        if (data != null && !data.containsKey('unlockedPuzzles')) {
          debugPrint('User without unlockedPuzzles found: ${user.uid}');
          debugPrint('User data keys: ${data.keys.toList()}');
          
          // Critério MUITO mais restritivo para migração
          // Só migra se claramente é conta muito antiga (tem múltiplos dados)
          final bool isLegacyAccount = data.containsKey('username') && 
                                     data.containsKey('email') &&
                                     data.keys.length >= 3; // Pelo menos 3 campos além de unlockedPuzzles
          
          if (isLegacyAccount) {
            debugPrint('LEGACY ACCOUNT detected - migrating with all puzzles: ${user.uid}');
            
            final allPuzzles = List.generate(_totalPuzzles, (index) => index + 1);
            await _saveUnlockedPuzzlesToFirestore(user.uid, allPuzzles);
            await _saveUnlockedPuzzlesToLocal(allPuzzles);
            
            _cachedUnlockedPuzzles = allPuzzles;
            
            debugPrint('Legacy migration completed: All puzzles unlocked');
          } else {
            debugPrint('NEW ACCOUNT detected - initializing with Puzzle 1 only: ${user.uid}');
            
            final initialPuzzles = [1];
            await _saveUnlockedPuzzlesToFirestore(user.uid, initialPuzzles);
            await _saveUnlockedPuzzlesToLocal(initialPuzzles);
            
            _cachedUnlockedPuzzles = initialPuzzles;
            
            debugPrint('New account initialization: Only Puzzle 1 unlocked');
          }
        } else {
          debugPrint('User already has unlockedPuzzles field, no migration needed: ${user.uid}');
        }
      } else {
        debugPrint('User document does not exist: ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error during user migration: $e');
    }
  }

  /// Limpa cache (útil para logout) - só memória
  void clearCache() {
    _cachedUnlockedPuzzles.clear();
    _cachedUserId = null;
    debugPrint('ProgressService cache cleared');
  }

  /// Limpa cache completamente incluindo SharedPreferences
  Future<void> clearAllCache() async {
    // Limpa cache de memória COMPLETAMENTE
    _cachedUnlockedPuzzles.clear();
    _cachedUserId = null;
    
    // Limpa dados locais
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_unlockedPuzzlesKey);
      debugPrint('ProgressService all cache cleared (including SharedPreferences)');
      
      // FORÇA um reload imediato para garantir estado consistente
      await forceReloadCache();
      
    } catch (e) {
      debugPrint('Error clearing ProgressService SharedPreferences: $e');
    }
  }

  // --- MÉTODOS PRIVADOS ---

  /// Carrega puzzles desbloqueados do SharedPreferences
  Future<List<int>> _loadUnlockedPuzzlesFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_unlockedPuzzlesKey);
      
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        return decoded.cast<int>();
      }
    } catch (e) {
      debugPrint('Error loading local unlocked puzzles: $e');
    }
    return [];
  }

  /// Salva puzzles desbloqueados no SharedPreferences
  Future<void> _saveUnlockedPuzzlesToLocal(List<int> puzzles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_unlockedPuzzlesKey, jsonEncode(puzzles));
    } catch (e) {
      debugPrint('Error saving local unlocked puzzles: $e');
    }
  }

  /// Carrega puzzles desbloqueados do Firestore
  Future<List<int>> _loadUnlockedPuzzlesFromFirestore(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('unlockedPuzzles')) {
          final List<dynamic> puzzles = data['unlockedPuzzles'];
          return puzzles.cast<int>();
        }
      }
    } catch (e) {
      debugPrint('Error loading Firestore unlocked puzzles: $e');
    }
    return [];
  }

  /// Salva puzzles desbloqueados no Firestore
  Future<void> _saveUnlockedPuzzlesToFirestore(String userId, List<int> puzzles) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
            'unlockedPuzzles': puzzles,
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving Firestore unlocked puzzles: $e');
    }
  }

  /// Extrai número do puzzle do ID (ex: "Puzzle 5" -> 5)
  int? _extractPuzzleNumber(String puzzleId) {
    final regex = RegExp(r'Puzzle (\d+)');
    final match = regex.firstMatch(puzzleId);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }


}