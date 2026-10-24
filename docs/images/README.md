# Capturas do KeyBudget

As imagens são renderizadas pelos widgets reais da aplicação com dados fictícios, sem autenticação ou contas reais. São 24 capturas do aplicativo, em temas claro e escuro, incluindo painel, lançamentos, cofres, análises, metas, perfil, personalização e seleção de widgets.

## Regenerar

Com Flutter no PATH e Python 3 com Pillow instalado:

```bash
uv run --with pillow python tool/update_readme_images.py
```

Se necessário, defina `FLUTTER_BIN` com o caminho do executável Flutter. O script executa `test/screenshots/readme_screenshots_test.dart` e atualiza os JPGs desta pasta. Os PNGs intermediários ficam em `build/readme-captures`, fora do Git.

- Tamanho: 412 × 915 pontos, renderizados em escala 2×.
- Fonte: os cinco pesos de Inter incluídos em `assets/fonts`, com a licença OFL correspondente.
- Conteúdo: fixtures de `test/screenshots/demo_data.dart`; datas acompanham o mês da execução.
- Animações desativadas apenas na captura, para obter um estado final estável.
- O teste sem `CAPTURE_README=1` valida as telas sem gravar arquivos.

Não use contas, documentos ou credenciais reais para produzir imagens públicas.

## Widgets Android

`widgets-light.jpg` e `widgets-dark.jpg` mostram os cinco layouts nativos reais com dados fictícios. A galeria é renderizada pelo teste instrumentado `WidgetRenderingTest`, usando as paletas de produção; não depende de login nem lê os dados da conta.

Com um **emulador descartável** iniciado (o comando instala a versão debug):

```bash
uv run --with pillow python tool/update_widget_images.py --serial emulator-5554
```

As capturas PNG ficam em `build/widget-captures/`; somente os JPEGs da documentação são versionados. As paletas de teste são verificadas por `home_widget_appearance_test.dart`. Se as regras de cores mudarem, regenere a fixture com `UPDATE_WIDGET_PALETTES=1 flutter test test/core/services/home_widget_appearance_test.dart` antes de capturar novamente.
