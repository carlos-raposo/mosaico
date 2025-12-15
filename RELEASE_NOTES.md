## 1.0.2 (2025-12-15)
- Correções de puzzles e assets:
	- Normalizados nomes de pastas de assets para minúsculas (ex.: `4x4`, `5x5`).
	- Ajustados `pieceFolder`/`pieceCount` para corresponder aos assets:
		- Puzzle 1/3/4/5/6/7/8/10 → `4x4` com 16 peças.
		- Puzzle 9 → `5x5` com 25 peças.
- UX e navegação:
	- Botão de saída passa a mostrar "Entrar/Login" quando não autenticado; quando autenticado, confirma e executa logout.
- Qualidade de código:
	- Removido aviso `empty_catches` adicionando comentário explicativo no fluxo de logout.
- Versionamento e build:
	- Android: `versionCode` 3, `versionName` 1.0.2.
	- Flutter/iOS: `pubspec.yaml` atualizado para `1.0.2+3` (iOS herda via `FLUTTER_BUILD_NAME/NUMBER`).
	- UI: rodapé da `HomeScreen` atualizado para "Versão 1.0.2".

### Play Store (curto)
PT-PT
- Corrigimos puzzles com grelhas erradas; assets normalizados (4x4, 5x5).
- Botão Entrar/Logout mais claro, com confirmação ao terminar sessão.
- Melhorias de estabilidade e pequenas correções.

PT-BR
- Corrigimos quebra-cabeças com grades incorretas; assets normalizados (4x4, 5x5).
- Botão Entrar/Sair mais claro, com confirmação ao encerrar sessão.
- Melhorias de estabilidade e pequenos ajustes.

EN
- Fixed incorrect puzzle grids; normalized assets (4x4, 5x5).
- Clearer Login/Logout button with logout confirmation.
- Stability improvements and minor fixes.

## 1.0.1 (2025-12-09)
- Atualizações de UX e textos:
	- Corrigido texto PT-BR corrompido no SnackBar de tempo irrealístico em `game_screen.dart`.
	- Rodapé na `HomeScreen` agora mostra "Versão 1.0.1".
- Confiabilidade e navegação:
	- Ajustes de uso de `BuildContext` assíncrono em `settings_page.dart` (captura de `NavigatorState`/`ScaffoldMessenger`, `mounted`).
	- Fluxo de logout mais robusto, evitando contextos pós-await.
- Build e publicação:
	- Incrementados `versionCode` para 2 e `versionName` para 1.0.1 em `android/app/build.gradle`.
	- Gerado `app-release.aab` para Play Store.

# Release Notes - Mosaico v1.0.0

## Google Play Store

**Novidades (PT-PT):**
Primeira versão do Mosaico! 🎉
• Quebra-cabeças com múltiplos níveis
• Coleções variadas de imagens
• Ranking global
• Login com Google e Apple
• Sincronização na nuvem
• Temas claro/escuro
• Suporte a PT-PT, PT-BR e EN
Divirta-se! 🧩

**Novidades (PT-BR):**
Primeira versão do Mosaico! 🎉
• Quebra-cabeças com vários níveis
• Diversas coleções de imagens
• Ranking global
• Login com Google e Apple
• Sincronização na nuvem
• Temas claro/escuro
• Suporte a PT-PT, PT-BR e EN
Divirta-se! 🧩

**What's new (EN):**
First release of Mosaico! 🎉
• Puzzles with multiple levels
• Various image collections
• Global ranking
• Google and Apple sign-in
• Cloud sync
• Light/dark themes
• Supports PT-PT, PT-BR and EN
Have fun! 🧩
