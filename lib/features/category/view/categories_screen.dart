import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passfin/core/design_system/widgets/app_skeleton_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/app/utils/app_animations.dart';
import 'package:passfin/app/utils/navigation_utils.dart';
import 'package:passfin/app/widgets/animated_list_item.dart';
import 'package:passfin/app/widgets/empty_state_widget.dart';
import 'package:passfin/app/widgets/responsive_center.dart';
import 'package:passfin/core/design_system/borders/app_borders.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_card.dart';
import 'package:passfin/core/design_system/widgets/app_feedback_panel.dart';
import 'package:passfin/core/models/expense_model.dart';
import 'package:passfin/core/money/money.dart';
import 'package:passfin/core/money/money_parser.dart';
import 'package:passfin/core/services/snackbar_service.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/features/category/repository/category_budget_repository.dart';
import 'package:passfin/features/category/view/add_edit_category_screen.dart';
import 'package:passfin/features/category/viewmodel/category_viewmodel.dart';
import 'package:passfin/features/expenses/repository/expense_period_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  late DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  static const _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authViewModelProvider).currentUser?.id;
      if (userId != null) {
        ref.read(categoryViewModelProvider).fetchCategories(userId);
      }
    });
  }

  Future<void> _editBudget(
    String categoryId,
    String categoryName,
    int? currentLimit,
  ) async {
    final controller = TextEditingController(
      text: currentLimit == null
          ? ''
          : Money.fromCents(currentLimit).formatBrl(includeSymbol: false),
    );
    String? validationMessage;
    final chosenLimit = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('Orçamento de $categoryName'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Limite mensal',
                prefixText: 'R\$ ',
                helperText:
                    'Vale apenas para ${_monthNames[_selectedMonth.month - 1]} de ${_selectedMonth.year}.',
                errorText: validationMessage,
              ),
            ),
            actions: [
              if (currentLimit != null)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(-1),
                  child: const Text('Remover limite'),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  try {
                    final amount = MoneyParser.parse(
                      controller.text,
                    ).amountMinor;
                    if (amount <= 0) throw const FormatException();
                    Navigator.of(dialogContext).pop(amount);
                  } catch (_) {
                    setDialogState(() {
                      validationMessage =
                          'Informe um valor maior que zero com até 2 casas decimais.';
                    });
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
      animationStyle: AppAnimations.routeStyle(context),
    );
    controller.dispose();
    if (chosenLimit == null || !mounted) return;
    final userId = ref.read(authViewModelProvider).currentUser?.id;
    if (userId == null) return;
    try {
      await ref
          .read(categoryBudgetRepositoryProvider)
          .setMonthlyBudget(
            userId,
            _selectedMonth,
            categoryId,
            chosenLimit < 0 ? null : chosenLimit,
          );
      if (mounted) {
        SnackbarService.showSuccess(context, 'Orçamento atualizado.');
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Não foi possível salvar o orçamento. Tente novamente.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPageScaffold(
      appBar: AppBar(title: const Text('Minhas Categorias')),
      body: SafeArea(
        child: AppAnimations.fadeInFromBottom(
          Consumer(
            builder: (context, ref, _) {
              final viewModel = ref.watch(categoryViewModelProvider);
              final userId = ref.watch(authViewModelProvider).currentUser?.id;
              final monthExpenses = userId == null
                  ? null
                  : ref.watch(
                      expensesForMonthProvider((
                        userId: userId,
                        month: _selectedMonth,
                      )),
                    );
              final expenses = monthExpenses?.value ?? const <Expense>[];
              final budgets = userId == null
                  ? <String, int>{}
                  : ref
                        .watch(
                          categoryBudgetsForMonthProvider((
                            userId: userId,
                            month: _selectedMonth,
                          )),
                        )
                        .when(
                          data: (value) => value,
                          loading: () => <String, int>{},
                          error: (_, _) => <String, int>{},
                        );

              return RefreshIndicator(
                onRefresh: () async {
                  final userId = ref
                      .read(authViewModelProvider)
                      .currentUser
                      ?.id;
                  if (userId != null) {
                    await ref
                        .read(categoryViewModelProvider)
                        .fetchCategories(userId);
                    ref.invalidate(
                      expensesForMonthProvider((
                        userId: userId,
                        month: _selectedMonth,
                      )),
                    );
                  }
                },
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                strokeWidth: 2.5,
                child: ResponsiveCenter(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Mês anterior',
                                onPressed: () => setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month - 1,
                                  );
                                }),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Text(
                                  '${_monthNames[_selectedMonth.month - 1]} de ${_selectedMonth.year}',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Próximo mês',
                                onPressed: () => setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month + 1,
                                  );
                                }),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (viewModel.isLoading)
                        const CategoriesSkeleton()
                      else if (viewModel.errorMessage != null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppFeedbackPanel(
                            title: 'Falha ao carregar categorias',
                            message: viewModel.errorMessage!,
                            type: AppFeedbackType.error,
                            actionLabel: 'Tentar novamente',
                            onAction: () {
                              final userId = ref
                                  .read(authViewModelProvider)
                                  .currentUser
                                  ?.id;
                              if (userId != null) {
                                ref
                                    .read(categoryViewModelProvider)
                                    .fetchCategories(userId);
                              }
                            },
                          ),
                        )
                      else if (monthExpenses?.isLoading == true)
                        const CategoriesSkeleton()
                      else if (monthExpenses?.hasError == true)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppFeedbackPanel(
                            title: 'Falha ao carregar o consumo do mês',
                            message: 'Confira sua conexão e tente novamente.',
                            type: AppFeedbackType.error,
                            actionLabel: 'Tentar novamente',
                            onAction: () {
                              if (userId != null) {
                                ref.invalidate(
                                  expensesForMonthProvider((
                                    userId: userId,
                                    month: _selectedMonth,
                                  )),
                                );
                              }
                            },
                          ),
                        )
                      else if (viewModel.activeCategories.isEmpty)
                        const SliverToBoxAdapter(
                          child: EmptyStateWidget(
                            icon: Icons.category_rounded,
                            message: 'Nenhuma categoria ativa.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate(
                              viewModel.activeCategories.map((category) {
                                return AnimatedListItem(
                                  key: ValueKey(category.id),
                                  animation: const AlwaysStoppedAnimation(1.0),
                                  child: AppCard(
                                    onTap: () {
                                      NavigationUtils.push(
                                        context,
                                        AddEditCategoryScreen(
                                          category: category,
                                        ),
                                      );
                                    },
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: category.color
                                                  .withAlpha(
                                                    (255 * 0.2).round(),
                                                  ),
                                              child: Icon(
                                                category.icon,
                                                color: category.color,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.md,
                                            ),
                                            Expanded(
                                              child: Text(
                                                category.name,
                                                style:
                                                    theme.textTheme.titleMedium,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip:
                                                  'Orçamento de ${category.name}',
                                              onPressed: category.id == null
                                                  ? null
                                                  : () => _editBudget(
                                                      category.id!,
                                                      category.name,
                                                      budgets[category.id],
                                                    ),
                                              icon: const Icon(
                                                Icons.tune_rounded,
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ],
                                        ),
                                        if (category.id != null &&
                                            budgets[category.id] != null) ...[
                                          const SizedBox(height: AppSpacing.sm),
                                          Builder(
                                            builder: (context) {
                                              final progress =
                                                  CategoryBudgetRepository.progressFor(
                                                    categoryId: category.id!,
                                                    limitMinor:
                                                        budgets[category.id]!,
                                                    expenses: expenses,
                                                    month: _selectedMonth,
                                                    now: () {
                                                      final now =
                                                          DateTime.now();
                                                      final monthEnd =
                                                          DateTime(
                                                            _selectedMonth.year,
                                                            _selectedMonth
                                                                    .month +
                                                                1,
                                                          ).subtract(
                                                            const Duration(
                                                              microseconds: 1,
                                                            ),
                                                          );
                                                      return now.isBefore(
                                                            monthEnd,
                                                          )
                                                          ? now
                                                          : monthEnd;
                                                    }(),
                                                  );
                                              final spent = Money.fromCents(
                                                progress.spentMinor,
                                              ).formatBrl();
                                              final limit = Money.fromCents(
                                                progress.limitMinor,
                                              ).formatBrl();
                                              final remaining = Money.fromCents(
                                                progress.remainingMinor.abs(),
                                              ).formatBrl();
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$spent de $limit no período',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.xs,
                                                  ),
                                                  LinearProgressIndicator(
                                                    value: progress.fraction
                                                        .clamp(0.0, 1.0),
                                                    color: progress.isExceeded
                                                        ? theme
                                                              .colorScheme
                                                              .error
                                                        : theme
                                                              .colorScheme
                                                              .primary,
                                                    backgroundColor: theme
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.xs,
                                                  ),
                                                  Text(
                                                    progress.isExceeded
                                                        ? '$remaining acima do limite'
                                                        : '$remaining restantes',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              progress
                                                                  .isExceeded
                                                              ? theme
                                                                    .colorScheme
                                                                    .error
                                                              : theme
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ] else
                                          Text(
                                            'Sem limite mensal',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      if (viewModel.categories.any(
                        (category) => category.isArchived,
                      ))
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: ExpansionTile(
                              title: const Text('Categorias arquivadas'),
                              children: [
                                for (final category
                                    in viewModel.categories.where(
                                      (item) => item.isArchived,
                                    ))
                                  ListTile(
                                    title: Text(category.name),
                                    subtitle: const Text(
                                      'Histórico preservado',
                                    ),
                                    trailing: TextButton(
                                      onPressed: userId == null
                                          ? null
                                          : () async {
                                              try {
                                                await viewModel.restoreCategory(
                                                  userId,
                                                  category.copyWith(
                                                    isArchived: false,
                                                  ),
                                                );
                                              } catch (_) {
                                                if (context.mounted) {
                                                  SnackbarService.showError(
                                                    context,
                                                    'Não foi possível reativar a categoria.',
                                                  );
                                                }
                                              }
                                            },
                                      child: const Text('Reativar'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          context: context,
        ),
      ),
      floatingActionButton: AppAnimations.scaleIn(
        FloatingActionButton.extended(
          heroTag: 'fab_categories',
          onPressed: () {
            HapticFeedback.lightImpact();
            NavigationUtils.push(context, const AddEditCategoryScreen());
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova Categoria'),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.borderRadiusXXL,
          ),
          elevation: 0,
        ),

        context: context,
      ),
    );
  }
}

class CategoriesSkeleton extends StatelessWidget {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      96,
    ),
    sliver: SliverList.builder(
      itemCount: 8,
      itemBuilder: (context, index) =>
          const AppSkeletonTile(showSubtitle: false, avatarSize: 40),
    ),
  );
}
