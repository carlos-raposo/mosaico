# 📊 Estrutura dos Dados Firestore - Aplicação Mosaico

## Visão Geral
A aplicação Mosaico utiliza Firebase Firestore como base de dados para armazenar informações de utilizadores e rankings de puzzles. Este documento descreve a estrutura completa dos dados.

---

## 🏗️ Estrutura das Coleções

### 1. Coleção: `users`
**Caminho**: `/users/{userId}`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `username` | string | Nome do utilizador (5-9 caracteres, único) |
| `email` | string | Email do utilizador (único) |
| `bestTimes` | map | Melhores tempos do utilizador por puzzle |
| `bestTimes.{puzzleId}` | int | Tempo em segundos para cada puzzle |
| `unlockedPuzzles` | array | Lista de números dos puzzles desbloqueados [1,2,3...] |

**Exemplo de documento:**
```json
{
  "username": "carlos123",
  "email": "carlos@example.com",
  "bestTimes": {
    "Puzzle 1": 45,
    "Puzzle 2": 78,
    "Puzzle 3": 120
  },
  "unlockedPuzzles": [1, 2, 3, 4]
}
```

### 2. Coleção: `rankings`
**Caminho**: `/rankings/{puzzleId}`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `puzzleId` | string | ID único do puzzle (igual ao document ID) |
| `puzzleName` | string | Nome display do puzzle |
| `topTimes` | array | Array dos 10 melhores tempos (ordenado por tempo crescente) |

**Estrutura do array `topTimes`:**
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `userId` | string | ID do utilizador |
| `time` | int | Tempo em segundos |
| `lastUpdated` | timestamp | Data/hora da última atualização |

**Exemplo de documento:**
```json
{
  "puzzleId": "Puzzle 1",
  "puzzleName": "Puzzle 1",
  "topTimes": [
    {
      "userId": "abc123def456",
      "time": 30,
      "lastUpdated": "2025-10-22T10:30:00Z"
    },
    {
      "userId": "xyz789uvw012",
      "time": 35,
      "lastUpdated": "2025-10-22T09:15:00Z"
    }
  ]
}
```

---

## 🔐 Regras de Segurança (Firestore Security Rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Perfis de utilizador
    match /users/{userId} {
      // Qualquer utilizador autenticado pode ler perfis
      allow read: if request.auth != null;
      
      // Utilizador só pode editar o próprio perfil
      allow write: if request.auth != null && 
                      request.auth.uid == userId;
    }
    
    // Rankings globais
    match /rankings/{rankingId} {
      // Qualquer um pode ler rankings (incluindo não autenticados)
      allow read: if true;
      
      // Só utilizadores autenticados podem escrever
      allow write: if request.auth != null;
    }
  }
}
```

---

## 🔄 Fluxos de Dados Principais

### Registo de Novo Utilizador
1. **Verificação de unicidade** do username na coleção `users`
2. **Verificação de unicidade** do email na coleção `users`
3. **Criação da conta** Firebase Authentication
4. **Criação do documento** em `/users/{uid}` com username e email

### Login com Google
1. **Autenticação** via Google Sign-In
2. **Verificação** se é novo utilizador
3. **Criação automática** do documento em `/users/{uid}` se necessário
4. **Geração do username** a partir do displayName (truncado para 9 chars) ou `User{uid_substring}`

### Atualização de Ranking
1. **Verificação** se o puzzle existe em `/rankings/{puzzleId}`
2. **Criação** do documento se não existir
3. **Atualização** do `bestTimes` do utilizador em `/users/{uid}`
4. **Atualização/inserção** no array `topTimes` do ranking
5. **Ordenação** por tempo crescente e manutenção de apenas top 10

### Conclusão de Puzzle
1. **Cálculo** do tempo final quando puzzle é completado
2. **Reprodução** de som de conclusão (se habilitado)
3. **Atualização** do melhor tempo pessoal do utilizador
4. **Verificação** se é novo recorde global
5. **Exibição** de confetti e mensagem se bateu recorde
6. **Notificação** com tempo de conclusão

---

## 📝 Características Técnicas Importantes

### Identificadores
- **PuzzleId** = **PuzzleName** (são idênticos e únicos)
- **UserId** corresponde ao UID do Firebase Authentication

### Limitações
- **Máximo 10 entradas** por ranking global
- **Username** deve ter entre 5-9 caracteres
- **Validação** de tipos (strings convertidas para int quando necessário)

### Operações
- **Merge operations** para preservar dados existentes
- **Transações** para atualizações atómicas de rankings
- **Timestamps** automáticos para tracking de atualizações
- **Ordenação automática** dos rankings por tempo

### Performance
- **Índices automáticos** para queries por username e email
- **Estrutura otimizada** para leitura de rankings
- **Caching local** de melhores tempos pessoais via SharedPreferences

---

## 🎯 Casos de Uso

### Para Utilizadores Não Autenticados
- ✅ Podem jogar puzzles
- ✅ Podem ver rankings globais
- ❌ Não podem salvar melhores tempos
- ❌ Não aparecem nos rankings

### Para Utilizadores Autenticados
- ✅ Podem jogar puzzles
- ✅ Podem ver rankings globais
- ✅ Salvam melhores tempos pessoais
- ✅ Podem aparecer nos rankings globais
- ✅ Recebem notificações de recordes

---

## 📱 Integração com a Aplicação

### Serviços Utilizados
- **RankingService**: Gestão de rankings e melhores tempos
- **Firebase Auth**: Autenticação de utilizadores
- **SharedPreferences**: Cache local de dados

### Estados da Aplicação
- **isAuthenticated**: Determina funcionalidades disponíveis
- **soundEnabled**: Controla reprodução de áudio
- **isDarkMode**: Tema da aplicação
- **locale**: Idioma (PT/EN)

---

*Documento gerado em: 22 de Outubro de 2025*  
*Aplicação: Mosaico - Jogo de Puzzles*  
*Versão: 1.0.0*