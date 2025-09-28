import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:provider/provider.dart';

import '../viewmodel/analysis_viewmodel.dart';
import '../widgets/analysis_stats_overview_widget.dart';
import '../widgets/category_analysis_section_widget.dart';
import '../widgets/monthly_trend_section_widget.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AnalysisViewModel>(context);
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
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Analisando seus dados...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withAlpha((255 * 0.7).round()),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
              )
            : RefreshIndicator(
                onRefresh: () async {},
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppTheme.defaultPadding),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const AnalysisStatsOverviewWidget()
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 100))
                              .slideY(begin: 0.3, end: 0),
                          const SizedBox(height: AppTheme.spaceXL),
                          _buildSectionHeader(context, 'Histórico Mensal',
                                  'Acompanhe sua evolução ao longo do tempo')
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 200))
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: AppTheme.spaceM),
                          const MonthlyTrendSectionWidget()
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 300))
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: AppTheme.spaceXL),
                          _buildSectionHeader(context, 'Análise por Categoria',
                                  'Entenda onde seu dinheiro é gasto')
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 400))
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: AppTheme.spaceM),
                          const CategoryAnalysisSectionWidget()
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 500))
                              .slideY(begin: 0.2, end: 0),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
          ),
        ),
      ],
    );
  }
}
