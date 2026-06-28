import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/pdf_service.dart';

import '../viewmodel/analysis_viewmodel.dart';
import '../widgets/analysis_stats_overview_widget.dart';
import '../widgets/category_analysis_section_widget.dart';
import '../widgets/monthly_trend_section_widget.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isFirstLoad = true;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(analysisViewModelProvider);
    final theme = Theme.of(context);

    Widget buildAnimatedWidget(Widget child, int index) {
      if (_isFirstLoad) {
        return AppAnimations.fadeInFromBottom(child,
            delay: Duration(milliseconds: 100 * (index + 1)));
      }
      return child;
    }

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
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting
                ? null
                : () async {
                    setState(() => _isExporting = true);
                    final vm = ref.read(analysisViewModelProvider);
                    await PdfService().exportAnalysisPdf(context, vm);
                    if (mounted) setState(() => _isExporting = false);
                  },
          ),
          IconButton(
            icon: const Icon(Icons.grid_on),
            onPressed: _isExporting
                ? null
                : () async {
                    setState(() => _isExporting = true);
                    final vm = ref.read(analysisViewModelProvider);
                    await CsvService().exportAnalysisCsv(context, vm);
                    if (mounted) setState(() => _isExporting = false);
                  },
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
            ? const AnalysisSkeleton()
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
                          buildAnimatedWidget(
                              const AnalysisStatsOverviewWidget(), 0),
                          const SizedBox(height: AppSpacing.xl),
                          buildAnimatedWidget(
                              const MonthlyTrendSectionWidget(), 1),
                          const SizedBox(height: AppSpacing.xl),
                          buildAnimatedWidget(
                              const CategoryAnalysisSectionWidget(), 2),
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
  const AnalysisSkeleton({super.key});

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
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1500.ms,
          color: shimmerColor,
        );
  }
}
