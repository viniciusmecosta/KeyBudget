import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class MainBottomNavigationBar extends ConsumerWidget {
  const MainBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(navigationViewModelProvider);
    final user = ref.watch(authViewModelProvider).currentUser;
    final theme = Theme.of(context);
    final destinations = AppDestination.getAvailable(
      enableSuppliers: user?.enableSuppliers ?? false,
      hiddenIds: user?.hiddenNavigationDestinations ?? const [],
      order: user?.navigationOrder ?? const [],
    );
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;

    Widget destinationButton(AppDestination destination) {
      final selected = navigation.currentDestination == destination;
      final label =
          destination == AppDestination.expenses &&
              !(user?.enableIncomes ?? false)
          ? 'Despesas'
          : destination == AppDestination.expenses
          ? 'Finanças'
          : destination == AppDestination.credentials
          ? 'Cofre'
          : destination == AppDestination.documents
          ? 'Docs'
          : destination.label;
      final color = selected
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant;
      void activate() {
        HapticFeedback.selectionClick();
        navigation.navigateTo(destination);
      }

      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label:
              (destination == AppDestination.credentials ||
                  destination == AppDestination.documents ||
                  destination == AppDestination.expenses &&
                      (user?.enableIncomes ?? false))
              ? destination.label
              : label,
          onTap: activate,
          excludeSemantics: true,
          child: Tooltip(
            message:
                (destination == AppDestination.credentials ||
                    destination == AppDestination.documents ||
                    destination == AppDestination.expenses &&
                        (user?.enableIncomes ?? false))
                ? destination.label
                : label,
            child: InkWell(
              onTap: activate,
              borderRadius: AppBorders.borderRadiusM,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 68, minWidth: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? destination.selectedIcon : destination.icon,
                        color: color,
                        size: 24,
                      ),
                      if (!largeText) ...[
                        const SizedBox(height: 4),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: destinations.length <= 6
                ? Row(children: destinations.map(destinationButton).toList())
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < destinations.length; i += 4)
                        Row(
                          children: destinations
                              .skip(i)
                              .take(4)
                              .map(destinationButton)
                              .toList(),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
