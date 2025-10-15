import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/activity_tile_widget.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:provider/provider.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DashboardViewModel>(context);
    final recentExpenses = viewModel.recentExpenses;

    if (viewModel.isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionHeader(context, 'Atividades Recentes'),
        const SizedBox(height: AppTheme.spaceM),
        if (recentExpenses.isEmpty)
          _buildEmptyState(context)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentExpenses.length > 5 ? 5 : recentExpenses.length,
            itemBuilder: (context, index) {
              return AppAnimations.listFadeIn(
                ActivityTile(
                  expense: recentExpenses[index],
                  index: index,
                ),
                index: index,
              );
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: InkWell(
            onTap: () {
              Provider.of<NavigationViewModel>(context, listen: false)
                  .selectedIndex = 1;
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceM,
                vertical: AppTheme.spaceS,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver todas',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceXS),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.primary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha((255 * 0.08).round()),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(AppTheme.spaceXL),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: theme.colorScheme.primary.withAlpha((255 * 0.7).round()),
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
          Text(
            'Nenhuma atividade recente',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Suas transações aparecerão aqui assim que forem registradas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
