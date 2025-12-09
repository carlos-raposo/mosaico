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
