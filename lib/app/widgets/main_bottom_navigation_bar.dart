import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:key_budget/app/config/app_theme.dart';
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

    var selectedIndex = navigationViewModel.selectedIndex;
    final tabCount = enableSuppliers ? 6 : 5;
    if (selectedIndex >= tabCount) {
      selectedIndex = tabCount - 1;
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
            rippleColor: theme.colorScheme.primary.withAlpha(
              (255 * 0.1).round(),
            ),
            hoverColor: theme.colorScheme.primary.withAlpha(
              (255 * 0.05).round(),
            ),
            gap: 8,
            activeColor: theme.colorScheme.primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceS,
              vertical: AppTheme.spaceS + 2,
            ),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: theme.colorScheme.primary.withAlpha(
              (255 * 0.1).round(),
            ),
            color: theme.colorScheme.onSurfaceVariant,
            tabs: [
              const GButton(icon: Icons.home_rounded, text: 'Painel'),
              GButton(
                icon: Icons.monetization_on_rounded,
                text: enableIncomes ? 'Lançamentos' : 'Despesas',
              ),
              const GButton(icon: Icons.vpn_key_rounded, text: 'Credenciais'),
              const GButton(
                icon: Icons.folder_copy_rounded,
                text: 'Documentos',
              ),
              if (enableSuppliers)
                const GButton(
                  icon: Icons.storefront_rounded,
                  text: 'Fornecedores',
                ),
              const GButton(icon: Icons.person_rounded, text: 'Perfil'),
            ],
            selectedIndex: selectedIndex,
            onTabChange: (index) {
              HapticFeedback.selectionClick();
              navigationViewModel.selectedIndex = index;
            },
          ),
        ),
      ),
    );
  }
}
