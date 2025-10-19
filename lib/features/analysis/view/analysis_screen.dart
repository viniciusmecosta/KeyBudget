import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/pdf_service.dart';
import 'package:provider/provider.dart';

import '../viewmodel/analysis_viewmodel.dart';
import '../widgets/analysis_stats_overview_widget.dart';
import '../widgets/category_analysis_section_widget.dart';
import '../widgets/monthly_trend_section_widget.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AnalysisViewModel>(context);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              final viewModel =
                  Provider.of<AnalysisViewModel>(context, listen: false);
              PdfService().exportAnalysisPdf(context, viewModel);
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_on),
            onPressed: () {
              final viewModel =
                  Provider.of<AnalysisViewModel>(context, listen: false);
              CsvService().exportAnalysisCsv(context, viewModel);
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
            ? AppAnimations.fadeIn(Center(
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
                ),
              ))
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
                          buildAnimatedWidget(
                              const AnalysisStatsOverviewWidget(), 0),
                          const SizedBox(height: AppTheme.spaceXL),
                          buildAnimatedWidget(
                              _buildSectionHeader(context, 'Histórico Mensal',
                                  'Acompanhe sua evolução ao longo do tempo'),
                              1),
                          const SizedBox(height: AppTheme.spaceM),
                          buildAnimatedWidget(
                              const MonthlyTrendSectionWidget(), 2),
                          const SizedBox(height: AppTheme.spaceXL),
                          buildAnimatedWidget(
                              _buildSectionHeader(
                                  context,
                                  'Análise por Categoria',
                                  'Entenda onde seu dinheiro é gasto'),
                              3),
                          const SizedBox(height: AppTheme.spaceM),
                          buildAnimatedWidget(
                              const CategoryAnalysisSectionWidget(), 4),
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
