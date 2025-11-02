# KeyBudget

[![Version](https://img.shields.io/badge/Version-0.9.0%20(Pre-release)-blue)](https://github.com/viniciusmecosta/KeyBudget/releases/tag/v0.9)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)

O **KeyBudget** é um aplicativo desenvolvido em **Flutter** que une praticidade e segurança para o
gerenciamento de finanças pessoais e de credenciais.
Com um design moderno e responsivo, o projeto oferece controle detalhado de gastos, relatórios
visuais e armazenamento seguro de senhas com criptografia local.

---

## Principais Recursos

* **Controle Financeiro Completo:** Registre despesas, crie categorias e acompanhe seu fluxo de
  caixa.
* **Gerenciamento de Credenciais:** Armazene logins e senhas com criptografia AES local antes do
  envio ao banco de dados.
* **Análises e Relatórios:** Visualize tendências e comparativos mensais por meio de gráficos
  interativos.
* **Autenticação Segura:** Suporte a login com e-mail/senha, Google e autenticação biométrica.
* **Privacidade Reforçada:** Bloqueio automático e proteção contra captura de tela.
* **Importação e Exportação:** Transfira dados em formato CSV de forma simples e rápida.

---

## Autenticação e Segurança

* **Login Flexível:** Autenticação via e-mail/senha e integração com o Google.
* **Biometria:** Desbloqueio rápido por impressão digital ou reconhecimento facial.
* **Bloqueio Automático:** Requer nova autenticação ao retornar do segundo plano.
* **Proteção Visual:** Impede capturas e gravações de tela no Android.

---

## Gerenciamento de Despesas

* **CRUD Completo:** Adicione, edite e remova despesas com facilidade.
* **Categorias Personalizadas:** Crie e edite categorias com ícones e cores próprias.
* **Filtros Avançados:** Analise gastos por categoria ou período.
* **Navegação Temporal:** Acesse totais mensais e alterne entre diferentes períodos.
* **Exportação e Importação CSV:** Mantenha seus dados portáteis e seguros.

---

## Gerenciamento de Credenciais

* **Sincronização com Firestore:** Armazena dados criptografados em nuvem.
* **Criptografia AES Local:** As senhas são criptografadas no dispositivo antes do envio.
* **Cópia Rápida:** Copie informações como usuário e senha com um toque.
* **Identificação Visual:** Associe logos personalizados a cada credencial.

---

## Dashboard e Relatórios

* **Resumo Mensal:** Exibe gastos, credenciais e comparativo com meses anteriores.
* **Tendência de Gastos:** Gráfico de linha com o histórico dos últimos seis meses.
* **Distribuição por Categoria:** Gráfico de pizza com análise de gastos detalhada.
* **Atividades Recentes:** Lista das últimas movimentações registradas.

---

## Perfil do Usuário

* **Gerenciamento de Perfil:** Atualize informações como nome, telefone e foto.
* **Alteração de Senha:** Modifique sua senha de forma segura.

---

## Tecnologias Utilizadas

[![Provider](https://img.shields.io/badge/Provider-4285F4?style=for-the-badge&logo=flutter&logoColor=white)](https://pub.dev/packages/provider) [![Flutter Secure Storage](https://img.shields.io/badge/Secure%20Storage-007ACC?style=for-the-badge&logo=flutter&logoColor=white)](https://pub.dev/packages/flutter_secure_storage) [![Encrypt](https://img.shields.io/badge/Encrypt-6200EE?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/encrypt) [![FL Chart](https://img.shields.io/badge/FL%20Chart-00C853?style=for-the-badge&logo=flutter&logoColor=white)](https://pub.dev/packages/fl_chart) [![Local Auth](https://img.shields.io/badge/Local%20Auth-00BCD4?style=for-the-badge&logo=flutter&logoColor=white)](https://pub.dev/packages/local_auth) [![Google Sign In](https://img.shields.io/badge/Google%20Sign%20In-DB4437?style=for-the-badge&logo=google&logoColor=white)](https://pub.dev/packages/google_sign_in) [![Syncfusion PDF Viewer](https://img.shields.io/badge/Syncfusion%20PDF-673AB7?style=for-the-badge&logo=flutter&logoColor=white)](https://pub.dev/packages/syncfusion_flutter_pdfviewer) [![Google ML Kit Text Recognition](https://img.shields.io/badge/ML%20Kit%20Text%20Recognition-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://pub.dev/packages/google_mlkit_text_recognition)

---

## Instalação e Configuração

### Pré-requisitos

* Flutter SDK instalado e configurado
* Conta no Firebase
* Chave AES de 32 caracteres para criptografia local

### Passos

```bash
git clone https://github.com/viniciusmecosta/KeyBudget.git
cd KeyBudget
```

1. **Configurar o Firebase**
    * Crie um projeto no [Firebase Console](https://console.firebase.google.com/).
    * Adicione o app Android/iOS e baixe os arquivos `google-services.json` e/ou `GoogleService-Info.plist`.
    * Ative **Authentication** (E-mail/Senha e Google) e **Firestore Database**.

2. **Criar arquivo `.env`**
   Na pasta `assets/`, adicione:

   ```
   ENCRYPTION_KEY=sua_chave_de_criptografia_de_32_caracteres
   ```

3. **Instalar dependências**

   ```bash
   flutter pub get
   ```

4. **Executar o aplicativo**

   ```bash
   flutter run
   ```

---

## Regras de Segurança do Firestore

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }

    match /users/{userId}/{collection}/{docId} {
      allow read, write, create, delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Estrutura do Projeto

```
lib/
├── main.dart
├── app/
│   ├── config/
│   ├── view/
│   ├── viewmodel/
│   └── widgets/
├── core/
│   ├── models/
│   └── services/
└── features/
    ├── auth/
    ├── credentials/
    ├── dashboard/
    ├── expenses/
    ├── analysis/
    ├── category/
    └── user/