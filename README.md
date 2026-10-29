<div align="center">

# PassFin

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/brand/passfin-lockup-dark.svg">
  <img src="assets/brand/passfin-lockup-light.svg" width="320" alt="PassFin: carteira com cédula e chave">
</picture>

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Riverpod](https://img.shields.io/badge/Riverpod-1A73E8?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev/)

**Senhas, finanças e documentos em um só lugar.**

</div>

Registre seus lançamentos, acompanhe metas e organize credenciais e documentos.
O painel reúne o mês e os gráficos escolhidos por você; em **Perfil → Aparência**, ajuste cores,
tema, navegação e seções, com resumo integrado ao topo ou em cartão.

A identidade visual e os arquivos da marca estão no [guia PassFin](docs/branding/README.md).

## Funcionalidades

- **Finanças:** receitas, despesas, parcelas, recorrências e categorias com cores e ícones.
- **Metas e análises:** objetivos de economia, gráficos interativos e relatórios em PDF e CSV.
- **Cofres:** credenciais em pastas e documentos com anexos, versões, leitor de PDF e validade.
- **Personalização:** temas claro/escuro, cores, abas, atalhos e sete gráficos com tamanhos ajustáveis no painel.
- **Dados e recuperação:** sincronização com Firestore, documentos e backups no Google Drive e lixeira de 30 dias.
- **Conveniência e proteção:** busca global, notificações, biometria, bloqueio por inatividade e cinco widgets Android redimensionáveis.

## Telas do Aplicativo

Capturas de telas Flutter renderizadas com dados fictícios. Em cada par, **tema claro à esquerda** e **escuro à direita**. Clique para ampliar.

### Entrada

<p align="center">
  <a href="docs/branding/login-light.png"><img src="docs/branding/login-light.png" width="23%" alt="Entrada do PassFin, tema claro" /></a>
  <a href="docs/branding/login-dark.png"><img src="docs/branding/login-dark.png" width="23%" alt="Entrada do PassFin, tema escuro" /></a>
</p>

### Painel e metas

<p align="center">
  <a href="docs/images/dashboard-light-current.png"><img src="docs/images/dashboard-light-current.png" width="23%" alt="Painel com despesas do mês e gráfico mensal, tema claro" /></a>
  <a href="docs/images/dashboard-dark-current.png"><img src="docs/images/dashboard-dark-current.png" width="23%" alt="Painel com despesas do mês e gráfico mensal, tema escuro" /></a>
  <a href="docs/images/goals-light-current.png"><img src="docs/images/goals-light-current.png" width="23%" alt="Metas com valores guardados e progresso, tema claro" /></a>
  <a href="docs/images/goals-dark-current.png"><img src="docs/images/goals-dark-current.png" width="23%" alt="Metas com valores guardados e progresso, tema escuro" /></a>
</p>

### Lançamentos e análise financeira

<p align="center">
  <a href="docs/images/expense-light-current.png"><img src="docs/images/expense-light-current.png" width="23%" alt="Lançamentos e saldo do mês, tema claro" /></a>
  <a href="docs/images/expense-dark-current.png"><img src="docs/images/expense-dark-current.png" width="23%" alt="Lançamentos e saldo do mês, tema escuro" /></a>
  <a href="docs/images/analysis-light-current.png"><img src="docs/images/analysis-light-current.png" width="23%" alt="Análise financeira com resumo e composição de gastos, tema claro" /></a>
  <a href="docs/images/analysis-dark-current.png"><img src="docs/images/analysis-dark-current.png" width="23%" alt="Análise financeira com resumo e composição de gastos, tema escuro" /></a>
</p>

### Credenciais e documentos

<p align="center">
  <a href="docs/images/credentials-light-current.png"><img src="docs/images/credentials-light-current.png" width="23%" alt="Cofre com pastas e credenciais, tema claro" /></a>
  <a href="docs/images/credentials-dark-current.png"><img src="docs/images/credentials-dark-current.png" width="23%" alt="Cofre com pastas e credenciais, tema escuro" /></a>
  <a href="docs/images/documents-light-current.png"><img src="docs/images/documents-light-current.png" width="23%" alt="Documentos e identificações, tema claro" /></a>
  <a href="docs/images/documents-dark-current.png"><img src="docs/images/documents-dark-current.png" width="23%" alt="Documentos e identificações, tema escuro" /></a>
</p>

## Widgets no Android

Adicione pelo **Perfil → Aparência → Widgets do celular** ou pelo seletor de widgets do Android.
Os cinco modelos acompanham a **cor e o modo de exibição do aplicativo**, com valores ocultos por padrão.
Usam os lançamentos salvos e recalculam os totais na virada do dia, mesmo com o app fechado; a legenda indica a data dos dados quando necessário.

| Widget | Tamanho sugerido |
| --- | --- |
| Gastos compactos | 3 × 1 |
| Gastos do mês | 2 × 2 |
| Resumo financeiro | 4 × 3 |
| Próximos gastos | 3 × 2 |
| Nova despesa | 1 × 1 |

## Tecnologias

| Base | Uso |
| --- | --- |
| Flutter, Dart e Material 3 | Interface adaptativa e componentes compartilhados |
| Riverpod | Estado e dependências, com código organizado por funcionalidade |
| Firebase Authentication e Cloud Firestore | Autenticação e sincronização |
| fl_chart, PDF e CSV | Gráficos e relatórios |
| AES, Secure Storage e local_auth | Criptografia, armazenamento seguro e biometria |
| Google Drive e home_widget | Documentos, backups e widgets do dispositivo |

## Como Executar

Use Flutter com Dart `>=3.12.0 <4.0.0`, conforme `pubspec.yaml`.

```bash
git clone https://github.com/viniciusmecosta/KeyBudget.git
cd KeyBudget
flutter pub get
```

Configure o Firebase seguindo o
[guia de configuração](docs/configuracao.md). Para usar o Drive, configure também a API e o login Google.

```bash
flutter run
```

## Desenvolvimento

```bash
flutter analyze
flutter test
```

Código em `lib/features`, com componentes comuns em `lib/core/design_system`.
[Padrão visual](DESIGN.md) · [Widgets e personalização](docs/engineering/widgets.md)
