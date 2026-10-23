# Widgets e personalização

## Painel do aplicativo

Em **Perfil → Aparência → Personalizar painel**, escolha e ordene as seções. Os sete gráficos opcionais aceitam alturas compacta, média e ampla; em telas largas, a opção ampla ocupa toda a linha. O resumo pode continuar integrado ao topo. As preferências ficam em `users/{uid}.dashboard_layout`, incluindo `card_sizes`; perfis antigos mantêm a disposição anterior.

Os gráficos de gastos diários e dias da semana usam somente despesas realizadas no mês até a data atual, calculadas em centavos. Dias da semana mostra totais, sem tratá-los como médias ou projeções. Próximos sete dias considera despesas já cadastradas a partir de amanhã, inclusive na virada do mês/ano.

## Tela inicial do Android

Toque e segure um espaço vazio na tela inicial → **Widgets → KeyBudget**. Escolha um dos cinco modelos e arraste para adicionar. Para redimensionar, toque e segure o widget já adicionado. O número de células disponível depende do launcher.

| Modelo | Tamanho sugerido | Conteúdo |
| --- | --- | --- |
| Gastos compactos | 3 × 1 | Despesas realizadas até hoje |
| Gastos do mês | 2 × 2 | Despesas e atalho de cadastro |
| Resumo financeiro | 4 × 3 | Despesas, entradas e saldo; receitas respeitam o módulo ativado |
| Próximos gastos | 3 × 2 | Total cadastrado para os próximos sete dias |
| Nova despesa | 1 × 1 | Atalho para cadastrar, respeitando autenticação e bloqueio |

Os valores começam ocultos. O olho revela temporariamente; o próximo toque oculta. O Android pode atrasar o alarme de ocultação quando alarmes exatos não estão disponíveis. Dados de outra conta, de um dia anterior ou de sessão encerrada nunca são revelados pela política de exibição. Ao sair, o conteúdo salvo é limpo; gravações e trocas de sessão são serializadas.

Os widgets acompanham o modo claro/escuro do sistema. São atualizados pelos lançamentos carregados no aplicativo e solicitam atualização de apresentação periodicamente; não fazem consultas ao Firebase em segundo plano. Se a fotografia dos dados estiver desatualizada, mostram **Atualize no app**. Os modelos nativos desta implementação são para Android.

A implementação conserva o receiver original para preservar widgets já instalados. Os demais compartilham renderização e política de privacidade, com metadados e layouts próprios. Referência: [layouts flexíveis de widgets Android](https://developer.android.com/develop/ui/views/appwidgets/layouts).

## Verificação

```bash
flutter test test/core/services/home_widget_snapshot_test.dart test/features/dashboard
cd android
./gradlew :app:testDebugUnitTest
```

Os testes cobrem precisão monetária, datas, troca de conta, logout, todos os receivers, validade da revelação, migração das preferências, tamanhos salvos e gráficos com texto a 200% em 320 px.
