# KeyBudget

## Descrição

O KeyBudget é um aplicativo móvel, desenvolvido em Flutter, para gerenciamento de despesas pessoais e armazenamento seguro de credenciais. Com uma interface moderna e intuitiva, o aplicativo permite que os usuários controlem seus gastos, visualizem relatórios e mantenham suas senhas e informações de login protegidas através de criptografia.

-----

## Funcionalidades Principais

* **Autenticação de Usuário:**

    * Cadastro e login com Email/Senha.
    * Login integrado com Google.
    * Autenticação biométrica para acesso rápido e seguro ao aplicativo.

* **Gerenciamento de Despesas:**

    * Adição, edição e exclusão de despesas.
    * Categorização de gastos (Alimentação, Lazer, etc.).
    * Filtro de despesas por categoria.
    * Visualização de gastos mensais com totalizador e navegação entre meses.
    * Importação e exportação de despesas em formato CSV.

* **Gerenciamento de Credenciais:**

    * Armazenamento seguro de logins, senhas e outras informações em nuvem (Firestore).
    * Criptografia **AES** para garantir a segurança das senhas armazenadas.
    * Funcionalidade para copiar informações rapidamente para a área de transferência.
    * Adição de logos personalizados para cada credencial.
    * Importação e exportação de credenciais em formato CSV.

* **Dashboard:**

    * Visão geral dos gastos do mês e da quantidade de credenciais salvas.
    * Gráfico com o histórico de despesas dos últimos seis meses.
    * Lista das atividades (despesas) mais recentes.

* **Perfil de Usuário:**

    * Visualização e edição de informações do perfil, como nome, telefone e foto.
    * Funcionalidade para alterar a senha da conta.

* **Segurança:**

    * Bloqueio automático do aplicativo ao ir para segundo plano, exigindo autenticação (biometria ou senha do dispositivo) para reabrir.
    * As senhas salvas são criptografadas no dispositivo antes de serem enviadas para o banco de dados, garantindo que nem mesmo o banco de dados tenha acesso à senha em texto plano.

-----

## Como Rodar o Projeto

### Pré-requisitos

1.  **Flutter SDK:** Certifique-se de ter o Flutter instalado e configurado corretamente no seu ambiente de desenvolvimento.
2.  **Conta no Firebase:** O projeto utiliza o Firebase para autenticação e banco de dados (Firestore). É necessário ter um projeto Firebase configurado.
3.  **Chave de Criptografia:** Uma chave secreta para a criptografia AES é necessária.

### Passos para Configuração

1.  **Clone o Repositório:**

    ```bash
    git clone https://github.com/viniciusmecosta/KeyBudget.git
    cd KeyBudget
    ```

2.  **Configure o Firebase:**

    * Crie um projeto no [console do Firebase](https://console.firebase.google.com/).
    * Adicione um aplicativo Android e/ou iOS ao seu projeto.
    * Siga as instruções para baixar o arquivo de configuração `google-services.json` (para Android) e/ou `GoogleService-Info.plist` (para iOS) e coloque-os nas pastas corretas do projeto (`android/app/` e `ios/Runner/`, respectivamente).
    * No console do Firebase, ative os seguintes serviços:
        * **Authentication:** Habilite os provedores "Email/Senha" e "Google".
        * **Firestore Database:** Crie um banco de dados Firestore e inicie em modo de produção (com regras de segurança).

3.  **Crie o Arquivo de Ambiente (`.env`):**

    * Na pasta `assets/`, crie um arquivo chamado `.env`.
    * Dentro deste arquivo, adicione a chave que será usada para criptografar e descriptografar as senhas. A chave **deve ter exatamente 32 caracteres**.

    <!-- end list -->

    ```
    ENCRYPTION_KEY=sua_chave_de_criptografia_de_32_caracteres
    ```

    > **Importante:** A perda desta chave resultará na impossibilidade de descriptografar as senhas já salvas. Guarde-a com segurança.

4.  **Instale as Dependências:**
    No terminal, na raiz do projeto, execute:

    ```bash
    flutter pub get
    ```

5.  **Execute o Aplicativo:**

    ```bash
    flutter run
    ```

-----

## Documentação da Estrutura de Arquivos

O projeto é organizado utilizando uma arquitetura modular, dividida por funcionalidades para facilitar a manutenção e escalabilidade.

* `lib/`
    * `main.dart`: Ponto de entrada da aplicação. Inicializa o Firebase, os provedores de estado (Providers) e a configuração do app.
    * `app/`: Contém a configuração e os widgets principais do aplicativo.
        * `config/`: Arquivos de configuração de tema (`app_theme.dart`) e injeção de dependências (`app_providers.dart`).
        * `view/`: Widgets de estrutura principal, como a tela de navegação (`main_screen.dart`), o portão de autenticação (`auth_gate.dart`) e a tela de bloqueio (`lock_screen.dart`).
        * `viewmodel/`: ViewModels globais, como o de navegação (`navigation_viewmodel.dart`).
        * `widgets/`: Widgets reutilizáveis em todo o aplicativo, como o `empty_state_widget.dart`.
    * `core/`: Camada com a lógica de negócios, modelos e serviços compartilhados.
        * `models/`: Modelos de dados da aplicação (`user_model.dart`, `credential_model.dart`, `expense_model.dart`, etc.).
        * `services/`: Serviços essenciais e reutilizáveis, como `encryption_service.dart`, `local_auth_service.dart`, `csv_service.dart`, entre outros.
    * `features/`: Diretório onde cada funcionalidade do app é encapsulada como um módulo independente.
        * `auth/`: Módulo de autenticação.
        * `credentials/`: Módulo de gerenciamento de credenciais.
        * `dashboard/`: Módulo do painel principal.
        * `expenses/`: Módulo de gerenciamento de despesas.
        * `user/`: Módulo do perfil do usuário.
    * Cada módulo (`feature`) segue a estrutura:
        * `view/`: Telas (Screens) e Widgets específicos da feature.
        * `viewmodel/`: Gerencia o estado e a lógica de apresentação para as views.
        * `repository/`: Responsável pela comunicação com as fontes de dados (neste caso, o Firestore).