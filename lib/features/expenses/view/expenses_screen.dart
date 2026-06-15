import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/services.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/balance_card.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/category_filter_modal.dart';
import '../widgets/expense_actions_popup_menu.dart';
import '../widgets/expense_list.dart';
import '../widgets/expenses_list_skeleton.dart';
import '../widgets/month_selector.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = ref.read(authViewModelProvider);
      if (authViewModel.currentUser != null) {
        ref
            .read(categoryViewModelProvider)
            .fetchCategories(authViewModel.currentUser!.id);
        ref
            .read(expenseViewModelProvider)
            .listenToExpenses(authViewModel.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final authViewModel = ref.read(authViewModelProvider);
    if (mounted && authViewModel.currentUser != null) {
      ref
          .read(expenseViewModelProvider)
          .listenToExpenses(authViewModel.currentUser!.id);
    }
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return const CategoryFilterModal();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseViewModel = ref.watch(expenseViewModelProvider);
    final categoryViewModel = ref.watch(categoryViewModelProvider);

    final bool isLoading =
        (expenseViewModel.isLoading || categoryViewModel.isLoading);

    Widget body = RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      strokeWidth: 2.5,
      child: ResponsiveCenter(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  MonthSelector(
                    selectedMonth: expenseViewModel.selectedMonth,
                    isAllPeriods: expenseViewModel.searchAllPeriods,
                    onMonthChanged: (newMonth) {
                      expenseViewModel.setSelectedMonth(newMonth);
                    },
                    onAllPeriodsChanged: (isAll) {
                      expenseViewModel.setSearchAllPeriods(isAll);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.defaultPadding),
                    child: AppAnimations.fadeInFromBottom(
                      TweenAnimationBuilder<double>(
                        key: ValueKey(expenseViewModel.currentMonthTotal),
                        tween: Tween<double>(
                            begin: 0, end: expenseViewModel.currentMonthTotal),
                        duration: AppAnimations.durationSlow,
                        curve: AppAnimations.curve,
                        builder: (context, value, child) {
                          return BalanceCard(
                            title: expenseViewModel.searchAllPeriods
                                ? 'Total filtrado'
                                : 'Total do mês',
                            totalValue: value,
                            backgroundColor: theme.colorScheme.primary,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                ],
              ),
            ),
            if (isLoading)
              const ExpensesListSkeleton()
            else if (expenseViewModel.currentDisplayItems.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Icons.money_off_rounded,
                  message: 'Nenhuma despesa encontrada.',
                ),
              )
            else
              ExpenseList(
                key: ValueKey(
                    '${expenseViewModel.selectedMonth}_${expenseViewModel.searchAllPeriods}'),
                monthlyExpenses: expenseViewModel.currentDisplayItems,
              ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            expenseViewModel.setSearchQuery('');
          });
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      expenseViewModel.setSearchQuery('');
                    });
                  },
                )
              : null,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _isSearching
                ? Container(
                    key: const ValueKey('searchBox'),
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface
                          .withAlpha((255 * 0.08).round()),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      textAlignVertical: TextAlignVertical.center,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Buscar despesas...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  expenseViewModel.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => expenseViewModel.setSearchQuery(val),
                    ),
                  )
                : Text(
                    'Despesas',
                    key: const ValueKey('titleText'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            if (!_isSearching)
              IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: _showCategoryFilter,
              ),
            if (!_isSearching) const ExpenseActionsPopupMenu(),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight((_isSearching ? 56.0 : 0.0) +
                (expenseViewModel.isImportingCsv ||
                        expenseViewModel.isExportingCsv ||
                        expenseViewModel.isExportingPdf
                    ? 4.0
                    : 0.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: _isSearching
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.defaultPadding, vertical: 8),
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    'Mês Atual',
                                    style: TextStyle(
                                      color: !expenseViewModel.searchAllPeriods
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  selected: !expenseViewModel.searchAllPeriods,
                                  selectedColor: theme.colorScheme.primary,
                                  backgroundColor: theme.colorScheme.surface,
                                  side: BorderSide(
                                      color: theme.colorScheme.primary),
                                  showCheckmark: false,
                                  onSelected: (val) {
                                    if (val) {
                                      expenseViewModel
                                          .setSearchAllPeriods(false);
                                    }
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusXL),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceM),
                                ChoiceChip(
                                  label: Text(
                                    'Todo o Período',
                                    style: TextStyle(
                                      color: expenseViewModel.searchAllPeriods
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  selected: expenseViewModel.searchAllPeriods,
                                  selectedColor: theme.colorScheme.primary,
                                  backgroundColor: theme.colorScheme.surface,
                                  side: BorderSide(
                                      color: theme.colorScheme.primary),
                                  showCheckmark: false,
                                  onSelected: (val) {
                                    if (val) {
                                      expenseViewModel
                                          .setSearchAllPeriods(true);
                                    }
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusXL),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (expenseViewModel.isImportingCsv ||
                    expenseViewModel.isExportingCsv ||
                    expenseViewModel.isExportingPdf)
                  const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: AppAnimations.fadeInFromBottom(body),
        ),
        floatingActionButton:
            AppAnimations.scaleIn(FloatingActionButton.extended(
          heroTag: 'fab_expenses',
          onPressed: () {
            HapticFeedback.lightImpact();
            NavigationUtils.push(context, const AddExpenseScreen());
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text("Nova Despesa"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
        )),
      ),
    );
  }
}
