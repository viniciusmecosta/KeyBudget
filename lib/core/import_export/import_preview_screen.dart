import 'package:flutter/material.dart';
import 'package:passfin/core/design_system/borders/app_borders.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/theme/app_semantic_colors.dart';
import 'package:passfin/core/design_system/widgets/app_card.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:passfin/core/models/credential_model.dart';
import 'package:passfin/core/models/expense_model.dart';
import 'package:passfin/core/models/recurring_expense_model.dart';
import 'package:passfin/core/money/money.dart';
import 'package:passfin/core/services/snackbar_service.dart';
import 'csv_import_parser.dart';
import 'import_service.dart';
import 'import_validation.dart';

class ImportPreviewScreen extends StatefulWidget {
  final String userId;
  final ImportExecutionPlan plan;
  final ImportService importService;

  const ImportPreviewScreen({
    super.key,
    required this.userId,
    required this.plan,
    required this.importService,
  });

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  int _selectedFilter = 0;
  bool _isApplying = false;

  List<ImportLineValidation<dynamic>> get _filteredLines {
    switch (_selectedFilter) {
      case 1:
        return widget.plan.lineResults.where((l) => l.isValid).toList();
      case 2:
        return widget.plan.lineResults
            .where((l) => l.hasErrors || l.hasWarnings)
            .toList();
      default:
        return widget.plan.lineResults;
    }
  }

  void _onConfirmImport() async {
    setState(() => _isApplying = true);

    try {
      final result = await widget.importService.applyPlan(
        userId: widget.userId,
        plan: widget.plan,
        importOnlyValid: true,
      );

      if (!mounted) return;

      if (result.isSuccess && result.data != null) {
        final report = result.data!;
        Navigator.of(context).pop(report.createdCount);
        SnackbarService.showUndoSnackbar(
          context,
          message: '${report.createdCount} registros importados com sucesso!',
          onUndo: () async {
            await widget.importService.rollbackImport(
              userId: widget.userId,
              report: report,
              type: widget.plan.detectedType,
            );
          },
        );
      } else {
        SnackbarService.showError(
          context,
          result.safeError ?? 'Erro ao aplicar importação.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Erro: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.plan;
    final statusColors = theme.extension<AppSemanticColors>()!;

    return AppPageScaffold(
      maxContentWidth: 1000,
      appBar: AppBar(title: Text('Prévia: ${plan.fileName}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildStatCard(
                        'Total',
                        '${plan.totalLines}',
                        theme.colorScheme.onSurface,
                      ),
                      _buildStatCard(
                        'Válidas',
                        '${plan.validCount}',
                        statusColors.onSuccessContainer,
                      ),
                      if (plan.warningCount > 0)
                        _buildStatCard(
                          'Avisos',
                          '${plan.warningCount}',
                          statusColors.onWarningContainer,
                        ),
                      if (plan.invalidCount > 0)
                        _buildStatCard(
                          'Inválidas',
                          '${plan.invalidCount}',
                          theme.colorScheme.error,
                        ),
                    ],
                  ),
                  if (plan.detectedType == CsvImportType.expenses) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (plan.totalIncomeMinor > 0)
                          Text(
                            'Receitas: ${Money.fromCents(plan.totalIncomeMinor).formatBrl()}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: statusColors.onSuccessContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (plan.totalExpenseMinor > 0)
                          Text(
                            'Despesas: ${Money.fromCents(plan.totalExpenseMinor).formatBrl()}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _filterChip(0, 'Todas (${plan.totalLines})'),
                _filterChip(1, 'Válidas (${plan.validCount})'),
                _filterChip(
                  2,
                  'Avisos/Erros (${plan.invalidCount + plan.warningCount})',
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredLines.isEmpty
                ? const Center(
                    child: Text('Nenhum registro correspondente ao filtro.'),
                  )
                : ListView.builder(
                    itemCount: _filteredLines.length,
                    itemBuilder: (context, index) =>
                        _buildLineTile(_filteredLines[index], theme),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stackButtons =
                      constraints.maxWidth < 420 ||
                      MediaQuery.textScalerOf(context).scale(14) > 18;
                  final cancel = OutlinedButton(
                    onPressed: _isApplying
                        ? null
                        : () => Navigator.of(context).pop(0),
                    child: const Text('Cancelar'),
                  );
                  final confirm = FilledButton(
                    onPressed: (_isApplying || !plan.canProceed)
                        ? null
                        : _onConfirmImport,
                    child: _isApplying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Importar Válidas (${plan.validCount})'),
                  );
                  if (stackButtons) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cancel,
                        const SizedBox(height: AppSpacing.sm),
                        confirm,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: cancel),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: confirm),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(int value, String label) => FilterChip(
    label: Text(label),
    selected: _selectedFilter == value,
    onSelected: (selected) {
      if (selected) setState(() => _selectedFilter = value);
    },
  );

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }

  Widget _buildLineTile(ImportLineValidation<dynamic> line, ThemeData theme) {
    String title = 'Linha ${line.lineNumber}';
    String subtitle = '';
    Widget? trailing;

    if (line.parsedItem is Expense) {
      final exp = line.parsedItem as Expense;
      title = exp.motivation?.isNotEmpty == true
          ? exp.motivation!
          : (exp.location?.isNotEmpty == true ? exp.location! : 'Despesa');
      final dateFormatted =
          '${exp.date.day.toString().padLeft(2, "0")}/${exp.date.month.toString().padLeft(2, "0")}/${exp.date.year}';
      subtitle = 'Data: $dateFormatted';
      final statusColors = theme.extension<AppSemanticColors>()!;
      trailing = Text(
        exp.money.formatBrl(),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: (exp.isIncome ?? false)
              ? statusColors.onSuccessContainer
              : theme.colorScheme.error,
        ),
      );
    } else if (line.parsedItem is Credential) {
      final cred = line.parsedItem as Credential;
      title = cred.location;
      subtitle = 'Login: ${cred.login}  |  Senha: ••••••••';
    } else if (line.parsedItem is RecurringExpense) {
      final rec = line.parsedItem as RecurringExpense;
      title = rec.motivation ?? 'Recorrência';
      subtitle = 'Frequência: ${rec.frequency.nameInPortuguese}';
      trailing = Text(
        rec.money.formatBrl(),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      title = 'Linha ${line.lineNumber} (inválida)';
      subtitle = line.rawValues.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusL,
        side: BorderSide(
          color: line.hasErrors
              ? theme.colorScheme.error.withValues(alpha: 0.5)
              : line.hasWarnings
              ? theme.extension<AppSemanticColors>()!.warning.withValues(
                  alpha: 0.5,
                )
              : theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: line.hasErrors
                        ? theme.colorScheme.errorContainer
                        : line.hasWarnings
                        ? theme.extension<AppSemanticColors>()!.warningContainer
                        : theme
                              .extension<AppSemanticColors>()!
                              .successContainer,
                    borderRadius: AppBorders.borderRadiusS,
                  ),
                  child: Text(
                    '#${line.lineNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: line.hasErrors
                          ? theme.colorScheme.error
                          : line.hasWarnings
                          ? theme
                                .extension<AppSemanticColors>()!
                                .onWarningContainer
                          : theme
                                .extension<AppSemanticColors>()!
                                .onSuccessContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?trailing,
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
            if (line.hasErrors) ...[
              const SizedBox(height: 4),
              ...line.errors.map(
                (err) => Text(
                  '• $err',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
            if (line.hasWarnings) ...[
              const SizedBox(height: 4),
              ...line.warnings.map(
                (warn) => Text(
                  '• $warn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme
                        .extension<AppSemanticColors>()!
                        .onWarningContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
