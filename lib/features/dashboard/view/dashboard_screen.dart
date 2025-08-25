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
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
    final authViewModel = Provider.of<AuthViewModel>(context);
    final navigationViewModel =
        Provider.of<NavigationViewModel>(context, listen: false);
    final theme = Theme.of(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo(a),',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              user?.name ?? 'Usuário',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  await viewModel.fetchDashboardData(user.id);
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildTotalBalanceCard(context, viewModel),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    context,
                    title: 'Credenciais Salvas',
                    value: viewModel.credentialCount.toString(),
                    icon: Icons.key_rounded,
                    color: theme.colorScheme.secondary,
                    onTap: () => navigationViewModel.selectedIndex = 2,
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 200.ms)
                      .slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Histórico Mensal'),
                  const SizedBox(height: 16),
                  _buildBarChartSection(context, viewModel)
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 300.ms)
                      .slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Últimas Atividades'),
                  const SizedBox(height: 16),
                  _buildRecentActivitySection(context, viewModel),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalBalanceCard(
      BuildContext context, DashboardViewModel viewModel) {
    final theme = Theme.of(context);
    return Card(
      elevation: 8,
      shadowColor: theme.colorScheme.primary.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              Theme.of(context).primaryColorLight
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gasto Total do Mês',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormatter.format(viewModel.totalAmountForMonth),
              style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3);
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: -0.2);
  }

  Widget _buildBarChartSection(
      BuildContext context, DashboardViewModel viewModel) {
    final monthlyTotals = viewModel.lastSixMonthsExpenseTotals;
    final theme = Theme.of(context);
    if (monthlyTotals.isEmpty) return const SizedBox.shrink();

    final chartData = monthlyTotals.entries.toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final value = rod.toY;
                return BarTooltipItem(
                  _currencyFormatter.format(value),
                  TextStyle(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
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
                      style: theme.textTheme.bodySmall,
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
          gridData: const FlGridData(show: false),
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
                      theme.colorScheme.secondary,
                      theme.colorScheme.secondary.withOpacity(0.5)
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 20,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(
      BuildContext context, DashboardViewModel viewModel) {
    final recentExpenses = viewModel.recentExpenses;
    if (recentExpenses.isEmpty) {
      return const Text('Nenhuma atividade recente.');
    }

    return Column(
      children: recentExpenses
          .map((expense) => _buildActivityTile(context, expense))
          .toList(),
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
  }

  Widget _buildActivityTile(BuildContext context, Expense expense) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(expense.category?.icon ?? Icons.category,
              color: theme.colorScheme.primary),
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
          '- ${_currencyFormatter.format(expense.amount)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
