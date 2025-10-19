import 'package:flutter/material.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/analysis/widgets/category_analysis_section_widget.dart';
import 'package:key_budget/features/analysis/widgets/monthly_trend_section_widget.dart';

class AnalysisReportWidget extends StatelessWidget {
  final AnalysisViewModel analysisViewModel;

  const AnalysisReportWidget({
    super.key,
    required this.analysisViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatório de Análise',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                MonthlyTrendSectionWidget(),
                const SizedBox(height: 16),
                CategoryAnalysisSectionWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
