import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class MainBottomNavigationBar extends ConsumerWidget {
  const MainBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationViewModel = ref.watch(navigationViewModelProvider);
    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;
    final enableSuppliers = authViewModel.currentUser?.enableSuppliers ?? false;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final useTwoRows = enableSuppliers &&
        (MediaQuery.sizeOf(context).width < 390 ||
            MediaQuery.textScalerOf(context).scale(14) > 19);

    final currentDest = navigationViewModel.currentDestination;

    final destinations = <AppDestination>[
      AppDestination.dashboard,
      AppDestination.expenses,
      AppDestination.credentials,
      AppDestination.documents,
      if (enableSuppliers) AppDestination.suppliers,
      AppDestination.profile,
    ];
    final activeTabIndex = destinations
        .indexOf(currentDest)
        .clamp(0, destinations.length - 1)
        .toInt();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spaceM,
            vertical: AppTheme.spaceS,
          ),
          child: useTwoRows
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var row = 0; row < 2; row++)
                      Row(
                        children: [
                          for (var column = 0; column < 3; column++)
                            Expanded(
                              child: Semantics(
                                button: true,
                                selected: activeTabIndex == row * 3 + column,
                                label: destinations[row * 3 + column].label,
                                child: InkWell(
                                  onTap: () => navigationViewModel.navigateTo(
                                    destinations[row * 3 + column],
                                  ),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      children: [
                                        Icon(
                                          destinations[row * 3 + column].icon,
                                          color: activeTabIndex == row * 3 + column
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                        Text(
                                          destinations[row * 3 + column] == AppDestination.expenses && !enableIncomes
                                              ? 'Despesas'
                                              : destinations[row * 3 + column].label,
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                )
              : GNav(
            rippleColor: theme.colorScheme.primary.withAlpha(
              (255 * 0.1).round(),
            ),
            hoverColor: theme.colorScheme.primary.withAlpha(
              (255 * 0.05).round(),
            ),
            gap: 8,
            activeColor: theme.colorScheme.primary,
            iconSize: 24,
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spaceS,
              vertical: AppTheme.spaceS + 2,
            ),
            duration: const Duration(milliseconds: 200),
            tabBackgroundColor: theme.colorScheme.primary.withAlpha(
              (255 * 0.1).round(),
            ),
            color: theme.colorScheme.onSurfaceVariant,
            tabs: [
              GButton(icon: Icons.home_rounded, text: 'Painel'),
              GButton(
                icon: Icons.monetization_on_rounded,
                text: enableIncomes ? 'Lançamentos' : 'Despesas',
              ),
              GButton(icon: Icons.vpn_key_rounded, text: 'Credenciais'),
              GButton(
                icon: Icons.folder_copy_rounded,
                text: 'Documentos',
              ),
              if (enableSuppliers)
                GButton(
                  icon: Icons.storefront_rounded,
                  text: 'Fornecedores',
                ),
              GButton(icon: Icons.person_rounded, text: 'Perfil'),
            ],
            selectedIndex: activeTabIndex,
            onTabChange: (index) {
              HapticFeedback.selectionClick();
              navigationViewModel.navigateTo(destinations[index]);
            },
          ),
        ),
      ),
    );
  }
}
