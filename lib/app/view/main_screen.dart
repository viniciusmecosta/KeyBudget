import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/features/credentials/view/credentials_screen.dart';
import 'package:key_budget/features/dashboard/view/dashboard_screen.dart';
import 'package:key_budget/features/expenses/view/expenses_screen.dart';
import 'package:key_budget/features/user/view/user_screen.dart';
import 'package:provider/provider.dart';

import '../../features/documents/view/documents_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    ExpensesScreen(),
    CredentialsScreen(),
    DocumentsScreen(),
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigationViewModel = Provider.of<NavigationViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(navigationViewModel.selectedIndex),
          child: _widgetOptions[navigationViewModel.selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: theme.shadowColor.withAlpha((255 * 0.1).round()),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: theme.splashColor,
              hoverColor: theme.hoverColor,
              gap: 8,
              activeColor: theme.colorScheme.primary,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor:
                  theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
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
      ),
    );
  }
}
