import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/main_bottom_navigation_bar.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/app/widgets/tab_selection_transition.dart';
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
  final Set<AppDestination> _loadedDestinations = {};
  String? _lastUserId;

  Widget _buildDestinationWidget(AppDestination destination) {
    switch (destination) {
      case AppDestination.dashboard:
        return const DashboardScreen();
      case AppDestination.expenses:
        return const ExpensesScreen();
      case AppDestination.credentials:
        return const CredentialsScreen();
      case AppDestination.documents:
        return const DocumentsScreen();
      case AppDestination.suppliers:
        return const SuppliersScreen();
      case AppDestination.profile:
        return const UserScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationViewModel = ref.watch(navigationViewModelProvider);
    final authViewModel = ref.watch(authViewModelProvider);
    final enableSuppliers = authViewModel.currentUser?.enableSuppliers ?? false;
    final currentUserId = authViewModel.currentUser?.id ?? 'anonymous';

    if (_lastUserId != currentUserId) {
      _lastUserId = currentUserId;
      _loadedDestinations.clear();
    }

    final currentDestination = navigationViewModel.currentDestination;
    final hasVisitedCurrentDestination = _loadedDestinations.contains(
      currentDestination,
    );
    _loadedDestinations.add(currentDestination);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigationViewModel.updateSuppliersAvailability(enableSuppliers);
    });

    final availableDestinations = AppDestination.getAvailable(
      enableSuppliers: enableSuppliers,
    );

    final activeIndex = availableDestinations.indexOf(currentDestination);
    final safeIndex = activeIndex >= 0 ? activeIndex : 0;

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final isMedium = screenWidth >= 600 && screenWidth < 840;
    final isExpanded = screenWidth >= 840;

    final stack = KeyedSubtree(
      key: ValueKey('main_stack_$currentUserId'),
      child: TabSelectionTransition(
        revision: navigationViewModel.selectionRevision,
        enabled: hasVisitedCurrentDestination,
        child: IndexedStack(
          index: safeIndex,
          children: availableDestinations.map((dest) {
            final isSelected = dest == currentDestination;
            final isLoaded = _loadedDestinations.contains(dest);
            final child = isLoaded ? _buildDestinationWidget(dest) : const SizedBox.shrink();
            return TickerMode(
              enabled: isSelected,
              child: isExpanded
                  ? ResponsiveCenter(maxWidth: 1200, child: child)
                  : (isMedium ? ResponsiveCenter(maxWidth: 800, child: child) : child),
            );
          }).toList(),
        ),
      ),
    );

    if (isCompact) {
      return Scaffold(
        body: stack,
        bottomNavigationBar: const MainBottomNavigationBar(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: theme.colorScheme.surface,
            selectedIndex: safeIndex,
            onDestinationSelected: (int index) {
              if (index >= 0 && index < availableDestinations.length) {
                navigationViewModel.navigateTo(availableDestinations[index]);
              }
            },
            labelType: isExpanded
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.selected,
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
            destinations: availableDestinations.map((dest) {
              return NavigationRailDestination(
                icon: Icon(dest.icon),
                selectedIcon: Icon(dest.selectedIcon),
                label: Text(dest.label),
              );
            }).toList(),
          ),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: theme.dividerTheme.color,
          ),
          Expanded(child: stack),
        ],
      ),
    );
  }
}
