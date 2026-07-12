import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';

import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/add_edit_category_screen.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authViewModelProvider).currentUser?.id;
      if (userId != null) {
        ref.read(categoryViewModelProvider).fetchCategories(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Categorias')),
      body: SafeArea(
        child: AppAnimations.fadeInFromBottom(
          Consumer(
            builder: (context, ref, _) {
              final viewModel = ref.watch(categoryViewModelProvider);

              return RefreshIndicator(
                onRefresh: () async {
                  final userId = ref
                      .read(authViewModelProvider)
                      .currentUser
                      ?.id;
                  if (userId != null) {
                    await ref
                        .read(categoryViewModelProvider)
                        .fetchCategories(userId);
                  }
                },
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                strokeWidth: 2.5,
                child: ResponsiveCenter(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      if (viewModel.isLoading)
                        const CategoriesSkeleton()
                      else if (viewModel.categories.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateWidget(
                            icon: Icons.category_rounded,
                            message: 'Nenhuma categoria cadastrada.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate(
                              viewModel.categories.map((category) {
                                return AnimatedListItem(
                                  key: ValueKey(category.id),
                                  animation: const AlwaysStoppedAnimation(1.0),
                                  child: AppCard(
                                    onTap: () {
                                      NavigationUtils.push(
                                        context,
                                        AddEditCategoryScreen(
                                          category: category,
                                        ),
                                      );
                                    },
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: category.color
                                              .withAlpha((255 * 0.2).round()),
                                          child: Icon(
                                            category.icon,
                                            color: category.color,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(
                                            category.name,
                                            style: theme.textTheme.titleMedium,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),

                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: AppAnimations.scaleIn(
        FloatingActionButton.extended(
          heroTag: 'fab_categories',
          onPressed: () {
            HapticFeedback.lightImpact();
            NavigationUtils.push(context, const AddEditCategoryScreen());
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova Categoria'),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.borderRadiusXXL,
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
        ),
      ),
    );
  }
}

class CategoriesSkeleton extends ConsumerWidget {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shimmerColor = theme.colorScheme.surface;

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: AppBorders.borderRadiusS,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, color: shimmerColor);
        }, childCount: 8),
      ),
    );
  }
}
