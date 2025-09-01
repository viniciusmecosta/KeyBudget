# KeyBudget

O **KeyBudget** é um aplicativo móvel completo, desenvolvido em Flutter, projetado para ser a
ferramenta definitiva no gerenciamento de despesas pessoais e no armazenamento seguro de
credenciais. Com uma interface moderna, intuitiva e reativa, o aplicativo permite que os usuários
controlem seus gastos com precisão, obtenham *insights* valiosos através de gráficos e relatórios, e
mantenham suas senhas e informações de login totalmente protegidas com criptografia de ponta.

-----

## Funcionalidades Principais

### Autenticação e Segurança de Acesso

* **Cadastro e Login Flexível:** Suporte completo para autenticação com E-mail/Senha e integração
  nativa com o **Login do Google**.
* **Autenticação Biométrica:** Acesso rápido e seguro ao aplicativo utilizando a biometria do
  dispositivo (impressão digital ou reconhecimento facial).
* **Bloqueio Automático:** O aplicativo é bloqueado automaticamente ao ser enviado para segundo
  plano, exigindo nova autenticação para reabertura, garantindo a privacidade dos seus dados.
* **Proteção de Tela:** A interface do app no Android é protegida contra capturas e gravações de
  tela.

### Gerenciamento de Despesas

* **CRUD Completo:** Adicione, edite e exclua despesas de forma simples e rápida.
* **Categorização Avançada:** Crie e gerencie suas próprias categorias de gastos, personalizando
  ícones e cores para uma melhor organização visual.
* **Filtros Inteligentes:** Filtre suas despesas por uma ou mais categorias para uma análise focada.
* **Navegação Temporal:** Visualize os gastos mensais com um totalizador claro e navegue facilmente
  entre os meses.
* **Importação e Exportação:** Exporte todo o seu histórico de despesas ou um período selecionado
  para um arquivo **CSV**. Importe despesas de um arquivo CSV para dentro do app.

### Gerenciamento de Credenciais

* **Armazenamento Seguro em Nuvem:** Salve logins, senhas e outras informações de forma segura no
  Firestore.
* **Criptografia Forte (AES):** As senhas são criptografadas no dispositivo com o algoritmo **AES**
  antes de serem enviadas para o banco de dados. Isso garante que ninguém, nem mesmo o banco de
  dados, tenha acesso às suas senhas em texto plano.
* **Acesso Rápido:** Copie qualquer informação (usuário, senha, etc.) para a área de transferência
  com um único toque.
* **Logos Personalizados:** Adicione logos a partir da sua galeria ou escolha um logo já utilizado
  em outra credencial para facilitar a identificação.

### Dashboard e Análises

* **Visão Geral Completa:** Um painel central que exibe um resumo dos gastos do mês atual, a
  quantidade de credenciais salvas e um comparativo percentual com a média de gastos dos meses
  anteriores.
* **Análise de Tendências:** Um gráfico de linhas interativo mostra o histórico de despesas dos
  últimos seis meses, com a possibilidade de navegar para períodos anteriores.
* **Análise por Categoria:** Um gráfico de pizza detalha a distribuição dos seus gastos por
  categoria no mês selecionado, permitindo uma compreensão clara de para onde seu dinheiro está
  indo.
* **Atividades Recentes:** Acompanhe as últimas despesas adicionadas diretamente no dashboard.

### Perfil de Usuário

* **Gerenciamento de Perfil:** Visualize e edite suas informações de perfil, como nome, telefone e
  foto.
* **Alteração de Senha:** Funcionalidade segura para alterar a senha da sua conta.

-----

## Como Rodar o Projeto

### Pré-requisitos

