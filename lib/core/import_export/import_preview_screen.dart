import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
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
        return widget.plan.lineResults.where((l) => l.hasErrors || l.hasWarnings).toList();
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Prévia: ${plan.fileName}'),
        elevation: 1,
      ),
      body: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', '${plan.totalLines}', theme.colorScheme.onSurface),
                    _buildStatCard('Válidas', '${plan.validCount}', Colors.green),
                    if (plan.warningCount > 0)
                      _buildStatCard('Avisos', '${plan.warningCount}', Colors.orange),
                    if (plan.invalidCount > 0)
                      _buildStatCard('Inválidas', '${plan.invalidCount}', Colors.red),
                  ],
                ),
                if (plan.detectedType == CsvImportType.expenses) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (plan.totalIncomeMinor > 0)
                        Text(
                          'Receitas: ${Money.fromCents(plan.totalIncomeMinor).formatBrl()}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      if (plan.totalExpenseMinor > 0)
                        Text(
                          'Despesas: ${Money.fromCents(plan.totalExpenseMinor).formatBrl()}',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment<int>(value: 0, label: Text('Todas (${plan.totalLines})')),
                ButtonSegment<int>(value: 1, label: Text('Válidas (${plan.validCount})')),
                ButtonSegment<int>(
                  value: 2,
                  label: Text('Avisos/Erros (${plan.invalidCount + plan.warningCount})'),
                ),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (set) => setState(() => _selectedFilter = set.first),
            ),
          ),

          Expanded(
            child: _filteredLines.isEmpty
                ? const Center(child: Text('Nenhum registro correspondente ao filtro.'))
                : ListView.builder(
                    itemCount: _filteredLines.length,
                    itemBuilder: (context, index) {
                      final item = _filteredLines[index];
                      return _buildLineTile(item, theme);
                    },
                  ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isApplying ? null : () => Navigator.of(context).pop(0),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isApplying || !plan.canProceed) ? null : _onConfirmImport,
                      child: _isApplying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Importar Válidas (${plan.validCount})'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
      trailing = Text(
        exp.money.formatBrl(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: (exp.isIncome ?? false) ? Colors.green : Colors.redAccent,
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
      trailing = Text(rec.money.formatBrl(), style: const TextStyle(fontWeight: FontWeight.bold));
    } else {
      title = 'Linha ${line.lineNumber} (inválida)';
      subtitle = line.rawValues.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusS,
        side: BorderSide(
          color: line.hasErrors
              ? Colors.red.withValues(alpha: 0.5)
              : line.hasWarnings
                  ? Colors.orange.withValues(alpha: 0.5)
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: line.hasErrors ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${line.lineNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: line.hasErrors ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
            if (line.hasWarnings) ...[
              const SizedBox(height: 4),
              ...line.warnings.map(
                (warn) => Text(
                  '• $warn',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
