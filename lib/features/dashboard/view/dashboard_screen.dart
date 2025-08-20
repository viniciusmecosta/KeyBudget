import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      appBar: AppBar(title: const Text('Dashboard')),
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
                  _buildCredentialCard(context, viewModel.credentialCount),
                  const SizedBox(height: 24),
                  _buildChartSection(context, viewModel),
                  const SizedBox(height: 24),
                  _buildBarChartSection(context, viewModel),
                ],
              ).animate().fade(duration: 500.ms),
            ),
    );
  }

  Widget _buildCredentialCard(BuildContext context, int count) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkGrey
          : AppTheme.darkestGrey,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.key, color: AppTheme.accentTeal, size: 32),
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
                  ?.copyWith(color: AppTheme.offWhite.withAlpha(180)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
      BuildContext context, DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gastos no Mês',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            _buildMonthSelector(context, viewModel),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Total: R\$ ${viewModel.totalAmountForMonth.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
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
                    context, viewModel.expensesByCategoryForMonth),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBarChartSection(
      BuildContext context, DashboardViewModel viewModel) {
    final monthlyTotals = viewModel.monthlyExpenseTotals;
    if (monthlyTotals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Histórico Mensal',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: monthlyTotals.entries.map((entry) {
                final dateParts = entry.key.split('-');
                final month = int.parse(dateParts[1]);
                return BarChartGroupData(
                  x: month,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      color: Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString()))),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(
      BuildContext context, DashboardViewModel viewModel) {
    return DropdownButton<DateTime>(
      value: viewModel.selectedMonth,
      dropdownColor: Theme.of(context).colorScheme.surface,
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
          child: Text(
            '${month.month}/${month.year}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(
      BuildContext context, Map<String, double> data) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final List<Color> colors = [
      AppTheme.accentTeal,
      isDarkMode ? AppTheme.offWhite.withAlpha(200) : AppTheme.darkGrey,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.tertiaryContainer,
    ];
    int colorIndex = 0;

    final titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? AppTheme.darkestGrey : AppTheme.offWhite,
      shadows: const [
        Shadow(
          color: Colors.black26,
          blurRadius: 2,
        )
      ],
    );

    return data.entries.map((entry) {
      final sectionColor = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: sectionColor,
        value: entry.value,
        title: entry.key,
        radius: 100,
        titleStyle: titleStyle,
      );
    }).toList();
  }
}
