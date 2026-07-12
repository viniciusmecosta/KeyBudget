import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/models/folder_model.dart';

class FolderListTile extends ConsumerWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FolderListTile({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: folder.color != null
                  ? Color(int.parse(folder.color!))
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: AppBorders.borderRadiusM,
            ),
            child: Icon(
              Icons.folder,
              color: folder.color != null
                  ? Colors.white
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              folder.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text('Excluir Pasta'),
                        subtitle: const Text(
                          'As credenciais voltarão para a tela principal',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
