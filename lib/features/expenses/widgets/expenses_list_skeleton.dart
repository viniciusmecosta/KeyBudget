import 'package:flutter/material.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_skeleton_tile.dart';

class ExpensesListSkeleton extends StatelessWidget {
  const ExpensesListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
    sliver: SliverList.builder(
      itemCount: 5,
      itemBuilder: (context, index) => const AppSkeletonTile(trailingWidth: 56),
    ),
  );
}
