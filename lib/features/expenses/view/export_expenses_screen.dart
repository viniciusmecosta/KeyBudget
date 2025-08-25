import 'package:flutter/material.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class ExportExpensesScreen extends StatefulWidget {
  const ExportExpensesScreen({super.key});

  @override
  State<ExportExpensesScreen> createState() => _ExportExpensesScreenState();
}

class _ExportExpensesScreenState extends State<ExportExpensesScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _export(BuildContext context, {bool all = false}) async {
    final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    bool success;
    if (all) {
      success = await viewModel.exportExpensesToCsv(null, null);
    } else {
      if (_startDate == null || _endDate == null) {
        scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Por favor, selecione um período.')));
        return;
      }
      success = await viewModel.exportExpensesToCsv(_startDate!, _endDate!);
    }

    if (success) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: const Text('Arquivo CSV exportado com sucesso!'),
          backgroundColor: theme.colorScheme.secondaryContainer));
    } else {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: const Text('Falha ao exportar arquivo.'),
          backgroundColor: theme.colorScheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Despesas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: const Text('Selecionar Período'),
              onPressed: _pickDateRange,
            ),
            const SizedBox(height: 16),
            if (_startDate != null && _endDate != null)
              Text(
                'Período: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _export(context),
              child: const Text('Exportar Período Selecionado'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _export(context, all: true),
              child: const Text('Exportar Todo o Histórico'),
            ),
          ],
        ),
      ),
    );
  }
}
