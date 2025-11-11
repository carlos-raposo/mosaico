# 🤝 Guia de Contribuição

Obrigado por considerar contribuir para o Mosaico! Este documento fornece diretrizes para contribuir com o projeto.

## 📋 Código de Conduta

Ao participar deste projeto, você concorda em manter um ambiente respeitoso e acolhedor para todos os colaboradores.

## 🚀 Como Contribuir

### Reportar Bugs

Se você encontrou um bug, por favor:

1. Verifique se o bug já não foi reportado nas [Issues](https://github.com/carlos-raposo/mosaico/issues)
2. Se não existir, crie uma nova issue incluindo:
   - Descrição clara do problema
   - Passos para reproduzir
   - Comportamento esperado vs. comportamento atual
   - Screenshots (se aplicável)
   - Informações do ambiente (versão do Flutter, SO, dispositivo)

### Sugerir Melhorias

Para sugerir novas funcionalidades:

1. Abra uma issue com o prefixo `[Feature Request]`
2. Descreva claramente a funcionalidade desejada
3. Explique por que seria útil para o projeto
4. Se possível, sugira uma implementação

### Fazer Pull Requests

1. **Fork o repositório**
   ```bash
   # Clone seu fork
   git clone https://github.com/seu-usuario/mosaico.git
   cd mosaico
   ```

2. **Crie uma branch para sua feature**
   ```bash
   git checkout -b feature/minha-feature
   # ou
   git checkout -b fix/meu-bug-fix
   ```

3. **Configure o ambiente**
   ```bash
   flutter pub get
   ```

4. **Faça suas alterações**
   - Mantenha o código limpo e bem documentado
   - Siga as convenções de código do projeto
   - Adicione comentários quando necessário

5. **Teste suas mudanças**
   ```bash
   # Execute os testes
   flutter test
   
   # Verifique o código
   flutter analyze
   
   # Formate o código
   flutter format .
   ```

6. **Commit suas mudanças**
   ```bash
   git add .
   git commit -m "feat: adiciona nova funcionalidade X"
   ```
   
   Use mensagens de commit descritivas seguindo o padrão:
   - `feat:` para novas funcionalidades
   - `fix:` para correções de bugs
   - `docs:` para mudanças na documentação
   - `style:` para formatação de código
   - `refactor:` para refatorações
   - `test:` para adição/modificação de testes
   - `chore:` para tarefas de manutenção

7. **Push para seu fork**
   ```bash
   git push origin feature/minha-feature
   ```

8. **Abra um Pull Request**
   - Descreva claramente as mudanças feitas
   - Referencie issues relacionadas
   - Adicione screenshots se houver mudanças visuais

## 📝 Diretrizes de Código

### Estilo de Código

- Siga as [Dart Style Guidelines](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format` antes de fazer commit
- Mantenha linhas com no máximo 80-100 caracteres quando possível
- Use nomes descritivos para variáveis e funções

### Estrutura de Arquivos

- Coloque novos widgets em arquivos separados quando apropriado
- Mantenha a organização de pastas existente
- Adicione assets à pasta apropriada (`assets/images/` ou `assets/audio/`)

### Documentação

- Documente funções públicas com comentários Dart (`///`)
- Atualize o README.md se adicionar novas funcionalidades
- Atualize ESTRUTURA_FIRESTORE.md se modificar a estrutura do banco de dados

## 🧪 Testes

- Adicione testes para novas funcionalidades
- Certifique-se de que todos os testes passam antes de submeter PR
- Mantenha cobertura de testes razoável

```bash
# Executar testes
flutter test

# Executar testes com cobertura
flutter test --coverage
```

## 🔍 Code Review

Todos os Pull Requests passarão por code review. Por favor:

- Seja receptivo ao feedback
- Faça as alterações solicitadas prontamente
- Mantenha a discussão profissional e construtiva

## 📦 Adicionando Dependências

Se precisar adicionar novas dependências:

1. Verifique se é realmente necessário
2. Escolha packages bem mantidas e com boa reputação
3. Atualize o `pubspec.yaml`
4. Execute `flutter pub get`
5. Documente a nova dependência no PR

## 🐛 Debugging

Para debug efetivo:

```bash
# Executar em modo debug
flutter run --debug

# Ver logs
flutter logs

# Analisar performance
flutter run --profile
```

## 📱 Testes em Múltiplas Plataformas

Se possível, teste suas mudanças em:
- Android
- iOS
- Web

## 🔐 Segurança

- Nunca commite credenciais ou chaves de API privadas
- Revise as Firestore Security Rules se modificar a estrutura de dados
- Reporte vulnerabilidades de segurança diretamente ao mantenedor

## ❓ Dúvidas?

Se tiver dúvidas sobre como contribuir:

1. Verifique a documentação existente
2. Procure em issues fechadas
3. Abra uma issue com sua pergunta

## 🎉 Reconhecimento

Todos os contribuidores serão reconhecidos no projeto!

---

Obrigado por contribuir para o Mosaico! 🎨✨
