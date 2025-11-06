import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:provider/provider.dart';

class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationViewModel = Provider.of<NavigationViewModel>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
          child: GNav(
            rippleColor:
                theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
            hoverColor:
                theme.colorScheme.primary.withAlpha((255 * 0.05).round()),
            gap: 8,
            activeColor: theme.colorScheme.primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceS, vertical: AppTheme.spaceS + 2),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor:
                theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
            color: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              GButton(icon: Icons.home_rounded, text: 'Painel'),
              GButton(icon: Icons.monetization_on_rounded, text: 'Despesas'),
              GButton(icon: Icons.vpn_key_rounded, text: 'Credenciais'),
              GButton(icon: Icons.folder_copy_rounded, text: 'Documentos'),
              GButton(icon: Icons.person_rounded, text: 'Perfil'),
            ],
            selectedIndex: navigationViewModel.selectedIndex,
            onTabChange: (index) {
              navigationViewModel.selectedIndex = index;
            },
          ),
        ),
      ),
    );
  }
}
