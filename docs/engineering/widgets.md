# Widgets e personalização

## Painel do aplicativo

Em **Perfil → Aparência → Personalizar painel**, escolha e ordene as seções. Os sete gráficos opcionais aceitam alturas compacta, média e ampla; em telas largas, a opção ampla ocupa toda a linha. O resumo pode continuar integrado ao topo. As preferências ficam em `users/{uid}.dashboard_layout`, incluindo `card_sizes`; perfis antigos mantêm a disposição anterior.

Os gráficos de gastos diários e dias da semana usam somente despesas realizadas no mês até a data atual, calculadas em centavos. Dias da semana mostra totais, sem tratá-los como médias ou projeções. Próximos sete dias considera despesas já cadastradas a partir de amanhã, inclusive na virada do mês/ano.

## Tela inicial do Android

Em **Perfil → Aparência → Widgets do celular**, conheça os modelos e solicite a inclusão. O Android pede a confirmação final; se o launcher não permitir esse atalho, a tela orienta a inclusão manual.

Toque e segure um espaço vazio na tela inicial → **Widgets → KeyBudget**. Escolha um dos cinco modelos e arraste para adicionar. Para redimensionar, toque e segure o widget já adicionado. O número de células disponível depende do launcher.

| Modelo | Tamanho sugerido | Conteúdo |
| --- | --- | --- |
| Gastos compactos | 3 × 1 | Despesas realizadas até hoje |
| Gastos do mês | 2 × 2 | Despesas e atalho de cadastro |
| Resumo financeiro | 4 × 3 | Despesas, entradas e saldo; receitas respeitam o módulo ativado |
| Próximos gastos | 3 × 2 | Total cadastrado para os próximos sete dias |
| Nova despesa | 1 × 1 | Atalho para cadastrar, respeitando autenticação e bloqueio |

Os valores começam ocultos. O olho revela temporariamente; o próximo toque oculta. O Android pode atrasar o alarme de ocultação quando alarmes exatos não estão disponíveis. Dados de outra conta ou de sessão encerrada nunca são revelados pela política de exibição. Ao sair, o conteúdo salvo é limpo; gravações e trocas de sessão são serializadas.

Os widgets acompanham a cor e o modo de exibição do perfil (claro, escuro ou sistema). Duas paletas opacas são calculadas com as regras de contraste do aplicativo e persistidas junto à sessão; cada texto tem contraste mínimo de 4,5:1. Trocar a cor atualiza todos os modelos instalados, sem substituir os dados financeiros. Eventos de perfil repetidos não provocam atualizações redundantes; falhas podem ser repetidas na próxima sincronização. Ao sair, a aparência salva também é limpa.

No modo sistema, Android 12 ou superior reaplica as cores claro/escuro automaticamente; versões anteriores aplicam o modo atual na próxima atualização do widget. No Android 15 ou superior, também publicamos prévias com o tema no seletor, sujeitas à cota de atualização do launcher; versões anteriores usam a prévia estática. Os fundos são formas nativas com cor sólida, preservando os cantos transparentes em todas as versões suportadas.

A sincronização dos lançamentos salva um resumo por dia (valores em centavos e contagem), sem nomes, descrições ou IDs de despesas. Isso acontece independentemente de abrir o painel e inclui edições, exclusões e lançamentos recebidos pelo app. Filtros e pesquisas não alteram o resumo. Um cache vazio ainda não confirmado pelo servidor e falhas de conexão não apagam o último conjunto válido.

O Android recalcula o mês, o saldo e os próximos sete dias usando esses dados persistidos, inclusive na virada do dia, mês e ano. O widget continua funcionando com o aplicativo fechado, sem exigir uma abertura diária. Se o app não sincronizou hoje, a legenda informa **Dados do app · dd/MM**. As atualizações periódicas dependem do agendamento do Android; tocar no olho também recalcula os valores. Não há consultas ao Firebase em segundo plano: alterações feitas em outro aparelho e recorrências ainda não geradas dependem da próxima sincronização do app. Sem dados válidos ou com um resumo de versão antiga, **Atualize no app** orienta a sincronização inicial. Os modelos nativos desta implementação são para Android.

A implementação conserva o receiver original para preservar widgets já instalados. Os demais compartilham renderização e política de privacidade, com metadados e layouts próprios. Referências: [layouts flexíveis de widgets Android](https://developer.android.com/develop/ui/views/appwidgets/layouts), [RemoteViews](https://developer.android.com/reference/android/widget/RemoteViews) e [prévias de widgets](https://developer.android.com/reference/android/appwidget/AppWidgetManager#setWidgetPreview(android.content.ComponentName,int,android.widget.RemoteViews)).

## Verificação

```bash
flutter test test/features/expenses/expense_widget_sync_test.dart test/core/services/home_widget_appearance_test.dart test/core/services/home_widget_snapshot_test.dart test/features/user/home_widgets_screen_test.dart test/features/dashboard
cd android
./gradlew :app:testDebugUnitTest
# Com emulador Android conectado:
./gradlew :app:connectedDebugAndroidTest
```

Os testes cobrem precisão monetária, datas, troca de conta, logout, todos os receivers, validade da revelação, migração das preferências, tamanhos salvos e gráficos com texto a 200% em 320 px.

Os testes nativos aplicam as RemoteViews reais dos cinco modelos em duas cores e dois modos, verificando transparência dos cantos, cores, valores e sessão encerrada com fonte ampliada. No Android 15+, também verificam a prévia temática antes da primeira inclusão e garantem que ela não revele valores.
