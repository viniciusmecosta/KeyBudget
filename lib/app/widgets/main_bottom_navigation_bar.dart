import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class MainBottomNavigationBar extends ConsumerWidget {
  const MainBottomNavigationBar({super.key});

  void _showMoreMenu(BuildContext context, WidgetRef ref) {
    final navigationViewModel = ref.read(navigationViewModelProvider);
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    'Mais opções',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: const Text('Fornecedores'),
                  selected: navigationViewModel.currentDestination == AppDestination.suppliers,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    navigationViewModel.navigateTo(AppDestination.suppliers);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: const Text('Perfil'),
                  selected: navigationViewModel.currentDestination == AppDestination.profile,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    navigationViewModel.navigateTo(AppDestination.profile);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationViewModel = ref.watch(navigationViewModelProvider);
    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;
    final enableSuppliers = authViewModel.currentUser?.enableSuppliers ?? false;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final currentDest = navigationViewModel.currentDestination;

    int activeTabIndex = 0;
    String fifthTabLabel = 'Perfil';
    IconData fifthTabIcon = Icons.person_rounded;

    if (enableSuppliers) {
      if (currentDest == AppDestination.dashboard) {
        activeTabIndex = 0;
      } else if (currentDest == AppDestination.expenses) {
        activeTabIndex = 1;
      } else if (currentDest == AppDestination.credentials) {
        activeTabIndex = 2;
      } else if (currentDest == AppDestination.documents) {
        activeTabIndex = 3;
      } else if (currentDest == AppDestination.suppliers) {
        activeTabIndex = 4;
        fifthTabLabel = 'Fornecedores';
        fifthTabIcon = Icons.storefront_rounded;
      } else if (currentDest == AppDestination.profile) {
        activeTabIndex = 4;
        fifthTabLabel = 'Perfil';
        fifthTabIcon = Icons.person_rounded;
      }
    } else {
      if (currentDest == AppDestination.dashboard) {
        activeTabIndex = 0;
      } else if (currentDest == AppDestination.expenses) {
        activeTabIndex = 1;
      } else if (currentDest == AppDestination.credentials) {
        activeTabIndex = 2;
      } else if (currentDest == AppDestination.documents) {
        activeTabIndex = 3;
      } else {
        activeTabIndex = 4;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              (255 * (isDarkMode ? 0.15 : 0.04)).round(),
            ),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceM,
            vertical: AppTheme.spaceS,
          ),
          child: GNav(
            rippleColor: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
            hoverColor: theme.colorScheme.primary.withAlpha((255 * 0.05).round()),
            gap: 8,
            activeColor: theme.colorScheme.primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceS,
              vertical: AppTheme.spaceS + 2,
            ),
            duration: const Duration(milliseconds: 200),
            tabBackgroundColor: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
            color: theme.colorScheme.onSurfaceVariant,
            tabs: [
              const GButton(icon: Icons.home_rounded, text: 'Painel'),
              GButton(
                icon: Icons.monetization_on_rounded,
                text: enableIncomes ? 'Lançamentos' : 'Despesas',
              ),
              const GButton(icon: Icons.vpn_key_rounded, text: 'Credenciais'),
              const GButton(icon: Icons.folder_copy_rounded, text: 'Documentos'),
              GButton(
                icon: fifthTabIcon,
                text: fifthTabLabel,
              ),
            ],
            selectedIndex: activeTabIndex,
            onTabChange: (index) {
              HapticFeedback.selectionClick();
              if (index == 0) {
                navigationViewModel.navigateTo(AppDestination.dashboard);
              } else if (index == 1) {
                navigationViewModel.navigateTo(AppDestination.expenses);
              } else if (index == 2) {
                navigationViewModel.navigateTo(AppDestination.credentials);
              } else if (index == 3) {
                navigationViewModel.navigateTo(AppDestination.documents);
              } else if (index == 4) {
                if (enableSuppliers) {
                  _showMoreMenu(context, ref);
                } else {
                  navigationViewModel.navigateTo(AppDestination.profile);
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
