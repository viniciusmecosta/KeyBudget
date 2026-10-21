<div align="center">

# KeyBudget

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Riverpod](https://img.shields.io/badge/Riverpod-1A73E8?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev/)

</div>

O **KeyBudget** é um aplicativo em Flutter para controle financeiro pessoal e gerenciamento seguro de senhas e documentos. Utiliza criptografia AES no próprio dispositivo para proteger credenciais e arquivos antes de qualquer sincronização com a nuvem.

## Funcionalidades

- **Controle financeiro**: gestão de receitas e despesas, parcelamentos, gastos fixos/recorrentes e categorização com cores e ícones.
- **Cofre de credenciais**: armazenamento de senhas, notas e logins com criptografia AES-256 local.
- **Cofre de documentos**: armazenamento de arquivos e comprovantes com leitor de PDF e controle de prazos de validade.
- **Gráficos e relatórios**: saldo mensal, distribuição por categoria via `fl_chart` e exportação em PDF e CSV.
- **Metas**: definição e acompanhamento de objetivos financeiros.
- **Busca global**: pesquisa unificada por transações, credenciais e documentos.
- **Lixeira com retenção de 30 dias**: recuperação de itens excluídos acidentalmente.
- **Widgets de tela inicial**: saldo e atalhos rápidos na home do smartphone (`home_widget`).
- **Backup e sincronização**: sincronização em tempo real com Cloud Firestore e suporte a backup no Google Drive.
- **Segurança e biometria**: autenticação biométrica (`local_auth`) e bloqueio automático por inatividade.

## Telas do Aplicativo

<div align="center">

### Dashboard e Despesas

<p align="center">
  <img src="docs/images/home-light.jpg" width="23%" alt="Dashboard Claro" />
  <img src="docs/images/home-dark.jpg" width="23%" alt="Dashboard Escuro" />
  <img src="docs/images/expense-light.jpg" width="23%" alt="Despesas Claro" />
  <img src="docs/images/expense-dark.jpg" width="23%" alt="Despesas Escuro" />
</p>

### Credenciais e Documentos

<p align="center">
  <img src="docs/images/credentials-light.jpg" width="23%" alt="Credenciais Claro" />
  <img src="docs/images/credentials-dark.jpg" width="23%" alt="Credenciais Escuro" />
  <img src="docs/images/documents-light.jpg" width="23%" alt="Documentos Claro" />
  <img src="docs/images/documents-dark.jpg" width="23%" alt="Documentos Escuro" />
</p>

### Análise Financeira

<p align="center">
  <img src="docs/images/analysis1-light.jpg" width="23%" alt="Análise Geral Claro" />
  <img src="docs/images/analysis1-dark.jpg" width="23%" alt="Análise Geral Escuro" />
  <img src="docs/images/analysis2-light.jpg" width="23%" alt="Distribuição Claro" />
  <img src="docs/images/analysis2-dark.jpg" width="23%" alt="Distribuição Escuro" />
</p>

### Perfil e Configurações

<p align="center">
  <img src="docs/images/user-light.jpg" width="23%" alt="Perfil Claro" />
  <img src="docs/images/user-dark.jpg" width="23%" alt="Perfil Escuro" />
</p>

</div>

## Como Executar

### Pré-requisitos

- Flutter SDK com Dart `>=3.12.0 <4.0.0` (conforme `pubspec.yaml`)
- Projeto configurado no Firebase (Authentication e Firestore)
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- Chave AES de 32 bytes para criptografia local

### Passo a passo

1. Clone o repositório:
```bash
git clone https://github.com/viniciusmecosta/KeyBudget.git
cd KeyBudget
```

2. Crie o arquivo `assets/.env` com a chave de criptografia de 32 caracteres:
```env
ENCRYPTION_KEY=<sua-chave-aleatoria-de-32-bytes>
```

3. Instale as dependências e execute:
```bash
flutter pub get
flutter run
```

## Regras de Segurança do Firestore

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
    }
    match /users/{userId}/{collection}/{document=**} {
      allow read, write, create, delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Personalização e desenvolvimento

Em **Perfil → Aparência**, escolha a cor, o modo claro/escuro e as seções do painel. O resumo mensal pode aparecer integrado ao topo ou em cartão.

Para o Google Drive, habilite a Drive API e configure o login Google do projeto Firebase. Em **Perfil → Google Drive**, conecte a conta e use **Verificar conexão** para testar o acesso.

```bash
flutter analyze
flutter test
```

Código organizado por funcionalidades em `lib/features`, com componentes compartilhados em `lib/core/design_system`. Consulte [DESIGN.md](DESIGN.md) para o padrão visual.
