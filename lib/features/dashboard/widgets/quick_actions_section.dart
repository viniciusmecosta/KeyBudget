import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/features/analysis/view/analysis_screen.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:provider/provider.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DashboardViewModel>(context);
    final navigationViewModel =
        Provider.of<NavigationViewModel>(context, listen: false);

    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            title: 'Credenciais',
            subtitle: '${viewModel.credentialCount} cadastradas',
            icon: Icons.security_rounded,
            color: Theme.of(context).colorScheme.secondary,
            onTap: () => navigationViewModel.selectedIndex = 2,
          ),
        ),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
          child: _buildQuickActionCard(
            context,
            title: 'Análise',
            subtitle: 'Ver relatórios',
            icon: Icons.bar_chart_rounded,
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () {
              NavigationUtils.push(context, const AnalysisScreen());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      elevation: 0,
      shadowColor: theme.colorScheme.shadow.withAlpha((255 * 0.05).round()),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha((255 * 0.08).round()),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceS + 2),
                decoration: BoxDecoration(
                  color: color.withAlpha((255 * 0.12).round()),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withAlpha((255 * 0.65).round()),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
