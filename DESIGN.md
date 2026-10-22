# Design System: KeyBudget

## 1. Visual Theme & Atmosphere
Interface financeira calma, legível e organizada. A saudação e o resumo mensal formam um topo contínuo; as demais seções usam superfícies discretas para separar ações e informações. O design deriva do aplicativo local, sem projeto Stitch associado.

## 2. Color Palette & Roles
- Azul profundo (#0058D9): identidade e ações principais no tema claro.
- Azul luminoso (#82B7FF): destaque no tema escuro.
- Azul quase branco (#EAF4FF): fundo claro.
- Branco azulado (#F8FCFF): superfícies claras.
- Marinho profundo (#091A2D): fundo escuro.
- Marinho suave (#142B45): superfícies escuras.
- Tinta azul (#102B50) e branco azulado (#EAF4FF): texto principal conforme o tema.

As cores personalizadas passam pelos ajustes de contraste existentes. O resumo integrado preserva a
cor escolhida no tema, ajustada para contraste mínimo de 7:1 com texto branco, mantendo pelo menos
4,5:1 nas legendas e na cápsula do período. A saudação compartilha o fundo com o resumo; um
gradiente suave aprofunda a cor na base, com cantos inferiores de 28 pontos. O valor principal usa
40 pontos e peso 700. O período aparece em uma cápsula discreta; receitas e despesas ficam em
colunas, empilhadas quando o texto ampliado exige.

## 3. Typography Rules
Inter, com texto corrente de 14–16 pontos e legendas a partir de 12 pontos. Pesos médios identificam ações; títulos e valores recebem maior peso. Respeitar a escala de texto do sistema e permitir quebra de linhas.

## 4. Component Stylings
- **Buttons:** cantos suavemente arredondados (16 pontos), rótulos claros e estado de carregamento. Botões flutuantes estendidos não recebem máscara circular.
- **Cards/Containers:** cantos moderadamente arredondados (20 pontos), com elevação discreta. Modais mantêm cantos amplos (24 pontos).
- **Inputs/Forms:** contorno suave, foco explícito e mensagens próximas do campo.
- **Section actions:** ícones de navegação em alvos de 48 pontos, alinhados ao título. Análise e
  lista completa têm tooltips e nomes acessíveis; não ocupam uma linha separada.
- **Feedback:** operações remotas devem informar sucesso, ausência de autorização ou falha. Verificar o Drive consulta a API sem abrir login automaticamente.

## 5. Layout Principles
Margens de 16–24 pontos e espaçamento consistente. Resumo integrado ocupa toda a largura disponível no topo. Grades se adaptam a telas maiores; listas reservam espaço para ações flutuantes. Tema, ordem, visibilidade e apresentação do resumo são personalizáveis.

## Decisões e escopo
Entendimento: concluir o README breve, corrigir Drive e metas, integrar o resumo e refinar componentes compartilhados. Preservar dados, autenticação e arquitetura Riverpod existentes.

Premissas: uso pessoal, mesmos volumes de dados atuais, sem novas dependências ou migração. A consulta de verificação é somente leitura e tem limite de tempo. Layout é persistido no perfil existente; perfis antigos recebem o resumo integrado por padrão.

Decisão: evolução incremental do sistema existente, em vez de uma substituição visual completa. Risco moderado de regressão visual por componentes compartilhados; validar com testes de widgets, análise estática e capturas. Próximo passo: implementação e validação. Login OAuth real depende de conta e configuração do dispositivo.

## Validação desta revisão
Capturas de painel e metas inspecionadas em 320, 390 e 1024 pontos, nos dois temas. Em 320 pontos, escala de texto de 180%: valor principal em uma linha, receitas/despesas com quebra de texto e cabeçalhos sem compressão pela ação lateral. Metas começam no topo e o botão estendido mantém seu rótulo dentro da área visível. Capturas usam dados fictícios e a fonte Roboto local como substituta de Inter, sem download de fontes.

381 testes passaram, incluindo regressões de contraste existentes, responsividade, abertura do formulário de metas, autorização expirada, falha de API e timeout da verificação. Análise estática de `lib`, `test/core`, `test/features` e `test/visual` sem problemas. A pasta local preexistente `test/temp_capture` não integra essa validação: contém referências a uma tela removida. OAuth real e leitura por tecnologia assistiva em dispositivo não foram verificados nesta revisão.
