# 🔒 Nota sobre Segurança do Firebase

## Arquivos de Configuração Públicos

Este repositório inclui os seguintes arquivos de configuração do Firebase:

- `android/app/google-services.json`
- `firebase.json`
- `.firebaserc`

## ⚠️ É Seguro Tornar Estes Arquivos Públicos?

**Sim!** Estes arquivos contêm apenas configurações **client-side** (lado do cliente) do Firebase, que são projetadas para serem públicas. Eles incluem:

- Project ID
- API Keys (client-side)
- App IDs
- Client IDs para OAuth

### Por que é Seguro?

1. **API Keys do Firebase são diferentes de chaves de servidor**: As chaves nos arquivos de configuração são chaves de cliente que podem ser expostas publicamente.

2. **Segurança via Firestore Rules**: A segurança real do seu projeto Firebase é garantida pelas **Firestore Security Rules** (definidas em `firestore.rules`), não pela ocultação das chaves de API.

3. **Documentação Oficial do Firebase**: O próprio Google/Firebase [confirma que é seguro](https://firebase.google.com/docs/projects/api-keys) expor estas chaves.

## 🛡️ Onde Está a Verdadeira Segurança?

A segurança do projeto é garantida por:

### 1. Firestore Security Rules (`firestore.rules`)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuários só podem editar seus próprios dados
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Rankings são públicos para leitura, mas requerem autenticação para escrita
    match /rankings/{rankingId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 2. Authentication

- Somente usuários autenticados podem modificar dados
- Validação de email/senha pelo Firebase Auth
- OAuth seguro via Google Sign-In

### 3. Configurações do Projeto Firebase

No Firebase Console, você deve:

- ✅ Configurar domínios autorizados para OAuth
- ✅ Habilitar apenas métodos de autenticação necessários
- ✅ Configurar quotas e limites de uso
- ✅ Monitorar logs de acesso

## 🔑 O que NÃO Deve Ser Tornado Público

Nunca commite para o repositório público:

- ❌ Service Account Keys (arquivos JSON de conta de serviço)
- ❌ Private Keys do Firebase Admin SDK
- ❌ Tokens de API de serviços terceiros
- ❌ Credenciais de banco de dados
- ❌ Chaves de API de servidor
- ❌ Arquivos `.env` com secrets

## 📚 Referências

- [Firebase: Using API Keys](https://firebase.google.com/docs/projects/api-keys)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Best Practices for Security Rules](https://firebase.google.com/docs/firestore/security/rules-best-practices)

## ✨ Para Contribuidores

Se você for usar este projeto com seu próprio Firebase:

1. Crie seu próprio projeto no [Firebase Console](https://console.firebase.google.com/)
2. Configure os serviços (Auth, Firestore, Hosting)
3. Baixe seus próprios arquivos de configuração
4. Substitua os arquivos existentes pelos seus
5. Configure as mesmas Security Rules para garantir segurança

---

**Em resumo**: As chaves de API do Firebase neste repositório são **client-side keys** que são seguras para serem públicas. A segurança real vem das Firestore Security Rules e configurações adequadas no Firebase Console.
