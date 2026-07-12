import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/main_bottom_navigation_bar.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/credentials_screen.dart';
import 'package:key_budget/features/dashboard/view/dashboard_screen.dart';
import 'package:key_budget/features/documents/view/documents_screen.dart';
import 'package:key_budget/features/expenses/view/expenses_screen.dart';
import 'package:key_budget/features/suppliers/view/suppliers_screen.dart';
import 'package:key_budget/features/user/view/user_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  List<Widget> _buildWidgetOptions(bool enableSuppliers) {
    return [
      const DashboardScreen(),
      const ExpensesScreen(),
      const CredentialsScreen(),
      const DocumentsScreen(),
      if (enableSuppliers) const SuppliersScreen(),
      const UserScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final navigationViewModel = ref.watch(navigationViewModelProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final theme = Theme.of(context);

    final authViewModel = ref.watch(authViewModelProvider);
    final enableSuppliers = authViewModel.currentUser?.enableSuppliers ?? false;
    final widgetOptions = _buildWidgetOptions(enableSuppliers);

    var selectedIndex = navigationViewModel.selectedIndex;
    if (selectedIndex >= widgetOptions.length) {
      selectedIndex = widgetOptions.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigationViewModel.selectedIndex = selectedIndex;
      });
    }

    final currentWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(
        key: ValueKey<int>(selectedIndex),
        child: isDesktop
            ? ResponsiveCenter(
                maxWidth: 800,
                child: widgetOptions[selectedIndex],
              )
            : widgetOptions[selectedIndex],
      ),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: theme.colorScheme.surface,
              selectedIndex: selectedIndex,
              onDestinationSelected: (int index) {
                navigationViewModel.selectedIndex = index;
              },
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
              ),
              selectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              unselectedIconTheme: IconThemeData(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.home_rounded),
                  label: Text('Painel'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.monetization_on_rounded),
                  label: Text('Lançamentos'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.vpn_key_rounded),
                  label: Text('Credenciais'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.folder_copy_rounded),
                  label: Text('Documentos'),
                ),
                if (enableSuppliers)
                  const NavigationRailDestination(
                    icon: Icon(Icons.storefront_rounded),
                    label: Text('Fornecedores'),
                  ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_rounded),
                  label: Text('Perfil'),
                ),
              ],
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: theme.dividerTheme.color,
            ),
            Expanded(child: currentWidget),
          ],
        ),
      );
    }

    return Scaffold(
      body: currentWidget,
      bottomNavigationBar: const MainBottomNavigationBar(),
    );
  }
}
