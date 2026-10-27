import 'package:passfin/features/dashboard/widgets/dashboard_insight_chart.dart';
import 'package:passfin/features/dashboard/widgets/dashboard_category_summary.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/app/widgets/responsive_center.dart';
import 'package:passfin/core/design_system/colors/app_contrast.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/features/category/viewmodel/category_viewmodel.dart';
import 'package:passfin/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:passfin/features/dashboard/repository/dashboard_layout_repository.dart';
import 'package:passfin/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:passfin/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:passfin/features/expenses/widgets/expense_sync_indicator.dart';

import '../widgets/dashboard_balance_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_monthly_chart.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_activity_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scrollController = ScrollController();
  final _summaryKey = GlobalKey();
  final _headerProgress = ValueNotifier<double>(0);
  bool _isRefreshing = false;
  bool _hasRenderedContent = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateHeader);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData(isRefresh: false);
    });
  }

  void _updateHeader() {
    final summary = _summaryKey.currentContext?.findRenderObject();
    final height = summary is RenderBox && summary.hasSize
        ? summary.size.height
        : 60.0;
    final progress =
        ((_scrollController.offset - (height - 48).clamp(0, double.infinity)) /
                48)
            .clamp(0.0, 1.0);
    if (_headerProgress.value != progress) _headerProgress.value = progress;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerProgress.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData({bool isRefresh = true}) async {
    final authViewModel = ref.read(authViewModelProvider);
    final userId = authViewModel.currentUser?.id;
    if (userId == null) return;

    if (!mounted || _isRefreshing) return;
    if (!isRefresh) {
      if (_isRefreshing) return;
      setState(() => _isRefreshing = true);
    } else {
      ref.read(dashboardViewModelProvider).triggerRefresh();
      setState(() => _isRefreshing = true);
    }

    try {
      if (authViewModel.currentUser != null && mounted) {
        await ref.read(categoryViewModelProvider).fetchCategories(userId);
        if (!mounted ||
            ref.read(authViewModelProvider).currentUser?.id != userId) {
          return;
        }
        if (isRefresh) {
          await ref
              .read(expenseViewModelProvider)
              .retryListenToExpenses(userId);
          if (!mounted ||
              ref.read(authViewModelProvider).currentUser?.id != userId) {
            return;
          }
          ref
              .read(credentialViewModelProvider)
              .retryListenToCredentials(userId);
        } else {
          ref.read(expenseViewModelProvider).listenToExpenses(userId);
          ref.read(credentialViewModelProvider).listenToCredentials(userId);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível atualizar o painel. Confira a conexão e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Widget _cardFor(String id, DashboardLayout layout) {
    final height = layout.sizeFor(id).chartHeight;
    switch (id) {
      case 'balance':
        return const DashboardBalanceCard();
      case 'accumulated':
        return DashboardInsightChart(
          chartHeight: height,
          insight: DashboardInsight.accumulated,
        );
      case 'periods':
        return DashboardInsightChart(
          chartHeight: height,
          insight: DashboardInsight.periods,
        );
      case 'upcoming':
        return DashboardInsightChart(
          chartHeight: height,
          insight: DashboardInsight.upcoming,
        );
      case 'daily':
        return DashboardInsightChart(
          insight: DashboardInsight.daily,
          chartHeight: height,
        );
      case 'weekdays':
        return DashboardInsightChart(
          insight: DashboardInsight.weekdays,
          chartHeight: height,
        );
      case 'categories':
        return DashboardCategorySummary(chartHeight: height + 4);
      case 'chart':
        return DashboardMonthlyChart(chartHeight: height - 16);
      case 'quick_actions':
        return QuickActionsSection(actionIds: layout.actions);
      default:
        return const RecentActivitySection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final expenseViewModel = ref.watch(expenseViewModelProvider);
    final theme = Theme.of(context);
    final userId = ref.watch(authViewModelProvider).currentUser?.id;
    final layoutState = userId == null
        ? null
        : ref.watch(dashboardLayoutProvider(userId));
    final layout = userId == null
        ? const DashboardLayout()
        : layoutState?.asData?.value ?? const DashboardLayout();

    final integrated =
        layout.integratedSummary && layout.cards.contains('balance');
    final cards = layout.cards
        .where((id) => !integrated || id != 'balance')
        .toList();
    if (!viewModel.isLoading) _hasRenderedContent = true;
    return AppPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ValueListenableBuilder<double>(
          valueListenable: _headerProgress,
          builder: (context, progress, _) {
            final background = Color.lerp(
              integrated
                  ? AppContrast.primaryWithWhiteText(
                      theme.colorScheme.primary,
                      minimumRatio: 7,
                    )
                  : theme.colorScheme.surface,
              theme.colorScheme.surface,
              progress,
            )!;
            return DashboardHeader(
              backgroundColor: background,
              foregroundColor: AppContrast.foregroundOn(background),
              collapsed: progress > .5,
            );
          },
        ),
      ),
      body: SafeArea(
        child: viewModel.isLoading && !_hasRenderedContent
            ? const ResponsiveCenter(maxWidth: 1200, child: DashboardSkeleton())
            : RefreshIndicator(
                onRefresh: _fetchInitialData,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                strokeWidth: 2.5,
                child: ResponsiveCenter(
                  maxWidth: 1200,
                  child: CustomScrollView(
                    controller: _scrollController,
                    scrollBehavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(overscroll: false),
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      if (integrated)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            key: _summaryKey,
                            child: const DashboardBalanceCard(integrated: true),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: ExpenseSyncIndicator(
                            status: expenseViewModel.syncStatus,
                            onRetry: () {
                              final userId = ref
                                  .read(authViewModelProvider)
                                  .currentUser
                                  ?.id;
                              if (userId != null) {
                                expenseViewModel.retryListenToExpenses(userId);
                              }
                            },
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final expanded = constraints.maxWidth >= 840;
                              final width = expanded
                                  ? (constraints.maxWidth - AppSpacing.lg) / 2
                                  : constraints.maxWidth;
                              return Wrap(
                                spacing: AppSpacing.lg,
                                runSpacing: AppSpacing.md,
                                children: [
                                  for (
                                    var index = 0;
                                    index < cards.length;
                                    index++
                                  )
                                    SizedBox(
                                      key: ValueKey(
                                        'dashboard_${cards[index]}',
                                      ),
                                      width:
                                          expanded &&
                                              layout.sizeFor(cards[index]) ==
                                                  DashboardCardSize.large
                                          ? constraints.maxWidth
                                          : width,
                                      child: _cardFor(cards[index], layout),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
