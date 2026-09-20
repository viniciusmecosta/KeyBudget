import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/pdf_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

import '../viewmodel/analysis_viewmodel.dart';
import '../widgets/analysis_stats_overview_widget.dart';
import '../widgets/category_analysis_section_widget.dart';
import '../widgets/global_month_selector_widget.dart';
import '../widgets/monthly_trend_section_widget.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isFirstLoad = true;
  bool _isExporting = false;

  Widget _buildAnimatedWidget(Widget child, int index) {
    if (_isFirstLoad) {
      return AppAnimations.fadeInFromBottom(
        child,
        delay: Duration(milliseconds: 100 * (index + 1)),
      );
    }
    return child;
  }

  void _showExportOptions(BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);
    final snapshot = viewModel.currentSnapshot;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDateStr = dateFormat.format(snapshot.query.range.startInclusive);
    final endDateStr = dateFormat.format(
      snapshot.query.range.endExclusive.subtract(const Duration(milliseconds: 1)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusVerticalXL,
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 48,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withAlpha(50),
                      borderRadius: AppBorders.borderRadiusS,
                    ),
                  ),
                ),
                Text(
                  'Exportar Análise',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Período congelado: $startDateStr até $endDateStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    setState(() => _isExporting = true);
                    await PdfService().exportAnalysisPdf(
                      context,
                      viewModel,
                      snapshot: snapshot,
                    );
                    if (mounted) setState(() => _isExporting = false);
                  },
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Relatório em PDF',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Documento consolidado pronto para impressão',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    setState(() => _isExporting = true);
                    await CsvService().exportAnalysisCsv(
                      context,
                      viewModel,
                      snapshot: snapshot,
                    );
                    if (mounted) setState(() => _isExporting = false);
                  },
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.table_chart_outlined,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Planilha em CSV',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Dados numéricos detalhados para Excel',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(analysisViewModelProvider);
    final enableIncomes =
        ref.watch(authViewModelProvider).currentUser?.enableIncomes ?? false;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Análise Financeira',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _isExporting
              ? const LinearProgressIndicator()
              : const SizedBox(height: 4),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Exportar Relatório',
            onPressed: _isExporting
                ? null
                : () => _showExportOptions(context, viewModel),
          ),
        ],
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: viewModel.isLoading
            ? AnalysisSkeleton(enableIncomes: enableIncomes)
            : RefreshIndicator(
                onRefresh: () async {},
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildAnimatedWidget(
                            const GlobalMonthSelectorWidget(),
                            0,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _buildAnimatedWidget(
                            const AnalysisStatsOverviewWidget(),
                            0,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _buildAnimatedWidget(
                            const CategoryAnalysisSectionWidget(),
                            1,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _buildAnimatedWidget(
                            const MonthlyTrendSectionWidget(),
                            2,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ]),
                      ),
                    ),
                  ],
                ),
              ).animate(
                target: _isFirstLoad ? 1.0 : 0.0,
                onComplete: (controller) {
                  if (_isFirstLoad) {
                    setState(() {
                      _isFirstLoad = false;
                    });
                  }
                },
              ),
      ),
    );
  }
}

class AnalysisSkeleton extends ConsumerWidget {
  final bool enableIncomes;

  const AnalysisSkeleton({super.key, required this.enableIncomes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shimmerColor = theme.colorScheme.surface;

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppBorders.borderRadiusXL,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppBorders.borderRadiusXL,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppBorders.borderRadiusXL,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppBorders.borderRadiusXL,
                ),
              ),
            ]),
          ),
        ),
      ],
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: shimmerColor);
  }
}
