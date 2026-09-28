import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/design_system/widgets/app_feedback_panel.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/money/money_parser.dart';
import 'package:key_budget/core/services/snackbar_service.dart';

import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/repository/category_budget_repository.dart';
import 'package:key_budget/features/category/view/add_edit_category_screen.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authViewModelProvider).currentUser?.id;
      if (userId != null) {
        ref.read(categoryViewModelProvider).fetchCategories(userId);
        ref.read(expenseViewModelProvider).listenToExpenses(userId);
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
                helperText: 'O limite se repete a cada mês.',
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
    );
    controller.dispose();
    if (chosenLimit == null || !mounted) return;
    final userId = ref.read(authViewModelProvider).currentUser?.id;
    if (userId == null) return;
    try {
      await ref
          .read(categoryBudgetRepositoryProvider)
          .setBudget(userId, categoryId, chosenLimit < 0 ? null : chosenLimit);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Categorias')),
      body: SafeArea(
        child: AppAnimations.fadeInFromBottom(
          Consumer(
            builder: (context, ref, _) {
              final viewModel = ref.watch(categoryViewModelProvider);
              final userId = ref.watch(authViewModelProvider).currentUser?.id;
              final expenses = ref.watch(expenseViewModelProvider).allExpenses;
              final budgets = userId == null
                  ? <String, int>{}
                  : ref
                        .watch(categoryBudgetsProvider(userId))
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
                      else if (viewModel.categories.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateWidget(
                            icon: Icons.category_rounded,
                            message: 'Nenhuma categoria cadastrada.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate(
                              viewModel.categories.map((category) {
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
                                                    now: DateTime.now(),
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
                                                    '$spent de $limit no mês',
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
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
        ),

        context: context,
      ),
    );
  }
}

class CategoriesSkeleton extends ConsumerWidget {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shimmerColor = theme.colorScheme.surface;

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: AppBorders.borderRadiusS,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, color: shimmerColor);
        }, childCount: 8),
      ),
    );
  }
}
