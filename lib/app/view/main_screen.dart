import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/import_export/automatic_backup_service.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
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
  late final AutomaticBackupService _automaticBackupService;
  Timer? _automaticBackupTimer;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _automaticBackupService = AutomaticBackupService(
      currentUserId: () => ref.read(authViewModelProvider).currentUser?.id,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutomaticBackup());
    _automaticBackupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _runAutomaticBackup(),
    );
  }

  void _runAutomaticBackup() {
    if (!mounted || ref.read(appLockServiceProvider).isLocked) return;
    final userId = ref.read(authViewModelProvider).currentUser?.id;
    if (userId != null) _automaticBackupService.runIfDue(userId);
  }

  @override
  void dispose() {
    _automaticBackupTimer?.cancel();
    super.dispose();
  }

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
    _loadedDestinations.add(currentDestination);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigationViewModel.updateSuppliersAvailability(enableSuppliers);
    });

    final availableDestinations = AppDestination.getAvailable(
      enableSuppliers: enableSuppliers,
    );

    final activeIndex = availableDestinations.indexOf(currentDestination);
    final navigationIndex = activeIndex >= 0 ? activeIndex : 0;
    final stackIndex = currentDestination == AppDestination.suppliers &&
            !enableSuppliers
        ? 0
        : AppDestination.values.indexOf(currentDestination);

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final isMedium = screenWidth >= 600 && screenWidth < 840;
    final isExpanded = screenWidth >= 840;
    final contentMaxWidth = isCompact
        ? screenWidth
        : (isMedium ? 800.0 : 1200.0);

    final stack = KeyedSubtree(
      key: ValueKey('main_stack_$currentUserId'),
      child: TabSelectionTransition(
        revision: navigationViewModel.selectionRevision,
        child: IndexedStack(
          index: stackIndex,
          children: AppDestination.values.map((dest) {
            final isSelected = dest == currentDestination;
            final isLoaded = _loadedDestinations.contains(dest);
            final child = isLoaded ? _buildDestinationWidget(dest) : const SizedBox.shrink();
            return TickerMode(
              key: ValueKey(dest),
              enabled: isSelected,
              child: ResponsiveCenter(maxWidth: contentMaxWidth, child: child),
            );
          }).toList(),
        ),
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          if (!isCompact) NavigationRail(
            backgroundColor: theme.colorScheme.surface,
            selectedIndex: navigationIndex,
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
          if (!isCompact) VerticalDivider(
            thickness: 1,
            width: 1,
            color: theme.dividerTheme.color,
          ),
          Expanded(child: stack),
        ],
      ),
      bottomNavigationBar: isCompact
          ? const MainBottomNavigationBar()
          : null,
    );
  }
}
