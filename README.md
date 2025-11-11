# 🎨 Mosaico - Jogo de Puzzles

Um jogo de puzzles em mosaico desenvolvido com Flutter, integrado com Firebase para autenticação e rankings globais.

## 📱 Sobre o Projeto

Mosaico é um jogo de puzzles interativo onde os jogadores podem resolver quebra-cabeças de diferentes tamanhos e dificuldades. O jogo oferece:

- 🧩 Múltiplos puzzles de diferentes níveis de dificuldade (4x4, 5x5, 6x4, 5x8)
- 🏆 Sistema de rankings globais
- 👤 Autenticação com Google Sign-In
- ⏱️ Registro de melhores tempos pessoais
- 🎵 Efeitos sonoros customizáveis
- 🌙 Tema escuro/claro
- 🌍 Suporte para Português e Inglês
- 🎉 Animações de confetti ao completar puzzles

## 🚀 Funcionalidades

### Para Todos os Usuários
- Jogar puzzles de diferentes tamanhos
- Visualizar rankings globais
- Ajustar configurações (som, tema, idioma)

### Para Usuários Autenticados
- Salvar melhores tempos pessoais
- Aparecer nos rankings globais
- Receber notificações de recordes
- Sincronização entre dispositivos

## 🛠️ Tecnologias Utilizadas

- **Flutter** 3.5.3+
- **Firebase Core** - Backend e infraestrutura
- **Firebase Auth** - Autenticação de usuários
- **Cloud Firestore** - Banco de dados NoSQL
- **Google Sign-In** - Autenticação social
- **Provider** - Gerenciamento de estado
- **Audioplayers** - Efeitos sonoros
- **Confetti** - Animações de celebração
- **Google Fonts** - Tipografia

## 📋 Pré-requisitos

- Flutter SDK 3.5.3 ou superior
- Dart SDK incluído no Flutter
- Android Studio / Xcode (para desenvolvimento mobile)
- Conta Firebase (para configuração do projeto)

## 🔧 Instalação e Configuração

### 1. Clone o Repositório

```bash
git clone https://github.com/carlos-raposo/mosaico.git
cd mosaico
```

### 2. Instale as Dependências

```bash
flutter pub get
```

### 3. Configuração do Firebase

Este projeto usa Firebase. Para executar o projeto, você precisará:

1. Criar um projeto no [Firebase Console](https://console.firebase.google.com/)
2. Adicionar aplicações Android/iOS/Web ao seu projeto Firebase
3. Baixar os arquivos de configuração:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
4. Configurar o Firebase CLI:

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login no Firebase
firebase login

# Configurar o projeto
flutterfire configure
```

5. Habilitar os seguintes serviços no Firebase Console:
   - **Authentication**: Ativar Google Sign-In
   - **Cloud Firestore**: Criar banco de dados
   - **Hosting** (opcional): Para deploy web

### 4. Configurar Regras do Firestore

As regras de segurança estão definidas em `firestore.rules`. Para aplicá-las:

```bash
firebase deploy --only firestore:rules
```

Consulte `ESTRUTURA_FIRESTORE.md` para detalhes sobre a estrutura do banco de dados.

### 5. Execute o Projeto

```bash
# Para executar em modo debug
flutter run

# Para executar em um dispositivo específico
flutter devices
flutter run -d <device-id>

# Para web
flutter run -d chrome
```

## 📱 Plataformas Suportadas

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Linux
- ✅ Windows

## 🗂️ Estrutura do Projeto

```
mosaico/
├── lib/
│   ├── main.dart                              # Ponto de entrada
│   ├── auth_page.dart                         # Tela de autenticação
│   ├── home_screen.dart                       # Tela inicial
│   ├── collection_selection_screen.dart       # Seleção de coleções
│   ├── puzzle_level_selection_screen.dart     # Seleção de níveis
│   ├── game_screen.dart                       # Tela do jogo
│   ├── ranking_screen.dart                    # Tela de rankings
│   ├── ranking_service.dart                   # Serviço de rankings
│   ├── settings_page.dart                     # Configurações
│   ├── settings_controller.dart               # Controle de configurações
│   ├── style_guide.dart                       # Guia de estilo
│   └── firebase_options.dart                  # Configurações Firebase
├── assets/
│   ├── audio/                                 # Efeitos sonoros
│   └── images/                                # Imagens dos puzzles
├── android/                                   # Configurações Android
├── ios/                                       # Configurações iOS
├── web/                                       # Configurações Web
├── firestore.rules                            # Regras de segurança Firestore
├── firestore.indexes.json                     # Índices Firestore
└── ESTRUTURA_FIRESTORE.md                     # Documentação do banco de dados
```

## 🎮 Como Jogar

1. **Autentique-se** (opcional): Faça login com sua conta Google para salvar seu progresso
2. **Escolha uma coleção**: Selecione uma coleção de puzzles
3. **Selecione um puzzle**: Escolha o puzzle que deseja resolver
4. **Monte o puzzle**: Arraste e solte as peças para completar a imagem
5. **Complete o desafio**: Tente bater seu melhor tempo ou entrar no ranking global!

## 🔒 Segurança e Privacidade

- As regras de segurança do Firestore garantem que usuários só podem editar seus próprios dados
- As chaves de API do Firebase incluídas no repositório são chaves **client-side** e são seguras para serem públicas
- A segurança é garantida pelas **Firestore Security Rules** configuradas no servidor
- Nunca compartilhamos informações pessoais além do username e email

## 📄 Documentação Adicional

- [ESTRUTURA_FIRESTORE.md](ESTRUTURA_FIRESTORE.md) - Documentação completa da estrutura do banco de dados

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para:

1. Fazer fork do projeto
2. Criar uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abrir um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👨‍💻 Autor

**Carlos Raposo**

- GitHub: [@carlos-raposo](https://github.com/carlos-raposo)

## 🙏 Agradecimentos

- Flutter Team pela excelente framework
- Firebase pela infraestrutura backend
- Comunidade Flutter pelas packages incríveis

---

Desenvolvido com ❤️ usando Flutter
