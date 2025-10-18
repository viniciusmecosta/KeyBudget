import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/ocr_service.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/expense_form.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = MoneyMaskedTextController(
      decimalSeparator: ',', thousandSeparator: '.', leftSymbol: 'R\$ ');
  final _motivationController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  ExpenseCategory? _selectedCategory;
  bool _isSaving = false;
  bool _isScanning = false;

  final _ocrService = OcrService();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _motivationController.dispose();
    _locationController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() => _isScanning = true);

      final recognizedText = await _ocrService.processImage(pickedFile);
      final extractedData =
          _ocrService.extractExpenseData(recognizedText.text);

      if (mounted) {
        final amount = extractedData['amount'] as double?;
        final date = extractedData['date'] as DateTime?;
        final description = extractedData['description'] as String?;

        setState(() {
          if (amount != null) _amountController.updateValue(amount);
          if (date != null) _selectedDate = date;
          if (description != null) _motivationController.text = description;
        });

        final foundParts = [
          if (amount != null) 'valor',
          if (date != null) 'data',
          if (description != null) 'descrição'
        ];

        String feedbackMessage;
        if (foundParts.isEmpty) {
          feedbackMessage =
              'Nenhum dado extraído. Por favor, preencha manualmente.';
          SnackbarService.showWarning(context, feedbackMessage);
        } else {
          feedbackMessage =
              '${foundParts.join(', ')} encontrado(s)! Verifique os campos.';
          SnackbarService.showInfo(context, feedbackMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
            context, 'Falha ao analisar a imagem. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                _scanReceipt(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () {
                _scanReceipt(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_amountController.numberValue == 0) {
      SnackbarService.showError(context, 'O valor não pode ser zero.');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final expenseViewModel =
        Provider.of<ExpenseViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser!.id;

    final newExpense = Expense(
      amount: _amountController.numberValue,
      date: _selectedDate,
      categoryId: _selectedCategory?.id,
      motivation: _motivationController.text.isNotEmpty
          ? _motivationController.text
          : null,
      location:
          _locationController.text.isNotEmpty ? _locationController.text : null,
    );

    await expenseViewModel.addExpense(userId, newExpense);

    if (mounted) {
      setState(() => _isSaving = false);
      SnackbarService.showSuccess(context, 'Despesa salva com sucesso!');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Despesa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: _isScanning ? null : _showImageSourceDialog,
            tooltip: 'Escanear Recibo',
          ),
        ],
      ),
      body: AppAnimations.fadeInFromBottom(Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          children: [
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 4),
                    Text('Analisando imagem...'),
                  ],
                ),
              ),
            Expanded(
              child: ExpenseForm(
                formKey: _formKey,
                amountController: _amountController,
                motivationController: _motivationController,
                locationController: _locationController,
                selectedDate: _selectedDate,
                selectedCategory: _selectedCategory,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _motivationController.clear();
                    _locationController.clear();
                  });
                },
                isEditing: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2.0))
                  : const Text('Salvar Despesa'),
            ),
          ],
        ),
      )),
    );
  }
}