1. **Flutter SDK:** Certifique-se de ter o [Flutter](https://flutter.dev/docs/get-started/install)
   instalado e configurado corretamente.
2. **Conta no Firebase:** O projeto utiliza o Firebase для autenticação e banco de dados. É
   necessário ter um projeto Firebase configurado.
3. **Chave de Criptografia:** Uma chave secreta para a criptografia AES é necessária para a
   segurança das credenciais.

### Passos para Configuração

1. **Clone o Repositório:**

   ```bash
   git clone https://github.com/viniciusmecosta/KeyBudget.git
   cd KeyBudget
   ```

2. **Configure o Firebase:**

    * Crie um projeto no [console do Firebase](https://console.firebase.google.com/).
    * Adicione um aplicativo Android e/ou iOS ao seu projeto.
    * Siga as instruções para baixar o arquivo de configuração `google-services.json` (para Android)
      e/ou `GoogleService-Info.plist` (para iOS) e coloque-os nas pastas corretas do projeto (
      `android/app/` e `ios/Runner/`).
    * No console do Firebase, ative os seguintes serviços:
        * **Authentication:** Habilite os provedores "E-mail/senha" e "Google".
        * **Firestore Database:** Crie um banco de dados Firestore e configure as regras de
          segurança (veja a seção abaixo).

3. **Crie o Arquivo de Ambiente (`.env`):**

    * Na pasta `assets/`, crie um arquivo chamado `.env`.
    * Dentro deste arquivo, adicione a chave que será usada para criptografar e descriptografar as
      senhas. A chave **deve ter exatamente 32 caracteres**.

   <!-- end list -->

   ```
   ENCRYPTION_KEY=sua_chave_de_criptografia_de_32_caracteres
   ```

   > **Importante:** A perda desta chave resultará na impossibilidade de descriptografar as senhas
   já salvas. Guarde-a com segurança.

4. **Instale as Dependências:**
   No terminal, na raiz do projeto, execute:

   ```bash
   flutter pub get
   ```

5. **Execute o Aplicativo:**

   ```bash
   flutter run
   ```

-----

## Regras de Segurança do Firestore

Para garantir que cada usuário tenha acesso apenas aos seus próprios dados, utilize as seguintes
regras de segurança no seu banco de dados Firestore:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Permite que o usuário leia e atualize seu próprio documento de perfil
    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }

    // Permite acesso total (leitura e escrita) às subcoleções do usuário
    // (despesas, credenciais, categorias) apenas se ele estiver autenticado
    // e for o dono dos dados.
    match /users/{userId}/{collection}/{docId} {
      allow read, write, create, delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

-----

## Estrutura de Arquivos do Projeto

O projeto é organizado utilizando uma arquitetura modular e limpa, dividida por funcionalidades para
facilitar a manutenção e escalabilidade.

* `lib/`
    * `main.dart`: Ponto de entrada da aplicação. Inicializa o Firebase, os provedores de estado (
      Providers) e a configuração do app.
    * `app/`: Contém a configuração e os widgets principais e globais do aplicativo.
        * `config/`: Arquivos de configuração de tema (`app_theme.dart`) e injeção de dependências (
          `app_providers.dart`).
        * `view/`: Widgets de estrutura principal, como a tela de navegação (`main_screen.dart`), o
          portão de autenticação (`auth_gate.dart`) e a tela de bloqueio (`lock_screen.dart`).
        * `viewmodel/`: ViewModels globais, como o de navegação (`navigation_viewmodel.dart`).
        * `widgets/`: Widgets reutilizáveis em todo o aplicativo (ex: `empty_state_widget.dart`).
    * `core/`: Camada com a lógica de negócios, modelos e serviços compartilhados por toda a
      aplicação.
        * `models/`: Modelos de dados (`user_model.dart`, `credential_model.dart`, etc.).
        * `services/`: Serviços essenciais e reutilizáveis, como `encryption_service.dart`,
          `local_auth_service.dart`, `csv_service.dart`.
    * `features/`: Diretório onde cada funcionalidade do app é encapsulada como um módulo
      independente.
        * `auth/`: Módulo de autenticação.
        * `credentials/`: Módulo de gerenciamento de credenciais.
        * `dashboard/`: Módulo do painel principal.
        * `expenses/`: Módulo de gerenciamento de despesas.
        * `analysis/`: Módulo de análise de dados.
        * `category/`: Módulo de gerenciamento de categorias.
        * `user/`: Módulo do perfil do usuário.
    * Cada módulo (`feature`) segue a estrutura **View-ViewModel-Repository**:
        * `view/`: Telas (Screens) e Widgets específicos da feature.
        * `viewmodel/`: Gerencia o estado e a lógica de apresentação para as views, utilizando o
          padrão `ChangeNotifier` com o pacote `provider`.
        * `repository/`: Responsável pela comunicação com as fontes de dados (neste caso, o
          Firestore).