import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/expenses/widgets/recurring_expense_form.dart';

class AddEditRecurringExpenseScreen extends ConsumerStatefulWidget {
  final RecurringExpense? expense;

  const AddEditRecurringExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddEditRecurringExpenseScreen> createState() =>
      _AddEditRecurringExpenseScreenState();
}

class _AddEditRecurringExpenseScreenState
    extends ConsumerState<AddEditRecurringExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late MoneyMaskedTextController _amountController;
  late TextEditingController _motivationController;
  late TextEditingController _locationController;
  late ValueNotifier<ExpenseCategory?> _selectedCategory;
  late ValueNotifier<RecurrenceFrequency> _frequency;
  late ValueNotifier<DateTime> _startDate;
  late ValueNotifier<DateTime?> _endDate;
  late ValueNotifier<int> _dayOfMonth;
  late ValueNotifier<int> _advanceGenerationCount;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final categoryViewModel = ref.read(categoryViewModelProvider);

    _amountController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'R\$ ',
      initialValue: widget.expense?.amount ?? 0,
    );
    _motivationController = TextEditingController(
      text: widget.expense?.motivation,
    );
    _locationController = TextEditingController(text: widget.expense?.location);
    _selectedCategory = ValueNotifier(
      categoryViewModel.getCategoryById(widget.expense?.categoryId),
    );
    _frequency = ValueNotifier(
      widget.expense?.frequency ?? RecurrenceFrequency.monthly,
    );
    _startDate = ValueNotifier(widget.expense?.startDate ?? DateTime.now());
    _endDate = ValueNotifier(widget.expense?.endDate);
    _dayOfMonth = ValueNotifier(
      widget.expense?.dayOfMonth ?? DateTime.now().day,
    );
    _advanceGenerationCount = ValueNotifier(
      widget.expense?.advanceGenerationCount ?? 0,
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final viewModel = ref.read(expenseViewModelProvider);
    final userId = ref.read(authViewModelProvider).currentUser!.id;
    final bool isUpdating = widget.expense != null;

    final recurringExpense = RecurringExpense(
      id: widget.expense?.id,
      amount: _amountController.numberValue,
      categoryId: _selectedCategory.value?.id,
      motivation: _motivationController.text,
      location: _locationController.text,
      frequency: _frequency.value,
      startDate: _startDate.value,
      endDate: _endDate.value,
      dayOfMonth: _dayOfMonth.value,
      advanceGenerationCount: _advanceGenerationCount.value,
      lastInstanceDate: widget.expense?.lastInstanceDate,
      isIncome: widget.expense?.isIncome ?? false,
    );

    try {
      if (isUpdating) {
        await viewModel.updateRecurringExpense(userId, recurringExpense);
      } else {
        await viewModel.addRecurringExpense(userId, recurringExpense);
      }
      if (!mounted) return;
      SnackbarService.showSuccess(context, 'Despesa recorrente salva!');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      SnackbarService.showError(context, 'Erro ao salvar despesa.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _delete() async {
    if (widget.expense == null) return;
    HapticFeedback.mediumImpact();

    final result = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorders.radiusL),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apagar recorrência',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Como deseja tratar as faturas vinculadas?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: const Text('Parar de gerar novas'),
                  subtitle: const Text('Mantém todas que já foram criadas.'),
                  onTap: () => Navigator.of(context).pop(0),
                ),
                ListTile(
                  leading: const Icon(Icons.event_busy),
                  title: const Text('Apagar futuras'),
                  subtitle: const Text('Mantém histórico, apaga as futuras.'),
                  onTap: () => Navigator.of(context).pop(1),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Apagar todas',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Apaga todo o histórico e futuras.'),
                  onTap: () => Navigator.of(context).pop(2),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() => _isDeleting = true);

    final viewModel = ref.read(expenseViewModelProvider);
    final userId = ref.read(authViewModelProvider).currentUser!.id;
    final currentContext = context;
    final screenNavigator = Navigator.of(context);
    final deletedExpense = widget.expense!;

    try {
      await viewModel.deleteRecurringExpense(
        userId,
        deletedExpense.id!,
        deleteMode: result,
      );
      if (!currentContext.mounted) return;
      SnackbarService.showUndoSnackbar(
        currentContext,
        message: 'Despesa recorrente excluída.',
        onUndo: () async {
          await viewModel.restoreRecurringExpense(userId, deletedExpense);
        },
      );
      screenNavigator.pop();
    } catch (e) {
      if (!currentContext.mounted) return;
      SnackbarService.showError(currentContext, 'Erro ao excluir despesa.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expense == null
              ? 'Nova Despesa Recorrente'
              : 'Editar Despesa Recorrente',
        ),
        actions: [
          if (widget.expense != null)
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _delete,
                  ),
        ],
      ),
      body: AppAnimations.fadeInFromBottom(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: RecurringExpenseForm(
                  formKey: _formKey,
                  amountController: _amountController,
                  motivationController: _motivationController,
                  locationController: _locationController,
                  selectedCategory: _selectedCategory,
                  frequency: _frequency,
                  startDate: _startDate,
                  endDate: _endDate,
                  dayOfMonth: _dayOfMonth,
                  advanceGenerationCount: _advanceGenerationCount,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  onPressed: _submit,
                  isLoading: _isSaving,
                  label: 'Salvar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
