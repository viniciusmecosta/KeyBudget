enum HomeWidgetKind {
  compact(
    'KeyBudgetCompactWidgetReceiver',
    'Gastos compactos',
    '3 × 1',
    'O total realizado no mês, ocupando pouco espaço.',
  ),
  monthly(
    'KeyBudgetWidgetReceiver',
    'Gastos do mês',
    '2 × 2',
    'Despesas realizadas e um atalho para novos lançamentos.',
  ),
  overview(
    'KeyBudgetOverviewWidgetReceiver',
    'Resumo financeiro',
    '4 × 3',
    'Despesas, entradas e saldo. Ative receitas para ver o resumo completo.',
  ),
  upcoming(
    'KeyBudgetUpcomingWidgetReceiver',
    'Próximos gastos',
    '3 × 2',
    'Despesas já cadastradas para os próximos sete dias.',
  ),
  quick(
    'KeyBudgetQuickWidgetReceiver',
    'Nova despesa',
    '1 × 1',
    'Abra o cadastro de uma despesa com um toque.',
  );

  const HomeWidgetKind(this.receiver, this.title, this.size, this.description);

  final String receiver;
  final String title;
  final String size;
  final String description;
}
