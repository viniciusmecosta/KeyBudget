import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        Provider.of<DashboardViewModel>(context, listen: false)
            .fetchDashboardData(authViewModel.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.expenseByCategory.isEmpty) {
            return const Center(
              child: Text('Sem dados de despesas para exibir.'),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gastos por Categoria (Mês Atual)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: _generatePieChartSections(
                          viewModel.expenseByCategory),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(
      Map<String, double> data) {
    final List<Color> colors = [
      AppTheme.accentBlue,
      AppTheme.darkGrey,
      AppTheme.softGrey,
      Colors.teal,
      Colors.orange,
      Colors.indigo,
    ];
    int colorIndex = 0;

    return data.entries.map((entry) {
      final sectionColor = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: sectionColor,
        value: entry.value,
        title: '${entry.key}\n${entry.value.toStringAsFixed(2)}',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.offWhite,
        ),
      );
    }).toList();
  }
}
