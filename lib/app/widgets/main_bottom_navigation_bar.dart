import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
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
    final currentDest = navigationViewModel.currentDestination;
    final destinations = AppDestination.getAvailable(
      enableSuppliers: enableSuppliers,
      hiddenIds:
          authViewModel.currentUser?.hiddenNavigationDestinations ?? const [],
      order: authViewModel.currentUser?.navigationOrder ?? const [],
    );
    final width = MediaQuery.sizeOf(context).width;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    final useTwoRows = destinations.length > 6;
    final useCompactRow = !useTwoRows && (width < 420 || largeText);
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
                    for (var start = 0; start < destinations.length; start += 3)
                      Row(
                        children: [
                          for (
                            var index = start;
                            index < destinations.length && index < start + 3;
                            index++
                          )
                            Expanded(
                              child: Semantics(
                                button: true,
                                selected: activeTabIndex == index,
                                label: destinations[index].label,
                                child: InkWell(
                                  onTap: () => navigationViewModel.navigateTo(
                                    destinations[index],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          destinations[index].icon,
                                          color: activeTabIndex == index
                                              ? theme.colorScheme.primary
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                        Text(
                                          destinations[index] ==
                                                      AppDestination.expenses &&
                                                  !enableIncomes
                                              ? 'Despesas'
                                              : destinations[index].label,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
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
              : useCompactRow
              ? Row(
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      Flexible(
                        flex:
                            activeTabIndex == index &&
                                !largeText &&
                                width >= 320
                            ? 2
                            : 1,
                        child: Semantics(
                          button: true,
                          selected: activeTabIndex == index,
                          label: destinations[index].label,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              navigationViewModel.navigateTo(
                                destinations[index],
                              );
                            },
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              decoration: BoxDecoration(
                                color: activeTabIndex == index
                                    ? theme.colorScheme.primary.withAlpha(26)
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    activeTabIndex == index
                                        ? destinations[index].selectedIcon
                                        : destinations[index].icon,
                                    color: activeTabIndex == index
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    size: 22,
                                  ),
                                  if (activeTabIndex == index &&
                                      !largeText &&
                                      width >= 320) ...[
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        destinations[index] ==
                                                    AppDestination.expenses &&
                                                !enableIncomes
                                            ? 'Despesas'
                                            : destinations[index].label,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
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
                  duration: AppAnimations.durationFor(
                    context,
                    const Duration(milliseconds: 200),
                  ),
                  tabBackgroundColor: theme.colorScheme.primary.withAlpha(
                    (255 * 0.1).round(),
                  ),
                  color: theme.colorScheme.onSurfaceVariant,
                  tabs: destinations
                      .map(
                        (destination) => GButton(
                          icon: destination.icon,
                          text:
                              destination == AppDestination.expenses &&
                                  !enableIncomes
                              ? 'Despesas'
                              : destination.label,
                        ),
                      )
                      .toList(),
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
