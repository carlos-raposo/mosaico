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
  bool _cacheLoaded = false;
  String? _cachedUserId; // Para detectar mudança de usuário

  /// Carrega a lista de puzzles desbloqueados (primeiro local, depois remoto se autenticado)
  Future<List<int>> getUnlockedPuzzles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;
    
    // Se mudou de usuário, limpa o cache
    if (_cachedUserId != currentUserId) {
      debugPrint('User changed from ${_cachedUserId} to ${currentUserId} - clearing cache');
      _cachedUnlockedPuzzles.clear();
      _cacheLoaded = false;
      _cachedUserId = currentUserId;
    }
    
    if (_cacheLoaded && _cachedUnlockedPuzzles.isNotEmpty) {
      return _cachedUnlockedPuzzles;
    }

    // Tenta carregar do cache local primeiro (mais rápido)
    final localPuzzles = await _loadUnlockedPuzzlesFromLocal();
    
    if (currentUser != null) {
      // USUÁRIO AUTENTICADO: Usa APENAS dados do Firestore (ignora dados locais)
      final remotePuzzles = await _loadUnlockedPuzzlesFromFirestore(currentUser.uid);
      
      if (remotePuzzles.isNotEmpty) {
        // Tem dados no Firestore - usa eles
        debugPrint('Authenticated user - using Firestore data: $remotePuzzles');
        _cachedUnlockedPuzzles = remotePuzzles;
      } else {
        // Não tem dados no Firestore - inicializa com puzzle 1
        debugPrint('Authenticated user - no Firestore data, initializing with Puzzle 1');
        _cachedUnlockedPuzzles = [1];
        await _saveUnlockedPuzzlesToFirestore(currentUser.uid, _cachedUnlockedPuzzles);
      }
      
      // NÃO salva/usa dados locais para usuários autenticados
      // Cada usuário tem seus próprios dados no Firestore
    } else {
      // Não autenticado, usa apenas dados locais
      _cachedUnlockedPuzzles = localPuzzles;
      
      // Se lista vazia, inicializa com puzzle 1
      if (_cachedUnlockedPuzzles.isEmpty) {
        _cachedUnlockedPuzzles = [1];
        await _saveUnlockedPuzzlesToLocal(_cachedUnlockedPuzzles);
      }
    }
    
    _cacheLoaded = true;
    return _cachedUnlockedPuzzles;
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
      
      // Atualiza cache
      _cachedUnlockedPuzzles = updatedPuzzles;
      
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
        final data = userDoc.data() as Map<String, dynamic>?;
        
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
            _cacheLoaded = true;
            
            debugPrint('Legacy migration completed: All puzzles unlocked');
          } else {
            debugPrint('NEW ACCOUNT detected - initializing with Puzzle 1 only: ${user.uid}');
            
            final initialPuzzles = [1];
            await _saveUnlockedPuzzlesToFirestore(user.uid, initialPuzzles);
            await _saveUnlockedPuzzlesToLocal(initialPuzzles);
            
            _cachedUnlockedPuzzles = initialPuzzles;
            _cacheLoaded = true;
            
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

  /// Limpa cache (útil para logout)
  void clearCache() {
    _cachedUnlockedPuzzles.clear();
    _cacheLoaded = false;
    _cachedUserId = null;
    debugPrint('ProgressService cache cleared');
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
        final data = userDoc.data() as Map<String, dynamic>?;
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

  /// Faz merge de duas listas, mantendo a que tem mais puzzles desbloqueados
  List<int> _mergePuzzleLists(List<int> list1, List<int> list2) {
    final merged = <int>{...list1, ...list2}.toList();
    merged.sort();
    return merged;
  }

  /// Verifica se duas listas são iguais
  bool _listsAreEqual(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}