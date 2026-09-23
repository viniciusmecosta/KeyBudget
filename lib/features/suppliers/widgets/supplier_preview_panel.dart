import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/models/supplier_model.dart';

class SupplierPreviewPanel extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onOpen;

  const SupplierPreviewPanel({
    super.key,
    required this.supplier,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      (Icons.person_outline, 'Representante', supplier.representativeName),
      (Icons.phone_outlined, 'Telefone', supplier.phoneNumber),
      (Icons.email_outlined, 'E-mail', supplier.email),
      (Icons.notes_outlined, 'Observações', supplier.notes),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fornecedor',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              supplier.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (icon, label, value) in details)
              if (value != null && value.trim().isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(value, style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Abrir detalhes',
                onPressed: onOpen,
                variant: AppButtonVariant.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
