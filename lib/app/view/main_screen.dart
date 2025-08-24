import 'package:flutter/material.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/features/credentials/view/credentials_screen.dart';
import 'package:key_budget/features/dashboard/view/dashboard_screen.dart';
import 'package:key_budget/features/expenses/view/expenses_screen.dart';
import 'package:key_budget/features/user/view/user_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

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
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigationViewModel = Provider.of<NavigationViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(navigationViewModel.selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
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
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              tabs: const [
                GButton(icon: Icons.home_outlined, text: 'Painel'),
                GButton(icon: Icons.payment_outlined, text: 'Gastos'),
                GButton(icon: Icons.vpn_key_outlined, text: 'Senhas'),
                GButton(icon: Icons.person_outline, text: 'Perfil'),
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