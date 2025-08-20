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
    final viewModel = Provider.of<DashboardViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final authViewModel =
                    Provider.of<AuthViewModel>(context, listen: false);
                if (authViewModel.currentUser != null) {
                  await viewModel
                      .fetchDashboardData(authViewModel.currentUser!.id!);
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildCredentialCard(viewModel.credentialCount),
                  const SizedBox(height: 24),
                  _buildChartSection(viewModel),
                ],
              ),
            ),
    );
  }

  Widget _buildCredentialCard(int count) {
    return Card(
      color: AppTheme.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.key, color: AppTheme.accentBlue, size: 32),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppTheme.offWhite),
            ),
            Text(
              'Credenciais Salvas',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.softGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gastos por Categoria',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            _buildMonthSelector(viewModel),
          ],
        ),
        const SizedBox(height: 24),
        if (viewModel.expensesByCategoryForMonth.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('Nenhum gasto neste mês.'),
            ),
          )
        else
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: _generatePieChartSections(
                    viewModel.expensesByCategoryForMonth),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthSelector(DashboardViewModel viewModel) {
    return DropdownButton<DateTime>(
      value: viewModel.selectedMonth,
      onChanged: (DateTime? newValue) {
        if (newValue != null) {
          viewModel.filterExpensesByMonth(newValue);
        }
      },
      items: List.generate(12, (index) {
        final month =
            DateTime(DateTime.now().year, DateTime.now().month - index);
        return DropdownMenuItem<DateTime>(
          value: month,
          child: Text('${month.month}/${month.year}'),
        );
      }),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(
      Map<String, double> data) {
    final List<Color> colors = [
      AppTheme.accentBlue,
      AppTheme.softGrey.withOpacity(0.8),
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
        title: entry.key,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkGrey,
          shadows: [Shadow(color: Colors.white, blurRadius: 2)],
        ),
      );
    }).toList();
  }
}
