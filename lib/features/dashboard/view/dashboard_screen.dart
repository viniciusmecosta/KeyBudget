import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:key_budget/core/models/expense_category.dart';

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
    final navigationViewModel =
        Provider.of<NavigationViewModel>(context, listen: false);

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
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => navigationViewModel.selectedIndex = 1,
                          child: _buildInfoCard(
                            context,
                            title: 'Gasto no Mês',
                            value:
                                'R\$ ${viewModel.totalAmountForMonth.toStringAsFixed(2)}',
                            icon: Icons.monetization_on,
                            color: AppTheme.pink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => navigationViewModel.selectedIndex = 2,
                          child: _buildInfoCard(
                            context,
                            title: 'Credenciais',
                            value: viewModel.credentialCount.toString(),
                            icon: Icons.key,
                            color: AppTheme.blue,
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 150.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 24),
                  _buildBarChartSection(context, viewModel)
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 200.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 24),
                  _buildRecentActivitySection(context, viewModel)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 200.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: theme.brightness == Brightness.dark
          ? AppTheme.darkBlue.withOpacity(0.85)
          : AppTheme.offWhite,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartSection(
      BuildContext context, DashboardViewModel viewModel) {
    final monthlyTotals = viewModel.lastSixMonthsExpenseTotals;
    final theme = Theme.of(context);
    if (monthlyTotals.isEmpty) return const SizedBox.shrink();

    final chartData = monthlyTotals.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Histórico Mensal',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final value = rod.toY;
                    return BarTooltipItem(
                      'R\$ ${value.toStringAsFixed(2)}',
                      const TextStyle(
                        color: AppTheme.offWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= chartData.length) {
                        return const SizedBox.shrink();
                      }
                      final date = chartData[index].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MMM', 'pt_BR').format(date),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.dividerColor.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(chartData.length, (index) {
                final item = chartData[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: item.value,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.pink.withOpacity(0.9),
                          AppTheme.pink.withOpacity(0.6)
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 22,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
      BuildContext context, DashboardViewModel viewModel) {
    final recentExpenses = viewModel.recentExpenses;
    final theme = Theme.of(context);

    if (recentExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Últimas Atividades',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ...recentExpenses
            .map((expense) => _buildActivityTile(context, expense)),
      ],
    );
  }

  Widget _buildActivityTile(BuildContext context, Expense expense) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: theme.brightness == Brightness.dark
          ? AppTheme.darkBlue.withOpacity(0.85)
          : AppTheme.offWhite,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.pink.withOpacity(0.1),
          child: Icon(expense.category?.icon ?? Icons.category,
              color: AppTheme.pink),
        ),
        title: Text(
          expense.location?.isNotEmpty == true
              ? expense.location!
              : (expense.category?.displayName ?? 'Gasto Geral'),
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(expense.date)),
        trailing: Text(
          '- R\$ ${expense.amount.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.pink),
        ),
      ),
    );
  }
}
