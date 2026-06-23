import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/features/documents/view/document_detail_screen.dart';

class DocumentListTile extends ConsumerWidget {
  const DocumentListTile({
    super.key,
    required this.doc,
  });

  final Document doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        NavigationUtils.push(context, DocumentDetailScreen(document: doc));
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
            child: Icon(Icons.folder_zip_rounded,
                color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  doc.documentName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  minFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                ),
                if (doc.number != null && doc.number!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Nº: ${doc.number!}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
